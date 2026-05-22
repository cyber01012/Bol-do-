import 'package:cloud_firestore/cloud_firestore.dart';
import '../intent_agent.dart';
import '../discovery_agent.dart';
import '../ranking_agent.dart';
import '../voice_agent.dart';
import '../pricing_agent/pricing_agent_service.dart';
import '../pricing_agent/pricing_model.dart';
import '../booking_agent/booking_agent_service.dart';
import '../booking_agent/booking_model.dart' as booking;
import '../notification_agent/notification_agent_service.dart';
import '../notification_agent/notification_model.dart';
import '../followup_agent/followup_agent_service.dart';
import '../followup_agent/followup_model.dart';
import '../dispute_agent/dispute_agent_service.dart';
import '../dispute_agent/dispute_model.dart';
import '../../models/intent_output.dart';
import '../../models/provider.dart';
import '../../models/ranking_output.dart';
import '../../models/log_entry.dart';
import '../../services/logging_service.dart';
import '../../services/central_trace_logger.dart';

class SupervisorAgentService {
  final FirebaseFirestore _firestore;

  SupervisorAgentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final IntentAgent _intentAgent = IntentAgent();
  final DiscoveryAgent _discoveryAgent = DiscoveryAgent();
  final RankingAgent _rankingAgent = RankingAgent();
  final VoiceAgent _voiceAgent = VoiceAgent();
  final PricingAgentService _pricingAgent = PricingAgentService();
  final BookingAgentService _bookingAgent = BookingAgentService();
  final NotificationAgentService _notificationAgent = NotificationAgentService();
  final FollowUpAgentService _followupAgent = FollowUpAgentService();

  VoiceAgent get voiceAgent => _voiceAgent;

  Future<void> initialize() async {
    await _voiceAgent.initialize();
  }

