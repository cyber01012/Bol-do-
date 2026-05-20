import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dev/mock_booking_seeder.dart';
import 'dev/mock_provider_seeder.dart';
import 'ui/theme.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/ranking_logs_screen.dart';
import 'ui/screens/provider_listing_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

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

  runApp(const MyApp());
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BolDo AI',
          theme: BolDoTheme.lightTheme,
          darkTheme: BolDoTheme.darkTheme,
          themeMode: currentMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}