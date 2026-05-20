import 'firestore_service.dart';
import 'package:boldo_ai/agents/booking_agent/booking_model.dart';

class TraceLogger {
  final FirestoreService _firestoreService;

  TraceLogger({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<void> logTrace({
    required BookingResponse bookingResponse,
    required String traceId,
    required String decision,
    required double confidence,
    required Map<String, dynamic> reasoningBreakdown,
  }) async {
    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();

      // 1. Fetch existing orchestration session to merge completed_agents securely
      final existingSession = await _firestoreService.getDocument(
        'orchestration_sessions',
        bookingResponse.sessionId,
      );

      final Map<String, dynamic> completedAgents = {};
      if (existingSession != null &&
          existingSession['completed_agents'] != null) {
        completedAgents.addAll(Map<String, dynamic>.from(
            existingSession['completed_agents'] as Map));
      }
      completedAgents['NotificationAgent'] = true;

      // 2. Save agent trace
      final traceData = {
        'trace_id': traceId,
        'session_id': bookingResponse.sessionId,
        'request_id': bookingResponse.requestId,
        'current_agent': 'NotificationAgent',
        'next_agent': null,
        'orchestration_status': bookingResponse.orchestrationStatus,
        'timestamp': timestamp,
        'inputs': {
          'booking_id': bookingResponse.bookingId,
          'booking_status': bookingResponse.bookingStatus,
        },
        'decision': decision,
        'confidence': confidence,
        'reasoning': reasoningBreakdown.entries
            .map((e) => '${e.key}: ${e.value}')
            .toList(),
        'reasoning_breakdown': reasoningBreakdown,
      };

      await _firestoreService.saveDocument('agent_traces', traceId, traceData);

      // 3. Update central orchestration session
      await _firestoreService.saveDocument(
        'orchestration_sessions',
        bookingResponse.sessionId,
        {
          'completed_agents': completedAgents,
          'last_updated': timestamp,
          'pipeline_status': 'completed_notification',
          'active_booking_id': bookingResponse.bookingId,
        },
      );
    } catch (e) {
      print('TraceLogger Logging Error: $e');
    }
  }
}
