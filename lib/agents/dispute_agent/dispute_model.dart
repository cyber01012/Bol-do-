// lib/agents/dispute_agent/dispute_model.dart

/// Class representing the metadata of a dispute escalation.
class EscalationMetadata {
  final String escalationId;
  final bool isEscalated;
  final String escalationReason;
  final String escalatedTo;
  final DateTime? escalationTime;
  final String riskLevel;

  const EscalationMetadata({
    required this.escalationId,
    required this.isEscalated,
    required this.escalationReason,
    required this.escalatedTo,
    this.escalationTime,
    required this.riskLevel,
  });

  /// Factory constructor to create [EscalationMetadata] from JSON Map with fallback defaults.
  factory EscalationMetadata.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTime;
    final timeRaw = json['escalation_time'] ?? json['escalationTime'];
    if (timeRaw != null) {
      parsedTime = DateTime.tryParse(timeRaw.toString());
    }

    return EscalationMetadata(
      escalationId: json['escalation_id'] as String? ?? json['escalationId'] as String? ?? '',
      isEscalated: json['is_escalated'] as bool? ?? json['isEscalated'] as bool? ?? false,
      escalationReason: json['escalation_reason'] as String? ?? json['escalationReason'] as String? ?? 'None',
      escalatedTo: json['escalated_to'] as String? ?? json['escalatedTo'] as String? ?? 'none',
      escalationTime: parsedTime,
      riskLevel: json['risk_level'] as String? ?? json['riskLevel'] as String? ?? 'low',
    );
  }

  /// Converts the metadata instance into a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'escalation_id': escalationId,
      'is_escalated': isEscalated,
      'escalation_reason': escalationReason,
      'escalated_to': escalatedTo,
      'escalation_time': escalationTime?.toIso8601String(),
      'risk_level': riskLevel,
    };
  }

  /// Creates a copy of the metadata with modified fields for immutable state operations.
  EscalationMetadata copyWith({
    String? escalationId,
    bool? isEscalated,
    String? escalationReason,
    String? escalatedTo,
    DateTime? escalationTime,
    String? riskLevel,
  }) {
    return EscalationMetadata(
      escalationId: escalationId ?? this.escalationId,
      isEscalated: isEscalated ?? this.isEscalated,
      escalationReason: escalationReason ?? this.escalationReason,
      escalatedTo: escalatedTo ?? this.escalatedTo,
      escalationTime: escalationTime ?? this.escalationTime,
      riskLevel: riskLevel ?? this.riskLevel,
    );
  }

  @override
  String toString() {
    return 'EscalationMetadata(escalationId: $escalationId, isEscalated: $isEscalated, '
        'escalationReason: $escalationReason, escalatedTo: $escalatedTo, '
        'escalationTime: $escalationTime, riskLevel: $riskLevel)';
  }
}

/// Class representing the recommendation for dispute resolution.
class ResolutionRecommendation {
  final double refundPercentage;
  final double providerPenalty;
  final String supportPriority;
  final String recommendedAction;

  const ResolutionRecommendation({
    required this.refundPercentage,
    required this.providerPenalty,
    required this.supportPriority,
    required this.recommendedAction,
  });

  /// Factory constructor to create [ResolutionRecommendation] from JSON Map with fallback defaults.
  factory ResolutionRecommendation.fromJson(Map<String, dynamic> json) {
    return ResolutionRecommendation(
      refundPercentage: (json['refund_percentage'] as num?)?.toDouble() ??
          (json['refundPercentage'] as num?)?.toDouble() ?? 0.0,
      providerPenalty: (json['provider_penalty'] as num?)?.toDouble() ??
          (json['providerPenalty'] as num?)?.toDouble() ?? 0.0,
      supportPriority: json['support_priority'] as String? ?? json['supportPriority'] as String? ?? 'low',
      recommendedAction: json['recommended_action'] as String? ?? json['recommendedAction'] as String? ?? 'none',
    );
  }

