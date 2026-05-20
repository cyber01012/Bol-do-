import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/provider.dart';
import '../models/ranking_output.dart';
import '../models/log_entry.dart';
import '../services/logging_service.dart';

class RankingAgent {
  Future<RankingOutput?> rankProviders(List<Provider> providers, String requestedService) async {
    if (providers.isEmpty) return null;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not set in .env file.');
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );

    // Serialize providers to send to prompt
    final providersJson = jsonEncode(providers.map((p) => p.toJson()).toList());

    final prompt = '''
Rank the following providers for the requested service: "$requestedService"

Providers:
$providersJson

Scoring logic:
1. Rating (30%)
2. Reliability (25%)
3. Cancellation Rate (lower is better) (15%)
4. Specialization match (10%)
5. Distance (20%) (Assume distance is random between 1-10km for this mock if not provided)

Generate reasoning explaining why the top provider is the best choice.
Return ONLY valid JSON (no markdown):
{
  "ranked_providers": [
    {
      "provider_id": "id",
      "name": "name",
      "score": 85.5,
      "reasoning": "reasoning here"
    }
  ],
  "top_choice": {
    "provider_id": "id",
    "name": "name",
    "score": 85.5,
    "reasoning": "Overall best because..."
  }
}
''';

    await LoggingService.log(LogEntry(
      agent: 'Ranking Agent',
      workflowStage: 'provider-ranking',
      decision: 'Starting ranking process',
      reasoning: 'Ranking ${providers.length} providers for $requestedService',
      actionTaken: 'calling_gemini_api',
      severity: 'info',
      timestamp: DateTime.now(),
    ));

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from model');
      }

      String cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> jsonResult = jsonDecode(cleanJson);
      final rankingOutput = RankingOutput.fromJson(jsonResult);

      await LoggingService.log(LogEntry(
        agent: 'Ranking Agent',
        workflowStage: 'provider-ranking',
        decision: 'Successfully ranked providers',
        reasoning: 'Top choice: ${rankingOutput.topChoice?.name}',
        actionTaken: 'ranking_complete',
        severity: 'info',
        timestamp: DateTime.now(),
        finalOutcomes: rankingOutput.topChoice?.reasoning,
      ));

      return rankingOutput;
    } catch (e) {
      await LoggingService.log(LogEntry(
        agent: 'Ranking Agent',
        workflowStage: 'provider-ranking',
        decision: 'Ranking failed',
        reasoning: e.toString(),
        actionTaken: 'error_handling',
        severity: 'critical',
        timestamp: DateTime.now(),
      ));
      return null;
    }
  }
}
