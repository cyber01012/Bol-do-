import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dev/mock_booking_seeder.dart';
import 'dev/mock_provider_seeder.dart';
import 'ui/theme.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/ranking_logs_screen.dart';
import 'ui/screens/provider_listing_screen.dart';

import 'firebase_options.dart';

// Agent imports
import 'agents/pricing_agent/pricing_agent_service.dart';
import 'agents/booking_agent/booking_agent_service.dart';
import 'agents/notification_agent/notification_agent_service.dart';
import 'agents/followup_agent/followup_agent_service.dart';

// Model imports
import 'agents/pricing_agent/pricing_model.dart';
import 'agents/booking_agent/booking_model.dart' as booking;
import 'agents/followup_agent/followup_model.dart';

// Screen imports
import 'screens/booking/booking_screen.dart';
import 'screens/debug/firestore_debug_screen.dart';
import 'screens/booking/trace_logs_screen.dart';
import 'screens/booking/dispute_screen.dart';
import 'screens/booking/notification_screen.dart';

/// Runs the complete, end-to-end multi-agent orchestration pipeline.
/// Pricing Agent -> Booking Agent -> Notification Agent -> FollowUp Agent.
Future<void> runEntirePipeline() async {
  final sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';
  final requestId = 'req_$sessionId';
  final firestore = FirebaseFirestore.instance;

  print("🤖 [Orchestrator] Starting end-to-end service orchestration...");
  print("🤖 [Orchestrator] Session ID: $sessionId | Request ID: $requestId");

  try {
    // 0. Initialize/Update session state in Firestore
    await firestore.collection('orchestration_sessions').doc(sessionId).set({
      'session_id': sessionId,
      'pipeline_status': 'started',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'completed_agents': <String, bool>{},
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));

    // 1. Create Pricing Request & Run Pricing Agent
    print("🤖 [PricingAgent] Processing calculation...");
    final pricingRequest = PricingRequest(
      requestId: requestId,
      sessionId: sessionId,
      userRequest: UserRequest(
        serviceType: "electrician",
        urgency: "urgent",
        requestedTime: DateTime.now().add(const Duration(hours: 2)),
        isRepeatCustomer: false,
      ),
      selectedProvider: SelectedProvider(
        providerId: "provider_001",
        distanceKm: 5.0,
        complexity: "basic",
      ),
    );

    final pricingAgent = PricingAgentService();
    final pricingResponse = await pricingAgent.processRequest(pricingRequest);
    print("🤖 [PricingAgent] Done. Final Price: ${pricingResponse.pricingData.totalPricePkr} PKR");

    if (pricingResponse.orchestrationStatus == 'failed') {
      throw Exception("Pricing Agent failed to calculate price.");
    }

    // 2. Create Booking Request & Run Booking Agent
    print("🤖 [BookingAgent] Processing confirmation...");
    final bookingRequest = booking.BookingRequest(
      requestId: pricingResponse.requestId,
      sessionId: sessionId,
      orchestrationStatus: pricingResponse.orchestrationStatus,
      selectedProvider: booking.SelectedProvider(
        providerId: pricingRequest.selectedProvider.providerId,
        name: "Ali Electric Works",
        serviceType: pricingRequest.userRequest.serviceType,
      ),
      pricingData: booking.PricingData(
        totalPricePkr: pricingResponse.pricingData.totalPricePkr,
        confidenceScore: pricingResponse.pricingData.confidenceScore,
        breakdown: pricingResponse.pricingData.breakdown,
      ),
      userRequest: booking.UserRequest(
        serviceType: pricingRequest.userRequest.serviceType,
        urgency: pricingRequest.userRequest.urgency ?? "urgent",
        requestedTime: pricingRequest.userRequest.requestedTime ?? DateTime.now(),
      ),
      bookingMetadata: booking.BookingMetadata(
        paymentMethod: "cash_on_delivery",
      ),
    );

    final bookingAgent = BookingAgentService();
    final bookingResponse = await bookingAgent.processRequest(bookingRequest);
    print("🤖 [BookingAgent] Done. Booking Status: ${bookingResponse.bookingStatus}");

    if (bookingResponse.orchestrationMetadata.orchestrationStatus == 'failed' ||
        bookingResponse.bookingStatus == 'failed') {
      throw Exception("Booking Agent slot confirmation failed.");
    }

    // 3. Run Notification Agent
    print("🤖 [NotificationAgent] Dispatching user and provider alerts...");
    final notificationAgent = NotificationAgentService();
    final notificationResponse = await notificationAgent.processResponse(bookingResponse);
    print("🤖 [NotificationAgent] Done. Created: ${notificationResponse.notificationsCreated} notifications");

    // 4. Create FollowUp Request & Run FollowUp Agent
    print("🤖 [FollowUpAgent] Scheduling lifecycle engagement workflow...");
    final followupRequest = FollowUpRequest(
      bookingId: bookingResponse.bookingId,
      sessionId: sessionId,
      bookingStatus: bookingResponse.bookingStatus,
      scheduledTime: bookingResponse.scheduledTime,
      provider: bookingResponse.provider,
      customerSummary: bookingResponse.customerSummary,
      orchestrationMetadata: bookingResponse.orchestrationMetadata,
    );

    final followupAgent = FollowUpAgentService();
    final followupResponse = await followupAgent.processRequest(followupRequest);
    print("🤖 [FollowUpAgent] Done. Scheduled actions: ${followupResponse.followupsCreated}");

    // 5. Finalize central orchestration session status in Firestore
    await firestore.collection('orchestration_sessions').doc(sessionId).set({
      'pipeline_status': 'completed_followup',
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));

    print("🤖 [Orchestrator] End-to-end pipeline completed successfully! 🎉");
  } catch (e) {
    print("❌ [Orchestrator] Pipeline Error: $e");

    try {
      await firestore.collection('orchestration_sessions').doc(sessionId).set({
        'pipeline_status': 'failed',
        'error_message': e.toString(),
        'last_updated': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));

      await firestore.collection('agent_traces').doc('trace_fail_$sessionId').set({
        'trace_id': 'trace_fail_$sessionId',
        'session_id': sessionId,
        'request_id': requestId,
        'current_agent': 'OrchestratorPipeline',
        'next_agent': 'failed',
        'orchestration_status': 'failed',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'decision': 'Orchestration pipeline execution aborted due to critical error.',
        'confidence': 0.0,
        'reasoning_breakdown': {
          'exception': e.toString(),
        },
      }, SetOptions(merge: true));
    } catch (fsEx) {
      print("❌ [Orchestrator] Failed to log failure state to Firestore: $fsEx");
    }
    rethrow;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

class _BolDoAppState extends State<BolDoApp> {
  String authStatus = "Initializing security protocols...";

  @override
  void initState() {
    super.initState();
    if (widget.firebaseInitialized) {
      _signInAnonymously();
    } else {
      setState(() {
        authStatus = "Firebase initialization failed: ${widget.firebaseInitError}";
      });
    }
  }

  Future<void> _signInAnonymously() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      print("🔐 Authenticated Anonymously: ${userCredential.user?.uid}");
      setState(() {
        authStatus = "Authenticated as guest.";
      });
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Auth Exception: [${e.code}] ${e.message}");
      setState(() {
        authStatus = "Auth failed: [${e.code}] ${e.message}";
      });
    } catch (e) {
      print("❌ General Authentication Failure: $e");
      setState(() {
        authStatus = "Auth failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('BolDo AI'),
        ),
        body: const Center(
          child: Text(
            'Firebase Connected Successfully 🚀',
          ),
        ),
      ),
    );
  }
}