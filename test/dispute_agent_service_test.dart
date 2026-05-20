import 'package:flutter_test/flutter_test.dart';
import 'package:boldo_ai/agents/dispute_agent/dispute_model.dart';
import 'package:boldo_ai/agents/dispute_agent/firestore_service.dart';
import 'package:boldo_ai/agents/dispute_agent/trace_logger.dart';
import 'package:boldo_ai/agents/dispute_agent/dispute_agent_service.dart';

class MockFirestoreService extends FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> database = {
    'disputes': {},
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
  group('DisputeAgentService Tests', () {
    late MockFirestoreService mockDb;
    late DisputeAgentService service;

    setUp(() {
      mockDb = MockFirestoreService();
      service = DisputeAgentService(
        firestoreService: mockDb,
      );
    });

    test('1. Success: Critical Severity (rating 1.0) & fraud categorization', () async {
      final req = DisputeRequest(
        requestId: 'req_c1',
        sessionId: 'sess_c1',
        bookingId: 'book_c1',
        customerId: 'cust_c1',
        providerId: 'prov_c1',
        rating: 1.0,
        feedback: 'The provider committed fraud and stole money',
        bookingStatus: 'completed',
        createdAt: DateTime.now(),
      );

      final resp = await service.processRequest(req);

      // Verify Model fields
      expect(resp.requestId, 'req_c1');
      expect(resp.orchestrationStatus, 'escalated');
      expect(resp.confidenceScore, 1.0); // 0.85 + 0.10 + 0.05 capped at 1.0

      expect(resp.disputeCase.severity, 'critical');
      expect(resp.disputeCase.category, 'fraud');
      expect(resp.disputeCase.status, 'escalated');

      expect(resp.resolutionRecommendation.refundPercentage, 100.0);
      expect(resp.resolutionRecommendation.providerPenalty, 3.0); // strike
      expect(resp.resolutionRecommendation.supportPriority, 'critical');
      expect(resp.resolutionRecommendation.recommendedAction, 'refund_and_ban');

      expect(resp.escalationMetadata.isEscalated, true);
      expect(resp.escalationMetadata.escalatedTo, 'human_support_tier_2');
      expect(resp.escalationMetadata.riskLevel, 'critical');

      // Verify Firestore state
      final savedDoc = mockDb.database['disputes']!['dispute_sess_c1'];
      expect(savedDoc, isNotNull);
      expect(savedDoc!['orchestration_status'], 'escalated');
      expect(savedDoc['booking_id'], 'book_c1');
    });

    test('2. Success: High Severity (rating 2.0) & rude behaviour categorization', () async {
      final req = DisputeRequest(
        requestId: 'req_h2',
        sessionId: 'sess_h2',
        bookingId: 'book_h2',
        customerId: 'cust_h2',
        providerId: 'prov_h2',
        rating: 2.0,
        feedback: 'Rude behavior and angry attitude',
        bookingStatus: 'completed',
        createdAt: DateTime.now(),
      );

      final resp = await service.processRequest(req);

      expect(resp.disputeCase.severity, 'high');
      expect(resp.disputeCase.category, 'rude_behavior');
      expect(resp.resolutionRecommendation.refundPercentage, 70.0);
      expect(resp.resolutionRecommendation.providerPenalty, 2.0); // warning
      expect(resp.escalationMetadata.isEscalated, true);
      expect(resp.escalationMetadata.escalatedTo, 'human_support_tier_1');
    });

    test('3. Success: Medium Severity (rating 3.0) & overcharging categorization', () async {
      final req = DisputeRequest(
        requestId: 'req_m3',
        sessionId: 'sess_m3',
        bookingId: 'book_m3',
        customerId: 'cust_m3',
        providerId: 'prov_m3',
        rating: 3.0,
        feedback: 'He charged me too much money. Total overcharge.',
        bookingStatus: 'completed',
        createdAt: DateTime.now(),
      );

      final resp = await service.processRequest(req);

      expect(resp.disputeCase.severity, 'medium');
      expect(resp.disputeCase.category, 'overcharging');
      expect(resp.disputeCase.status, 'resolved');
      expect(resp.resolutionRecommendation.refundPercentage, 40.0);
      expect(resp.resolutionRecommendation.providerPenalty, 1.0); // monitor
      expect(resp.escalationMetadata.isEscalated, false);
      expect(resp.orchestrationStatus, 'resolved');
    });

    test('4. Success: Low Severity (rating 5.0) & late service', () async {
      final req = DisputeRequest(
        requestId: 'req_l5',
        sessionId: 'sess_l5',
        bookingId: 'book_l5',
        customerId: 'cust_l5',
        providerId: 'prov_l5',
        rating: 5.0,
        feedback: 'He was slightly late',
        bookingStatus: 'completed',
        createdAt: DateTime.now(),
      );

      final resp = await service.processRequest(req);

      expect(resp.disputeCase.severity, 'low');
      expect(resp.disputeCase.category, 'late_service');
      expect(resp.resolutionRecommendation.refundPercentage, 10.0);
      expect(resp.resolutionRecommendation.providerPenalty, 0.0); // none
      expect(resp.escalationMetadata.isEscalated, false);
      expect(resp.resolutionRecommendation.recommendedAction, 'educational_feedback');
    });

    test('5. Input Validation Failures', () async {
      final invalidReq = DisputeRequest(
        requestId: '',
        sessionId: 'sess_1',
        bookingId: 'book_1',
        customerId: 'cust_1',
        providerId: 'prov_1',
        rating: 6.0, // Invalid rating (> 5)
        feedback: 'feedback',
        bookingStatus: 'completed',
        createdAt: DateTime.now(),
      );

      // System should enter degraded fallback mode due to validation/argument error
      final resp = await service.processRequest(invalidReq);
      expect(resp.orchestrationStatus, 'failed_degraded');
      expect(resp.confidenceScore, 0.5);
      expect(resp.resolutionRecommendation.recommendedAction, 'manual_review_fallback');
    });

    test('6. Idempotency Check', () async {
      final req = DisputeRequest(
        requestId: 'req_idemp',
        sessionId: 'sess_idemp',
        bookingId: 'book_idemp',
        customerId: 'cust_idemp',
        providerId: 'prov_idemp',
        rating: 1.0,
        feedback: 'Scam',
        bookingStatus: 'completed',
        createdAt: DateTime.now(),
      );

      // First call
      final resp1 = await service.processRequest(req);
      final countBefore = mockDb.database['disputes']!.length;

      // Second call
      final resp2 = await service.processRequest(req);

      // Verify same results and no duplicate database insert
      expect(resp2.disputeCase.disputeId, resp1.disputeCase.disputeId);
      expect(resp2.resolutionRecommendation.refundPercentage, resp1.resolutionRecommendation.refundPercentage);
      expect(mockDb.database['disputes']!.length, countBefore);
    });

    test('7. Database outage triggers degraded fallback gracefully', () async {
      final req = DisputeRequest(
        requestId: 'req_outage',
        sessionId: 'sess_outage',
        bookingId: 'book_outage',
        customerId: 'cust_outage',
        providerId: 'prov_outage',
        rating: 1.0,
        feedback: 'Outage',
        bookingStatus: 'completed',
        createdAt: DateTime.now(),
      );

      mockDb.throwError = true;

      // Should not throw, should return degraded response
      final resp = await service.processRequest(req);
      expect(resp.orchestrationStatus, 'failed_degraded');
      expect(resp.confidenceScore, 0.5);
      expect(resp.resolutionRecommendation.recommendedAction, 'manual_review_fallback');
    });
  });
}
