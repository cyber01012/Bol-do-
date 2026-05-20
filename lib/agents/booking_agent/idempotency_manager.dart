import 'firestore_service.dart';

enum BookingCheckState {
  clear,
  idempotentMatch,
  providerUnavailable,
  providerDoubleBookedConflict,
}

class IdempotencyCheckResult {
  final BookingCheckState state;
  final Map<String, dynamic>? existingBooking;

  IdempotencyCheckResult({required this.state, this.existingBooking});
}

class IdempotencyManager {
  final FirestoreService _firestoreService;

  IdempotencyManager({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<IdempotencyCheckResult> checkSafety({
    required String sessionId,
    required String providerId,
    required DateTime requestedTime,
  }) async {
    // 1. Identical Session ID (Idempotency) Check
    final existingBooking = await _firestoreService.getDocument('bookings', 'book_$sessionId');
    if (existingBooking != null) {
      return IdempotencyCheckResult(
        state: BookingCheckState.idempotentMatch,
        existingBooking: existingBooking,
      );
    }

    // 2. Provider Availability Check
    final providerDoc = await _firestoreService.getDocument('providers', providerId);
    if (providerDoc == null) {
      return IdempotencyCheckResult(state: BookingCheckState.providerUnavailable);
    }
    
    final isAvailable = providerDoc['is_available'] as bool? ?? false;
    if (!isAvailable) {
      return IdempotencyCheckResult(state: BookingCheckState.providerUnavailable);
    }

    // 3. Double Booking Time-Conflict Check (+/- 2 hours)
    final overlaps = await _firestoreService.queryOverlapBookings(
      providerId: providerId,
      requestedTime: requestedTime,
      bufferWindow: const Duration(hours: 2),
    );

    if (overlaps.isNotEmpty) {
      return IdempotencyCheckResult(state: BookingCheckState.providerDoubleBookedConflict);
    }

    return IdempotencyCheckResult(state: BookingCheckState.clear);
  }

  Future<bool> validateSession(String sessionId) async {
    try {
      final doc = await _firestoreService.getDocument('orchestration_sessions', sessionId);
      if (doc == null) return false;

      final completed = doc['completed_agents'] as Map<String, dynamic>?;
      if (completed == null || completed['PricingAgent'] != true) {
        return false;
      }

      final status = doc['pipeline_status'] as String?;
      if (status == 'failed') {
        return false;
      }

      return true;
    } catch (e) {
      print('Session Validation Error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> findBackupProvider({
    required String serviceType,
    required String excludedProviderId,
  }) async {
    try {
      final providers = await _firestoreService.queryBackupProviders(serviceType);

      final candidates = providers.where((p) => p['provider_id'] != excludedProviderId).toList();
      if (candidates.isEmpty) return null;

      // Rank by rating descending
      candidates.sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return ratingB.compareTo(ratingA);
      });

      return candidates.first;
    } catch (e) {
      print('Find Backup Provider Error: $e');
      return null;
    }
  }
}
