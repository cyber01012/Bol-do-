class NotificationResponse {
  final String status;
  final int notificationsCreated;
  final String sessionId;
  final String bookingId;
  final String timestamp;
  final String orchestrationStatus;
  final bool isSuccess;
  final String? error;
  final Map<String, dynamic> notificationPayload;
  final Map<String, dynamic> orchestrationMetadata;

  NotificationResponse({
    required this.status,
    required this.notificationsCreated,
    required this.sessionId,
    required this.bookingId,
    required this.timestamp,
    required this.orchestrationStatus,
    required this.isSuccess,
    this.error,
    required this.notificationPayload,
    required this.orchestrationMetadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'notifications_created': notificationsCreated,
      'session_id': sessionId,
      'booking_id': bookingId,
      'timestamp': timestamp,
      'orchestration_status': orchestrationStatus,
      'is_success': isSuccess,
      'error': error,
      'notification_payload': notificationPayload,
      'orchestration_metadata': orchestrationMetadata,
    };
  }
}
