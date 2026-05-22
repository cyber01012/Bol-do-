import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:boldo_ai/agents/supervisor_agent/supervisor_agent_service.dart';

void main() async {
  print('Starting test');
  final supervisor = SupervisorAgentService();
  try {
    await supervisor.runCentralizedPipeline(
      sessionId: 'test_session',
      requestId: 'test_req',
      userId: 'test_user',
      serviceType: 'electrician',
      providerId: 'provider_123',
      providerName: 'Test Provider',
      distanceKm: 5.0,
      providerMetadata: {'rating': 4.5},
    );
    print('Test complete');
  } catch (e, st) {
    print('Exception: $e');
    print('Stack trace: $st');
  }
}
