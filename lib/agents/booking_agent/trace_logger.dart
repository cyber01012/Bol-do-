import 'firestore_service.dart';
import 'booking_model.dart';

class TraceLogger {
  final FirestoreService _firestoreService;

  TraceLogger({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<void> logTrace({
    required BookingRequest request,
    required BookingResponse response,
    required String traceId,
    required String decision,
    required double confidence,
    required Map<String, dynamic> reasoningBreakdown,
  }) async {
    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();

      // 1. Save agent trace with exact keys requested by contracts
      final traceData = {
        'trace_id': traceId,
        'session_id': request.sessionId,
        'request_id': request.requestId,
        'current_agent': 'BookingAgent',
        'next_agent': 'NotificationAgent',
        'orchestration_status': response.orchestrationStatus,
        'timestamp': timestamp,
        'inputs': {
          'provider_id': request.selectedProvider.providerId,
          'requested_time': request.userRequest.requestedTime.toIso8601String(),
          'total_price': request.pricingData.totalPricePkr,
        },
        'decision': decision,
        'confidence': confidence,
        'reasoning': reasoningBreakdown.entries
    .map((e) => '${e.key}: ${e.value}')
    .toList(),
        'reasoning_breakdown': reasoningBreakdown,
      };
      await _firestoreService.saveDocument('agent_traces', traceId, traceData);

      // 2. Update central orchestration session
      await _firestoreService.saveDocument('orchestration_sessions', request.sessionId, {
        'completed_agents': {'BookingAgent': true},
        'last_updated': timestamp,
        'pipeline_status': response.orchestrationStatus,
        'active_booking_id': response.bookingId,
      });

      // 3. Stage simulated notifications (if booking succeeded/confirmed)
      if (response.bookingStatus == 'confirmed') {
        // User notification
        await _firestoreService.saveDocument(
          'notifications',
          'notif_user_${request.sessionId}',
          {
            'notification_id': 'notif_user_${request.sessionId}',
            'session_id': request.sessionId,
            'booking_id': response.bookingId,
            'recipient_id': response.notificationPayload.user.recipientId,
            'recipient_type': 'user',
            'channel': response.notificationPayload.user.channel,
            'message': response.notificationPayload.user.message,
            'status': 'pending',
            'created_at': timestamp,
          },
        );

        // Provider notification
        await _firestoreService.saveDocument(
          'notifications',
          'notif_provider_${request.sessionId}',
          {
            'notification_id': 'notif_provider_${request.sessionId}',
            'session_id': request.sessionId,
            'booking_id': response.bookingId,
            'recipient_id': response.notificationPayload.provider.recipientId,
            'recipient_type': 'provider',
            'channel': response.notificationPayload.provider.channel,
            'message': response.notificationPayload.provider.message,
            'status': 'pending',
            'created_at': timestamp,
          },
        );
      }
    } catch (e) {
      print('TraceLogger Logging Error: $e');
    }
  }
}