  /// Robust wrapper to execute an agent stage, perform automatic 1-time retry, and track status.
  Future<T?> executeAgentStage<T>({
    required String sessionId,
    required String userId,
    required String agentName,
    required Future<T?> Function() stageBlock,
  }) async {
    final docRef = _firestore.collection('orchestration_sessions').doc(sessionId);
    
    // Check if session document exists first, if not create it
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) {
      await docRef.set({
        'session_id': sessionId,
        'user_id': userId,
        'current_agent': agentName,
        'completed_agents': <String, bool>{},
        'failed_agents': <String, String>{},
        'orchestration_status': 'running',
        'pipeline_status': 'running_${agentName.toLowerCase()}',
        'retry_count': 0,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } else {
      await docRef.update({
        'current_agent': agentName,
        'orchestration_status': 'running',
        'pipeline_status': 'running_${agentName.toLowerCase()}',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }

    int currentRetry = 0;
    const int maxStageRetries = 1;

    while (true) {
      try {
        final result = await stageBlock();
        if (result == null) {
          throw Exception("$agentName returned a null or empty outcome.");
        }

        // Detect failed status in output models
        if (result is PricingResponse && result.orchestrationStatus == 'failed') {
          throw Exception("Pricing calculation failed.");
        }
        if (result is booking.BookingResponse && 
            (result.orchestrationMetadata.orchestrationStatus == 'failed' || result.bookingStatus == 'failed')) {
          throw Exception("Booking slot processing failed.");
        }
        if (result is NotificationResponse && result.status == 'failed') {
          throw Exception("Notification dispatch failed.");
        }
        if (result is DisputeResponse && result.orchestrationStatus == 'failed_degraded') {
          throw Exception("Dispute processing failed.");
        }

        // Successfully executed stage. Retrieve latest state to safely merge.
        final latestSnapshot = await docRef.get();
        final currentData = latestSnapshot.data() ?? {};
        final completedAgents = Map<String, dynamic>.from(currentData['completed_agents'] as Map? ?? {});
        completedAgents[agentName] = true;

        final failedAgents = Map<String, dynamic>.from(currentData['failed_agents'] as Map? ?? {});
        failedAgents.remove(agentName);

        final updatePayload = {
          'completed_agents': completedAgents,
          'failed_agents': failedAgents,
          'orchestration_status': 'running',
          'pipeline_status': 'running_${agentName.toLowerCase()}_success',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

        // If booking_id is retrieved, save it
        if (result is booking.BookingResponse) {
          updatePayload['booking_id'] = result.bookingId;
          updatePayload['active_booking_id'] = result.bookingId;
        }

        await docRef.update(updatePayload);
        return result;
      } catch (e) {
        if (currentRetry < maxStageRetries) {
          currentRetry++;
          print("⚠️ [SupervisorAgent] $agentName failed: $e. Automatically retrying ($currentRetry/1)...");

          // Update retry count in Firestore
          final latestSnapshot = await docRef.get();
          final currentData = latestSnapshot.data() ?? {};
          final totalRetryCount = (currentData['retry_count'] as int? ?? 0) + 1;

          await docRef.update({
            'retry_count': totalRetryCount,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });

          await Future.delayed(const Duration(seconds: 1));
          continue; // retry loop
        } else {
          // Permanently failed this stage
          print("❌ [SupervisorAgent] $agentName failed permanently: $e");

          final latestSnapshot = await docRef.get();
          final currentData = latestSnapshot.data() ?? {};
          final failedAgents = Map<String, dynamic>.from(currentData['failed_agents'] as Map? ?? {});
          failedAgents[agentName] = e.toString();

          await docRef.update({
            'failed_agents': failedAgents,
            'orchestration_status': 'failed',
            'pipeline_status': 'failed_${agentName.toLowerCase()}',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });

          throw e; // bubble exception up
        }
      }
    }
  }

  // Exposed for UI step-by-step navigation
  Future<IntentOutput?> extractIntent(String input) async {
    final sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';
    final requestId = 'req_$sessionId';

    await _logTrace(sessionId, 'user_customer_999', 'SupervisorAgent', 'started', 'Begin pipeline for: $input', 1.0, 'User initiated pipeline');
    await LoggingService.log(LogEntry(agent: 'Supervisor', workflowStage: 'intent-extraction', decision: 'Begin pipeline', reasoning: 'User initiated', actionTaken: 'start', severity: 'info', timestamp: DateTime.now()));

    final intent = await executeAgentStage<IntentOutput>(
      sessionId: sessionId,
      userId: 'user_customer_999',
      agentName: 'IntentAgent',
      stageBlock: () => _intentAgent.processInput(input),
    );

    if (intent == null) {
      await _logTrace(sessionId, 'user_customer_999', 'IntentAgent', 'failed', 'No intent extracted', 0.0, 'Failed to extract valid intent');
      return null;
    }

    if (intent.confidenceScore < 0.65) {
      final clarificationMsg = "Did you mean you need a ${intent.serviceType} in ${intent.location}?";
      await _voiceAgent.speak(clarificationMsg);
      await _logTrace(sessionId, 'user_customer_999', 'IntentAgent', 'failed', 'Low confidence', intent.confidenceScore, 'Confidence below 0.65');
      return null;
    }

    await _logTrace(sessionId, 'user_customer_999', 'IntentAgent', 'completed', 'Extracted: ${intent.serviceType}', intent.confidenceScore, 'Intent extracted successfully');
    return intent;
  }

  Future<List<Provider>> discoverProviders(IntentOutput intent) async {
    final providers = await _discoveryAgent.discoverProviders(intent);
    return providers;
  }

  Future<RankingOutput?> rankProviders(List<Provider> providers, String serviceType, {String? sessionId}) async {
    final activeSessionId = sessionId ?? 'sess_${DateTime.now().millisecondsSinceEpoch}';
    final requestId = 'req_$activeSessionId';

    final rankingOutput = await executeAgentStage<RankingOutput>(
      sessionId: activeSessionId,
      userId: 'user_customer_999',
      agentName: 'RankingAgent',
      stageBlock: () => _rankingAgent.rankProviders(providers, serviceType),
    );

    if (rankingOutput == null || rankingOutput.topChoice == null) {
      await _logTrace(activeSessionId, 'user_customer_999', 'RankingAgent', 'failed', 'Ranking failed', 0.0, 'No top choice found');
      return null;
    }

    final topProvider = rankingOutput.topChoice!;
    await _logTrace(activeSessionId, 'user_customer_999', 'RankingAgent', 'completed', 'Ranked top provider: ${topProvider.name}', 1.0, topProvider.reasoning);

    // Speak result
    final responseMsg = "I found a great match for you! ${topProvider.name} is highly rated. ${topProvider.reasoning}";
    await _voiceAgent.speak(responseMsg);

    return rankingOutput;
  }

  Future<PricingResponse?> calculatePricing({
    required String sessionId,
    required String requestId,
    required String userId,
    required String serviceType,
    required String providerId,
    required String providerName,
    required double distanceKm,
    Map<String, dynamic>? providerMetadata,
  }) async {
    print("🤖 [SupervisorAgent] Calculating Pricing for $sessionId...");

    final docRef = _firestore.collection('orchestration_sessions').doc(sessionId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await docRef.set({
        'session_id': sessionId,
        'user_id': userId,
        'current_agent': 'SupervisorAgent',
        'completed_agents': <String, bool>{
          'IntentAgent': true,
          'RankingAgent': true,
        },
        'failed_agents': <String, String>{},
        'orchestration_status': 'running',
        'pipeline_status': 'running',
        'retry_count': 0,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }

    try {
      print("🤖 [PricingAgent] Processing calculation...");
      final pricingRequest = PricingRequest(
        requestId: requestId,
        sessionId: sessionId,
        userRequest: UserRequest(
          serviceType: serviceType,
          urgency: "medium",
          requestedTime: DateTime.now().add(const Duration(hours: 2)),
          isRepeatCustomer: false,
        ),
        selectedProvider: SelectedProvider(
          providerId: providerId,
          name: providerName,
          serviceType: serviceType,
          distanceKm: distanceKm,
          complexity: "basic",
          providerMetadata: providerMetadata,
        ),
      );

      final pricingResponse = await executeAgentStage<PricingResponse>(
        sessionId: sessionId,
        userId: userId,
        agentName: 'PricingAgent',
        stageBlock: () => _pricingAgent.processRequest(pricingRequest),
      );

      await _logTrace(sessionId, userId, 'PricingAgent', 'completed', 'Price calculated: ${pricingResponse!.pricingData.totalPricePkr}', pricingResponse.pricingData.confidenceScore, pricingResponse.pricingData.breakdown);

      return pricingResponse;
    } catch (e) {
      print("❌ [Supervisor] Pricing Error: $e");
      await _logTrace(sessionId, userId, 'SupervisorAgent', 'failed', 'Pricing failed: $e', 0.0, e.toString());
      
      await docRef.set({
        'pipeline_status': 'failed',
        'orchestration_status': 'failed',
        'error_message': e.toString(),
        'last_updated': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));
      rethrow;
    }
  }

  /// Continues the orchestration pipeline after user confirms pricing.
  Future<void> runBookingPipeline({
    required String sessionId,
    required String userId,
    required String serviceType,
    required PricingResponse pricingResponse,
  }) async {
    print("🤖 [SupervisorAgent] Continuing Booking Pipeline for $sessionId...");
    final docRef = _firestore.collection('orchestration_sessions').doc(sessionId);

    try {

      // 5. Booking
      print("🤖 [BookingAgent] Processing confirmation...");
      final bookingRequest = booking.BookingRequest(
        requestId: pricingResponse.requestId,
        sessionId: sessionId,
        orchestrationStatus: pricingResponse.orchestrationStatus,
        selectedProvider: booking.SelectedProvider(
          providerId: pricingResponse.selectedProvider.providerId,
          name: pricingResponse.selectedProvider.name,
          serviceType: pricingResponse.selectedProvider.serviceType,
          providerMetadata: pricingResponse.selectedProvider.providerMetadata,
        ),
        pricingData: booking.PricingData(
          totalPricePkr: pricingResponse.pricingData.totalPricePkr,
          confidenceScore: pricingResponse.pricingData.confidenceScore,
          breakdown: pricingResponse.pricingData.breakdown,
        ),
        userRequest: booking.UserRequest(
          serviceType: serviceType,
          urgency: "medium",
          requestedTime: DateTime.now(),
        ),
        bookingMetadata: booking.BookingMetadata(
          paymentMethod: "cash_on_delivery",
        ),
      );

      final bookingResponse = await executeAgentStage<booking.BookingResponse>(
        sessionId: sessionId,
        userId: userId,
        agentName: 'BookingAgent',
        stageBlock: () => _bookingAgent.processRequest(bookingRequest),
      );

      await _logTrace(sessionId, userId, 'BookingAgent', 'completed', 'Booking confirmed: ${bookingResponse!.bookingId}', 1.0, 'Slot booked successfully');

      // 6. Notification
      print("🤖 [NotificationAgent] Dispatching alerts...");
      final notificationResponse = await executeAgentStage<NotificationResponse>(
        sessionId: sessionId,
        userId: userId,
        agentName: 'NotificationAgent',
        stageBlock: () => _notificationAgent.processResponse(bookingResponse!),
      );

    await _logTrace(
  sessionId,
  userId,
  'NotificationAgent',
  'completed',
  'Created ${notificationResponse!.notificationsCreated} notifications',
  1.0,
  {
    'notifications_created':
        notificationResponse.notificationsCreated,

    'notification_payload':
        notificationResponse.notificationPayload,

    'orchestration_metadata':
        notificationResponse.orchestrationMetadata,
  },
);
      // 7. FollowUp
      print("🤖 [FollowUpAgent] Scheduling lifecycle engagement workflow...");
      final followupRequest = FollowUpRequest(
        bookingId: bookingResponse!.bookingId,
        sessionId: sessionId,
        bookingStatus: bookingResponse.bookingStatus,
        scheduledTime: bookingResponse.scheduledTime,
        provider: bookingResponse.provider,
        customerSummary: bookingResponse.customerSummary,
        orchestrationMetadata: bookingResponse.orchestrationMetadata,
      );

      final followupResponse = await executeAgentStage<FollowUpResponse>(
        sessionId: sessionId,
        userId: userId,
        agentName: 'FollowUpAgent',
        stageBlock: () => _followupAgent.processRequest(followupRequest),
      );

      await _logTrace(
        sessionId,
        userId,
        'FollowUpAgent',
        'completed',
        'Scheduled actions: ${followupResponse!.followupsCreated}',
        1.0,
        {
          'followups_created': followupResponse.followupsCreated,
        },
      );
      // Finalize session
      await docRef.set({
        'pipeline_status': 'completed',
        'orchestration_status': 'completed',
        'last_updated': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));

      await _logTrace(sessionId, userId, 'SupervisorAgent', 'completed', 'End-to-end pipeline completed successfully', 1.0, 'All stages passed');
      print("🤖 [Supervisor] Pipeline completed successfully! 🎉");

    } catch (e) {
      print("❌ [Supervisor] Pipeline Error: $e");
      await _logTrace(sessionId, userId, 'SupervisorAgent', 'failed', 'Pipeline failed: $e', 0.0, e.toString());
      
      await docRef.set({
        'pipeline_status': 'failed',
        'orchestration_status': 'failed',
        'error_message': e.toString(),
        'last_updated': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));
      rethrow;
    }
  }

  /// Orchestrate Dispute Agent through Supervisor tracking
  Future<DisputeResponse> processDispute(DisputeRequest request) async {
    final response = await executeAgentStage<DisputeResponse>(
      sessionId: request.sessionId,
      userId: request.customerId,
      agentName: 'DisputeAgent',
      stageBlock: () async {
        final service = DisputeAgentService();
        return await service.processRequest(request);
      },
    );
    return response!;
  }

  Future<void> _logTrace(String sessionId, String userId, String agent, String status, String decision, double confidence, dynamic reasoning) async {
    try {
      final traceId = 'trace_${DateTime.now().millisecondsSinceEpoch}_$agent';
      await CentralTraceLogger().logTrace(
        traceId: traceId,
        sessionId: sessionId,
        userId: userId,
        agentName: agent,
        decision: decision,
        confidence: confidence,
        orchestrationStatus: status,
        reasoning: reasoning,
      );
    } catch (e) {
      print("Failed to log trace: $e");
    }
  }
}
