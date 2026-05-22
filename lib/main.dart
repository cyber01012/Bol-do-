import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'ui/theme.dart';
import 'core/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables for agents
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("⚠️ Dotenv failed to load, proceeding anyway: $e");
  }

  bool firebaseInitialized = false;
  String firebaseInitError = '';

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    firebaseInitError = e.toString();
  }

  runApp(BolDoApp(
    firebaseInitialized: firebaseInitialized,
    firebaseInitError: firebaseInitError,
  ));
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

class BolDoApp extends StatefulWidget {
  final bool firebaseInitialized;
  final String firebaseInitError;

  const BolDoApp({
    super.key,
    required this.firebaseInitialized,
    required this.firebaseInitError,
  });

  @override
  State<BolDoApp> createState() => _BolDoAppState();
}

class _BolDoAppState extends State<BolDoApp> {
  String authStatus = "Initializing security protocols...";

  @override
  void initState() {
    super.initState();
    if (widget.firebaseInitialized) {
      _signInAnonymously();
    } else {
      setState(() {
        authStatus = "Firebase initialization failed: ${widget.firebaseInitError}";
      });
    }
  }

  Future<void> _signInAnonymously() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      print("🔐 Authenticated Anonymously: ${userCredential.user?.uid}");
      setState(() {
        authStatus = "Authenticated as guest.";
      });
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Auth Exception: [${e.code}] ${e.message}");
      setState(() {
        authStatus = "Auth failed: [${e.code}] ${e.message}";
      });
    } catch (e) {
      print("❌ General Authentication Failure: $e");
      setState(() {
        authStatus = "Auth failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'BolDo AI',
          debugShowCheckedModeBanner: false,
          theme: BolDoTheme.lightTheme,
          darkTheme: BolDoTheme.darkTheme,
          themeMode: currentMode,
          home: const MainShell(),
        );
      },
    );
  }
}