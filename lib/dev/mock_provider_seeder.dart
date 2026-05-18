import 'package:cloud_firestore/cloud_firestore.dart';

class MockProviderSeeder {
  static Future<void> seedOnce() async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('providers');

    final providers = [
      {
        'id': 'prov1',
        'name': 'Ali Plumber',
        'service': 'Plumbing',
        'rating': 4.8,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'prov2',
        'name': 'Sara Electrician',
        'service': 'Electrical',
        'rating': 4.9,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'prov3',
        'name': 'John Carpenter',
        'service': 'Carpentry',
        'rating': 4.7,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'prov4',
        'name': 'Ayesha Cleaner',
        'service': 'Cleaning',
        'rating': 5.0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'prov5',
        'name': 'Zain Painter',
        'service': 'Painting',
        'rating': 4.6,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'prov6',
        'name': 'Fatima AC Repair',
        'service': 'AC Repair',
        'rating': 4.9,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'prov7',
        'name': 'Bilal Handyman',
        'service': 'General',
        'rating': 4.5,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'prov8',
        'name': 'Hira Electrician',
        'service': 'Electrical',
        'rating': 4.8,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'prov9',
        'name': 'Omar Plumber',
        'service': 'Plumbing',
        'rating': 4.7,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'prov10',
        'name': 'Sana Cleaner',
        'service': 'Cleaning',
        'rating': 4.9,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'prov11',
        'name': 'Tariq Carpenter',
        'service': 'Carpentry',
        'rating': 4.6,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'prov12',
        'name': 'Rabia Painter',
        'service': 'Painting',
        'rating': 4.8,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'prov13',
        'name': 'Usman AC Repair',
        'service': 'AC Repair',
        'rating': 4.7,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'prov14',
        'name': 'Nadia Handyman',
        'service': 'General',
        'rating': 4.8,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'prov15',
        'name': 'Aliya Plumber',
        'service': 'Plumbing',
        'rating': 4.9,
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];

    for (final provider in providers) {
      // Using .set() will overwrite existing ones with the same ID or create new ones
      await collection.doc(provider['id'] as String).set(provider);
    }
    print('Successfully seeded 15 providers.');
  }
}
