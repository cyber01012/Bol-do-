class Provider {
  final String providerId;
  final String name;
  final String serviceType;
  final double rating;
  final double reliabilityScore;
  final double cancellationRate;
  final List<String> specializations;
  final bool availability;
  final String locationArea;

  Provider({
    required this.providerId,
    required this.name,
    required this.serviceType,
    required this.rating,
    required this.reliabilityScore,
    required this.cancellationRate,
    required this.specializations,
    required this.availability,
    required this.locationArea,
  });

  factory Provider.fromJson(Map<String, dynamic> json, String id) {
    return Provider(
      providerId: id,
      name: json['name'] ?? '',
      serviceType: json['service'] ?? json['service_type'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reliabilityScore: (json['reliability_score'] ?? 100.0).toDouble(),
      cancellationRate: (json['cancellation_rate'] ?? 0.0).toDouble(),
      specializations: List<String>.from(json['specializations'] ?? []),
      availability: json['availability'] ?? true,
      locationArea: json['location_area'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': providerId,
      'name': name,
      'service': serviceType,
      'rating': rating,
      'reliability_score': reliabilityScore,
      'cancellation_rate': cancellationRate,
      'specializations': specializations,
      'availability': availability,
      'location_area': locationArea,
    };
  }
}
