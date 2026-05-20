import 'dart:math';
import 'pricing_model.dart';
import 'pricing_calculator.dart';
import 'trace_logger.dart';

class PricingAgentService {
  final TraceLogger _traceLogger;

  PricingAgentService({TraceLogger? traceLogger})
      : _traceLogger = traceLogger ?? TraceLogger();

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
      agentTraceId: traceId,
      orchestrationStatus: _determineStatus(request),
      readyForBooking: true,
      selectedProvider: request.selectedProvider.providerId,
      pricingData: pricingData,
    );

    await _traceLogger.logTrace(
      request: request,
      response: response,
      traceId: traceId,
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
    agentTraceId: traceId,
    orchestrationStatus: 'failed_degraded',
    readyForBooking: true,
    selectedProvider:
        request.selectedProvider.providerId,
    pricingData: fallbackPrice,
  );

  // SAVE FAILURE TRACE TO FIRESTORE
  await _traceLogger.logTrace(
    request: request,
    response: response,
    traceId: traceId,
  );

  return response;
 }
}
