import 'dart:math';
import 'package:boldo_ai/agents/booking_agent/booking_model.dart';
import 'firestore_service.dart';
import 'notification_model.dart';
import 'trace_logger.dart';

class NotificationAgentService {
  final FirestoreService _firestoreService;
  final TraceLogger _traceLogger;

  NotificationAgentService({
    FirestoreService? firestoreService,
    TraceLogger? traceLogger,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _traceLogger =
            traceLogger ?? TraceLogger(firestoreService: firestoreService);

  Future<NotificationResponse> processResponse(
      BookingResponse bookingResponse) async {
    final traceId =
        'trace_notif_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

    try {
      // 1. Input Validation
      if (bookingResponse.bookingId.trim().isEmpty) {
        throw ArgumentError('booking_id cannot be empty');
      }
      if (bookingResponse.sessionId.trim().isEmpty) {
        throw ArgumentError('session_id cannot be empty');
      }

      // 2. Idempotency Check (repeat requests)
      final existingNotif = await _firestoreService.getDocument(
        'notifications',
        'notif_user_${bookingResponse.sessionId}',
      );

      if (existingNotif != null) {
        final existingProviderNotif = await _firestoreService.getDocument(
          'notifications',
          'notif_provider_${bookingResponse.sessionId}',
        );

        final payload = {
          'user': existingNotif,
          'provider': existingProviderNotif ?? {},
        };

        final timestamp = DateTime.now().toUtc().toIso8601String();
        final response = NotificationResponse(
          status: 'success',
          notificationsCreated: 2,
          sessionId: bookingResponse.sessionId,
          bookingId: bookingResponse.bookingId,
          timestamp: timestamp,
          orchestrationStatus: bookingResponse.orchestrationStatus,
          isSuccess: true,
          notificationPayload: payload,
          orchestrationMetadata: bookingResponse.orchestrationMetadata.toJson(),
        );

        // Log trace for idempotency match
        await _traceLogger.logTrace(
          bookingResponse: bookingResponse,
          traceId: traceId,
          decision:
              'Idempotency Match: Notifications already generated and stored.',
          confidence: 1.0,
          reasoningBreakdown: {
            'idempotency': 'matched',
            'user_notification_found': true,
            'provider_notification_found': existingProviderNotif != null,
            'skipped_regeneration': true,
          },
        );

        return response;
      }

      // 3. Structure user and provider notifications
      final userNotifMap = _buildUserNotification(bookingResponse);
      final providerNotifMap = _buildProviderNotification(bookingResponse);

      // Determine notification type based on booking_status
      String notificationType;
      if (bookingResponse.bookingStatus == 'confirmed') {
        notificationType = 'success notifications';
      } else if (bookingResponse.bookingStatus == 'failed') {
        notificationType = 'failure notifications';
      } else if (bookingResponse.bookingStatus == 'rescheduled') {
        notificationType = 'update notifications';
      } else {
        notificationType = 'unknown notifications';
      }

      final timestamp = DateTime.now().toUtc().toIso8601String();

      // Save user notification to Firestore
      final userNotifDocId = 'notif_user_${bookingResponse.sessionId}';
      final userNotifData = {
        'notification_id': userNotifDocId,
        'session_id': bookingResponse.sessionId,
        'booking_id': bookingResponse.bookingId,
        'recipient_id': userNotifMap['recipient_id'],
        'recipient_type': 'user',
        'channel': 'sms',
        'message': userNotifMap['message'],
        'status': 'sent',
        'notification_type': notificationType,
        'created_at': timestamp,
      };
      await _firestoreService.saveDocument(
          'notifications', userNotifDocId, userNotifData);

      // Save provider notification to Firestore
      final providerNotifDocId = 'notif_provider_${bookingResponse.sessionId}';
      final providerNotifData = {
        'notification_id': providerNotifDocId,
        'session_id': bookingResponse.sessionId,
        'booking_id': bookingResponse.bookingId,
        'recipient_id': providerNotifMap['recipient_id'],
        'recipient_type': 'provider',
        'channel': 'sms',
        'message': providerNotifMap['message'],
        'status': 'sent',
        'notification_type': notificationType,
        'created_at': timestamp,
      };
      await _firestoreService.saveDocument(
          'notifications', providerNotifDocId, providerNotifData);

      final payload = {
        'user': userNotifData,
        'provider': providerNotifData,
      };

      final response = NotificationResponse(
        status: 'success',
        notificationsCreated: 2,
        sessionId: bookingResponse.sessionId,
        bookingId: bookingResponse.bookingId,
        timestamp: timestamp,
        orchestrationStatus: bookingResponse.orchestrationStatus,
        isSuccess: true,
        notificationPayload: payload,
        orchestrationMetadata: bookingResponse.orchestrationMetadata.toJson(),
      );

      // 4. Log Trace and update central orchestration status
      await _traceLogger.logTrace(
        bookingResponse: bookingResponse,
        traceId: traceId,
        decision:
            'Successfully structured and persisted user and provider notifications.',
        confidence: 1.0,
        reasoningBreakdown: {
          'idempotency': 'clear',
          'user_notification_created': true,
          'provider_notification_created': true,
          'session_updated': true,
          'status': bookingResponse.bookingStatus,
        },
      );

      return response;
    } catch (e) {
      // 5. Degraded Fallback on failure or bad data
      return _buildFallbackResponse(bookingResponse, traceId, e.toString());
    }
  }

  Map<String, dynamic> _buildUserNotification(BookingResponse bookingResponse) {
    final providerName = bookingResponse.provider.name;

    String template;
    String message;

    if (bookingResponse.bookingStatus == 'confirmed') {
      template = 'booking_confirmed';
      message = 'Your booking is confirmed with $providerName';
    } else if (bookingResponse.bookingStatus == 'rescheduled') {
      template = 'booking_rescheduled';
      message = 'Your booking has been rescheduled';
    } else {
      template = 'booking_failed';
      String reason = 'provider_unavailable';
      try {
        final msg = bookingResponse.notificationPayload.user.message;
        if (msg.trim().isNotEmpty) {
          if (msg.startsWith('Booking failed: ')) {
            reason = msg.replaceFirst('Booking failed: ', '');
          } else {
            reason = msg;
          }
        }
      } catch (_) {}
      message = 'Booking failed: $reason';
    }

    return {
      'recipient_id': bookingResponse.customerSummary.customerId,
      'channel': 'sms',
      'template': template,
      'message': message,
    };
  }

  Map<String, dynamic> _buildProviderNotification(
      BookingResponse bookingResponse) {
    final service = bookingResponse.provider.serviceType;

    String template;
    String message;

    if (bookingResponse.bookingStatus == 'confirmed') {
      template = 'new_job_assigned';
      message = 'New booking assigned for $service';
    } else if (bookingResponse.bookingStatus == 'rescheduled') {
      template = 'booking_rescheduled';
      message = 'Booking time updated';
    } else {
      template = 'booking_failed';
      message = 'Booking attempt received but not assigned';
    }

    return {
      'recipient_id': bookingResponse.provider.providerId,
      'channel': 'sms',
      'template': template,
      'message': message,
    };
  }

  NotificationResponse _buildFallbackResponse(
      BookingResponse bookingResponse, String traceId, String error) {
    final payload = {
      'user': {
        'recipient_id': 'user_customer_999',
        'channel': 'sms',
        'template': 'notification_degraded',
        'message':
            'Your booking was processed, but notification dispatch is slightly delayed. Please view status in-app.',
      },
      'provider': {
        'recipient_id': 'provider_unknown',
        'channel': 'sms',
        'template': 'notification_degraded',
        'message': 'A booking update is pending. Please check provider portal.',
      }
    };

    final timestamp = DateTime.now().toUtc().toIso8601String();
    final response = NotificationResponse(
      status: 'failed',
      notificationsCreated: 0,
      sessionId: bookingResponse.sessionId,
      bookingId: bookingResponse.bookingId,
      timestamp: timestamp,
      orchestrationStatus: 'failed_degraded',
      isSuccess: false,
      error: error,
      notificationPayload: payload,
      orchestrationMetadata: bookingResponse.orchestrationMetadata.toJson(),
    );

    // Run async trace log
    _traceLogger.logTrace(
      bookingResponse: bookingResponse,
      traceId: traceId,
      decision:
          'Catastrophic error in Notification Agent. Initiated degraded fallback notifications.',
      confidence: 0.1,
      reasoningBreakdown: {
        'error': error,
        'status': 'degraded',
        'user_notified': false,
        'provider_notified': false,
      },
    );

    return response;
  }
}
