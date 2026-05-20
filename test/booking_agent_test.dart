import 'package:flutter_test/flutter_test.dart';
import 'package:boldo_ai/agents/booking_agent/booking_model.dart';
import 'package:boldo_ai/agents/booking_agent/booking_agent_service.dart';
import 'package:boldo_ai/agents/booking_agent/firestore_service.dart';
import 'package:boldo_ai/agents/booking_agent/trace_logger.dart';
import 'package:boldo_ai/agents/booking_agent/idempotency_manager.dart';

// In-memory Mock Firestore Service
class MockFirestoreService extends FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> database = {
    'providers': {},
    'bookings': {},
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

  @override
  Future<List<Map<String, dynamic>>> queryOverlapBookings({
    required String providerId,
    required DateTime requestedTime,
    required Duration bufferWindow,
  }) async {
    final startTime = requestedTime.subtract(bufferWindow);
    final endTime = requestedTime.add(bufferWindow);

    final results = <Map<String, dynamic>>[];
    final bookingsCollection = database['bookings'] ?? {};
    
    for (final booking in bookingsCollection.values) {
      if (booking['provider_id'] == providerId) {
        final status = booking['booking_status'] as String?;
        if (status == 'confirmed' || status == 'provider_assigned' || status == 'in_progress') {
          final requestedTimeStr = booking['requested_time'] as String?;
          if (requestedTimeStr != null) {
            final bookingTime = DateTime.parse(requestedTimeStr);
            if (bookingTime.isAfter(startTime) && bookingTime.isBefore(endTime)) {
              results.add(booking);
            }
          }
        }
      }
    }
    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> queryBackupProviders(String serviceType) async {
    final results = <Map<String, dynamic>>[];
    final providersCollection = database['providers'] ?? {};
    for (final provider in providersCollection.values) {
      if (provider['service_type'] == serviceType && provider['is_available'] == true) {
        results.add(provider);
      }
    }
    return results;
  }
}

// Exception throwing mock to test Outages
class OutageFirestoreService extends FirestoreService {
  @override
  Future<Map<String, dynamic>?> getDocument(String collectionPath, String documentId) async {
    throw Exception('Firestore Database Network Timeout Outage');
  }

