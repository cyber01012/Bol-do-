import 'firestore_service.dart';
import 'pricing_model.dart';

class TraceLogger {
  final FirestoreService _firestoreService;

  TraceLogger({FirestoreService? firestoreService}) 
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<void> logTrace({
    required PricingRequest request,
    required PricingResponse response,
    required String traceId,
  }) async {
    final traceData = {
      'trace_id': traceId,
      'session_id': request.sessionId,
      'request_id': request.requestId,
      'agent': 'PricingAgent',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'inputs': {
        'service_type': request.userRequest.serviceType,
        'distance_km': request.selectedProvider.distanceKm,
        'urgency': request.userRequest.urgency,
      },
      'decision': 'Calculated price: ${response.pricingData.totalPricePkr}',
      'confidence': response.pricingData.confidenceScore,
      'reasoning_breakdown': response.pricingData.breakdown,
    };

  await _firestoreService.saveDocument(
  'agent_traces',
  traceId,
  traceData,
);

await _firestoreService.saveDocument(
  'orchestration_sessions',
  request.sessionId,
  {
    'completed_agents': {
      'PricingAgent': true
    },
    'last_updated':
        DateTime.now().toUtc().toIso8601String(),
    'pipeline_status':
        response.orchestrationStatus,
  },
);

await _firestoreService.saveDocument(
  'pricing_logs',
  traceId,
  {
    'session_id': request.sessionId,
    'request_id': request.requestId,
    'provider_id':
        request.selectedProvider.providerId,
    'final_price':
        response.pricingData.totalPricePkr,
    'confidence':
        response.pricingData.confidenceScore,
    'breakdown':
        response.pricingData.breakdown,
    'timestamp':
        DateTime.now().toUtc().toIso8601String(),
  },
);
  }
}
