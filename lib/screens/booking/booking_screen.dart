import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Agent imports
import '../../agents/pricing_agent/pricing_agent_service.dart';
import '../../agents/pricing_agent/pricing_model.dart';
import '../../agents/booking_agent/booking_agent_service.dart';
import '../../agents/booking_agent/booking_model.dart' as booking;
import '../../agents/notification_agent/notification_agent_service.dart';
import '../../agents/followup_agent/followup_agent_service.dart';
import '../../agents/followup_agent/followup_model.dart';
import '../../agents/supervisor_agent/supervisor_agent_service.dart';

// Screen imports
import 'widgets/booking_header.dart';
import 'widgets/provider_card.dart';
import 'widgets/price_breakdown.dart';
import 'widgets/workflow_timeline.dart';
import 'widgets/integrity_audit.dart';
import 'widgets/dispute_banner.dart';
import 'trace_logs_screen.dart';
import 'dispute_screen.dart';
import 'notification_screen.dart';
import 'followup_screen.dart';
import '../supervisor/supervisor_dashboard_screen.dart';

class BookingScreen extends StatefulWidget {
  final String sessionId;
  final String userId;
  final String serviceType;
  final PricingResponse pricingResponse;
  final dynamic provider; // using dynamic to avoid tight coupling if not needed, or we can use app_models.Provider
  final Future<void> Function()? onRunRawPipeline;

