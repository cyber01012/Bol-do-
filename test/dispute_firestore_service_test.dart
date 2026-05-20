import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:boldo_ai/agents/dispute_agent/firestore_service.dart';

class FakeFirebaseFirestore implements FirebaseFirestore {
  final Map<String, FakeCollectionReference> collections = {};
  bool throwOnAccess = false;

  @override
  FakeCollectionReference collection(String collectionPath) {
    if (throwOnAccess) {
      throw FirebaseException(plugin: 'cloud_firestore', message: 'Simulated connection failure');
    }
    return collections.putIfAbsent(collectionPath, () => FakeCollectionReference(collectionPath, this));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final String path;
  final FakeFirebaseFirestore firestoreInstance;
  final Map<String, FakeDocumentReference> documents = {};

  FakeCollectionReference(this.path, this.firestoreInstance);

  @override
  FakeDocumentReference doc([String? path]) {
    final docId = path ?? 'temp_id';
    return documents.putIfAbsent(docId, () => FakeDocumentReference(docId, this));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final String id;
  final FakeCollectionReference collectionReference;
  Map<String, dynamic>? data;

  FakeDocumentReference(this.id, this.collectionReference);

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (collectionReference.firestoreInstance.throwOnAccess) {
      throw FirebaseException(plugin: 'cloud_firestore', message: 'Simulated set failure');
    }
    if (options?.merge == true && this.data != null) {
      this.data!.addAll(data);
    } else {
      this.data = Map<String, dynamic>.from(data);
    }
  }

  @override
  Future<FakeDocumentSnapshot> get([GetOptions? options]) async {
    if (collectionReference.firestoreInstance.throwOnAccess) {
      throw FirebaseException(plugin: 'cloud_firestore', message: 'Simulated get failure');
    }
    return FakeDocumentSnapshot(id, data);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    if (collectionReference.firestoreInstance.throwOnAccess) {
      throw FirebaseException(plugin: 'cloud_firestore', message: 'Simulated update failure');
    }
    if (this.data == null) {
      throw FirebaseException(plugin: 'cloud_firestore', message: 'Document does not exist');
    }
    this.data!.addAll(Map<String, dynamic>.from(data));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic>? _data;

  FakeDocumentSnapshot(this.id, this._data);

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('FirestoreService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreService firestoreService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      firestoreService = FirestoreService(firestore: fakeFirestore);
    });

    test('saveDocument successfully creates/merges a document', () async {
      final docData = {'name': 'Dispute Item', 'status': 'open'};
      await firestoreService.saveDocument('disputes', 'disp_1', docData);

      final docRef = fakeFirestore.collection('disputes').doc('disp_1');
      expect(docRef.data, isNotNull);
      expect(docRef.data!['name'], 'Dispute Item');
      expect(docRef.data!['status'], 'open');

      // Test merge logic
      await firestoreService.saveDocument('disputes', 'disp_1', {'status': 'closed'});
      expect(docRef.data!['name'], 'Dispute Item');
      expect(docRef.data!['status'], 'closed');
    });

    test('saveDocument handles errors gracefully', () async {
      fakeFirestore.throwOnAccess = true;

      // Should not throw, but print/log error
      await firestoreService.saveDocument('disputes', 'disp_1', {'key': 'val'});

      // Since throwOnAccess is true, the collection won't have the doc set.
      fakeFirestore.throwOnAccess = false;
      final docRef = fakeFirestore.collection('disputes').doc('disp_1');
      expect(docRef.data, isNull);
    });

    test('getDocument returns data successfully', () async {
      final docRef = fakeFirestore.collection('disputes').doc('disp_2');
      docRef.data = {'amount': 150.0, 'currency': 'PKR'};

      final retrieved = await firestoreService.getDocument('disputes', 'disp_2');
      expect(retrieved, isNotNull);
      expect(retrieved!['amount'], 150.0);
      expect(retrieved['currency'], 'PKR');
    });

    test('getDocument returns null on error', () async {
      fakeFirestore.throwOnAccess = true;
      final retrieved = await firestoreService.getDocument('disputes', 'disp_2');
      expect(retrieved, isNull);
    });

    test('updateDocument updates fields successfully', () async {
      final docRef = fakeFirestore.collection('disputes').doc('disp_3');
      docRef.data = {'category': 'refund', 'priority': 'low'};

      await firestoreService.updateDocument('disputes', 'disp_3', {'priority': 'high'});
      expect(docRef.data!['category'], 'refund');
      expect(docRef.data!['priority'], 'high');
    });

    test('updateDocument handles errors gracefully', () async {
      fakeFirestore.throwOnAccess = true;
      // Should not throw
      await firestoreService.updateDocument('disputes', 'disp_3', {'priority': 'high'});
    });
  });
}
