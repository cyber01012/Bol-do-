class PricingRequest {
  final String requestId;
  final String sessionId;
  final UserRequest userRequest;
  final SelectedProvider selectedProvider;
  final RankingMetadata? rankingMetadata;

  PricingRequest({
    required this.requestId,
    required this.sessionId,
    required this.userRequest,
    required this.selectedProvider,
    this.rankingMetadata,
  });

  factory PricingRequest.fromJson(Map<String, dynamic> json) {
    return PricingRequest(
      requestId: json['request_id'] as String,
      sessionId: json['session_id'] as String,
      userRequest: UserRequest.fromJson(json['user_request'] as Map<String, dynamic>),
      selectedProvider: SelectedProvider.fromJson(json['selected_provider'] as Map<String, dynamic>),
      rankingMetadata: json['ranking_metadata'] != null ? RankingMetadata.fromJson(json['ranking_metadata'] as Map<String, dynamic>) : null,
    );
  }
}

class UserRequest {
  final String serviceType;
  final String? urgency;
  final DateTime? requestedTime;
  final bool isRepeatCustomer;

  UserRequest({
    required this.serviceType,
    this.urgency,
    this.requestedTime,
    required this.isRepeatCustomer,
  });

  factory UserRequest.fromJson(Map<String, dynamic> json) {
    return UserRequest(
      serviceType: json['service_type'] as String? ?? 'basic',
      urgency: json['urgency'] as String?,
      requestedTime: json['requested_time'] != null ? DateTime.parse(json['requested_time'] as String) : null,
      isRepeatCustomer: json['is_repeat_customer'] as bool? ?? false,
    );
  }
}

class SelectedProvider {
  final String providerId;
  final String name;
  final String serviceType;
  final double? distanceKm;
  final String complexity;
  final Map<String, dynamic>? providerMetadata;

  SelectedProvider({
    required this.providerId,
    required this.name,
    required this.serviceType,
    this.distanceKm,
    required this.complexity,
    this.providerMetadata,
  });

  factory SelectedProvider.fromJson(Map<String, dynamic> json) {
    return SelectedProvider(
      providerId: json['provider_id'] as String,
      name: json['name'] as String? ?? '',
      serviceType: json['service_type'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      complexity: json['complexity'] as String? ?? 'basic',
      providerMetadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'name': name,
      'service_type': serviceType,
      'distance_km': distanceKm,
      'complexity': complexity,
      'metadata': providerMetadata,
    };
  }
}

class RankingMetadata {
  final double rankScore;
  final String rankingReason;

  RankingMetadata({required this.rankScore, required this.rankingReason});

  factory RankingMetadata.fromJson(Map<String, dynamic> json) {
    return RankingMetadata(
      rankScore: (json['rank_score'] as num).toDouble(),
      rankingReason: json['ranking_reason'] as String,
    );
  }
}

class PricingResponse {
  final String requestId;
  final String sessionId;
  final String agentTraceId;
  final String orchestrationStatus;
  final bool readyForBooking;
  final SelectedProvider selectedProvider;
  final PricingData pricingData;

  PricingResponse({
    required this.requestId,
    required this.sessionId,
    required this.agentTraceId,
    required this.orchestrationStatus,
    required this.readyForBooking,
    required this.selectedProvider,
    required this.pricingData,
  });

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'session_id': sessionId,
      'agent_trace_id': agentTraceId,
      'orchestration_status': orchestrationStatus,
      'ready_for_booking': readyForBooking,
      'selected_provider': selectedProvider.toJson(),
      'pricing_data': pricingData.toJson(),
    };
  }
}

class PricingData {
  final double totalPricePkr;
  final double confidenceScore;
  final Map<String, dynamic> breakdown;

  PricingData({
    required this.totalPricePkr,
    required this.confidenceScore,
    required this.breakdown,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_price_pkr': totalPricePkr,
      'confidence_score': confidenceScore,
      'breakdown': breakdown,
    };
  }
}
