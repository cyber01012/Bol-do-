import 'booking_model.dart';

class BookingValidator {
  /// Validates standard input fields are present and structurally valid.
  static void validateInput(BookingRequest request) {
    if (request.requestId.trim().isEmpty) {
      throw ArgumentError('request_id cannot be empty');
    }
    if (request.sessionId.trim().isEmpty) {
      throw ArgumentError('session_id cannot be empty');
    }
    if (request.selectedProvider.providerId.trim().isEmpty) {
      throw ArgumentError('provider_id cannot be empty');
    }
    if (request.selectedProvider.serviceType.trim().isEmpty) {
      throw ArgumentError('service_type cannot be empty');
    }
  }

  /// Clamps calculations to minimum basic fee of 500.0 PKR if pricing is missing or <= 0
  static double validateAndClampPrice(double price) {
    if (price <= 0) {
      return 500.0; // Minimum baseline price
    }
    return price;
  }
}
