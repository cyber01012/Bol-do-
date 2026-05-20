import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveDocument(String collectionPath, String documentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).doc(documentId).set(data, SetOptions(merge: true));
    } catch (e) {
      print('Firestore Error: $e');
      // Intentionally not throwing to prevent blocking the synchronous orchestrator flow
    }
  }
}
