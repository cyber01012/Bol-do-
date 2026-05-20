import 'package:boldo_ai/agents/booking_agent/booking_model.dart';

class FollowUpRequest {
  final String bookingId;
  final String bookingStatus;
  final String sessionId;
  final SelectedProvider provider;
  final CustomerSummary customerSummary;
  final OrchestrationMetadata orchestrationMetadata;
  final DateTime scheduledTime;

  // Optional feedback parameters for the completed flow
  final double? rating;
  final String? feedback;

  FollowUpRequest({
    required this.bookingId,
    required this.bookingStatus,
    required this.sessionId,
    required this.provider,
    required this.customerSummary,
    required this.orchestrationMetadata,
    required this.scheduledTime,
    this.rating,
    this.feedback,
  });

  factory FollowUpRequest.fromJson(Map<String, dynamic> json) {
    return FollowUpRequest(
      bookingId: json['booking_id'] as String,
      bookingStatus: json['booking_status'] as String,
      sessionId: json['session_id'] as String,
      provider: SelectedProvider.fromJson(json['provider'] as Map<String, dynamic>),
      customerSummary: CustomerSummary.fromJson(json['customer_summary'] as Map<String, dynamic>),
      orchestrationMetadata: OrchestrationMetadata.fromJson(json['orchestration_metadata'] as Map<String, dynamic>),
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      feedback: json['feedback'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'booking_status': bookingStatus,
      'session_id': sessionId,
      'provider': provider.toJson(),
      'customer_summary': customerSummary.toJson(),
      'orchestration_metadata': orchestrationMetadata.toJson(),
      'scheduled_time': scheduledTime.toIso8601String(),
      if (rating != null) 'rating': rating,
      if (feedback != null) 'feedback': feedback,
    };
  }
}

class FollowUpAction {
  final String type; // 'reminder', 'rating_request', 're_engagement_flow', 'dispute_suggestion'
  final String scheduledTime;
  final Map<String, dynamic> payload;

  FollowUpAction({
    required this.type,
    required this.scheduledTime,
    required this.payload,
  });

  factory FollowUpAction.fromJson(Map<String, dynamic> json) {
    return FollowUpAction(
      type: json['type'] as String,
      scheduledTime: json['scheduled_time'] as String,
      payload: json['payload'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'scheduled_time': scheduledTime,
      'payload': payload,
    };
  }
}

class FollowUpResponse {
  final String status;
  final int followupsCreated;
  final String sessionId;
  final String bookingId;
  final String agent;
  final String timestamp;

  // Keep these additional internal fields for compatibility with service and tests
  final String orchestrationStatus;
  final bool isSuccess;
  final String? error;
  final List<FollowUpAction> actions;
  final Map<String, dynamic> followUpRecord;

  FollowUpResponse({
    required this.status,
    required this.followupsCreated,
    required this.sessionId,
    required this.bookingId,
    required this.agent,
    required this.timestamp,
    required this.orchestrationStatus,
    required this.isSuccess,
    this.error,
    required this.actions,
    required this.followUpRecord,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'followups_created': followupsCreated,
      'session_id': sessionId,
      'booking_id': bookingId,
      'agent': agent,
      'timestamp': timestamp,
    };
  }
}
