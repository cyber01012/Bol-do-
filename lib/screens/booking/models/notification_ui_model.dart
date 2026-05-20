import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationUiModel {
  final String notificationId;
  final String sessionId;
  final String bookingId;
  final String recipientId;
  final String recipientType;
  final String channel;
  final String message;
  final String status;
  final String notificationType;
  final DateTime? createdAt;
  final String sourceCollection;

  NotificationUiModel({
    required this.notificationId,
    required this.sessionId,
    required this.bookingId,
    required this.recipientId,
    required this.recipientType,
    required this.channel,
    required this.message,
    required this.status,
    required this.notificationType,
    required this.createdAt,
    required this.sourceCollection,
  });

  factory NotificationUiModel.fromFirestore(Map<String, dynamic> json, String docId, String sourceCollection) {
    final notifId = json['notification_id'] as String? ?? json['followup_id'] as String? ?? docId;
    final sessId = json['session_id'] as String? ?? '';
    final bookId = json['booking_id'] as String? ?? '';
    final recId = json['recipient_id'] as String? ?? '';

    String recType = json['recipient_type'] as String? ?? '';
    if (sourceCollection == 'followups') {
      recType = 'followup';
    }

    final chan = json['channel'] as String? ?? 'sms';
    final msg = json['message'] as String? ?? '';
    final stat = json['status'] as String? ?? 'sent';

    String notifType = json['notification_type'] as String? ?? '';
    if (sourceCollection == 'followups') {
      notifType = 'followup';
    }

    DateTime? createdTime;
    final rawCreatedAt = json['created_at'];
    if (rawCreatedAt != null) {
      if (rawCreatedAt is Timestamp) {
        createdTime = rawCreatedAt.toDate();
      } else if (rawCreatedAt is String) {
        createdTime = DateTime.tryParse(rawCreatedAt);
      }
    }

    return NotificationUiModel(
      notificationId: notifId,
      sessionId: sessId,
      bookingId: bookId,
      recipientId: recId,
      recipientType: recType.toLowerCase(),
      channel: chan.toLowerCase(),
      message: msg,
      status: stat.toLowerCase(),
      notificationType: notifType.toLowerCase(),
      createdAt: createdTime,
      sourceCollection: sourceCollection,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'session_id': sessionId,
      'booking_id': bookingId,
      'recipient_id': recipientId,
      'recipient_type': recipientType,
      'channel': channel,
      'message': message,
      'status': status,
      'notification_type': notificationType,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  NotificationUiModel copyWith({String? status}) {
    return NotificationUiModel(
      notificationId: notificationId,
      sessionId: sessionId,
      bookingId: bookingId,
      recipientId: recipientId,
      recipientType: recipientType,
      channel: channel,
      message: message,
      status: status ?? this.status,
      notificationType: notificationType,
      createdAt: createdAt,
      sourceCollection: sourceCollection,
    );
  }
}
