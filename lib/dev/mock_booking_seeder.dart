import 'package:cloud_firestore/cloud_firestore.dart';

class MockBookingSeeder {
  static Future<void> seedOnce() async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('bookings');
    
    // Check if empty
    final snapshot = await collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      print('Bookings already seeded.');
      return;
    }

    final bookings = [
      {
        'customerId': 'cust1',
        'providerId': 'prov1',
        'service': 'Plumbing',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'customerId': 'cust2',
        'providerId': 'prov2',
        'service': 'Electrical',
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];

    for (final booking in bookings) {
      await collection.add(booking);
    }
    print('Successfully seeded bookings.');
  }
}