  /// Converts the recommendation instance into a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'refund_percentage': refundPercentage,
      'provider_penalty': providerPenalty,
      'support_priority': supportPriority,
      'recommended_action': recommendedAction,
    };
  }

  /// Creates a copy of the recommendation with modified fields for immutable state operations.
  ResolutionRecommendation copyWith({
    double? refundPercentage,
    double? providerPenalty,
    String? supportPriority,
    String? recommendedAction,
  }) {
    return ResolutionRecommendation(
      refundPercentage: refundPercentage ?? this.refundPercentage,
      providerPenalty: providerPenalty ?? this.providerPenalty,
      supportPriority: supportPriority ?? this.supportPriority,
      recommendedAction: recommendedAction ?? this.recommendedAction,
    );
  }

  @override
  String toString() {
    return 'ResolutionRecommendation(refundPercentage: $refundPercentage, '
        'providerPenalty: $providerPenalty, supportPriority: $supportPriority, '
        'recommendedAction: $recommendedAction)';
  }
}

/// Class representing an individual dispute case details.
class DisputeCase {
  final String disputeId;
  final String severity;
  final String category;
  final String status;
  final DateTime createdAt;

  const DisputeCase({
    required this.disputeId,
    required this.severity,
    required this.category,
    required this.status,
    required this.createdAt,
  });

  /// Factory constructor to create [DisputeCase] from JSON Map with fallback defaults.
  factory DisputeCase.fromJson(Map<String, dynamic> json) {
    DateTime? parsedCreated;
    final createdRaw = json['created_at'] ?? json['createdAt'];
    if (createdRaw != null) {
      parsedCreated = DateTime.tryParse(createdRaw.toString());
    }

    return DisputeCase(
      disputeId: json['dispute_id'] as String? ?? json['disputeId'] as String? ?? '',
      severity: json['severity'] as String? ?? json['severity'] as String? ?? 'medium',
      category: json['category'] as String? ?? json['category'] as String? ?? 'general',
      status: json['status'] as String? ?? json['status'] as String? ?? 'pending',
      createdAt: parsedCreated ?? DateTime.now(),
    );
  }

  /// Converts the case instance into a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'dispute_id': disputeId,
      'severity': severity,
      'category': category,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of the case with modified fields for immutable state operations.
  DisputeCase copyWith({
    String? disputeId,
    String? severity,
    String? category,
    String? status,
    DateTime? createdAt,
  }) {
    return DisputeCase(
      disputeId: disputeId ?? this.disputeId,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'DisputeCase(disputeId: $disputeId, severity: $severity, '
        'category: $category, status: $status, createdAt: $createdAt)';
  }
}

/// Class representing the input request for the dispute orchestrator.
class DisputeRequest {
  final String requestId;
  final String sessionId;
  final String bookingId;
  final String customerId;
  final String providerId;
  final double rating;
  final String feedback;
  final String bookingStatus;
  final DateTime createdAt;

  const DisputeRequest({
    required this.requestId,
    required this.sessionId,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    required this.rating,
    required this.feedback,
    required this.bookingStatus,
    required this.createdAt,
  });

