import '../agents/intent_agent.dart';
import '../agents/discovery_agent.dart';
import '../agents/ranking_agent.dart';
import '../agents/voice_agent.dart';
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

  Future<RankedProvider?> processUserRequest(String input) async {
    await LoggingService.log(LogEntry(
      agent: 'Antigravity Orchestrator',
      workflowStage: 'orchestration-start',
      decision: 'Begin pipeline',
      reasoning: 'User initiated request',
      actionTaken: 'start',
      severity: 'info',
      timestamp: DateTime.now(),
    ));

    // Step 1: Intent Extraction
    final intent = await _intentAgent.processInput(input);
    if (intent == null) {
      await _voiceAgent.speak("I'm sorry, I couldn't understand your request.");
      return null;
    }

    if (intent.confidenceScore < 0.65) {
      final clarificationMsg = "Did you mean you need a ${intent.serviceType} in ${intent.location}?";
      await _voiceAgent.speak(clarificationMsg);
      return null; // Return to UI for clarification
    }

    // Step 2: Discovery
    final providers = await _discoveryAgent.discoverProviders(intent);
    if (providers.isEmpty) {
      await _voiceAgent.speak("I'm sorry, I couldn't find any ${intent.serviceType} in ${intent.location}.");
      return null;
    }

    // Step 3: Ranking
    final rankingOutput = await _rankingAgent.rankProviders(providers, intent.serviceType);
    if (rankingOutput == null || rankingOutput.topChoice == null) {
      await _voiceAgent.speak("I found some providers, but couldn't determine the best one.");
      return null;
    }

    final topProvider = rankingOutput.topChoice!;
    
    // Step 4: Final Output
    final responseMsg = "I found a great match for you! ${topProvider.name} is highly rated. ${topProvider.reasoning}";
    await _voiceAgent.speak(responseMsg);

    await LoggingService.log(LogEntry(
      agent: 'Antigravity Orchestrator',
      workflowStage: 'orchestration-end',
      decision: 'Pipeline complete',
      reasoning: 'Successfully found and ranked provider',
      actionTaken: 'end',
      severity: 'info',
      timestamp: DateTime.now(),
      finalOutcomes: topProvider.providerId,
    ));

    return topProvider;
  }
}
