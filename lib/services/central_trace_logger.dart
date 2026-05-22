import 'package:cloud_firestore/cloud_firestore.dart';

class CentralTraceLogger {
  static final CentralTraceLogger _instance = CentralTraceLogger._internal();
  factory CentralTraceLogger() => _instance;
  
  final FirebaseFirestore _firestore;

  CentralTraceLogger._internal({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> logTrace({
    required String traceId,
    required String sessionId,
    required String userId,
    required String agentName,
    required String decision,
    required double confidence,
    required String orchestrationStatus,
    required dynamic reasoning,
  }) async {
    try {
      final traceData = {
        'trace_id': traceId,
        'session_id': sessionId,
        'user_id': userId,
        'agent_name': agentName,
        'decision': decision,
        'confidence': confidence,
        'orchestration_status': orchestrationStatus,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'reasoning': reasoning,
      };

      await _firestore
          .collection('agent_traces')
          .doc(traceId)
          .set(traceData, SetOptions(merge: true));
    } catch (e) {
      print("❌ [CentralTraceLogger] Failed to log trace for $agentName: $e");
    }
  }
}
