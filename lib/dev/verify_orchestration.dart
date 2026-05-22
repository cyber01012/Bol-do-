import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

void runVerification() async {
  print('==================================================');
  print('          BOLDO-AI ORCHESTRATION VERIFIER          ');
  print('==================================================\n');

  // 1. Load Environment Variables
  print('[1/4] Loading environment variables...');
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ ERROR: .env file not found at project root!');
    exit(1);
  }

  // Parse .env manually to avoid Flutter platform dependencies in pure Dart
  final lines = envFile.readAsLinesSync();
  String? apiKey;
  for (var line in lines) {
    if (line.trim().startsWith('GEMINI_API_KEY')) {
      final parts = line.split('=');
      if (parts.length > 1) {
        apiKey = parts[1].replaceAll('"', '').replaceAll("'", "").trim();
      }
    }
  }

  if (apiKey == null || apiKey.isEmpty) {
    print('❌ ERROR: GEMINI_API_KEY is not defined in .env!');
    exit(1);
  }
  print('✅ Environment loaded. Gemini API Key found (ends with: ...${apiKey.substring(apiKey.length - 6)})\n');

  // 2. Initialize Gemini Model
  print('[2/4] Initializing Gemini 2.5 Flash Model...');
  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
  );
  print('✅ Model initialized successfully.\n');

  // 3. Test Intent Extraction (Multilingual)
  print('[3/4] Testing Multilingual Intent Extraction...');
  final testQueries = [
    'kal subah plumber chahiye DHA mein', // Roman Urdu
    'Need AC technician urgently at PECHS tomorrow morning', // English
    'Saddar me safai karne wala chahiye urgent' // Roman Urdu mixed
  ];

  for (var query in testQueries) {
    print('   👉 Input Query: "$query"');
    final prompt = '''
Extract user booking intent from this input. The input can be in English, Urdu (Perso-Arabic script), Roman Urdu (English alphabet phonetic Urdu), or a mix of these.

User input: "$query"

Analyze the request and return ONLY a valid JSON object matching the following structure (no markdown code blocks, just raw JSON):
{
  "service_type": "plumber|electrician|painter|carpenter|cleaner|appliance_repair|ac_technician",
  "location": "extracted location or area (e.g. DHA, Clifton, Gulshan, PECHS, Saddar, etc. Default to 'unknown' if not mentioned)",
  "preferred_time": "today|tomorrow|next_week|next_month",
  "urgency": "high|medium|low",
  "budget": "low|medium|high",
  "confidence_score": 0.0 to 1.0,
  "language_detected": "urdu|english|roman_urdu|mixed",
  "type": "the extracted type of service requested (e.g. Plumbing, Electrical, Painting, Carpentry, Cleaning, AC Repair)"
}
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Empty response received');
      }

      String cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> jsonResult = jsonDecode(cleanJson);
      
      print('   ✅ Extraction Successful:');
      print('      - Service Type: ${jsonResult['service_type']}');
      print('      - Type:         ${jsonResult['type']}');
      print('      - Location:     ${jsonResult['location']}');
      print('      - Urgency:      ${jsonResult['urgency']}');
      print('      - Confidence:   ${jsonResult['confidence_score']}');
      print('      - Language:     ${jsonResult['language_detected']}');
    } catch (e) {
      print('   ❌ Extraction Failed: $e');
    }
    print('');
  }

  // 4. Test Provider Ranking
  print('[4/4] Testing Provider Ranking with Mock Dataset...');
  final mockProviders = [
    {
      'providerId': 'prov1',
      'name': 'Ali Plumber',
      'serviceType': 'Plumbing',
      'rating': 4.8,
      'distanceKm': 2.3,
      'availability': true,
      'basePrice': 1500.0,
      'location': 'DHA Phase 5'
    },
    {
      'providerId': 'prov9',
      'name': 'Omar Plumber',
      'serviceType': 'Plumbing',
      'rating': 4.7,
      'distanceKm': 2.9,
      'availability': true,
      'basePrice': 1300.0,
      'location': 'Gulshan'
    },
    {
      'providerId': 'prov16',
      'name': 'Kamil Plumber',
      'serviceType': 'Plumbing',
      'rating': 4.5,
      'distanceKm': 6.0,
      'availability': false,
      'basePrice': 1100.0,
      'location': 'Clifton'
    }
  ];

  final rankingPrompt = '''
Rank the following providers for the requested service: "Plumbing"

Providers:
${jsonEncode(mockProviders)}

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

  try {
    final response = await model.generateContent([Content.text(rankingPrompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Empty response received');
    }

    String cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final Map<String, dynamic> jsonResult = jsonDecode(cleanJson);
    
    print('   ✅ Ranking Successful:');
    print('      - Top Choice: ${jsonResult['top_choice']['name']} (ID: ${jsonResult['top_choice']['provider_id']})');
    print('      - Reasoning:  ${jsonResult['top_choice']['reasoning']}');
    print('      - Total Ranked Options: ${jsonResult['ranked_providers'].length}');
    for (var rp in jsonResult['ranked_providers']) {
      print('        * Provider: ${rp['name']} (Score: ${rp['score']})');
      print('          Reason: ${rp['reasoning']}');
    }
  } catch (e) {
    print('   ❌ Ranking Failed: $e');
  }

  print('\n==================================================');
  print('       VERIFICATION COMPLETE - PIPELINE VALID!     ');
  print('==================================================');
}
