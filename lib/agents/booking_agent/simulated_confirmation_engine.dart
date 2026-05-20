import 'dart:math';

class SimulatedConfirmationResult {
  final bool confirmed;
  final String reasoningTrace;
  final double confidenceScore;

  SimulatedConfirmationResult({
    required this.confirmed,
    required this.reasoningTrace,
    required this.confidenceScore,
  });
}

class SimulatedConfirmationEngine {
  SimulatedConfirmationResult simulate({
    required String providerName,
    required String providerId,
    required double providerRating,
    required String serviceType,
    required DateTime requestedTime,
    required String urgency,
    required double totalPricePkr,
  }) {
    // 1. Core Heuristic Probability Calculation
    double confirmProbability = 0.80; // Baseline for average rating

    if (providerRating >= 4.5) {
      confirmProbability = 0.95; // High rating baseline
    } else if (providerRating >= 4.0) {
      confirmProbability = 0.88;
    }

    // Night Slot Penalty: 10 PM - 6 AM (inclusive)
    final hour = requestedTime.hour;
    final isNight = hour >= 22 || hour < 6;
    if (isNight) {
      confirmProbability -= 0.20;
    }

    // Lucrative Pricing Bonus: >= 5000 PKR
    final isLucrative = totalPricePkr >= 5000.0;
    if (isLucrative) {
      confirmProbability += 0.10;
    }

    // Clamp between 0.05 and 0.99
    confirmProbability = confirmProbability.clamp(0.05, 0.99);

    // 2. Determine Outcome (using a seeded or pseudo-random check, or high rating fallback)
    // To ensure testing stability, we can base it on simple logic: if confirmProbability >= 0.70, it confirms.
    // That ensures high reliability while still reflecting the dynamic probability in the confidence score.
    final isConfirmed = confirmProbability >= 0.70;

    // 3. Generate dynamic "Gemini Internal Dialogue & Outreach Monologue"
    final formattedTime = '${requestedTime.year}-${requestedTime.month.toString().padLeft(2, '0')}-${requestedTime.day.toString().padLeft(2, '0')} at ${requestedTime.hour.toString().padLeft(2, '0')}:${requestedTime.minute.toString().padLeft(2, '0')}';
    
    final buffer = StringBuffer();
    buffer.writeln('[Gemini AI Outreach Coordinator Initiated]');
    buffer.writeln('- Provider ID: $providerId ($providerName)');
    buffer.writeln('- Requested Slot: $formattedTime');
    buffer.writeln('- Pricing Offered: $totalPricePkr PKR');
    buffer.writeln('- Heuristic Evaluation: Night Slot = $isNight, Lucrative Job = $isLucrative, Probability = ${(confirmProbability * 100).toStringAsFixed(1)}%');
    buffer.writeln('\n[Internal Dialogue]');
    
    if (isConfirmed) {
      buffer.writeln('Monologue: The provider has a rating of $providerRating. Although it is ${isNight ? "night" : "day"} time, the booking is attractive due to ${isLucrative ? "lucrative pricing ($totalPricePkr PKR)" : "clean scheduling alignment"}. Let\'s execute simulated WhatsApp outreach...');
      buffer.writeln('Outreach: "Assalam-o-Alaikum $providerName, a new job for $serviceType is available on $formattedTime. Estimated earning: $totalPricePkr PKR. Would you like to accept?"');
      buffer.writeln('Response from $providerName: "Walaikum Assalam! Yes, I am available. Slot is confirmed."');
      buffer.writeln('Decision: Booking accepted and locked.');
    } else {
      buffer.writeln('Monologue: The provider has a rating of $providerRating. The slot is at $formattedTime (${isNight ? "night shift" : "day shift"}). The probability calculation indicates provider is highly likely resting or fully booked. Executing simulated WhatsApp outreach...');
      buffer.writeln('Outreach: "Assalam-o-Alaikum $providerName, we have a job for $serviceType on $formattedTime. Earning: $totalPricePkr PKR. Please respond if you can take this."');
      buffer.writeln('Response from $providerName: "Walaikum Assalam. Sorry, I cannot make it at this hour. Please assign to another provider."');
      buffer.writeln('Decision: Booking declined by provider.');
    }

    return SimulatedConfirmationResult(
      confirmed: isConfirmed,
      reasoningTrace: buffer.toString(),
      confidenceScore: confirmProbability,
    );
  }
}
