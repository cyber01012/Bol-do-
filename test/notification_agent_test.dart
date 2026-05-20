import 'package:flutter_test/flutter_test.dart';
import 'package:boldo_ai/agents/booking_agent/booking_model.dart';
import 'package:boldo_ai/agents/notification_agent/firestore_service.dart';
import 'package:boldo_ai/agents/notification_agent/notification_agent_service.dart';
import 'package:boldo_ai/agents/notification_agent/trace_logger.dart';

// In-memory Mock Firestore Service
class MockFirestoreService extends FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> database = {
    'agent_traces': {},
    'orchestration_sessions': {},
    'notifications': {},
  };

  @override
  Future<void> saveDocument(
    String collectionPath,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    database.putIfAbsent(collectionPath, () => {})[documentId] = data;
  }

  @override
  Future<Map<String, dynamic>?> getDocument(
    String collectionPath,
    String documentId,
  ) async {
    return database[collectionPath]?[documentId];
  }
}

// Exception throwing mock to test Outages
class OutageFirestoreService extends FirestoreService {
  @override
  Future<Map<String, dynamic>?> getDocument(
      String collectionPath, String documentId) async {
    throw Exception('Firestore Database Network Timeout Outage');
  }

  @override
  Future<void> saveDocument(String collectionPath, String documentId,
      Map<String, dynamic> data) async {
    throw Exception('Firestore Database Network Timeout Outage');
  }
}

