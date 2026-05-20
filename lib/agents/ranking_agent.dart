import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/provider.dart';
import '../models/ranking_output.dart';
import '../models/log_entry.dart';
import '../services/logging_service.dart';
import '../utils/gemini_key_rotator.dart';

class RankingAgent {
  static const int _maxRetries = 3;

  Future<RankingOutput?> rankProviders(List<Provider> providers, String requestedService) async {
    if (providers.isEmpty) return null;

    // Serialize providers to send to prompt
    final providersJson = jsonEncode(providers.map((p) => p.toJson()).toList());

    final prompt = '''
Rank the following providers for the requested service: "$requestedService"

Providers:
$providersJson

Scoring and ranking criteria:
1. Distance (closer providers should rank much higher)
2. Availability (providers must be available; unavailable ones should be filtered out or ranked at the bottom)
3. Rating (higher rating is highly preferred)

Please generate a clear, simple reasoning explaining why the selected best provider is the top choice.
The explanation must be in extremely simple, friendly, easy-to-understand terms for a regular customer (e.g. "Ali is the closest plumber to you, only 2.3km away, and has an amazing 4.8 rating!").

Return ONLY a valid JSON object matching the following structure (no markdown code blocks, just raw JSON):
{
  "ranked_providers": [
    {
      "provider_id": "id",
      "name": "name",
      "score": 85.5,
      "reasoning": "A simple 1-sentence explanation of why this provider is ranked here based on distance, availability, and rating."
    }
  ],
  "top_choice": {
    "provider_id": "id",
    "name": "name",
    "score": 95.0,
    "reasoning": "A simple, friendly, clear customer explanation of why they are the absolute best choice."
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

    int retryCount = 0;
    String? errorRecoveryInfo;

    while (retryCount < _maxRetries) {
      final apiKey = GeminiKeyRotator.instance.getNextKey();
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

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
          errorRecovery: errorRecoveryInfo,
          finalOutcomes: rankingOutput.topChoice?.reasoning,
        ));

        return rankingOutput;
      } catch (e) {
        retryCount++;
        final sanitizedError = GeminiKeyRotator.instance.sanitizeLog(e.toString());
        errorRecoveryInfo = 'Retried $retryCount times due to error: $sanitizedError';

        await LoggingService.log(LogEntry(
          agent: 'Ranking Agent',
          workflowStage: 'provider-ranking',
          decision: 'Ranking failed, attempting retry',
          reasoning: sanitizedError,
          actionTaken: 'retry_$retryCount',
          severity: 'warning',
          timestamp: DateTime.now(),
        ));

        if (retryCount >= _maxRetries) {
          await LoggingService.log(LogEntry(
            agent: 'Ranking Agent',
            workflowStage: 'provider-ranking',
            decision: 'Ranking completely failed',
            reasoning: 'Max retries reached: $sanitizedError',
            actionTaken: 'error_handling',
            severity: 'critical',
            timestamp: DateTime.now(),
          ));
          throw Exception('Failed to rank providers after $_maxRetries attempts: $sanitizedError');
        }

        await Future.delayed(Duration(seconds: 2 * retryCount));
      }
    }
    return null;
  }
}
