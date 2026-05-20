import 'package:flutter_test/flutter_test.dart';
import 'package:boldo_ai/agents/pricing_agent/pricing_model.dart';
import 'package:boldo_ai/agents/pricing_agent/pricing_calculator.dart';
import 'package:boldo_ai/agents/pricing_agent/pricing_agent_service.dart';
import 'package:boldo_ai/agents/pricing_agent/trace_logger.dart';

// Mock TraceLogger to prevent real Firestore calls during tests
class MockTraceLogger extends TraceLogger {
  bool traceLogged = false;
  
  @override
  Future<void> logTrace({required PricingRequest request, required PricingResponse response, required String traceId}) async {
    traceLogged = true;
  }
}

void main() {
  late PricingAgentService agent;
  late MockTraceLogger mockLogger;

  setUp(() {
    mockLogger = MockTraceLogger();
    agent = PricingAgentService(traceLogger: mockLogger);
  });

  group('Pricing Agent Tests', () {
    test('1. Success Scenario: Standard booking with normal distance', () async {
      final req = PricingRequest(
        requestId: 'req_1',
        sessionId: 'sess_1',
        userRequest: UserRequest(
          serviceType: 'plumber',
          urgency: 'next_day',
          requestedTime: DateTime(2026, 5, 19, 15, 0), // 3 PM (normal)
          isRepeatCustomer: false,
        ),
        selectedProvider: SelectedProvider(
          providerId: 'prov_1',
          distanceKm: 5.0,
          complexity: 'basic',
        ),
      );

      final response = await agent.processRequest(req);

      expect(response.orchestrationStatus, 'success');
      expect(response.readyForBooking, true);
      // Base (500) + Distance (5 * 25 = 125) = 625 -> Rounded: 650
      expect(response.pricingData.totalPricePkr, 650.0);
      expect(mockLogger.traceLogged, true);
    });

    test('2. Edge Case Scenario: Extreme multipliers and max cap hit', () async {
      final req = PricingRequest(
        requestId: 'req_2',
        sessionId: 'sess_2',
        userRequest: UserRequest(
          serviceType: 'electrician',
          urgency: 'same_day', // 1.3x
          requestedTime: DateTime(2026, 5, 19, 23, 0), // Night 1.2x -> combined 1.56x
          isRepeatCustomer: false,
        ),
        selectedProvider: SelectedProvider(
          providerId: 'prov_2',
          distanceKm: 200.0, // High distance
          complexity: 'complex', // Base 2000
        ),
      );

      final response = await agent.processRequest(req);
      
      // Base(2000) + Distance(2000 * 0.5 cap = 1000) = 3000
      // 3000 * 1.56 = 4680 -> Round 4700
      expect(response.pricingData.totalPricePkr, 4700.0);
      expect(response.pricingData.breakdown['distance_cost'], 1000.0); // Capped at 50% of base
    });

    test('3. Failure Scenario / Fallback: Missing distance triggers degraded status', () async {
      final req = PricingRequest(
        requestId: 'req_3',
        sessionId: 'sess_3',
        userRequest: UserRequest(
          serviceType: 'cleaner',
          urgency: 'flexible',
          requestedTime: null, // Missing time
          isRepeatCustomer: true,
        ),
        selectedProvider: SelectedProvider(
          providerId: 'prov_3',
          distanceKm: null, // Missing distance
          complexity: 'intermediate',
        ),
      );

      final response = await agent.processRequest(req);

      expect(response.orchestrationStatus, 'degraded');
      expect(response.pricingData.breakdown['distance_km'], 0.0);
      // Base (1000) + Dist (0) = 1000
      // flexible (0.95) * time(1.0) = 0.95 => 950
      // Discount (5% of 950) = 47.5
      // 950 - 47.5 = 902.5 -> Round 900
      expect(response.pricingData.totalPricePkr, 900.0);
    });
  });
}
