import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:boldo_ai/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setupFirebaseMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('BolDo App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BolDoApp(
      firebaseInitialized: true,
      firebaseInitError: '',
    ));

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

void setupFirebaseMocks() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_core'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'Firebase#initializeCore') {
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'fake_key',
              'appId': 'fake_app_id',
              'messagingSenderId': 'fake_sender_id',
              'projectId': 'fake_project_id',
            },
            'pluginConstants': {},
          }
        ];
      }

      if (methodCall.method == 'Firebase#initializeApp') {
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'fake_key',
            'appId': 'fake_app_id',
            'messagingSenderId': 'fake_sender_id',
            'projectId': 'fake_project_id',
          },
            'pluginConstants': {},
        };
      }

      return null;
    },
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/cloud_firestore'),
    (MethodCall methodCall) async {
      return null;
    },
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_auth'),
    (MethodCall methodCall) async {
      return {
        'user': {
          'uid': 'fake_uid',
          'isAnonymous': true,
        }
      };
    },
  );
}