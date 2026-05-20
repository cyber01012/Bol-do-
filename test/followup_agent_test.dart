import 'package:flutter_test/flutter_test.dart';
import 'package:boldo_ai/agents/booking_agent/booking_model.dart' show SelectedProvider, CustomerSummary, OrchestrationMetadata;
import 'package:boldo_ai/agents/followup_agent/firestore_service.dart';
import 'package:boldo_ai/agents/followup_agent/followup_agent_service.dart';
import 'package:boldo_ai/agents/followup_agent/followup_model.dart';
import 'package:boldo_ai/agents/followup_agent/trace_logger.dart';

// In-memory Mock Firestore Service
class MockFirestoreService extends FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> database = {
    'agent_traces': {},
    'orchestration_sessions': {},
    'followups': {},
    'providers': {},
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
  group('FollowUp Agent Tests', () {
    late MockFirestoreService mockDb;
    late FollowUpAgentService agentService;

    setUp(() {
      mockDb = MockFirestoreService();
      agentService = FollowUpAgentService(firestoreService: mockDb);
    });

    test(
        '1. Confirmed Booking Success: schedules and asserts strict output JSON contract serialization',
        () async {
      final request = FollowUpRequest(
        bookingId: 'book_001',
        bookingStatus: 'confirmed',
        sessionId: 'sess_001',
        provider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        scheduledTime: DateTime.now().add(const Duration(hours: 3)),
        customerSummary: CustomerSummary(
          customerId: 'user_customer_999',
          name: 'Hafsa Khan',
          contactNumber: '+923001234567',
        ),
        orchestrationMetadata: OrchestrationMetadata(
          sessionId: 'sess_001',
          requestId: 'req_001',
          traceId: 'trace_book_001',
          orchestrationStatus: 'success',
          currentAgent: 'NotificationAgent',
          nextAgent: 'FollowUpAgent',
        ),
      );

      // Seed the orchestration session
      mockDb.database['orchestration_sessions']!['sess_001'] = {
        'session_id': 'sess_001',
        'completed_agents': {'PricingAgent': true, 'BookingAgent': true, 'NotificationAgent': true},
        'pipeline_status': 'completed_notification',
      };

      final response = await agentService.processRequest(request);

      // Verify response output isSuccess is true, but check the strict JSON contract
      expect(response.isSuccess, true);
      expect(response.actions.length, 3);
      
      final json = response.toJson();
      expect(json['status'], 'success');
      expect(json['followups_created'], 3);
      expect(json['session_id'], 'sess_001');
      expect(json['booking_id'], 'book_001');
      expect(json['agent'], 'FollowUpAgent');
      expect(json['timestamp'], isNotNull);

      // Verify strict schema: internal helper fields should not be serialized
      expect(json.containsKey('actions'), false);
      expect(json.containsKey('follow_up_record'), false);
      expect(json.containsKey('orchestration_status'), false);
      expect(json.containsKey('is_success'), false);

      // Verify separate follow-ups created in Firestore
      final reminderDoc = mockDb.database['followups']!['followup_reminder_sess_001'];
      expect(reminderDoc, isNotNull);
      expect(reminderDoc!['followup_type'], 'service_reminder');

      // Verify orchestration session updated exactly as requested
      final session = mockDb.database['orchestration_sessions']!['sess_001'];
      expect(session, isNotNull);
      expect(session!['completed_agents']['FollowUpAgent'], true);
      expect(session['pipeline_status'], 'completed_followup');
    });

    test(
        '2. Failed Booking: asserts strict output JSON contract serialization',
        () async {
      final request = FollowUpRequest(
        bookingId: 'book_002',
        bookingStatus: 'failed',
        sessionId: 'sess_002',
        provider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        scheduledTime: DateTime.now().add(const Duration(hours: 3)),
        customerSummary: CustomerSummary(
          customerId: 'user_customer_999',
          name: 'Hafsa Khan',
          contactNumber: '+923001234567',
        ),
        orchestrationMetadata: OrchestrationMetadata(
          sessionId: 'sess_002',
          requestId: 'req_002',
          traceId: 'trace_book_002',
          orchestrationStatus: 'failed',
          currentAgent: 'NotificationAgent',
          nextAgent: 'FollowUpAgent',
        ),
      );

      final response = await agentService.processRequest(request);

      final json = response.toJson();
      expect(json['status'], 'success');
      expect(json['followups_created'], 1);
      expect(json['session_id'], 'sess_002');
      expect(json['booking_id'], 'book_002');
      expect(json['agent'], 'FollowUpAgent');
      expect(json['timestamp'], isNotNull);

      // Verify persisted follow-up document
      final retryDoc = mockDb.database['followups']!['followup_retry_sess_002'];
      expect(retryDoc, isNotNull);
      expect(retryDoc!['followup_type'], 'retry_suggestion');
    });

    test(
        '3. Rescheduled Booking: asserts strict output JSON contract serialization',
        () async {
      final request = FollowUpRequest(
        bookingId: 'book_003',
        bookingStatus: 'rescheduled',
        sessionId: 'sess_003',
        provider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        scheduledTime: DateTime.now().add(const Duration(hours: 3)),
        customerSummary: CustomerSummary(
          customerId: 'user_customer_999',
          name: 'Hafsa Khan',
          contactNumber: '+923001234567',
        ),
        orchestrationMetadata: OrchestrationMetadata(
          sessionId: 'sess_003',
          requestId: 'req_003',
          traceId: 'trace_book_003',
          orchestrationStatus: 'success',
          currentAgent: 'NotificationAgent',
          nextAgent: 'FollowUpAgent',
        ),
      );

      final response = await agentService.processRequest(request);

      final json = response.toJson();
      expect(json['status'], 'success');
      expect(json['followups_created'], 1);
      expect(json['session_id'], 'sess_003');
      expect(json['booking_id'], 'book_003');
      expect(json['agent'], 'FollowUpAgent');

      // Verify persisted follow-up document
      final rescheduledDoc = mockDb.database['followups']!['followup_reminder_sess_003'];
      expect(rescheduledDoc, isNotNull);
      expect(rescheduledDoc!['followup_type'], 'updated_reminder');
    });

    test(
        '4. Idempotency: Repeating request returns identical response and skips duplicate writes',
        () async {
      final request = FollowUpRequest(
        bookingId: 'book_004',
        bookingStatus: 'confirmed',
        sessionId: 'sess_004',
        provider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        scheduledTime: DateTime.now().add(const Duration(hours: 3)),
        customerSummary: CustomerSummary(
          customerId: 'user_customer_999',
          name: 'Hafsa Khan',
          contactNumber: '+923001234567',
        ),
        orchestrationMetadata: OrchestrationMetadata(
          sessionId: 'sess_004',
          requestId: 'req_004',
          traceId: 'trace_book_004',
          orchestrationStatus: 'success',
          currentAgent: 'NotificationAgent',
          nextAgent: 'FollowUpAgent',
        ),
      );

      // Send first request
      final res1 = await agentService.processRequest(request);
      final json1 = res1.toJson();
      expect(json1['status'], 'success');
      expect(json1['followups_created'], 3);
      final countBefore = mockDb.database['followups']!.length;

      // Send identical second request
      final res2 = await agentService.processRequest(request);
      final json2 = res2.toJson();
      expect(json2['status'], 'success');
      expect(json2['followups_created'], 3);

      // Assure no extra document created in Firestore
      expect(mockDb.database['followups']!.length, countBefore);
    });

    test(
        '5. Robust Fallback: Handles Firestore outage safely and returns degraded status in contract',
        () async {
      final outageDb = OutageFirestoreService();
      final outageAgent = FollowUpAgentService(firestoreService: outageDb);

      final request = FollowUpRequest(
        bookingId: 'book_005',
        bookingStatus: 'confirmed',
        sessionId: 'sess_005',
        provider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        scheduledTime: DateTime.now().add(const Duration(hours: 3)),
        customerSummary: CustomerSummary(
          customerId: 'user_customer_999',
          name: 'Hafsa Khan',
          contactNumber: '+923001234567',
        ),
        orchestrationMetadata: OrchestrationMetadata(
          sessionId: 'sess_005',
          requestId: 'req_005',
          traceId: 'trace_book_005',
          orchestrationStatus: 'success',
          currentAgent: 'NotificationAgent',
          nextAgent: 'FollowUpAgent',
        ),
      );

      final response = await outageAgent.processRequest(request);

      // Verify safe failure fallback in JSON contract
      final json = response.toJson();
      expect(json['status'], 'failed');
      expect(json['followups_created'], 0);
      expect(json['session_id'], 'sess_005');
      expect(json['booking_id'], 'book_005');
      expect(json['agent'], 'FollowUpAgent');
    });
  });
}
