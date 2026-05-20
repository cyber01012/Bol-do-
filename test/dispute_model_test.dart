import 'package:flutter_test/flutter_test.dart';
import 'package:boldo_ai/agents/dispute_agent/dispute_model.dart';

void main() {
  group('EscalationMetadata Tests', () {
    test('Constructor and values', () {
      final time = DateTime(2026, 5, 19, 12, 0);
      final metadata = EscalationMetadata(
        escalationId: 'esc_123',
        isEscalated: true,
        escalationReason: 'Late arrival',
        escalatedTo: 'support_lead',
        escalationTime: time,
        riskLevel: 'high',
      );

      expect(metadata.escalationId, 'esc_123');
      expect(metadata.isEscalated, true);
      expect(metadata.escalationReason, 'Late arrival');
      expect(metadata.escalatedTo, 'support_lead');
      expect(metadata.escalationTime, time);
      expect(metadata.riskLevel, 'high');
    });

    test('fromJson and toJson serialization', () {
      final time = DateTime(2026, 5, 19, 12, 0);
      final json = {
        'escalation_id': 'esc_123',
        'is_escalated': true,
        'escalation_reason': 'Late arrival',
        'escalated_to': 'support_lead',
        'escalation_time': time.toIso8601String(),
        'risk_level': 'high',
      };

      final metadata = EscalationMetadata.fromJson(json);
      expect(metadata.escalationId, 'esc_123');
      expect(metadata.isEscalated, true);
      expect(metadata.escalationReason, 'Late arrival');
      expect(metadata.escalatedTo, 'support_lead');
      expect(metadata.escalationTime, time);
      expect(metadata.riskLevel, 'high');

      final serialized = metadata.toJson();
      expect(serialized['escalation_id'], 'esc_123');
      expect(serialized['is_escalated'], true);
      expect(serialized['escalation_reason'], 'Late arrival');
      expect(serialized['escalated_to'], 'support_lead');
      expect(serialized['escalation_time'], time.toIso8601String());
      expect(serialized['risk_level'], 'high');
    });

    test('fromJson fallback defaults', () {
      final metadata = EscalationMetadata.fromJson({});
      expect(metadata.escalationId, '');
      expect(metadata.isEscalated, false);
      expect(metadata.escalationReason, 'None');
      expect(metadata.escalatedTo, 'none');
      expect(metadata.escalationTime, isNull);
      expect(metadata.riskLevel, 'low');
    });

    test('copyWith logic', () {
      final metadata = const EscalationMetadata(
        escalationId: 'esc_123',
        isEscalated: true,
        escalationReason: 'Late arrival',
        escalatedTo: 'support_lead',
        riskLevel: 'high',
      );

      final updated = metadata.copyWith(
        escalationId: 'esc_456',
        isEscalated: false,
      );

      expect(updated.escalationId, 'esc_456');
      expect(updated.isEscalated, false);
      expect(updated.escalationReason, 'Late arrival');
      expect(updated.escalatedTo, 'support_lead');
      expect(updated.riskLevel, 'high');
    });

    test('toString representation', () {
      final metadata = const EscalationMetadata(
        escalationId: 'esc_123',
        isEscalated: true,
        escalationReason: 'Late',
        escalatedTo: 'agent',
        riskLevel: 'high',
      );

      expect(metadata.toString(), contains('escalationId: esc_123'));
    });
  });

  group('ResolutionRecommendation Tests', () {
    test('Constructor and serialization', () {
      final rec = ResolutionRecommendation(
        refundPercentage: 50.0,
        providerPenalty: 25.0,
        supportPriority: 'urgent',
        recommendedAction: 'refund',
      );

      expect(rec.refundPercentage, 50.0);
      expect(rec.providerPenalty, 25.0);
      expect(rec.supportPriority, 'urgent');
      expect(rec.recommendedAction, 'refund');

      final json = rec.toJson();
      expect(json['refund_percentage'], 50.0);
      expect(json['provider_penalty'], 25.0);
      expect(json['support_priority'], 'urgent');
      expect(json['recommended_action'], 'refund');

      final fromJson = ResolutionRecommendation.fromJson(json);
      expect(fromJson.refundPercentage, 50.0);
      expect(fromJson.providerPenalty, 25.0);
      expect(fromJson.supportPriority, 'urgent');
      expect(fromJson.recommendedAction, 'refund');
    });

    test('fromJson fallback defaults', () {
      final rec = ResolutionRecommendation.fromJson({});
      expect(rec.refundPercentage, 0.0);
      expect(rec.providerPenalty, 0.0);
      expect(rec.supportPriority, 'low');
      expect(rec.recommendedAction, 'none');
    });

    test('copyWith logic', () {
      final rec = const ResolutionRecommendation(
        refundPercentage: 50.0,
        providerPenalty: 25.0,
        supportPriority: 'urgent',
        recommendedAction: 'refund',
      );

      final updated = rec.copyWith(refundPercentage: 100.0);
      expect(updated.refundPercentage, 100.0);
      expect(updated.providerPenalty, 25.0);
    });
  });

  group('DisputeCase Tests', () {
    test('Constructor and serialization', () {
      final time = DateTime(2026, 5, 19, 12, 0);
      final dCase = DisputeCase(
        disputeId: 'disp_123',
        severity: 'high',
        category: 'damage',
        status: 'investigating',
        createdAt: time,
      );

      expect(dCase.disputeId, 'disp_123');
      expect(dCase.severity, 'high');
      expect(dCase.category, 'damage');
      expect(dCase.status, 'investigating');
      expect(dCase.createdAt, time);

      final json = dCase.toJson();
      expect(json['dispute_id'], 'disp_123');
      expect(json['created_at'], time.toIso8601String());

      final fromJson = DisputeCase.fromJson(json);
      expect(fromJson.disputeId, 'disp_123');
      expect(fromJson.createdAt, time);
    });

    test('fromJson fallback defaults', () {
      final dCase = DisputeCase.fromJson({});
      expect(dCase.disputeId, '');
      expect(dCase.severity, 'medium');
      expect(dCase.category, 'general');
      expect(dCase.status, 'pending');
      expect(dCase.createdAt, isNotNull);
    });

    test('copyWith logic', () {
      final time = DateTime(2026, 5, 19, 12, 0);
      final dCase = DisputeCase(
        disputeId: 'disp_123',
        severity: 'high',
        category: 'damage',
        status: 'investigating',
        createdAt: time,
      );

      final updated = dCase.copyWith(status: 'resolved');
      expect(updated.status, 'resolved');
      expect(updated.disputeId, 'disp_123');
    });
  });

  group('DisputeRequest Tests', () {
    test('Constructor and serialization', () {
      final time = DateTime(2026, 5, 19, 12, 0);
      final req = DisputeRequest(
        requestId: 'req_123',
        sessionId: 'sess_123',
        bookingId: 'book_123',
        customerId: 'cust_123',
        providerId: 'prov_123',
        rating: 1.5,
        feedback: 'Poor service quality',
        bookingStatus: 'completed',
        createdAt: time,
      );

      expect(req.requestId, 'req_123');
      expect(req.sessionId, 'sess_123');
      expect(req.bookingId, 'book_123');
      expect(req.customerId, 'cust_123');
      expect(req.providerId, 'prov_123');
      expect(req.rating, 1.5);
      expect(req.feedback, 'Poor service quality');
      expect(req.bookingStatus, 'completed');
      expect(req.createdAt, time);

      final json = req.toJson();
      expect(json['request_id'], 'req_123');
      expect(json['rating'], 1.5);
      expect(json['created_at'], time.toIso8601String());

      final fromJson = DisputeRequest.fromJson(json);
      expect(fromJson.requestId, 'req_123');
      expect(fromJson.rating, 1.5);
      expect(fromJson.createdAt, time);
    });

    test('fromJson fallback defaults', () {
      final req = DisputeRequest.fromJson({});
      expect(req.requestId, '');
      expect(req.sessionId, '');
      expect(req.bookingId, '');
      expect(req.customerId, '');
      expect(req.providerId, '');
      expect(req.rating, 0.0);
      expect(req.feedback, '');
      expect(req.bookingStatus, 'pending');
      expect(req.createdAt, isNotNull);
    });
  });

  group('DisputeResponse Tests', () {
    test('Constructor and serialization', () {
      final time = DateTime(2026, 5, 19, 12, 0);
      final dCase = DisputeCase(
        disputeId: 'disp_123',
        severity: 'high',
        category: 'damage',
        status: 'investigating',
        createdAt: time,
      );
      final rec = ResolutionRecommendation(
        refundPercentage: 50.0,
        providerPenalty: 25.0,
        supportPriority: 'urgent',
        recommendedAction: 'refund',
      );
      final metadata = EscalationMetadata(
        escalationId: 'esc_123',
        isEscalated: true,
        escalationReason: 'Late arrival',
        escalatedTo: 'support_lead',
        escalationTime: time,
        riskLevel: 'high',
      );

      final resp = DisputeResponse(
        requestId: 'req_123',
        disputeCase: dCase,
        resolutionRecommendation: rec,
        orchestrationStatus: 'resolved',
        confidenceScore: 0.95,
        escalationMetadata: metadata,
      );

      expect(resp.requestId, 'req_123');
      expect(resp.disputeCase.disputeId, 'disp_123');
      expect(resp.resolutionRecommendation.refundPercentage, 50.0);
      expect(resp.orchestrationStatus, 'resolved');
      expect(resp.confidenceScore, 0.95);
      expect(resp.escalationMetadata.escalationId, 'esc_123');

      final json = resp.toJson();
      expect(json['request_id'], 'req_123');
      expect(json['confidence_score'], 0.95);

      final fromJson = DisputeResponse.fromJson(json);
      expect(fromJson.requestId, 'req_123');
      expect(fromJson.disputeCase.disputeId, 'disp_123');
      expect(fromJson.resolutionRecommendation.refundPercentage, 50.0);
      expect(fromJson.orchestrationStatus, 'resolved');
      expect(fromJson.confidenceScore, 0.95);
      expect(fromJson.escalationMetadata.escalationId, 'esc_123');
    });

    test('fromJson fallback defaults', () {
      final resp = DisputeResponse.fromJson({});
      expect(resp.requestId, '');
      expect(resp.disputeCase, isNotNull);
      expect(resp.resolutionRecommendation, isNotNull);
      expect(resp.orchestrationStatus, 'success');
      expect(resp.confidenceScore, 1.0);
      expect(resp.escalationMetadata, isNotNull);
    });
  });
}
