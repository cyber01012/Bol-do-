import 'package:flutter_test/flutter_test.dart';
import 'package:boldo_ai/agents/dispute_agent/dispute_model.dart';
import 'package:boldo_ai/agents/dispute_agent/firestore_service.dart';
import 'package:boldo_ai/agents/dispute_agent/trace_logger.dart';

class MockFirestoreService extends FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> database = {
    'agent_traces': {},
    'orchestration_sessions': {},
  };
  bool throwError = false;

  @override
  Future<void> saveDocument(
    String collectionPath,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    if (throwError) {
      throw Exception('Simulated Database Outage');
    }
    database.putIfAbsent(collectionPath, () => {})[documentId] = data;
  }

  @override
  Future<Map<String, dynamic>?> getDocument(
    String collectionPath,
    String documentId,
  ) async {
    if (throwError) {
      throw Exception('Simulated Database Outage');
    }
    return database[collectionPath]?[documentId];
  }
}

void main() {
  group('TraceLogger Tests', () {
    late MockFirestoreService mockFirestore;
    late TraceLogger traceLogger;

    setUp(() {
      mockFirestore = MockFirestoreService();
      traceLogger = TraceLogger(firestoreService: mockFirestore);
    });

    test('logTrace successfully saves trace and updates orchestration session', () async {
      final request = DisputeRequest(
        requestId: 'req_1',
        sessionId: 'sess_1',
        bookingId: 'book_1',
        customerId: 'cust_1',
        providerId: 'prov_1',
        rating: 1.0,
        feedback: 'Terrible service',
        bookingStatus: 'completed',
        createdAt: DateTime.now(),
      );

      final response = DisputeResponse(
        requestId: 'req_1',
        disputeCase: DisputeCase(
          disputeId: 'disp_1',
          severity: 'high',
          category: 'refund',
          status: 'escalated',
          createdAt: DateTime.now(),
        ),
        resolutionRecommendation: const ResolutionRecommendation(
          refundPercentage: 100.0,
          providerPenalty: 50.0,
          supportPriority: 'critical',
          recommendedAction: 'refund_and_ban',
        ),
        orchestrationStatus: 'escalated',
        confidenceScore: 0.98,
        escalationMetadata: const EscalationMetadata(
          escalationId: 'esc_1',
          isEscalated: true,
          escalationReason: 'Low rating and negative feedback',
          escalatedTo: 'support_tier_2',
          riskLevel: 'high',
        ),
      );

      // Seed session
      mockFirestore.database['orchestration_sessions']!['sess_1'] = {
        'completed_agents': {'PricingAgent': true, 'BookingAgent': true},
        'pipeline_status': 'success',
      };

      await traceLogger.logTrace(
        request: request,
        response: response,
        traceId: 'trace_1',
        confidence: 0.95,
        decision: 'Escalate to Tier 2 support',
        reasoningBreakdown: {'rating_check': 'failed', 'severity_check': 'high'},
        escalationLevel: 'tier_2',
      );

      // Check agent_traces collection
      final trace = mockFirestore.database['agent_traces']!['trace_1'];
      expect(trace, isNotNull);
      expect(trace!['trace_id'], 'trace_1');
      expect(trace['session_id'], 'sess_1');
      expect(trace['request_id'], 'req_1');
      expect(trace['current_agent'], 'DisputeAgent');
      expect(trace['next_agent'], 'human_escalation');
      expect(trace['orchestration_status'], 'escalated');
      expect(trace['confidence'], 0.95);
      expect(trace['decision'], 'Escalate to Tier 2 support');
      expect(trace['escalation_level'], 'tier_2');
      expect(trace['reasoning_breakdown']['severity_check'], 'high');

      // Check orchestration_sessions update and merged completed_agents
      final session = mockFirestore.database['orchestration_sessions']!['sess_1'];
      expect(session, isNotNull);
      expect(session!['completed_agents']['PricingAgent'], true);
      expect(session['completed_agents']['BookingAgent'], true);
      expect(session['completed_agents']['DisputeAgent'], true);
      expect(session['pipeline_status'], 'escalated');
      expect(session['active_booking_id'], 'book_1');
    });

    test('logTrace handles database outage gracefully (degraded fallback)', () async {
      final request = DisputeRequest(
        requestId: 'req_2',
        sessionId: 'sess_2',
        bookingId: 'book_2',
        customerId: 'cust_2',
        providerId: 'prov_2',
        rating: 2.0,
        feedback: 'Overslept',
        bookingStatus: 'completed',
        createdAt: DateTime.now(),
      );

      final response = DisputeResponse(
        requestId: 'req_2',
        disputeCase: DisputeCase(
          disputeId: 'disp_2',
          severity: 'medium',
          category: 'no_show',
          status: 'resolved',
          createdAt: DateTime.now(),
        ),
        resolutionRecommendation: const ResolutionRecommendation(
          refundPercentage: 50.0,
          providerPenalty: 10.0,
          supportPriority: 'medium',
          recommendedAction: 'partial_refund',
        ),
        orchestrationStatus: 'resolved',
        confidenceScore: 0.90,
        escalationMetadata: const EscalationMetadata(
          escalationId: '',
          isEscalated: false,
          escalationReason: 'None',
          escalatedTo: 'none',
          riskLevel: 'low',
        ),
      );

      mockFirestore.throwError = true;

      // Should run without throwing exception (fallback to print)
      await traceLogger.logTrace(
        request: request,
        response: response,
        traceId: 'trace_2',
        confidence: 0.90,
        decision: 'Resolve with 50% refund',
        reasoningBreakdown: {'no_show_verified': true},
        escalationLevel: 'none',
      );
    });
  });
}
