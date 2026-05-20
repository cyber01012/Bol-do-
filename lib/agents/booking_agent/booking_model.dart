class BookingRequest {
  final String requestId;
  final String sessionId;
  final String orchestrationStatus;
  final SelectedProvider selectedProvider;
  final PricingData pricingData;
  final UserRequest userRequest;
  final BookingMetadata? bookingMetadata;

  BookingRequest({
    required this.requestId,
    required this.sessionId,
    required this.orchestrationStatus,
    required this.selectedProvider,
    required this.pricingData,
    required this.userRequest,
    this.bookingMetadata,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    return BookingRequest(
      requestId: json['request_id'] as String,
      sessionId: json['session_id'] as String,
      orchestrationStatus: json['orchestration_status'] as String? ?? 'success',
      selectedProvider: SelectedProvider.fromJson(json['selected_provider'] as Map<String, dynamic>),
      pricingData: PricingData.fromJson(json['pricing_data'] as Map<String, dynamic>),
      userRequest: UserRequest.fromJson(json['user_request'] as Map<String, dynamic>),
      bookingMetadata: json['booking_metadata'] != null
          ? BookingMetadata.fromJson(json['booking_metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'session_id': sessionId,
      'orchestration_status': orchestrationStatus,
      'selected_provider': selectedProvider.toJson(),
      'pricing_data': pricingData.toJson(),
      'user_request': userRequest.toJson(),
      'booking_metadata': bookingMetadata?.toJson(),
    };
  }
}

class SelectedProvider {
  final String providerId;
  final String name;
  final String serviceType;

  SelectedProvider({
    required this.providerId,
    required this.name,
    required this.serviceType,
  });

  factory SelectedProvider.fromJson(Map<String, dynamic> json) {
    return SelectedProvider(
      providerId: json['provider_id'] as String,
      name: json['name'] as String? ?? 'Provider',
      serviceType: json['service_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'name': name,
      'service_type': serviceType,
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

  factory PricingData.fromJson(Map<String, dynamic> json) {
    return PricingData(
      totalPricePkr: (json['total_price_pkr'] as num).toDouble(),
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 1.0,
      breakdown: json['breakdown'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_price_pkr': totalPricePkr,
      'confidence_score': confidenceScore,
      'breakdown': breakdown,
    };
  }
}

class UserRequest {
  final String serviceType;
  final String urgency;
  final DateTime requestedTime;

  UserRequest({
    required this.serviceType,
    required this.urgency,
    required this.requestedTime,
  });

  factory UserRequest.fromJson(Map<String, dynamic> json) {
    return UserRequest(
      serviceType: json['service_type'] as String,
      urgency: json['urgency'] as String? ?? 'same_day',
      requestedTime: json['requested_time'] != null
          ? DateTime.parse(json['requested_time'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_type': serviceType,
      'urgency': urgency,
      'requested_time': requestedTime.toIso8601String(),
    };
  }
}

class BookingMetadata {
  final String paymentMethod;

  BookingMetadata({required this.paymentMethod});

  factory BookingMetadata.fromJson(Map<String, dynamic> json) {
    return BookingMetadata(
      paymentMethod: json['payment_method'] as String? ?? 'cash_on_delivery',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_method': paymentMethod,
    };
  }
}

class AlternativeRecommendation {
  final String providerId;
  final String name;
  final double rating;
  final String serviceType;
  final String reason;

  AlternativeRecommendation({
    required this.providerId,
    required this.name,
    required this.rating,
    required this.serviceType,
    required this.reason,
  });

  factory AlternativeRecommendation.fromJson(Map<String, dynamic> json) {
    return AlternativeRecommendation(
      providerId: json['provider_id'] as String,
      name: json['name'] as String,
      rating: (json['rating'] as num).toDouble(),
      serviceType: json['service_type'] as String,
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'name': name,
      'rating': rating,
      'service_type': serviceType,
      'reason': reason,
    };
  }
}

class CustomerSummary {
  final String customerId;
  final String name;
  final String contactNumber;

  CustomerSummary({
    required this.customerId,
    required this.name,
    required this.contactNumber,
  });

  factory CustomerSummary.fromJson(Map<String, dynamic> json) {
    return CustomerSummary(
      customerId: json['customer_id'] as String? ?? 'user_customer_999',
      name: json['name'] as String? ?? 'Valued Customer',
      contactNumber: json['contact_number'] as String? ?? '+923001234567',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'name': name,
      'contact_number': contactNumber,
    };
  }
}

class OrchestrationMetadata {
  final String sessionId;
  final String requestId;
  final String traceId;
  final String orchestrationStatus;
  final String currentAgent;
  final String nextAgent;

  OrchestrationMetadata({
    required this.sessionId,
    required this.requestId,
    required this.traceId,
    required this.orchestrationStatus,
    required this.currentAgent,
    required this.nextAgent,
  });

  factory OrchestrationMetadata.fromJson(Map<String, dynamic> json) {
    return OrchestrationMetadata(
      sessionId: json['session_id'] as String,
      requestId: json['request_id'] as String,
      traceId: json['trace_id'] as String,
      orchestrationStatus: json['orchestration_status'] as String,
      currentAgent: json['current_agent'] as String? ?? 'BookingAgent',
      nextAgent: json['next_agent'] as String? ?? 'NotificationAgent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'request_id': requestId,
      'trace_id': traceId,
      'orchestration_status': orchestrationStatus,
      'current_agent': currentAgent,
      'next_agent': nextAgent,
    };
  }
}

class BookingResponse {
  final String bookingId;
  final String bookingStatus;
  final SelectedProvider provider;
  final DateTime scheduledTime;
  final CustomerSummary customerSummary;
  final bool notificationRequired;
  final OrchestrationMetadata orchestrationMetadata;
  final AlternativeRecommendation? alternativeRecommendation;

  // Backward-compatible properties & placeholders
  final Map<String, dynamic> pricingData;
  final NotificationPayload notificationPayload;

  BookingResponse({
    required this.bookingId,
    required this.bookingStatus,
    required this.provider,
    required this.scheduledTime,
    required this.customerSummary,
    required this.notificationRequired,
    required this.orchestrationMetadata,
    this.alternativeRecommendation,
    required this.pricingData,
    required this.notificationPayload,
  });

  // Getter aliases for seamless backward compatibility with existing tests
  String get requestId => orchestrationMetadata.requestId;
  String get sessionId => orchestrationMetadata.sessionId;
  String get agentTraceId => orchestrationMetadata.traceId;
  String get orchestrationStatus => orchestrationMetadata.orchestrationStatus;
  SelectedProvider get selectedProvider => provider;

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'booking_status': bookingStatus,
      'provider': provider.toJson(),
      'scheduled_time': scheduledTime.toIso8601String(),
      'customer_summary': customerSummary.toJson(),
      'notification_required': notificationRequired,
      'orchestration_metadata': orchestrationMetadata.toJson(),
      'alternative_recommendation': alternativeRecommendation?.toJson(),
      
      // Backward compatibility keys
      'request_id': requestId,
      'session_id': sessionId,
      'agent_trace_id': agentTraceId,
      'orchestration_status': orchestrationStatus,
      'selected_provider': selectedProvider.toJson(),
      'pricing_data': pricingData,
      'notification_payload': notificationPayload.toJson(),
    };
  }
}

class NotificationPayload {
  final RecipientNotification user;
  final RecipientNotification provider;

  NotificationPayload({
    required this.user,
    required this.provider,
  });

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'provider': provider.toJson(),
    };
  }
}

class RecipientNotification {
  final String recipientId;
  final String channel;
  final String template;
  final String message;

  RecipientNotification({
    required this.recipientId,
    required this.channel,
    required this.template,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipient_id': recipientId,
      'channel': channel,
      'template': template,
      'message': message,
    };
  }
}
