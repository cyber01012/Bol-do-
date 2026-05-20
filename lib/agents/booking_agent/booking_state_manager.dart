import 'firestore_service.dart';

class BookingStateManager {
  final FirestoreService _firestoreService;

  BookingStateManager({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Standard allowed transitions for booking state transitions.
  final Map<String, List<String>> _allowedTransitions = {
    'pending': ['confirmed', 'failed', 'cancelled'],
    'confirmed': ['completed', 'cancelled', 'failed'],
    'completed': ['disputed'],
    'cancelled': [],
    'failed': [],
    'disputed': [],
  };

  /// Safely transitions a booking record in Firestore from one state to another.
  Future<void> transitionState({
    required String bookingId,
    required String fromState,
    required String toState,
  }) async {
    final doc = await _firestoreService.getDocument('bookings', bookingId);
    if (doc == null) {
      throw Exception('Booking $bookingId does not exist in the database');
    }

    final currentStatus = doc['booking_status'] as String? ?? 'pending';
    if (currentStatus != fromState) {
      throw Exception('Invalid starting state transition: booking is currently in status $currentStatus, expected $fromState');
    }

    final targets = _allowedTransitions[currentStatus];
    if (targets == null || !targets.contains(toState)) {
      throw Exception('Transition from $currentStatus to $toState is blocked by the lifecycle schema rules');
    }

    // Apply change
    await _firestoreService.saveDocument('bookings', bookingId, {
      'booking_status': toState,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