void main() {
  group('Notification Agent Tests', () {
    late MockFirestoreService mockDb;
    late NotificationAgentService agentService;

    setUp(() {
      mockDb = MockFirestoreService();
      agentService = NotificationAgentService(firestoreService: mockDb);
    });

    test(
        '1. Confirmed Booking Success: saves notifications, trace, and updates orchestration session',
        () async {
      final bookingResponse = BookingResponse(
        bookingId: 'book_sess_001',
        bookingStatus: 'confirmed',
        provider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        scheduledTime: DateTime(2026, 5, 19, 14, 0),
        customerSummary: CustomerSummary(
          customerId: 'user_customer_123',
          name: 'Hafsa Khan',
          contactNumber: '+923001234567',
        ),
        notificationRequired: true,
        orchestrationMetadata: OrchestrationMetadata(
          sessionId: 'sess_001',
          requestId: 'req_001',
          traceId: 'trace_book_001',
          orchestrationStatus: 'success',
          currentAgent: 'BookingAgent',
          nextAgent: 'NotificationAgent',
        ),
        pricingData: {'total_price_pkr': 1450.0},
        notificationPayload: NotificationPayload(
          user: RecipientNotification(
            recipientId: 'user_customer_123',
            channel: 'sms',
            template: 'booking_confirmed',
            message: '',
          ),
          provider: RecipientNotification(
            recipientId: 'prov_ali',
            channel: 'sms',
            template: 'new_job_assigned',
            message: '',
          ),
        ),
      );

      // Seed the orchestration session
      mockDb.database['orchestration_sessions']!['sess_001'] = {
        'session_id': 'sess_001',
        'completed_agents': {'PricingAgent': true, 'BookingAgent': true},
        'pipeline_status': 'success',
      };

      final response = await agentService.processResponse(bookingResponse);

      // Verify response output
      expect(response.isSuccess, true);
      expect(response.status, 'success');
      expect(response.notificationsCreated, 2);
      expect(response.timestamp, isNotEmpty);
      expect(response.sessionId, 'sess_001');
      expect(response.bookingId, 'book_sess_001');

      // Verify Firestore persisted notifications
      final userNotif =
          mockDb.database['notifications']!['notif_user_sess_001'];
      expect(userNotif, isNotNull);
      expect(userNotif!['recipient_id'], 'user_customer_123');
      expect(
          userNotif['message'], 'Your booking is confirmed with Ali AC Repair');
      expect(userNotif['status'], 'sent');
      expect(userNotif['notification_type'], 'success notifications');

      final providerNotif =
          mockDb.database['notifications']!['notif_provider_sess_001'];
      expect(providerNotif, isNotNull);
      expect(providerNotif!['recipient_id'], 'prov_ali');
      expect(
          providerNotif['message'], 'New booking assigned for ac_technician');
      expect(providerNotif['status'], 'sent');
      expect(providerNotif['notification_type'], 'success notifications');

      // Verify orchestration session updated
      final session = mockDb.database['orchestration_sessions']!['sess_001'];
      expect(session, isNotNull);
      expect(session!['completed_agents']['NotificationAgent'], true);
      expect(session['completed_agents']['PricingAgent'], true);
      expect(session['completed_agents']['BookingAgent'], true);
      expect(session['pipeline_status'], 'completed_notification');

      // Verify trace logged
      expect(mockDb.database['agent_traces']!.isNotEmpty, true);
    });

    test(
        '2. Failed Booking: structures and persists failed notifications correctly',
        () async {
      final bookingResponse = BookingResponse(
        bookingId: 'book_sess_002',
        bookingStatus: 'failed',
        provider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        scheduledTime: DateTime(2026, 5, 19, 14, 0),
        customerSummary: CustomerSummary(
          customerId: 'user_customer_123',
          name: 'Hafsa Khan',
          contactNumber: '+923001234567',
        ),
        notificationRequired: true,
        orchestrationMetadata: OrchestrationMetadata(
          sessionId: 'sess_002',
          requestId: 'req_002',
          traceId: 'trace_book_002',
          orchestrationStatus: 'failed',
          currentAgent: 'BookingAgent',
          nextAgent: 'NotificationAgent',
        ),
        pricingData: {'total_price_pkr': 1450.0},
        notificationPayload: NotificationPayload(
          user: RecipientNotification(
            recipientId: 'user_customer_123',
            channel: 'sms',
            template: 'booking_failed',
            message: 'Booking failed: provider_unavailable',
          ),
          provider: RecipientNotification(
            recipientId: 'prov_ali',
            channel: 'sms',
            template: 'booking_failed',
            message: 'Booking failed: provider_unavailable',
          ),
        ),
      );

      final response = await agentService.processResponse(bookingResponse);

      expect(response.isSuccess, true);
      expect(response.status, 'success');
      expect(response.notificationsCreated, 2);
      expect(response.timestamp, isNotEmpty);
      expect(response.orchestrationStatus, 'failed');

      final userNotif =
          mockDb.database['notifications']!['notif_user_sess_002'];
      expect(userNotif, isNotNull);
      expect(userNotif!['message'], 'Booking failed: provider_unavailable');
      expect(userNotif['status'], 'sent');
      expect(userNotif['notification_type'], 'failure notifications');

      final providerNotif =
          mockDb.database['notifications']!['notif_provider_sess_002'];
      expect(providerNotif, isNotNull);
      expect(providerNotif!['message'],
          'Booking attempt received but not assigned');
      expect(providerNotif['status'], 'sent');
      expect(providerNotif['notification_type'], 'failure notifications');
    });

    test('3. Rescheduled Booking: generates and persists rescheduled templates',
        () async {
      final bookingResponse = BookingResponse(
        bookingId: 'book_sess_003',
        bookingStatus: 'rescheduled',
        provider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        scheduledTime: DateTime(2026, 5, 19, 16, 0), // Rescheduled time
        customerSummary: CustomerSummary(
          customerId: 'user_customer_123',
          name: 'Hafsa Khan',
          contactNumber: '+923001234567',
        ),
        notificationRequired: true,
        orchestrationMetadata: OrchestrationMetadata(
          sessionId: 'sess_003',
          requestId: 'req_003',
          traceId: 'trace_book_003',
          orchestrationStatus: 'success',
          currentAgent: 'BookingAgent',
          nextAgent: 'NotificationAgent',
        ),
        pricingData: {'total_price_pkr': 1450.0},
        notificationPayload: NotificationPayload(
          user: RecipientNotification(
            recipientId: 'user_customer_123',
            channel: 'sms',
            template: 'booking_rescheduled',
            message: '',
          ),
          provider: RecipientNotification(
            recipientId: 'prov_ali',
            channel: 'sms',
            template: 'booking_rescheduled',
            message: '',
          ),
        ),
      );

      final response = await agentService.processResponse(bookingResponse);

      expect(response.isSuccess, true);
      expect(response.status, 'success');
      expect(response.notificationsCreated, 2);
      expect(response.timestamp, isNotEmpty);

      final userNotif =
          mockDb.database['notifications']!['notif_user_sess_003'];
      expect(userNotif, isNotNull);
      expect(userNotif!['message'], 'Your booking has been rescheduled');
      expect(userNotif['status'], 'sent');
      expect(userNotif['notification_type'], 'update notifications');

      final providerNotif =
          mockDb.database['notifications']!['notif_provider_sess_003'];
      expect(providerNotif, isNotNull);
      expect(providerNotif!['message'], 'Booking time updated');
      expect(providerNotif['status'], 'sent');
      expect(providerNotif['notification_type'], 'update notifications');
    });

    test(
        '4. Idempotency: Repeating requests returns identical notifications and skips regeneration',
        () async {
      final bookingResponse = BookingResponse(
        bookingId: 'book_sess_004',
        bookingStatus: 'confirmed',
        provider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        scheduledTime: DateTime(2026, 5, 19, 14, 0),
        customerSummary: CustomerSummary(
          customerId: 'user_customer_123',
          name: 'Hafsa Khan',
          contactNumber: '+923001234567',
        ),
        notificationRequired: true,
        orchestrationMetadata: OrchestrationMetadata(
          sessionId: 'sess_004',
          requestId: 'req_004',
          traceId: 'trace_book_004',
          orchestrationStatus: 'success',
          currentAgent: 'BookingAgent',
          nextAgent: 'NotificationAgent',
        ),
        pricingData: {'total_price_pkr': 1450.0},
        notificationPayload: NotificationPayload(
          user: RecipientNotification(
            recipientId: 'user_customer_123',
            channel: 'sms',
            template: 'booking_confirmed',
            message: '',
          ),
          provider: RecipientNotification(
            recipientId: 'prov_ali',
            channel: 'sms',
            template: 'new_job_assigned',
            message: '',
          ),
        ),
      );

      // Process first time
      final response1 = await agentService.processResponse(bookingResponse);
      expect(response1.isSuccess, true);
      expect(response1.status, 'success');
      expect(response1.notificationsCreated, 2);
      expect(response1.timestamp, isNotEmpty);

      final notifCountBefore = mockDb.database['notifications']!.length;

      // Process second time (repeat)
      final response2 = await agentService.processResponse(bookingResponse);
      expect(response2.isSuccess, true);
      expect(response2.status, 'success');
      expect(response2.notificationsCreated, 2);
      expect(response2.timestamp, isNotEmpty);

      // Verify no new documents added, returns same payload
      expect(mockDb.database['notifications']!.length, notifCountBefore);
      expect(response2.notificationPayload['user']['message'],
          'Your booking is confirmed with Ali AC Repair');
    });

    test(
        '5. Robust Fallback: Handles Firestore outage safely and returns degraded status',
        () async {
      final outageDb = OutageFirestoreService();
      final outageAgent = NotificationAgentService(firestoreService: outageDb);

      final bookingResponse = BookingResponse(
        bookingId: 'book_sess_005',
        bookingStatus: 'confirmed',
        provider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        scheduledTime: DateTime(2026, 5, 19, 14, 0),
        customerSummary: CustomerSummary(
          customerId: 'user_customer_123',
          name: 'Hafsa Khan',
          contactNumber: '+923001234567',
        ),
        notificationRequired: true,
        orchestrationMetadata: OrchestrationMetadata(
          sessionId: 'sess_005',
          requestId: 'req_005',
          traceId: 'trace_book_005',
          orchestrationStatus: 'success',
          currentAgent: 'BookingAgent',
          nextAgent: 'NotificationAgent',
        ),
        pricingData: {'total_price_pkr': 1450.0},
        notificationPayload: NotificationPayload(
          user: RecipientNotification(
            recipientId: 'user_customer_123',
            channel: 'sms',
            template: 'booking_confirmed',
            message: '',
          ),
          provider: RecipientNotification(
            recipientId: 'prov_ali',
            channel: 'sms',
            template: 'new_job_assigned',
            message: '',
          ),
        ),
      );

      final response = await outageAgent.processResponse(bookingResponse);

      expect(response.isSuccess, false);
      expect(response.orchestrationStatus, 'failed_degraded');
      expect(response.notificationPayload['user']['template'],
          'notification_degraded');
    });
  });
}