  @override
  Future<void> saveDocument(String collectionPath, String documentId, Map<String, dynamic> data) async {
    throw Exception('Firestore Database Network Timeout Outage');
  }
}

void main() {
  group('Booking Agent Tests', () {
    late MockFirestoreService mockDb;
    late BookingAgentService agentService;

    setUp(() {
      mockDb = MockFirestoreService();
      
      // Initialize mock providers
      mockDb.database['providers']!['prov_ali'] = {
        'provider_id': 'prov_ali',
        'name': 'Ali AC Repair',
        'service_type': 'ac_technician',
        'is_available': true,
        'rating': 4.8,
      };

      mockDb.database['providers']!['prov_babar'] = {
        'provider_id': 'prov_babar',
        'name': 'Babar Electrician',
        'service_type': 'ac_technician',
        'is_available': true,
        'rating': 4.6,
      };

      // Seed valid sessions for standard success path tests
      mockDb.database['orchestration_sessions']!['sess_success'] = {
        'session_id': 'sess_success',
        'completed_agents': {'PricingAgent': true},
        'pipeline_status': 'success',
      };

      mockDb.database['orchestration_sessions']!['sess_conflict'] = {
        'session_id': 'sess_conflict',
        'completed_agents': {'PricingAgent': true},
        'pipeline_status': 'success',
      };

      mockDb.database['orchestration_sessions']!['sess_offline'] = {
        'session_id': 'sess_offline',
        'completed_agents': {'PricingAgent': true},
        'pipeline_status': 'success',
      };

      mockDb.database['orchestration_sessions']!['sess_invalid_price'] = {
        'session_id': 'sess_invalid_price',
        'completed_agents': {'PricingAgent': true},
        'pipeline_status': 'success',
      };

      agentService = BookingAgentService(
        firestoreService: mockDb,
      );
    });

    test('1. Success Booking Scenario 1: Active provider accepts slot & notifications stage', () async {
      final request = BookingRequest(
        requestId: 'req_success',
        sessionId: 'sess_success',
        orchestrationStatus: 'success',
        selectedProvider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        pricingData: PricingData(
          totalPricePkr: 1450.0,
          confidenceScore: 0.95,
          breakdown: {
            'base_price': 1000.0,
            'distance_cost': 312.5,
            'urgency_multiplier': 1.3,
            'time_multiplier': 1.2,
          },
        ),
        userRequest: UserRequest(
          serviceType: 'ac_technician',
          urgency: 'same_day',
          requestedTime: DateTime(2026, 5, 19, 14, 0), // 2 PM (daytime)
        ),
        bookingMetadata: BookingMetadata(paymentMethod: 'cash_on_delivery'),
      );

      final response = await agentService.processRequest(request);

      // Allow async fire-and-forget logging to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify Output Contract
      expect(response.orchestrationStatus, 'success');
      expect(response.bookingStatus, 'confirmed');
      expect(response.bookingId, 'book_sess_success');
      expect(response.selectedProvider.providerId, 'prov_ali');
      expect(response.pricingData['total_price_pkr'], 1450.0);

      // Verify Notification Messages
      expect(response.notificationPayload.user.message.contains('CONFIRMED'), true);
      expect(response.notificationPayload.user.message.contains('1450 PKR'), true);
      expect(response.notificationPayload.provider.message.contains('1450 PKR'), true);

      // Verify Firestore state changes
      final savedBooking = mockDb.database['bookings']!['book_sess_success'];
      expect(savedBooking, isNotNull);
      expect(savedBooking!['booking_status'], 'confirmed');
      expect(savedBooking['provider_id'], 'prov_ali');

      // Verify traces and notifications saved in Mock DB
      expect(mockDb.database['notifications']!['notif_user_sess_success'], isNotNull);
      expect(mockDb.database['notifications']!['notif_provider_sess_success'], isNotNull);
      expect(mockDb.database['orchestration_sessions']!['sess_success'], isNotNull);
    });

    test('2. Success Booking Scenario 2 (Idempotency): Repeat requests return same booking without duplicate database entries', () async {
      // 1. Send first request
      final request = BookingRequest(
        requestId: 'req_success',
        sessionId: 'sess_success',
        orchestrationStatus: 'success',
        selectedProvider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        pricingData: PricingData(
          totalPricePkr: 1450.0,
          confidenceScore: 0.95,
          breakdown: {},
        ),
        userRequest: UserRequest(
          serviceType: 'ac_technician',
          urgency: 'same_day',
          requestedTime: DateTime(2026, 5, 19, 14, 0),
        ),
      );

      final response1 = await agentService.processRequest(request);
      expect(response1.bookingId, 'book_sess_success');
      expect(response1.bookingStatus, 'confirmed');

      final countBefore = mockDb.database['bookings']!.length;

      // 2. Submit second identical request
      final response2 = await agentService.processRequest(request);

      // 3. Verify same response is returned and no duplicate entry is written
      expect(response2.bookingId, 'book_sess_success');
      expect(response2.bookingStatus, 'confirmed');
      expect(mockDb.database['bookings']!.length, countBefore);
    });

    test('3. Success Booking Scenario 3 (Decayed Pricing): Clamps price to 500 PKR and completes booking successfully', () async {
      final request = BookingRequest(
        requestId: 'req_invalid_price',
        sessionId: 'sess_invalid_price',
        orchestrationStatus: 'success',
        selectedProvider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        pricingData: PricingData(
          totalPricePkr: -150.0, // Subzero price!
          confidenceScore: 0.95,
          breakdown: {},
        ),
        userRequest: UserRequest(
          serviceType: 'ac_technician',
          urgency: 'same_day',
          requestedTime: DateTime(2026, 5, 19, 14, 0),
        ),
      );

      final response = await agentService.processRequest(request);

      // Price gets clamped to 500 PKR, orchestration degraded, but booking succeeded
      expect(response.pricingData['total_price_pkr'], 500.0);
      expect(response.orchestrationStatus, 'failed_degraded');
      expect(response.bookingStatus, 'confirmed');
    });

    test('4. Double Booking Prevention: Rejects slot and provides alternative recommendation when provider is busy within +/- 2-hour window', () async {
      // Seed an existing confirmed booking for Ali at 2 PM
      mockDb.database['bookings']!['book_existing'] = {
        'booking_id': 'book_existing',
        'session_id': 'sess_existing',
        'provider_id': 'prov_ali',
        'requested_time': DateTime(2026, 5, 19, 14, 0).toIso8601String(), // 2 PM
        'booking_status': 'confirmed',
      };

      // Request a booking at 3 PM for Ali (within the 2-hour window -> conflict!)
      final request = BookingRequest(
        requestId: 'req_conflict',
        sessionId: 'sess_conflict',
        orchestrationStatus: 'success',
        selectedProvider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        pricingData: PricingData(
          totalPricePkr: 1450.0,
          confidenceScore: 0.95,
          breakdown: {},
        ),
        userRequest: UserRequest(
          serviceType: 'ac_technician',
          urgency: 'same_day',
          requestedTime: DateTime(2026, 5, 19, 15, 0),
        ),
      );

      final response = await agentService.processRequest(request);

      // Assert Double Booking Blocked
      expect(response.orchestrationStatus, 'failed');
      expect(response.bookingStatus, 'failed');
      
      // Assert alternative recommendation generated (Babar)
      expect(response.alternativeRecommendation, isNotNull);
      expect(response.alternativeRecommendation!.providerId, 'prov_babar');
      expect(response.alternativeRecommendation!.name, 'Babar Electrician');
    });

    test('5. Failure Scenario 1 (Provider Offline): Returns failed status and attaches alternative backup recommendation', () async {
      mockDb.database['providers']!['prov_offline'] = {
        'provider_id': 'prov_offline',
        'name': 'Offline Aircon',
        'service_type': 'ac_technician',
        'is_available': false, // Inactive/Offline!
        'rating': 4.9,
      };

      final request = BookingRequest(
        requestId: 'req_offline',
        sessionId: 'sess_offline',
        orchestrationStatus: 'success',
        selectedProvider: SelectedProvider(
          providerId: 'prov_offline',
          name: 'Offline Aircon',
          serviceType: 'ac_technician',
        ),
        pricingData: PricingData(
          totalPricePkr: 1450.0,
          confidenceScore: 0.95,
          breakdown: {},
        ),
        userRequest: UserRequest(
          serviceType: 'ac_technician',
          urgency: 'same_day',
          requestedTime: DateTime(2026, 5, 19, 14, 0),
        ),
      );

      final response = await agentService.processRequest(request);

      expect(response.orchestrationStatus, 'failed');
      expect(response.bookingStatus, 'failed');
      expect(response.alternativeRecommendation!.providerId, 'prov_ali'); // prov_ali has rating 4.8, which is higher than prov_babar (4.6)
    });

    test('6. Failure Scenario 2 (Database Outage): Handles firestore read/write outages gracefully without crashing the pipeline', () async {
      final outageDb = OutageFirestoreService();
      final outageService = BookingAgentService(
        firestoreService: outageDb,
      );

      final request = BookingRequest(
        requestId: 'req_outage',
        sessionId: 'sess_outage',
        orchestrationStatus: 'success',
        selectedProvider: SelectedProvider(
          providerId: 'prov_ali',
          name: 'Ali AC Repair',
          serviceType: 'ac_technician',
        ),
        pricingData: PricingData(
          totalPricePkr: 1450.0,
          confidenceScore: 0.95,
          breakdown: {},
        ),
        userRequest: UserRequest(
          serviceType: 'ac_technician',
          urgency: 'same_day',
          requestedTime: DateTime(2026, 5, 19, 14, 0),
        ),
      );

      final response = await outageService.processRequest(request);

      // Gracefully completes returning in-memory failure details
      expect(response.orchestrationStatus, 'failed_degraded');
      expect(response.bookingStatus, 'failed');
      expect(response.notificationPayload.user.message.contains('connection lag'), true);
    });
  });
}
