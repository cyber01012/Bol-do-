import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore? _firestoreInstance;

  FirestoreService({FirebaseFirestore? firestore}) : _firestoreInstance = firestore;

  FirebaseFirestore get _firestore => _firestoreInstance ?? FirebaseFirestore.instance;

  Future<void> saveDocument(
    String collectionPath,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(documentId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print('Firestore Write Error: $e');
      // Gracefully swallow to prevent blocking pipeline orchestration execution flow
    }
  }

  Future<Map<String, dynamic>?> getDocument(
    String collectionPath,
    String documentId,
  ) async {
    try {
      final doc = await _firestore.collection(collectionPath).doc(documentId).get();
      return doc.data();
    } catch (e) {
      print('Firestore Read Error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> queryOverlapBookings({
    required String providerId,
    required DateTime requestedTime,
    required Duration bufferWindow,
  }) async {
    try {
      final startTime = requestedTime.subtract(bufferWindow);
      final endTime = requestedTime.add(bufferWindow);

      final snapshot = await _firestore
          .collection('bookings')
          .where('provider_id', isEqualTo: providerId)
          .where('booking_status', whereIn: ['confirmed', 'provider_assigned', 'in_progress'])
          .get();

      final results = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final requestedTimeStr = data['requested_time'] as String?;
        if (requestedTimeStr != null) {
          final bookingTime = DateTime.parse(requestedTimeStr);
          if (bookingTime.isAfter(startTime) && bookingTime.isBefore(endTime)) {
            results.add(data);
          }
        }
      }
      return results;
    } catch (e) {
      print('Firestore Query Error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> queryBackupProviders(String serviceType) async {
    try {
      final snapshot = await _firestore
          .collection('providers')
          .where('service_type', isEqualTo: serviceType)
          .where('is_available', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Firestore Query Backup Providers Error: $e');
      return [];
    }
  }
}

