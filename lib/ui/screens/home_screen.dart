import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../orchestrator/antigravity_orchestrator.dart';
import '../../models/ranking_output.dart';
import '../../models/provider.dart' as model;
import '../widgets/glass_card.dart';
import '../theme.dart';
import 'provider_listing_screen.dart';
import 'provider_detail_screen.dart';
import 'ranking_logs_screen.dart';
import '../../main.dart';
import '../widgets/boldo_app_bar.dart';
import '../widgets/boldo_bottom_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final AntigravityOrchestrator _orchestrator = AntigravityOrchestrator();
  
  bool _isDarkMode = true;
  bool _isProcessing = false;
  bool _isListening = false;
  
  RankedProvider? _selectedProvider;
  model.Provider? _fullProviderDetails;

  late AnimationController _glowController;
  late AnimationController _thinkingPulseController;

  final List<String> _suggestions = [
    "need electrician in gulshan",
    "urgent plumber Clifton",
    "need carpentry Clifton",
    "ac repair DHA Clifton",
  ];

  @override
  void initState() {
    super.initState();
    _initializeOrchestrator();
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _thinkingPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    _thinkingPulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeOrchestrator() async {
    await _orchestrator.initialize();
  }

  Future<void> _handleSubmit(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _selectedProvider = null;
      _fullProviderDetails = null;
    });

    HapticFeedback.mediumImpact();

    try {
      // Step 1: Extract intent
      final intent = await _orchestrator.extractIntent(text);
      if (intent == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not understand your request. Please try again.'),
            backgroundColor: Color(0xFFEC4899),
          ),
        );
        return;
      }

      // Step 2: Discover providers
      final providers = await _orchestrator.discoverProviders(intent);
      if (providers.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No providers found in your area.'),
            backgroundColor: Color(0xFFEC4899),
          ),
        );
        return;
      }

      // Step 3: Navigate to ProviderListingScreen and pass ranking future
      if (!mounted) return;
      
      final rankingFuture = _orchestrator.rankProviders(providers, intent.serviceType);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProviderListingScreen(
            requestedService: intent.serviceType,
            rankingFuture: rankingFuture,
          ),
        ),
      );
      
      // We don't wait here; _handleSubmit finishes. ProviderListingScreen will handle the future.
    } catch (e) {
      if (!mounted) return;
      
      String errorMsg = e.toString();
      if (errorMsg.contains('quota') || errorMsg.contains('limit')) {
        errorMsg = 'Gemini API Quota Exceeded. Please try again in a moment.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _controller.clear();
        });
      }
    }
  }

  void _simulateVoiceInput() async {
    setState(() {
      _isListening = true;
      _controller.text = 'Listening...';
    });

    await Future.delayed(const Duration(seconds: 3));

    final voiceInputs = [
      'plumber urgent DHA Phase 5',
      'Need John Carpenter in Clifton',
      'Mujhe kal subah electrician chahiye Tariq Road mein',
    ];
    final selectedInput = (voiceInputs..shuffle()).first;

    setState(() {
      _isListening = false;
      _controller.text = selectedInput;
    });
    HapticFeedback.lightImpact();
  }

  void _handleVoiceInput() async {
    final voiceAgent = _orchestrator.voiceAgent;

    if (_isListening) {
      await voiceAgent.stopListening();
      setState(() {
        _isListening = false;
      });
      return;
    }

    if (!voiceAgent.isAvailable) {
      _simulateVoiceInput();
      return;
    }

    setState(() {
      _isListening = true;
      _controller.text = 'Listening...';
    });

    try {
      await voiceAgent.startListening(
        onResult: (text) {
          setState(() {
            _controller.text = text;
          });
        },
      );

      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return false;
        if (!voiceAgent.isListening && _isListening) {
          setState(() {
            _isListening = false;
          });
          return false;
        }
        return _isListening;
      });

    } catch (e) {
      setState(() {
        _isListening = false;
        _controller.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech Error: $e')),
      );
    }
  }

  void _showNavigationPlaceholder(String title) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title dashboard configuration is active.'),
        backgroundColor: const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        _isDarkMode = currentMode == ThemeMode.dark;
        final themeBg = _isDarkMode ? const Color(0xFF060608) : const Color(0xFFF4F6F9);
        final themePrimaryText = _isDarkMode ? Colors.white : const Color(0xFF1E2025);
        final themeSecondaryText = _isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);
        final themeCardBg = _isDarkMode ? const Color(0xFF121216) : Colors.white;
        final themeBorder = _isDarkMode ? const Color(0xFF232330) : const Color(0xFFE5E7EB);
        final appTheme = _isDarkMode ? BolDoTheme.darkTheme : BolDoTheme.lightTheme;

        return Theme(
          data: appTheme,
          child: Scaffold(
            backgroundColor: themeBg,
            extendBody: true,
            appBar: const BolDoAppBar(),
            body: Stack(
          children: [
            // Decorative background glowing accents
            if (_isDarkMode) ...[
              Positioned(
                top: -150,
                left: -150,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8B5CF6).withOpacity(0.06),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                right: -150,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEC4899).withOpacity(0.05),
                    ),
                  ),
                ),
              ),
            ],

            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          
                          // Animated Big bold brand name with premium glowing effect
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 1200),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutBack,
                            builder: (context, double value, child) {
                              return Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: Opacity(
                                  opacity: value.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                            child: ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF3B82F6)],
                              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                              child: Text(
                                'Bol Do',
                                style: GoogleFonts.poppins(
                                  fontSize: 70,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -2.0,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Tagline in Urdu
                          Text(
                            'Kya Home Services Chahiye?',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: themeSecondaryText,
                              letterSpacing: -0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Centered ChatGPT-style Floating Input Island Pill
                          Container(
                            decoration: BoxDecoration(
                              color: themeCardBg,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _isProcessing 
                                  ? const Color(0xFF8B5CF6).withOpacity(0.5) 
                                  : themeBorder,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isDarkMode ? const Color(0xFF8B5CF6) : Colors.black).withOpacity(0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    style: GoogleFonts.poppins(color: themePrimaryText, fontSize: 15),
                                    decoration: InputDecoration(
                                      hintText: _isListening ? 'Listening to speech...' : 'Type service & location (e.g. plumber Clifton)...',
                                      hintStyle: GoogleFonts.poppins(color: themeSecondaryText.withOpacity(0.55), fontSize: 13.5),
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: _handleSubmit,
                                  ),
                                ),
                                
                                // Voice Mic Button
                                Tooltip(
                                  message: "Voice Assistant",
                                  child: IconButton(
                                    icon: Icon(
                                      _isListening ? Icons.mic : Icons.mic_none_rounded,
                                      color: _isListening ? const Color(0xFFEC4899) : themeSecondaryText,
                                      size: 22,
                                    ),
                                    onPressed: _handleVoiceInput,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                
                                // Gradient Send Button
                                Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                                    onPressed: () => _handleSubmit(_controller.text),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Small Interactive Suggestion Chips
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _suggestions.map((suggestion) {
                              return GestureDetector(
                                onTap: () {
                                  _controller.text = suggestion;
                                  _handleSubmit(suggestion);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: themeCardBg.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: themeBorder),
                                  ),
                                  child: Text(
                                    suggestion,
                                    style: GoogleFonts.poppins(
                                      color: themeSecondaryText,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 40),

                          // Live Agent Pipeline Thinking Block
                          if (_isProcessing) ...[
                            _buildClaudeThinkingBlock(themeCardBg, themeBorder, themePrimaryText, themeSecondaryText),
                            const SizedBox(height: 20),
                          ],

                          // Selected Recommended Provider Results Block
                          if (_selectedProvider != null && !_isProcessing) ...[
                            _buildRecommendedProviderBlock(themeCardBg, themeBorder, themePrimaryText, themeSecondaryText),
                            const SizedBox(height: 20),
                          ],

                          // Stream of Live Pipeline Logs at bottom
                          if (_isProcessing) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'LIVE PIPELINE MONITOR',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: const Color(0xFF8B5CF6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: themeCardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: themeBorder),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('workflow_logs')
                                    .orderBy('timestamp', descending: true)
                                    .limit(5)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                                      ),
                                    );
                                  }
                                  final docs = snapshot.data?.docs ?? [];
                                  if (docs.isEmpty) {
                                    return Center(
                                      child: Padding(
                                        child: Text(
                                          'Orchestrator ready. Submit a suggestion above to initiate agent workflow.',
                                          style: GoogleFonts.poppins(color: themeSecondaryText, fontSize: 12),
                                          textAlign: TextAlign.center,
                                        ),
                                        padding: const EdgeInsets.all(20),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    itemCount: docs.length,
                                    physics: const BouncingScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final data = docs[index].data() as Map<String, dynamic>;
                                      final agent = data['agent'] ?? 'System';
                                      final decision = data['decision'] ?? '';
                                      final action = data['action_taken'] ?? '';
                                      final severity = data['severity'] ?? 'info';
                                      
                                      Color agentColor = const Color(0xFF8B5CF6);
                                      if (agent.toString().contains('Intent')) agentColor = const Color(0xFF3B82F6);
                                      if (agent.toString().contains('Discovery')) agentColor = const Color(0xFFEC4899);
                                      if (agent.toString().contains('Ranking')) agentColor = Colors.amber;
                                      if (severity == 'critical') agentColor = const Color(0xFFEF4444);

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _isDarkMode ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.01),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '🤖 $agent',
                                                  style: GoogleFonts.poppins(
                                                    color: agentColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                Text(
                                                  action.toString().toUpperCase(),
                                                  style: GoogleFonts.poppins(color: agentColor.withOpacity(0.8), fontSize: 8, fontWeight: FontWeight.w800),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              decision,
                                              style: GoogleFonts.poppins(color: themePrimaryText, fontSize: 12, height: 1.3),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: const BolDoBottomBar(isHome: true),
            ),
          ],
        ),
      ),
    );
  },
);
  }

  // Claude-style realtime thinking block
  Widget _buildClaudeThinkingBlock(Color cardBg, Color border, Color primaryText, Color secondaryText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _thinkingPulseController,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8B5CF6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(_thinkingPulseController.value * 0.6 + 0.2),
                          blurRadius: 8,
                          spreadRadius: _thinkingPulseController.value * 3,
                        )
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Text(
                'BolDo Orchestrator is thinking...',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('workflow_logs')
                .orderBy('timestamp', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Text(
                  'Activating intent analysis agents...',
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final agent = data['agent'] ?? '';
                  final decision = data['decision'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⚡ ', style: TextStyle(fontSize: 10)),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(color: secondaryText, fontSize: 11.5, height: 1.3),
                              children: [
                                TextSpan(
                                  text: '[$agent]: ',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                                ),
                                TextSpan(text: decision),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Recommended provider block showing direct results & clear reasoning on homepage
  Widget _buildRecommendedProviderBlock(Color cardBg, Color border, Color primaryText, Color secondaryText) {
    if (_selectedProvider == null) return const SizedBox.shrink();

    final p = _selectedProvider!;
    final basePriceStr = _fullProviderDetails != null ? 'Rs ${_fullProviderDetails!.basePrice}' : 'Flexible Rates';
    final distanceStr = _fullProviderDetails != null ? '${_fullProviderDetails!.distanceKm} km' : 'Nearby';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'BEST MATCH EXPERT FOUND!',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Score: ${p.score.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                child: const Icon(Icons.person_rounded, color: Color(0xFF8B5CF6), size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: primaryText),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _fullProviderDetails != null ? '${_fullProviderDetails!.rating}' : '4.8',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: primaryText),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.directions_car_rounded, color: Color(0xFF8B5CF6), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          distanceStr,
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: secondaryText),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.payments_outlined, color: Colors.tealAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          basePriceStr,
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: primaryText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 AI RECOMMENDATION REASONING',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF8B5CF6),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.reasoning,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.4,
                    color: primaryText.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Confirming booking slot with ${p.name}...'),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'BOOK NOW WITH THIS EXPERT',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
