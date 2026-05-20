import 'pricing_model.dart';

class PricingCalculator {
  static const double minPrice = 500.0;
  static const double maxPrice = 15000.0;
  static const double distanceRate = 25.0;

  static PricingData calculate(PricingRequest request) {
    // 1. Inputs & Fallbacks
    final complexityStr = request.selectedProvider.complexity;
    final distanceKm = request.selectedProvider.distanceKm ?? 0.0;
    final urgencyStr = request.userRequest.urgency ?? 'normal';
    final isRepeatCustomer = request.userRequest.isRepeatCustomer;
    final requestedTime = request.userRequest.requestedTime;

    // 2. Base Price
    double basePrice = 500.0; // basic default
    if (complexityStr == 'intermediate') basePrice = 1000.0;
    if (complexityStr == 'complex') basePrice = 2000.0;

    // 3. Distance Cost with Cap
    double rawDistanceCost = distanceKm * distanceRate;
    double maxDistanceCost = basePrice * 0.5; // Cap at 50% of base
    double distanceCost = rawDistanceCost > maxDistanceCost ? maxDistanceCost : rawDistanceCost;

    // 4. Subtotal
    double subtotal = basePrice + distanceCost;

    // 5. Multipliers
    double urgencyMultiplier = 1.0;
    if (urgencyStr == 'same_day') urgencyMultiplier = 1.3;
    if (urgencyStr == 'flexible') urgencyMultiplier = 0.95;

    double timeMultiplier = 1.0;
    if (requestedTime != null) {
      final hour = requestedTime.hour;
      if (hour >= 22 || hour < 6) {
        timeMultiplier = 1.2; // night
      } else if (hour >= 12 && hour < 14) {
        timeMultiplier = 1.1; // peak
      }
    }

    double combinedMultiplier = urgencyMultiplier * timeMultiplier;
    double preDiscountTotal = subtotal * combinedMultiplier;

    // 6. Discounts
    double loyaltyDiscountPercent = isRepeatCustomer ? 0.05 : 0.0;
    double loyaltyDiscountValue = preDiscountTotal * loyaltyDiscountPercent;
    
    double rawFinalPrice = preDiscountTotal - loyaltyDiscountValue;

    // 7. Clamp and Round
    if (rawFinalPrice < minPrice) rawFinalPrice = minPrice;
    if (rawFinalPrice > maxPrice) rawFinalPrice = maxPrice;

    double finalPrice = _roundToNearest50(rawFinalPrice);

    return PricingData(
      totalPricePkr: finalPrice,
      confidenceScore: 0.95,
      breakdown: {
        'base_price': basePrice,
        'distance_km': distanceKm,
        'distance_cost': distanceCost,
        'subtotal': subtotal,
        'urgency': urgencyStr,
        'urgency_multiplier': urgencyMultiplier,
        'time_multiplier': timeMultiplier,
        'combined_multiplier': combinedMultiplier,
        'pre_discount_total': preDiscountTotal,
        'loyalty_discount_applied_percent': loyaltyDiscountPercent * 100,
        'loyalty_discount_value': loyaltyDiscountValue,
        'raw_final_price': rawFinalPrice,
        'rounded_final_price': finalPrice
      },
    );
  }

  static double _roundToNearest50(double value) {
    return (value / 50.0).roundToDouble() * 50.0;
  }
}
