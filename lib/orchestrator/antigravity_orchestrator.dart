import '../agents/intent_agent.dart';
import '../agents/discovery_agent.dart';
import '../agents/ranking_agent.dart';
import '../agents/voice_agent.dart';
import '../models/intent_output.dart';
import '../models/provider.dart';
import '../models/log_entry.dart';
import '../services/logging_service.dart';
import '../models/ranking_output.dart';

class AntigravityOrchestrator {
  final IntentAgent _intentAgent = IntentAgent();
  final DiscoveryAgent _discoveryAgent = DiscoveryAgent();
  final RankingAgent _rankingAgent = RankingAgent();
  final VoiceAgent _voiceAgent = VoiceAgent();
  
  VoiceAgent get voiceAgent => _voiceAgent;

  Future<void> initialize() async {
    await _voiceAgent.initialize();
  }

  /// Step 1: Extract intent from user input
  Future<IntentOutput?> extractIntent(String input) async {
    await LoggingService.log(LogEntry(
      agent: 'Antigravity Orchestrator',
      workflowStage: 'orchestration-start',
      decision: 'Begin pipeline',
      reasoning: 'User initiated request',
      actionTaken: 'start',
      severity: 'info',
      timestamp: DateTime.now(),
    ));

    final intent = await _intentAgent.processInput(input);
    if (intent == null) {
      return null;
    }

    if (intent.confidenceScore < 0.65) {
      final clarificationMsg = "Did you mean you need a ${intent.serviceType} in ${intent.location}?";
      await _voiceAgent.speak(clarificationMsg);
      return null;
    }

    return intent;
  }

  /// Step 2: Discover providers for the extracted intent
  Future<List<Provider>> discoverProviders(IntentOutput intent) async {
    final providers = await _discoveryAgent.discoverProviders(intent);
    return providers;
  }

  /// Step 3: Rank providers and return the ranking output
  Future<RankingOutput?> rankProviders(List<Provider> providers, String serviceType) async {
    final rankingOutput = await _rankingAgent.rankProviders(providers, serviceType);
    if (rankingOutput == null || rankingOutput.topChoice == null) {
      return null;
    }

    final topProvider = rankingOutput.topChoice!;

    // Pricing Agent Preparation
    final matchedProviderObj = providers.firstWhere(
      (p) => p.providerId == topProvider.providerId, 
      orElse: () => providers.first,
    );
    final pricingPayload = {
      "service_type": serviceType,
      "distance_km": matchedProviderObj.distanceKm,
      "urgency": "medium"
    };

    await LoggingService.log(LogEntry(
      agent: 'Pricing Agent Linker',
      workflowStage: 'pricing-preparation',
      decision: 'Prepared Pricing Agent payload: $pricingPayload',
      reasoning: 'Ready for dynamic pricing calculations using basePrice: Rs ${matchedProviderObj.basePrice}',
      actionTaken: 'pricing_payload_ready',
      severity: 'info',
      timestamp: DateTime.now(),
      finalOutcomes: 'Downstream Pricing Agent inputs prepared',
    ));

    // Speak result ONCE
    final responseMsg = "I found a great match for you! ${topProvider.name} is highly rated. ${topProvider.reasoning}";
    await _voiceAgent.speak(responseMsg);

    await LoggingService.log(LogEntry(
      agent: 'Antigravity Orchestrator',
      workflowStage: 'orchestration-end',
      decision: 'Pipeline complete',
      reasoning: 'Successfully found, ranked provider and prepared dynamic pricing details.',
      actionTaken: 'end',
      severity: 'info',
      timestamp: DateTime.now(),
      finalOutcomes: topProvider.providerId,
    ));

    return rankingOutput;
  }

  /// Legacy: Full pipeline in one call (kept for backward compatibility)
  Future<RankedProvider?> processUserRequest(String input) async {
    final intent = await extractIntent(input);
    if (intent == null) return null;

    final providers = await discoverProviders(intent);
    if (providers.isEmpty) {
      await _voiceAgent.speak("I'm sorry, I couldn't find any ${intent.serviceType} in ${intent.location}.");
      return null;
    }

    final rankingOutput = await rankProviders(providers, intent.serviceType);
    return rankingOutput?.topChoice;
  }
}
