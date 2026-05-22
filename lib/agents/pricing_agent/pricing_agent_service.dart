import 'dart:math';
import 'pricing_model.dart';
import 'pricing_calculator.dart';
import '../../services/central_trace_logger.dart';

class PricingAgentService {
  final CentralTraceLogger _traceLogger;

  PricingAgentService({CentralTraceLogger? traceLogger})
      : _traceLogger = traceLogger ?? CentralTraceLogger();

  Future<PricingResponse> processRequest(
    PricingRequest request,
) async {
  try {

    final pricingData =
        PricingCalculator.calculate(request);

    final traceId =
        'trace_price_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

    final response = PricingResponse(
      requestId: request.requestId,
      sessionId: request.sessionId,
      agentTraceId: traceId,
      orchestrationStatus: _determineStatus(request),
      readyForBooking: true,
      selectedProvider: request.selectedProvider,
      pricingData: pricingData,
    );

    await _traceLogger.logTrace(
      traceId: traceId,
      sessionId: request.sessionId,
      userId: request.requestId, // Fallback as user_id if not explicitly provided in the request
      agentName: 'PricingAgent',
      decision: 'Calculated price: ${response.pricingData.totalPricePkr}',
      confidence: response.pricingData.confidenceScore,
      orchestrationStatus: response.orchestrationStatus,
      reasoning: response.pricingData.breakdown,
    );

    return response;

  } catch (e) {

    return await _buildFallbackResponse(request);
  }
}

  String _determineStatus(PricingRequest request) {
    if (request.selectedProvider.distanceKm == null || request.userRequest.requestedTime == null) {
      return 'degraded';
    }
    return 'success';
  }

Future<PricingResponse> _buildFallbackResponse(
    PricingRequest request,
) async {

  final traceId =
      'trace_price_fallback_${DateTime.now().millisecondsSinceEpoch}';

  final fallbackPrice = PricingData(
    totalPricePkr: 500.0,
    confidenceScore: 0.1,
    breakdown: {
      'error': 'Fallback triggered due to calculation failure',
      'base_price': 500.0,
    },
  );

  final response = PricingResponse(
    requestId: request.requestId,
    sessionId: request.sessionId,
    agentTraceId: traceId,
    orchestrationStatus: 'failed_degraded',
    readyForBooking: true,
    selectedProvider: request.selectedProvider,
    pricingData: fallbackPrice,
  );

  // SAVE FAILURE TRACE TO FIRESTORE
  await _traceLogger.logTrace(
    traceId: traceId,
    sessionId: request.sessionId,
    userId: request.requestId,
    agentName: 'PricingAgent',
    decision: 'Fallback calculation',
    confidence: fallbackPrice.confidenceScore,
    orchestrationStatus: 'failed_degraded',
    reasoning: fallbackPrice.breakdown,
  );

  return response;
 }
}
