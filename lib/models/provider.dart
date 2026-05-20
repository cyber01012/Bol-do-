class Provider {
  final String providerId;
  final String name;
  final String serviceType;
  final double rating;
  final double reliabilityScore;
  final double cancellationRate;
  final List<String> specializations;
  final bool availability;
  final double distanceKm;
  final double basePrice;
  final String location;

  // Getter for UI backward compatibility
  String get locationArea => location;

  Provider({
    required this.providerId,
    required this.name,
    required this.serviceType,
    required this.rating,
    required this.reliabilityScore,
    required this.cancellationRate,
    required this.specializations,
    required this.availability,
    required this.distanceKm,
    required this.basePrice,
    required this.location,
  });

  factory Provider.fromJson(Map<String, dynamic> json, String id) {
    return Provider(
      providerId: id,
      name: json['name'] ?? '',
      serviceType: json['serviceType'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reliabilityScore: (json['reliabilityScore'] ?? 100.0).toDouble(),
      cancellationRate: (json['cancellationRate'] ?? 0.0).toDouble(),
      specializations: List<String>.from(json['specializations'] ?? []),
      availability: json['availability'] ?? true,
      distanceKm: (json['distanceKm'] ?? 1.0).toDouble(),
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      location: json['location'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'name': name,
      'serviceType': serviceType,
      'rating': rating,
      'reliabilityScore': reliabilityScore,
      'cancellationRate': cancellationRate,
      'specializations': specializations,
      'availability': availability,
      'distanceKm': distanceKm,
      'basePrice': basePrice,
      'location': location,
    };
  }
}
