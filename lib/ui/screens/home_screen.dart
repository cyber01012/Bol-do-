import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../orchestrator/antigravity_orchestrator.dart';
import '../widgets/glass_card.dart';
import 'provider_listing_screen.dart';
import 'ranking_logs_screen.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final AntigravityOrchestrator _orchestrator = AntigravityOrchestrator();
  bool _isProcessing = false;
  bool _isListening = false;
  String _currentSpeechText = '';

  @override
  void initState() {
    super.initState();
    _initializeOrchestrator();
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeOrchestrator() async {
    await _orchestrator.initialize();
  }

  Future<void> _handleSubmit(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final topChoice = await _orchestrator.processUserRequest(text);
      if (topChoice != null) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderListingScreen(
              requestedService: text,
              initialTopChoiceId: topChoice.providerId,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No suitable provider found or clarification needed. Check logs!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
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
      _currentSpeechText = 'Listening...';
    });

    // Mock speech recognition delay
    await Future.delayed(const Duration(seconds: 3));

    // Sample multilingual speech outputs commonly expected
    final voiceInputs = [
      'Mujhe kal subah plumber chahiye DHA mein',
      'Need AC technician tomorrow morning',
      'kal electrician urgent Saddar mein',
    ];
    final selectedInput = (voiceInputs..shuffle()).first;

    setState(() {
      _isListening = false;
      _currentSpeechText = selectedInput;
      _controller.text = selectedInput;
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone not available. Running in simulated voice mode...'),
          duration: Duration(seconds: 2),
        ),
      );
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
        SnackBar(content: Text('STT Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BOLDO AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: BolDoTheme.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RankingLogsScreen()),
              );
            },
            tooltip: 'View AI Trace Logs',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Header
            const Text(
              'Hey, Bol Do!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: BolDoTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Speak or type your home service request in Urdu, Roman Urdu, or English.',
              style: TextStyle(
                fontSize: 14,
                color: BolDoTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Live Trace Widget (Frosted Glass Container)
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AI ORCHESTRATOR TRACE',
                          style: TextStyle(
                            color: BolDoTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Icon(Icons.developer_board, color: BolDoTheme.primary, size: 16),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('workflow_logs')
                            .orderBy('timestamp', descending: true)
                            .limit(10)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No trace logs yet. Try starting a workflow!',
                                style: TextStyle(color: BolDoTheme.textSecondary),
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs;
                          return ListView.builder(
                            reverse: true,
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final agent = data['agent'] ?? 'System';
                              final decision = data['decision'] ?? '';
                              final reasoning = data['reasoning'] ?? '';
                              final action = data['action_taken'] ?? '';
                              final severity = data['severity'] ?? 'info';

                              Color severityColor = Colors.white60;
                              if (severity == 'warning') severityColor = Colors.orangeAccent;
                              if (severity == 'critical') severityColor = Colors.redAccent;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '[$agent] - $action',
                                            style: const TextStyle(
                                              color: BolDoTheme.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Icon(
                                            Icons.lens,
                                            size: 8,
                                            color: severityColor,
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        decision,
                                        style: const TextStyle(
                                          color: BolDoTheme.textPrimary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (reasoning.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          reasoning,
                                          style: const TextStyle(
                                            color: BolDoTheme.textSecondary,
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Speech Simulation Feedback
            if (_isListening || _isProcessing) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(BolDoTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isListening ? 'Speech-to-Text Processing...' : 'AI Orchestration In Progress...',
                        style: const TextStyle(color: BolDoTheme.primary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Proceed button shown when there is text
            if (_controller.text.trim().isNotEmpty && !_isListening && !_isProcessing) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [BolDoTheme.primary, Colors.tealAccent],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: BolDoTheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _handleSubmit(_controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PROCEED WITH REQUEST',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Input Form
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: BolDoTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Type your request here...',
                        hintStyle: TextStyle(color: Colors.white30),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _handleSubmit,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isProcessing ? null : _handleVoiceInput,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: const BoxDecoration(
                      color: BolDoTheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: BolDoTheme.primary,
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: const Icon(Icons.mic, color: BolDoTheme.background),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
