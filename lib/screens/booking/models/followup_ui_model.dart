import 'package:cloud_firestore/cloud_firestore.dart';

class FollowUpUiModel {
  final String followupId;
  final String sessionId;
  final String bookingId;
  final String recipientId;
  final String followupType;
  final String message;
  final String status;
  final DateTime? createdAt;
  final DateTime? scheduledAt;

  FollowUpUiModel({
    required this.followupId,
    required this.sessionId,
    required this.bookingId,
    required this.recipientId,
    required this.followupType,
    required this.message,
    required this.status,
    this.createdAt,
    this.scheduledAt,
  });

  factory FollowUpUiModel.fromFirestore(Map<String, dynamic> json, String docId) {
    final id = json['followup_id'] as String? ?? docId;
    final sessId = json['session_id'] as String? ?? '';
    final bookId = json['booking_id'] as String? ?? '';
    final recId = json['recipient_id'] as String? ?? '';
    final type = json['followup_type'] as String? ?? '';
    final msg = json['message'] as String? ?? '';
    final stat = json['status'] as String? ?? 'pending';

    DateTime? createdTime;
    final rawCreated = json['created_at'];
    if (rawCreated != null) {
      if (rawCreated is Timestamp) {
        createdTime = rawCreated.toDate();
      } else if (rawCreated is String) {
        createdTime = DateTime.tryParse(rawCreated);
      }
    }

    DateTime? scheduledTime;
    final rawScheduled = json['scheduled_at'];
    if (rawScheduled != null) {
      if (rawScheduled is Timestamp) {
        scheduledTime = rawScheduled.toDate();
      } else if (rawScheduled is String) {
        scheduledTime = DateTime.tryParse(rawScheduled);
      }
    }

    return FollowUpUiModel(
      followupId: id,
      sessionId: sessId,
      bookingId: bookId,
      recipientId: recId,
      followupType: type,
      message: msg,
      status: stat,
      createdAt: createdTime,
      scheduledAt: scheduledTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followup_id': followupId,
      'session_id': sessionId,
      'booking_id': bookingId,
      'recipient_id': recipientId,
      'followup_type': followupType,
      'message': message,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'scheduled_at': scheduledAt?.toIso8601String(),
    };
  }

  FollowUpUiModel copyWith({
    String? status,
  }) {
    return FollowUpUiModel(
      followupId: followupId,
      sessionId: sessionId,
      bookingId: bookingId,
      recipientId: recipientId,
      followupType: followupType,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
      scheduledAt: scheduledAt,
    );
  }
}

class OrchestrationGroup {
  final String bookingId;
  final String sessionId;
  final Map<String, dynamic>? mainSessionDoc;
  final List<FollowUpUiModel> actions;

  OrchestrationGroup({
    required this.bookingId,
    required this.sessionId,
    this.mainSessionDoc,
    required this.actions,
  });
}

class OrchestrationStreamData {
  final List<OrchestrationGroup> groups;
  final bool hasData;

  OrchestrationStreamData({
    required this.groups,
    required this.hasData,
  });
}