  /// Factory constructor to create [DisputeRequest] from JSON Map with fallback defaults.
  factory DisputeRequest.fromJson(Map<String, dynamic> json) {
    DateTime? parsedCreated;
    final createdRaw = json['created_at'] ?? json['createdAt'];
    if (createdRaw != null) {
      parsedCreated = DateTime.tryParse(createdRaw.toString());
    }

    return DisputeRequest(
      requestId: json['request_id'] as String? ?? json['requestId'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? json['sessionId'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? json['bookingId'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? json['customerId'] as String? ?? '',
      providerId: json['provider_id'] as String? ?? json['providerId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      feedback: json['feedback'] as String? ?? '',
      bookingStatus: json['booking_status'] as String? ?? json['bookingStatus'] as String? ?? 'pending',
      createdAt: parsedCreated ?? DateTime.now(),
    );
  }

  /// Converts the request instance into a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'session_id': sessionId,
      'booking_id': bookingId,
      'customer_id': customerId,
      'provider_id': providerId,
      'rating': rating,
      'feedback': feedback,
      'booking_status': bookingStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of the request with modified fields for immutable state operations.
  DisputeRequest copyWith({
    String? requestId,
    String? sessionId,
    String? bookingId,
    String? customerId,
    String? providerId,
    double? rating,
    String? feedback,
    String? bookingStatus,
    DateTime? createdAt,
  }) {
    return DisputeRequest(
      requestId: requestId ?? this.requestId,
      sessionId: sessionId ?? this.sessionId,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'DisputeRequest(requestId: $requestId, sessionId: $sessionId, '
        'bookingId: $bookingId, customerId: $customerId, providerId: $providerId, '
        'rating: $rating, feedback: $feedback, bookingStatus: $bookingStatus, '
        'createdAt: $createdAt)';
  }
}

/// Class representing the output response from the dispute orchestrator.
class DisputeResponse {
  final String requestId;
  final DisputeCase disputeCase;
  final ResolutionRecommendation resolutionRecommendation;
  final String orchestrationStatus;
  final double confidenceScore;
  final EscalationMetadata escalationMetadata;

  const DisputeResponse({
    required this.requestId,
    required this.disputeCase,
    required this.resolutionRecommendation,
    required this.orchestrationStatus,
    required this.confidenceScore,
    required this.escalationMetadata,
  });

  /// Factory constructor to create [DisputeResponse] from JSON Map with fallback defaults.
  factory DisputeResponse.fromJson(Map<String, dynamic> json) {
    return DisputeResponse(
      requestId: json['request_id'] as String? ?? json['requestId'] as String? ?? '',
      disputeCase: json['dispute_case'] != null
          ? DisputeCase.fromJson(json['dispute_case'] as Map<String, dynamic>)
          : (json['disputeCase'] != null
              ? DisputeCase.fromJson(json['disputeCase'] as Map<String, dynamic>)
              : DisputeCase.fromJson(const {})),
      resolutionRecommendation: json['resolution_recommendation'] != null
          ? ResolutionRecommendation.fromJson(json['resolution_recommendation'] as Map<String, dynamic>)
          : (json['resolutionRecommendation'] != null
              ? ResolutionRecommendation.fromJson(json['resolutionRecommendation'] as Map<String, dynamic>)
              : ResolutionRecommendation.fromJson(const {})),
      orchestrationStatus: json['orchestration_status'] as String? ?? json['orchestrationStatus'] as String? ?? 'success',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ??
          (json['confidenceScore'] as num?)?.toDouble() ?? 1.0,
      escalationMetadata: json['escalation_metadata'] != null
          ? EscalationMetadata.fromJson(json['escalation_metadata'] as Map<String, dynamic>)
          : (json['escalationMetadata'] != null
              ? EscalationMetadata.fromJson(json['escalationMetadata'] as Map<String, dynamic>)
              : EscalationMetadata.fromJson(const {})),
    );
  }

  /// Converts the response instance into a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'dispute_case': disputeCase.toJson(),
      'resolution_recommendation': resolutionRecommendation.toJson(),
      'orchestration_status': orchestrationStatus,
      'confidence_score': confidenceScore,
      'escalation_metadata': escalationMetadata.toJson(),
    };
  }

  /// Creates a copy of the response with modified fields for immutable state operations.
  DisputeResponse copyWith({
    String? requestId,
    DisputeCase? disputeCase,
    ResolutionRecommendation? resolutionRecommendation,
    String? orchestrationStatus,
    double? confidenceScore,
    EscalationMetadata? escalationMetadata,
  }) {
    return DisputeResponse(
      requestId: requestId ?? this.requestId,
      disputeCase: disputeCase ?? this.disputeCase,
      resolutionRecommendation: resolutionRecommendation ?? this.resolutionRecommendation,
      orchestrationStatus: orchestrationStatus ?? this.orchestrationStatus,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      escalationMetadata: escalationMetadata ?? this.escalationMetadata,
    );
  }

  @override
  String toString() {
    return 'DisputeResponse(requestId: $requestId, disputeCase: $disputeCase, '
        'resolutionRecommendation: $resolutionRecommendation, '
        'orchestrationStatus: $orchestrationStatus, confidenceScore: $confidenceScore, '
        'escalationMetadata: $escalationMetadata)';
  }
}
