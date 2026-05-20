import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../orchestrator/antigravity_orchestrator.dart';
import '../../models/ranking_output.dart';
import '../../models/provider.dart' as model;
import '../widgets/glass_card.dart';
import '../theme.dart';
import 'provider_listing_screen.dart';
import 'ranking_logs_screen.dart';
import '../../main.dart';

// Checked out screen imports for seamless navigation
import '../../screens/booking/notification_screen.dart';
import '../../screens/booking/followup_screen.dart';
import '../../screens/debug/firestore_debug_screen.dart';

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
  
  // Storing final orchestration outcome for clear UI display
  RankedProvider? _selectedProvider;
  model.Provider? _fullProviderDetails;

  late AnimationController _glowController;
  late AnimationController _thinkingPulseController;

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
      final topChoice = await _orchestrator.processUserRequest(text);
      if (topChoice != null) {
        // Fetch full provider details from Firestore to show clear ranking
        final doc = await FirebaseFirestore.instance
            .collection('providers')
            .doc(topChoice.providerId)
            .get();

        if (mounted) {
          setState(() {
            _selectedProvider = topChoice;
            if (doc.exists) {
              _fullProviderDetails = model.Provider.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            }
          });
          HapticFeedback.heavyImpact();
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No suitable provider found or clarification needed. Check logs!'),
            backgroundColor: Color(0xFFEC4899),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Orchestrator Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
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

  void _navigateToNotifications() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationScreen(
          isDarkMode: _isDarkMode,
          sessionId: 'sess_2026_001',
          bookingId: 'book_sess_2026_001',
        ),
      ),
    );
  }

  void _navigateToFollowUp() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowUpScreen(
          isDarkMode: _isDarkMode,
          sessionId: 'sess_2026_001',
          bookingId: 'book_sess_2026_001',
        ),
      ),
    );
  }

  void _navigateToDebugScreen() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FirestoreDebugScreen(
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }

  void _showNavigationPlaceholder(String title) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigation to $title is simulated for downstream development.'),
        backgroundColor: const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 20),
            ),
          ),
          title: Text(
            'BolDo AI',
            style: TextStyle(
              color: themePrimaryText,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.6,
            ),
          ),
          actions: [
            // Follow Up Logs Button
            IconButton(
              icon: Icon(Icons.repeat_rounded, color: themePrimaryText, size: 22),
              onPressed: _navigateToFollowUp,
              tooltip: 'Follow Up Logs',
            ),
            // Notifications Bell
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none_rounded, color: themePrimaryText, size: 22),
                  onPressed: _navigateToNotifications,
                  tooltip: 'Notifications',
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEC4899),
                    ),
                  ),
                ),
              ],
            ),
            // Debug screen icon
            IconButton(
              icon: const Icon(Icons.analytics_outlined, color: Color(0xFF8B5CF6), size: 22),
              onPressed: _navigateToDebugScreen,
              tooltip: 'Observability',
            ),
            // Theme toggle
            IconButton(
              icon: Icon(
                _isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                color: _isDarkMode ? Colors.amber : const Color(0xFF8B5CF6),
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                  themeNotifier.value = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
                });
                HapticFeedback.selectionClick();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            // Decorative background glowing accents
            if (_isDarkMode) ...[
              Positioned(
                top: -100,
                left: -100,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8B5CF6).withOpacity(0.04),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 200,
                right: -100,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEC4899).withOpacity(0.04),
                    ),
                  ),
                ),
              ),
            ],

            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hey, Bol Do Hero Header
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Hey, Bol Do! 👋',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: themePrimaryText,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Speak or type your service request below in English or Urdu.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: themeSecondaryText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Image-style Category & Page Action row (Circular icons with label below)
                        const Text(
                          'QUICK SERVICES & ACTIONS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 96,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildCategoryIcon(
                                icon: Icons.person_outline_rounded,
                                label: 'User Profile',
                                color: const Color(0xFF3B82F6),
                                onTap: () => _showNavigationPlaceholder('User Profile'),
                              ),
                              _buildCategoryIcon(
                                icon: Icons.dashboard_customize_outlined,
                                label: 'Supervisor',
                                color: const Color(0xFF10B981),
                                onTap: () => _showNavigationPlaceholder('Supervisor Dashboard'),
                              ),
                              _buildCategoryIcon(
                                icon: Icons.plumbing_rounded,
                                label: 'Plumbing',
                                color: const Color(0xFF8B5CF6),
                                onTap: () {
                                  _controller.text = 'Mujhe urgent DHA mein plumber chahiye';
                                  HapticFeedback.lightImpact();
                                },
                              ),
                              _buildCategoryIcon(
                                icon: Icons.flash_on_rounded,
                                label: 'Electrical',
                                color: const Color(0xFFEC4899),
                                onTap: () {
                                  _controller.text = 'Need electrician in Tariq Road';
                                  HapticFeedback.lightImpact();
                                },
                              ),
                              _buildCategoryIcon(
                                icon: Icons.construction_rounded,
                                label: 'Carpentry',
                                color: Colors.amber,
                                onTap: () {
                                  _controller.text = 'Need carpenter in Clifton';
                                  HapticFeedback.lightImpact();
                                },
                              ),
                              _buildCategoryIcon(
                                icon: Icons.brush_rounded,
                                label: 'Painting',
                                color: Colors.teal,
                                onTap: () {
                                  _controller.text = 'Need wall painting in Gulshan';
                                  HapticFeedback.lightImpact();
                                },
                              ),
                              _buildCategoryIcon(
                                icon: Icons.ac_unit_rounded,
                                label: 'AC Repair',
                                color: Colors.cyan,
                                onTap: () {
                                  _controller.text = 'AC leak repair Clifton';
                                  HapticFeedback.lightImpact();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sleek Claude-style realtime agent orchestration block
                        if (_isProcessing) ...[
                          _buildClaudeThinkingBlock(themeCardBg, themeBorder, themePrimaryText, themeSecondaryText),
                          const SizedBox(height: 20),
                        ],

                        // Clear AI Selection & Ranking Results Block
                        if (_selectedProvider != null && !_isProcessing) ...[
                          _buildRecommendedProviderBlock(themeCardBg, themeBorder, themePrimaryText, themeSecondaryText),
                          const SizedBox(height: 20),
                        ],

                        // Recent Logs Accordion Section
                        if (!_isProcessing && _selectedProvider == null) ...[
                          const Text(
                            'LIVE ORCHESTRATION PIPELINE MONITOR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 280,
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
                                  .limit(10)
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
                                      padding: const EdgeInsets.all(24.0),
                                      child: Text(
                                        'Orchestrator ready. Submit a voice or text command above to dispatch agents.',
                                        style: TextStyle(color: themeSecondaryText, fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
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
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _isDarkMode ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '🤖 $agent',
                                                style: TextStyle(
                                                  color: agentColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: agentColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  action.toString().toUpperCase(),
                                                  style: TextStyle(color: agentColor, fontSize: 8, fontWeight: FontWeight.w800),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            decision,
                                            style: TextStyle(color: themePrimaryText, fontSize: 13, height: 1.3),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ChatGPT bot-style sticky user input bar at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? const Color(0xDC060608) : Colors.white.withOpacity(0.85),
                      border: Border(
                        top: BorderSide(
                          color: _isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: _isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      style: TextStyle(color: themePrimaryText, fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: _isListening ? 'Listening to speech...' : 'Describe service type & location...',
                                        hintStyle: TextStyle(color: themeSecondaryText.withOpacity(0.6), fontSize: 13),
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: _handleSubmit,
                                    ),
                                  ),
                                  // Voice Button
                                  IconButton(
                                    icon: Icon(
                                      _isListening ? Icons.mic : Icons.mic_none_rounded,
                                      color: _isListening ? const Color(0xFFEC4899) : themeSecondaryText,
                                    ),
                                    onPressed: _handleVoiceInput,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Send Button
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                              onPressed: () => _handleSubmit(_controller.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Quick Category items builder (circular avatars with label)
  Widget _buildCategoryIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isPageAction = label == 'User Profile' || label == 'Supervisor';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPageAction
                      ? color.withOpacity(0.4)
                      : (_isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF4B5563),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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
            color: const Color(0xFF8B5CF6).withOpacity(0.05),
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Live agent coordination stream
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('workflow_logs')
                .orderBy('timestamp', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Text(
                  'Activating intent analysis agents...',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
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
                              style: TextStyle(color: secondaryText, fontSize: 11.5, height: 1.3),
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
                    style: TextStyle(
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryText),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _fullProviderDetails != null ? '${_fullProviderDetails!.rating}' : '4.8',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryText),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.directions_car_rounded, color: Color(0xFF8B5CF6), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          distanceStr,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: secondaryText),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.payments_outlined, color: Colors.tealAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          basePriceStr,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Clean Customer Reasoning Section
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
                const Text(
                  '💡 AI RECOMMENDATION REASONING',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8B5CF6),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.reasoning,
                  style: TextStyle(
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
          // Action button
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'BOOK NOW WITH THIS EXPERT',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.6),
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
