import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dev/mock_booking_seeder.dart';
import 'dev/mock_provider_seeder.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String statusMessage = 'Firebase Connected Successfully 🚀\nSeeding completed.';

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Execute the seeders
    await MockBookingSeeder.seedOnce();
    await MockProviderSeeder.seedOnce();
  } catch (e) {
    statusMessage = 'Error during initialization or seeding:\n$e';
    print(statusMessage);
  }

  runApp(MyApp(statusMessage: statusMessage));
}

class MyApp extends StatelessWidget {
  final String statusMessage;

  const MyApp({super.key, required this.statusMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('BolDo AI'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}