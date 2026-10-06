// Basic smoke test for the splash + onboarding flow entry point.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/main.dart';

void main() {
  testWidgets('App starts on the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Splash screen shows the character image while waiting to auto-advance.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
