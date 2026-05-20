import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/intent_output.dart';
import '../models/log_entry.dart';
import '../services/logging_service.dart';

class IntentAgent {
  static const int _maxRetries = 3;
  static const double _clarificationThreshold = 0.65;

  Future<IntentOutput?> processInput(String userInput) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not set in .env file.');
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );

    final prompt = '''
Extract user booking intent from this input (may be Urdu/English/Roman Urdu):

User input: "$userInput"

Return ONLY valid JSON (no markdown):
{
  "service_type": "plumber|electrician|painter|carpenter|cleaner|appliance_repair|ac_technician",
  "location": "extracted location or area",
  "preferred_time": "today|tomorrow|next_week|next_month",
  "urgency": "high|medium|low",
  "budget": "low|medium|high",
  "confidence_score": 0.0 to 1.0,
  "language_detected": "urdu|english|roman_urdu|mixed"
}
''';

    int retryCount = 0;
    String? errorRecoveryInfo;

    // Log Start
    await LoggingService.log(LogEntry(
      agent: 'Intent Agent',
      workflowStage: 'intent-extraction',
      decision: 'Starting intent extraction',
      reasoning: 'Received user input',
      actionTaken: 'calling_gemini_api',
      severity: 'info',
      timestamp: DateTime.now(),
    ));

    while (retryCount < _maxRetries) {
      try {
        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);

        if (response.text == null || response.text!.isEmpty) {
          throw Exception('Empty response from model');
        }

        // Clean markdown backticks if model accidentally outputs them
        String cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> jsonResult = jsonDecode(cleanJson);
        final intentOutput = IntentOutput.fromJson(jsonResult);

        // Check Confidence Score
        if (intentOutput.confidenceScore < _clarificationThreshold) {
          await LoggingService.log(LogEntry(
            agent: 'Intent Agent',
            workflowStage: 'intent-extraction',
            decision: 'Trigger clarification',
            reasoning: 'Confidence score ${intentOutput.confidenceScore} is below threshold $_clarificationThreshold',
            actionTaken: 'ask_clarification',
            severity: 'warning',
            timestamp: DateTime.now(),
            toolCalls: ['generateContent'],
            finalOutcomes: 'Requires user clarification',
          ));
          // Return the low confidence output so UI can ask clarification
          return intentOutput;
        }

        // Success Log
        await LoggingService.log(LogEntry(
          agent: 'Intent Agent',
          workflowStage: 'intent-extraction',
          decision: 'Successfully extracted intent',
          reasoning: 'High confidence extraction: ${intentOutput.confidenceScore}',
          actionTaken: 'extraction_complete',
          severity: 'info',
          timestamp: DateTime.now(),
          toolCalls: ['generateContent'],
          errorRecovery: errorRecoveryInfo,
          finalOutcomes: 'Proceed to Provider Discovery',
        ));

        return intentOutput;

      } catch (e) {
        retryCount++;
        errorRecoveryInfo = 'Retried $retryCount times due to error: $e';
        
        await LoggingService.log(LogEntry(
          agent: 'Intent Agent',
          workflowStage: 'intent-extraction',
          decision: 'API call failed, attempting retry',
          reasoning: e.toString(),
          actionTaken: 'retry_$retryCount',
          severity: 'warning',
          timestamp: DateTime.now(),
          toolCalls: ['generateContent'],
        ));

        if (retryCount >= _maxRetries) {
          await LoggingService.log(LogEntry(
            agent: 'Intent Agent',
            workflowStage: 'intent-extraction',
            decision: 'Failed to extract intent',
            reasoning: 'Max retries reached',
            actionTaken: 'extraction_failed',
            severity: 'critical',
            timestamp: DateTime.now(),
            toolCalls: ['generateContent'],
            errorRecovery: errorRecoveryInfo,
            finalOutcomes: 'Workflow failed',
          ));
          throw Exception('Failed to extract intent after $_maxRetries attempts: $e');
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: 2 * retryCount));
      }
    }
    return null;
  }
}
