import 'dart:math';
import 'dart:developer' as developer;
import 'dispute_model.dart';
import 'firestore_service.dart';
import '../../services/central_trace_logger.dart';

/// Enterprise-grade service that handles dispute processing for bookings.
/// Coordinates input validation, idempotency checks, categorization, severity checks,
/// penalty assignment, escalation checks, Firestore persistence, and trace logging.
class DisputeAgentService {
  final FirestoreService _firestoreService;
  final CentralTraceLogger _traceLogger;

  /// Default constructor allowing dependency injection of services.
  DisputeAgentService({
    FirestoreService? firestoreService,
    CentralTraceLogger? traceLogger,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _traceLogger = traceLogger ?? CentralTraceLogger();

  /// Main entry point to process a dispute request.
  /// Runs deterministically to detect category, severity, penalty, refund rate,
  /// and escalation requirements. Saves state to Firestore and writes trace logs.
  /// Enters degraded fallback mode in case of unhandled database or system errors.
  Future<DisputeResponse> processRequest(DisputeRequest request) async {
    final traceId = 'trace_disp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

    try {
      // 1. Input Validation
      _validateRequest(request);

      final String docId = 'dispute_${request.sessionId}';

      // 2. Idempotency Check
      final existingDoc = await _firestoreService.getDocument('disputes', docId);
      if (existingDoc != null) {
        final response = DisputeResponse.fromJson(existingDoc);

        // Async trace log for the idempotency match
        await _traceLogger.logTrace(
          traceId: traceId,
          sessionId: request.sessionId,
          userId: request.requestId,
          agentName: 'DisputeAgent',
          decision: 'Idempotency Match: dispute already processed for this session.',
          confidence: 1.0,
          orchestrationStatus: response.orchestrationStatus,
          reasoning: {
            'idempotency': 'matched',
            'saved_status': response.disputeCase.status,
            'skipped_recalculation': true,
            'escalation_level': response.escalationMetadata.riskLevel,
          },
        );

        return response;
      }

      // 3. Severity Detection
      final String severity = _detectSeverity(request.rating);

      // 4. Dispute Categorization
      final String category = _categorizeDispute(request.feedback);

      // 5. Refund Recommendation
      final double refundPercentage = _calculateRefund(severity);

      // 6. Provider Penalty Calculation
      final double providerPenalty = _calculatePenaltyScore(severity);

      // 7. Escalation Logic
      final escalationMetadata = _buildEscalationMetadata(request.sessionId, severity);

      // Support Priority Assessment
      String supportPriority = 'low';
      if (severity == 'critical') {
        supportPriority = 'critical';
      } else if (severity == 'high') {
        supportPriority = 'high';
      } else if (severity == 'medium') {
        supportPriority = 'medium';
      }

      // Action Determination
      String recommendedAction = 'none';
      if (severity == 'critical') {
        recommendedAction = 'refund_and_ban';
      } else if (severity == 'high') {
        recommendedAction = 'refund_and_warning';
      } else if (severity == 'medium') {
        recommendedAction = 'partial_refund';
      } else {
        recommendedAction = 'educational_feedback';
      }

      final resolutionRecommendation = ResolutionRecommendation(
        refundPercentage: refundPercentage,
        providerPenalty: providerPenalty,
        supportPriority: supportPriority,
        recommendedAction: recommendedAction,
      );

      final disputeCase = DisputeCase(
        disputeId: 'disp_${request.sessionId}',
        severity: severity,
        category: category,
        status: escalationMetadata.isEscalated ? 'escalated' : 'resolved',
        createdAt: DateTime.now().toUtc(),
      );

      final orchestrationStatus = escalationMetadata.isEscalated ? 'escalated' : 'resolved';

      // 8. Confidence Scoring
      final double confidenceScore = _calculateConfidence(category, request.feedback);

      final response = DisputeResponse(
        requestId: request.requestId,
        disputeCase: disputeCase,
        resolutionRecommendation: resolutionRecommendation,
        orchestrationStatus: orchestrationStatus,
        confidenceScore: confidenceScore,
        escalationMetadata: escalationMetadata,
      );

      // 9. Firestore Persistence
      final Map<String, dynamic> disputeDocData = {
        ...response.toJson(),
        'session_id': request.sessionId,
        'booking_id': request.bookingId,
        'customer_id': request.customerId,
        'provider_id': request.providerId,
        'rating': request.rating,
        'feedback': request.feedback,
        'booking_status': request.bookingStatus,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _firestoreService.saveDocument('disputes', docId, disputeDocData);

      // 10. Trace Logging
      await _traceLogger.logTrace(
        traceId: traceId,
        sessionId: request.sessionId,
        userId: request.requestId,
        agentName: 'DisputeAgent',
        decision: orchestrationStatus == 'escalated'
            ? 'Dispute escalated to support tier due to high severity rating.'
            : 'Dispute auto-resolved with recommendation action.',
        confidence: confidenceScore,
        orchestrationStatus: orchestrationStatus,
        reasoning: {
          'idempotency': 'clear',
          'rating_score': request.rating,
          'severity_level': severity,
          'detected_category': category,
          'refund_percentage': refundPercentage,
          'penalty_score': providerPenalty,
          'is_escalated': escalationMetadata.isEscalated,
          'escalation_level': severity,
        },
      );

      return response;
    } catch (e) {
      // 11. Degraded Fallback Mode
      return _buildFallbackResponse(request, traceId, e.toString());
    }
  }

  /// Performs strict input validations on the dispute request model.
  void _validateRequest(DisputeRequest request) {
    if (request.requestId.trim().isEmpty) {
      throw ArgumentError('requestId cannot be empty');
    }
    if (request.sessionId.trim().isEmpty) {
      throw ArgumentError('sessionId cannot be empty');
    }
    if (request.bookingId.trim().isEmpty) {
      throw ArgumentError('bookingId cannot be empty');
    }
    if (request.customerId.trim().isEmpty) {
      throw ArgumentError('customerId cannot be empty');
    }
    if (request.providerId.trim().isEmpty) {
      throw ArgumentError('providerId cannot be empty');
    }
    if (request.rating < 0.0 || request.rating > 5.0) {
      throw ArgumentError('rating must be between 0.0 and 5.0 inclusive');
    }
  }

  /// Evaluates severity based on rating.
  String _detectSeverity(double rating) {
    if (rating <= 1.0) {
      return 'critical';
    } else if (rating <= 2.0) {
      return 'high';
    } else if (rating <= 3.0) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  /// Maps feedback text to a specific category deterministically.
  String _categorizeDispute(String feedback) {
    final cleanFeedback = feedback.toLowerCase();
    if (cleanFeedback.contains('fraud') ||
        cleanFeedback.contains('cheat') ||
        cleanFeedback.contains('fake') ||
        cleanFeedback.contains('stole') ||
        cleanFeedback.contains('scam')) {
      return 'fraud';
    }
    if (cleanFeedback.contains('late') ||
        cleanFeedback.contains('delay') ||
        cleanFeedback.contains('time') ||
        cleanFeedback.contains('hour') ||
        cleanFeedback.contains('wait') ||
        cleanFeedback.contains('slow')) {
      return 'late_service';
    }
    if (cleanFeedback.contains('quality') ||
        cleanFeedback.contains('bad') ||
        cleanFeedback.contains('poor') ||
        cleanFeedback.contains('broken') ||
        cleanFeedback.contains('worst') ||
        cleanFeedback.contains('unprofessional') ||
        cleanFeedback.contains('dirty') ||
        cleanFeedback.contains('damage')) {
      return 'poor_quality';
    }
    if (cleanFeedback.contains('rude') ||
        cleanFeedback.contains('behavior') ||
        cleanFeedback.contains('attitude') ||
        cleanFeedback.contains('mean') ||
        cleanFeedback.contains('angry') ||
        cleanFeedback.contains('shout') ||
        cleanFeedback.contains('abuse')) {
      return 'rude_behavior';
    }
    if (cleanFeedback.contains('charge') ||
        cleanFeedback.contains('price') ||
        cleanFeedback.contains('money') ||
        cleanFeedback.contains('expensive') ||
        cleanFeedback.contains('fee') ||
        cleanFeedback.contains('cost') ||
        cleanFeedback.contains('overcharge')) {
      return 'overcharging';
    }
    return 'unknown';
  }

  /// Calculates refund rate based on severity.
  double _calculateRefund(String severity) {
    switch (severity) {
      case 'critical':
        return 100.0;
      case 'high':
        return 70.0;
      case 'medium':
        return 40.0;
      case 'low':
        return 10.0;
      default:
        return 0.0;
    }
  }

  /// Determines numerical penalty scores corresponding to penalty categories:
  /// critical -> strike (3.0), high -> warning (2.0), medium -> monitor (1.0), low -> none (0.0).
  double _calculatePenaltyScore(String severity) {
    switch (severity) {
      case 'critical':
        return 3.0; // strike
      case 'high':
        return 2.0; // warning
      case 'medium':
        return 1.0; // monitor
      case 'low':
      default:
        return 0.0; // none
    }
  }

  /// Constructs the escalation details based on severity rules.
  EscalationMetadata _buildEscalationMetadata(String sessionId, String severity) {
    final isEscalated = severity == 'critical' || severity == 'high';
    final escalatedTo = isEscalated
        ? (severity == 'critical' ? 'human_support_tier_2' : 'human_support_tier_1')
        : 'none';
    final escalationReason = isEscalated
        ? 'High severity dispute triggered automated escalation.'
        : 'None';

    return EscalationMetadata(
      escalationId: isEscalated ? 'esc_$sessionId' : '',
      isEscalated: isEscalated,
      escalationReason: escalationReason,
      escalatedTo: escalatedTo,
      escalationTime: isEscalated ? DateTime.now().toUtc() : null,
      riskLevel: severity,
    );
  }

  /// Computes a deterministic confidence score between 0.0 and 1.0.
  double _calculateConfidence(String category, String feedback) {
    double score = 0.85;
    if (category != 'unknown') {
      score += 0.10;
    }
    if (feedback.trim().length > 15) {
      score += 0.05;
    }
    return min(1.0, max(0.0, score));
  }

  /// Builds a fallback degraded response on catastrophic failure.
  DisputeResponse _buildFallbackResponse(DisputeRequest request, String traceId, String errorMessage) {
    final timestamp = DateTime.now().toUtc();

    final disputeCase = DisputeCase(
      disputeId: 'disp_fallback_${request.sessionId}',
      severity: 'medium',
      category: 'unknown',
      status: 'pending',
      createdAt: timestamp,
    );

    const resolutionRecommendation = ResolutionRecommendation(
      refundPercentage: 0.0,
      providerPenalty: 0.0,
      supportPriority: 'low',
      recommendedAction: 'manual_review_fallback',
    );

    final escalationMetadata = EscalationMetadata(
      escalationId: 'esc_fallback_${request.sessionId}',
      isEscalated: true,
      escalationReason: 'System entered degraded fallback mode due to processing error: $errorMessage',
      escalatedTo: 'support_manual_queue',
      escalationTime: timestamp,
      riskLevel: 'medium',
    );

    final response = DisputeResponse(
      requestId: request.requestId,
      disputeCase: disputeCase,
      resolutionRecommendation: resolutionRecommendation,
      orchestrationStatus: 'failed_degraded',
      confidenceScore: 0.5,
      escalationMetadata: escalationMetadata,
    );

    // Safely attempt trace logging
    _traceLogger.logTrace(
      traceId: traceId,
      sessionId: request.sessionId,
      userId: request.requestId,
      agentName: 'DisputeAgent',
      decision: 'Catastrophic error triggered degraded fallback mode.',
      confidence: 0.5,
      orchestrationStatus: 'failed_degraded',
      reasoning: {
        'error': errorMessage,
        'fallback': true,
        'escalation_level': 'degraded',
      },
    ).catchError((e) {
      print('TraceLogger failed during fallback logging: $e');
    });

    return response;
  }
}
