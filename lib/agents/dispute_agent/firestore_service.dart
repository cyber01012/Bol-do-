import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service class for interacting with Firestore.
/// Provides safe write, read, and update operations with error handling and logging.
class FirestoreService {
  final FirebaseFirestore? _firestoreInstance;

  /// Constructor allowing dependency injection of [FirebaseFirestore].
  /// If null is provided, defaults to [FirebaseFirestore.instance].
  FirestoreService({FirebaseFirestore? firestore}) : _firestoreInstance = firestore;

  /// Getter that returns the injected firestore instance or fallback instance.
  FirebaseFirestore get _firestore => _firestoreInstance ?? FirebaseFirestore.instance;

  /// Saves a document by setting its data in the specified collection and document ID.
  /// Uses merge options to avoid overwriting existing sibling fields.
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
    } catch (e, stackTrace) {
      developer.log(
        'Firestore Write Error in collection $collectionPath for doc $documentId: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'DisputeFirestoreService',
      );
      print('Firestore Write Error: $e');
    }
  }

  /// Retrieves a document's fields as a Map from the specified collection and document ID.
  /// Returns null if the document does not exist or if an error occurs.
  Future<Map<String, dynamic>?> getDocument(
    String collectionPath,
    String documentId,
  ) async {
    try {
      final doc = await _firestore.collection(collectionPath).doc(documentId).get();
      return doc.data();
    } catch (e, stackTrace) {
      developer.log(
        'Firestore Read Error in collection $collectionPath for doc $documentId: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'DisputeFirestoreService',
      );
      print('Firestore Read Error: $e');
      return null;
    }
  }

  /// Updates specific fields of an existing document.
  Future<void> updateDocument(
    String collectionPath,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(documentId)
          .update(data);
    } catch (e, stackTrace) {
      developer.log(
        'Firestore Update Error in collection $collectionPath for doc $documentId: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'DisputeFirestoreService',
      );
      print('Firestore Update Error: $e');
    }
  }
}