  const BookingScreen({
    super.key,
    required this.sessionId,
    required this.userId,
    required this.serviceType,
    required this.pricingResponse,
    required this.provider,
    this.onRunRawPipeline,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with TickerProviderStateMixin {
  // Theme state
  bool _isDarkMode = true;

  // Active Session & Booking IDs
  String _currentSessionId = 'sess_2026_001';
  String _currentBookingId = 'book_sess_2026_001';

  // Booking states
  bool _isOrchestrating = false;
  bool _hasError = false;
  String? _errorMessage;

  // Timestamps for the timeline steps
  String _timeIntent = '--:--:--';
  String _timeRanked = '--:--:--';
  String _timePricing = '--:--:--';
  String _timeBooking = '--:--:--';
  String _timeNotification = '--:--:--';
  String _timeFollowup = '--:--:--';

  // Animation controller
  late AnimationController _pulseController;
  StreamSubscription<DocumentSnapshot>? _sessionSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Trigger orchestration on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("BOOKING START");
      print("[BookingScreen] Session: ${widget.sessionId}");
      print("[BookingScreen] Provider: ${widget.provider.name}");
      print("[BookingScreen] Price: ${widget.pricingResponse.pricingData.totalPricePkr}");
      _runRealAIOrchestration();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sessionSubscription?.cancel();
    super.dispose();
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _runRealAIOrchestration() async {
    if (_isOrchestrating) {
      print("[BookingScreen] Pipeline already running — ignoring duplicate call.");
      return;
    }

    // Cancel any existing Firestore listener before creating a new one
    await _sessionSubscription?.cancel();
    _sessionSubscription = null;

    setState(() {
      _isOrchestrating = true;
      _currentSessionId = widget.sessionId;
      _currentBookingId = 'book_${widget.sessionId}';
      _timeIntent = _formatCurrentTime();
      _timeRanked = _formatCurrentTime();
      _timePricing = _formatCurrentTime();
      _timeBooking = '--:--:--';
      _timeNotification = '--:--:--';
      _timeFollowup = '--:--:--';
      _hasError = false;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 300));

    // Subscribe to Firestore for real-time orchestration session updates
    _sessionSubscription = FirebaseFirestore.instance
        .collection('orchestration_sessions')
        .doc(widget.sessionId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      final data = snapshot.data();
      if (data == null) return;

      final completed = data['completed_agents'] as Map? ?? {};
      final orchestrationStatus = data['orchestration_status'] as String? ?? 'running';
      final pipelineStatus = data['pipeline_status'] as String? ?? 'pending';

      setState(() {
        if (completed['PricingAgent'] == true && _timePricing == '--:--:--') {
          _timePricing = _formatCurrentTime();
          HapticFeedback.lightImpact();
        }
        if (completed['BookingAgent'] == true && _timeBooking == '--:--:--') {
          _timeBooking = _formatCurrentTime();
          HapticFeedback.mediumImpact();
        }
        if (completed['NotificationAgent'] == true && _timeNotification == '--:--:--') {
          _timeNotification = _formatCurrentTime();
          HapticFeedback.lightImpact();
        }
        if (completed['FollowUpAgent'] == true && _timeFollowup == '--:--:--') {
          _timeFollowup = _formatCurrentTime();
          HapticFeedback.heavyImpact();
          _isOrchestrating = false;
        }
        
        final String? bId = data['booking_id'] as String?;
        if (bId != null && bId.isNotEmpty) {
          _currentBookingId = bId;
        }

        if (orchestrationStatus == 'failed' || pipelineStatus == 'failed') {
          _hasError = true;
          _isOrchestrating = false;
          _errorMessage = data['error_message'] as String? ?? "An error occurred during supervisor orchestration.";
          HapticFeedback.vibrate();
          // Snackbar is handled exclusively by the catch block to prevent duplicates.
        }
      });
    });

    try {
      final supervisor = SupervisorAgentService();
      await supervisor.runBookingPipeline(
        sessionId: widget.sessionId,
        userId: widget.userId,
        serviceType: widget.serviceType,
        pricingResponse: widget.pricingResponse,
      );

      if (widget.onRunRawPipeline != null) {
        widget.onRunRawPipeline!();
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst("Exception: ", "");
        setState(() {
          _isOrchestrating = false;
          _hasError = true;
          _errorMessage = errorMsg;
        });
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _navigateToTraceLogs() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TraceLogsScreen(
          sessionId: _currentSessionId,
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }

  void _navigateToFollowUp() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowUpScreen(
          sessionId: _currentSessionId,
          bookingId: _currentBookingId,
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }

  void _navigateToDispute() {
    HapticFeedback.heavyImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisputeScreen(
          sessionId: _currentSessionId,
          bookingId: _currentBookingId,
          customerId: 'user_customer_999',
          providerId: 'provider_001',
          bookingStatus: 'confirmed',
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }

  void _navigateToDebugScreen() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupervisorDashboardScreen(
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeBg = _isDarkMode ? const Color(0xFF0C0C0E) : const Color(0xFFF4F6F9);
    final themeCardBg = _isDarkMode ? const Color(0xFF16161C) : Colors.white;
    final themeBorder = _isDarkMode ? const Color(0xFF232330) : const Color(0xFFE5E7EB);
    final themePrimaryText = _isDarkMode ? Colors.white : const Color(0xFF1E2025);

    final appTheme = _isDarkMode
        ? ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
          )
        : ThemeData.light(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.light,
            ),
          );

    return Theme(
      data: appTheme,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkMode
                ? [const Color(0xFF060608), const Color(0xFF110C1B)]
                : [const Color(0xFFE5E7EB), const Color(0xFFD1D5DB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 600;

              // Firestore Streams
              final contentWidget = StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orchestration_sessions')
                    .doc(_currentSessionId)
                    .snapshots(),
                builder: (context, sessionSnapshot) {
                  final sessionData = sessionSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final completed = sessionData['completed_agents'] as Map? ?? {};
                  final pipelineStatus = sessionData['pipeline_status'] as String? ?? 'pending';

                  // Calculate active steps based on DB completion
                  int computedActiveStep = 0;
                  if (_isOrchestrating || completed.isNotEmpty) {
                    computedActiveStep = 2; // Intent decoded & matched immediately
                  }
                  if (completed['PricingAgent'] == true) computedActiveStep = 3;
                  if (completed['BookingAgent'] == true) computedActiveStep = 4;
                  if (completed['NotificationAgent'] == true) computedActiveStep = 5;
                  if (completed['FollowUpAgent'] == true) computedActiveStep = 6;

                  final bool isSyncComplete = completed['FollowUpAgent'] == true;
                  final bool isSuccessfullyFinished = pipelineStatus == 'completed_followup' || isSyncComplete;

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('disputes')
                        .doc('dispute_$_currentSessionId')
                        .snapshots(),
                    builder: (context, disputeSnapshot) {
                      final hasDispute = disputeSnapshot.data?.exists ?? false;

                      return Scaffold(
                        backgroundColor: Colors.transparent,
                        body: Stack(
                          children: [
                            // Ambient glow
                            if (_isDarkMode) ...[
                              Positioned(
                                top: -100,
                                left: -100,
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEC4899).withOpacity(0.05),
                                        blurRadius: 100,
                                        spreadRadius: 50,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 150,
                                right: -100,
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B5CF6).withOpacity(0.05),
                                        blurRadius: 100,
                                        spreadRadius: 50,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Content area
                            Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header
                                        BookingHeader(
                                          isDarkMode: _isDarkMode,
                                          isBookingComplete: isSuccessfullyFinished,
                                          isOrchestrating: _isOrchestrating,
                                          pulseAnimation: _pulseController,
                                          onThemeToggle: () {
                                            setState(() {
                                              _isDarkMode = !_isDarkMode;
                                            });
                                          },
                                          onRetriggerPipeline: _runRealAIOrchestration,
                                          onFollowUpTap: _navigateToFollowUp,
                                          onNotificationTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => NotificationScreen(
                                                  isDarkMode: _isDarkMode,
                                                  sessionId: _currentSessionId,
                                                  bookingId: _currentBookingId,
                                                ),
                                              ),
                                            );
                                          },
                                          onDebugTap: _navigateToDebugScreen,
                                        ),
                                        const SizedBox(height: 20),

                                        // ERROR/FAILURE STATE CARD
                                        if (_hasError) ...[
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            margin: const EdgeInsets.only(bottom: 16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444).withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: const Color(0xFFEF4444).withOpacity(0.2),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "Orchestration Error",
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 14,
                                                        color: themePrimaryText,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _errorMessage ?? "Unknown conflict occurred during processing.",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: themePrimaryText.withOpacity(0.8),
                                                    height: 1.4,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                ElevatedButton.icon(
                                                  onPressed: _runRealAIOrchestration,
                                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                                  label: const Text("Retry Pipeline"),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFEF4444),
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],

                                        // Provider Card
                                        ProviderCard(
                                          providerName: widget.provider.name,
                                          serviceType: widget.serviceType,
                                          rating: widget.provider.rating,
                                          isDarkMode: _isDarkMode,
                                        ),
                                        const SizedBox(height: 16),

                                        // Price Summary
                                        PriceBreakdown(
                                          totalPrice: widget.pricingResponse.pricingData.totalPricePkr,
                                          confidence: widget.pricingResponse.pricingData.confidenceScore,
                                          breakdown: widget.pricingResponse.pricingData.breakdown,
                                          isDarkMode: _isDarkMode,
                                        ),
                                        const SizedBox(height: 16),

                                        // AI Timeline
                                        WorkflowTimeline(
                                          isDarkMode: _isDarkMode,
                                          activeStep: computedActiveStep,
                                          timeIntent: _timeIntent,
                                          timeRanked: _timeRanked,
                                          timePricing: _timePricing,
                                          timeBooking: _timeBooking,
                                          timeNotification: _timeNotification,
                                          timeFollowup: _timeFollowup,
                                           onFollowUpTap: _navigateToFollowUp,
                                        ),
                                        const SizedBox(height: 16),

                                        // Service Integrity
                                        IntegrityAudit(
                                          isDarkMode: _isDarkMode,
                                          syncComplete: isSyncComplete,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Lock banner
                            if (hasDispute)
                              DisputeBanner(
                                onClose: () {
                                  // Simply hide overlay visually
                                },
                              ),

                            // Sticky CTA buttons
                            _buildBottomStickyCTA(themeBg, themeCardBg, themeBorder),
                          ],
                        ),
                        floatingActionButton: Container(
                          margin: const EdgeInsets.only(bottom: 74),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: FloatingActionButton(
                            onPressed: _navigateToDebugScreen,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            highlightElevation: 0,
                            child: const Icon(
                              Icons.analytics_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );

              if (isDesktop) {
                return Center(
                  child: Container(
                    width: 480,
                    height: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: themeBg,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(_isDarkMode ? 0.5 : 0.12),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                      border: Border.all(
                        color: _isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: contentWidget,
                  ),
                );
              }

              return Container(
                color: themeBg,
                child: contentWidget,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomStickyCTA(Color bg, Color cardBg, Color border) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xEC16161C) : Colors.white.withOpacity(0.85),
              border: Border(
                top: BorderSide(
                  color: _isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _navigateToDispute,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Raise Dispute',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _navigateToTraceLogs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'View Decisions',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
