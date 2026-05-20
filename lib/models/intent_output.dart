class IntentOutput {
  final String serviceType;
  final String location;
  final String preferredTime;
  final String urgency;
  final String budgetPreference;
  final double confidenceScore;
  final String languageDetected;
  final String type;

  IntentOutput({
    required this.serviceType,
    required this.location,
    required this.preferredTime,
    required this.urgency,
    required this.budgetPreference,
    required this.confidenceScore,
    required this.languageDetected,
    required this.type,
  });

  factory IntentOutput.fromJson(Map<String, dynamic> json) {
    return IntentOutput(
      serviceType: json['service_type'] ?? '',
      location: json['location'] ?? '',
      preferredTime: json['preferred_time'] ?? '',
      urgency: json['urgency'] ?? '',
      budgetPreference: json['budget'] ?? json['budget_preference'] ?? '',
      confidenceScore: (json['confidence_score'] ?? 0).toDouble(),
      languageDetected: json['language_detected'] ?? '',
      type: json['type'] ?? json['service_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_type': serviceType,
      'location': location,
      'preferred_time': preferredTime,
      'urgency': urgency,
      'budget_preference': budgetPreference,
      'confidence_score': confidenceScore,
      'language_detected': languageDetected,
      'type': type,
    };
  }
}
