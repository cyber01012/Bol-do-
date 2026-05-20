import 'firestore_service.dart';
import 'followup_model.dart';

class TraceLogger {
  final FirestoreService _firestoreService;

  TraceLogger({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<void> logTrace({
    required FollowUpRequest request,
    required FollowUpResponse response,
    required String traceId,
    required String decision,
    required double confidence,
    required Map<String, dynamic> reasoningBreakdown,
    required int generatedFollowupsCount,
  }) async {
    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();

      // 1. Fetch existing orchestration session to merge completed_agents securely
      final existingSession = await _firestoreService.getDocument(
        'orchestration_sessions',
        request.sessionId,
      );

      final Map<String, dynamic> completedAgents = {};
      if (existingSession != null &&
          existingSession['completed_agents'] != null) {
        completedAgents.addAll(Map<String, dynamic>.from(
            existingSession['completed_agents'] as Map));
      }
      completedAgents['FollowUpAgent'] = true;

      // 2. Save agent trace
      final traceData = {
        'trace_id': traceId,
        'session_id': request.sessionId,
        'request_id': request.orchestrationMetadata.requestId,
        'current_agent': 'FollowUpAgent',
        'next_agent': 'completed',
        'orchestration_status': response.orchestrationStatus,
        'timestamp': timestamp,
        'generated_followups_count': generatedFollowupsCount,
        'inputs': {
          'booking_id': request.bookingId,
          'booking_status': request.bookingStatus,
          'rating': request.rating,
          'feedback': request.feedback,
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
        request.sessionId,
        {
          'completed_agents': completedAgents,
          'last_updated': timestamp,
          'pipeline_status': 'completed_followup',
          'active_booking_id': request.bookingId,
        },
      );
    } catch (e) {
      print('TraceLogger Logging Error: $e');
    }
  }
}
