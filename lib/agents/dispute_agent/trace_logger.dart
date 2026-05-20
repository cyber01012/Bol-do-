import 'dart:developer' as developer;
import 'firestore_service.dart';
import 'dispute_model.dart';

/// Logger class to persist and track dispute agent orchestration traces.
class TraceLogger {
  final FirestoreService _firestoreService;

  /// Constructor allowing dependency injection of [FirestoreService].
  /// Defaults to a new instance of [FirestoreService] if none is provided.
  TraceLogger({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Logs a dispute orchestration trace.
  /// Saves details into 'agent_traces' and updates the 'orchestration_sessions' collection.
  /// If Firestore is unavailable, falls back to degraded local console logging.
  Future<void> logTrace({
    required DisputeRequest request,
    required DisputeResponse response,
    required String traceId,
    required double confidence,
    required String decision,
    required Map<String, dynamic> reasoningBreakdown,
    required String escalationLevel,
  }) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();

    try {
      // 1. Fetch existing orchestration session to merge completed_agents securely
      final existingSession = await _firestoreService.getDocument(
        'orchestration_sessions',
        request.sessionId,
      );

      final Map<String, dynamic> completedAgents = {};
      if (existingSession != null && existingSession['completed_agents'] != null) {
        completedAgents.addAll(Map<String, dynamic>.from(existingSession['completed_agents'] as Map));
      }
      completedAgents['DisputeAgent'] = true;

      // 2. Prepare the trace data
      final traceData = {
        'trace_id': traceId,
        'session_id': request.sessionId,
        'request_id': request.requestId,
        'current_agent': 'DisputeAgent',
        'next_agent': response.orchestrationStatus == 'escalated' ? 'human_escalation' : 'completed',
        'orchestration_status': response.orchestrationStatus,
        'timestamp': timestamp,
        'inputs': request.toJson(),
        'decision': decision,
        'confidence': confidence,
        'reasoning': reasoningBreakdown.entries.map((e) => '${e.key}: ${e.value}').toList(),
        'reasoning_breakdown': reasoningBreakdown,
        'escalation_level': escalationLevel,
      };

      // 3. Save the trace document
      await _firestoreService.saveDocument('agent_traces', traceId, traceData);

      // 4. Update the central orchestration session
      await _firestoreService.saveDocument(
        'orchestration_sessions',
        request.sessionId,
        {
          'completed_agents': completedAgents,
          'last_updated': timestamp,
          'pipeline_status': response.orchestrationStatus,
          'active_booking_id': request.bookingId,
        },
      );
    } catch (e, stackTrace) {
      // Degraded fallback logging
      developer.log(
        'TraceLogger Degradation Warning: Firestore unreachable. Logging locally.',
        error: e,
        stackTrace: stackTrace,
        name: 'DisputeTraceLogger',
      );
      print('TraceLogger Degradation Warning: Failed to save trace to Firestore. Local fallback data below:');
      print('--- DEGRADED FALLBACK TRACE ---');
      print('Trace ID: $traceId');
      print('Session ID: ${request.sessionId}');
      print('Request ID: ${request.requestId}');
      print('Timestamp (UTC): $timestamp');
      print('Orchestration Status: ${response.orchestrationStatus}');
      print('Escalation Level: $escalationLevel');
      print('Decision: $decision');
      print('Confidence Score: $confidence');
      print('Reasoning Breakdown: $reasoningBreakdown');
      print('Original Error: $e');
      print('---------------------------------');
    }
  }
}
