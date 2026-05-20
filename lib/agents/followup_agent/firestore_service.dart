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
}
