// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_emergency/main.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame with required parameters
    await tester.pumpWidget(
      const MyApp(
        isLoggedIn: false,
        isBombero: false,
      ),
    );

    // Verify that the login screen is displayed
    expect(find.text('Sistema de Emergencias'), findsOneWidget);
    expect(find.text('Bomberos Rubio'), findsOneWidget);
  });

  testWidgets('App shows user dashboard when logged in as user', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(
        isLoggedIn: true,
        isBombero: false,
      ),
    );

    // Verify user dashboard elements
    await tester.pumpAndSettle();
    // Aquí podrías verificar elementos específicos del UserDashboard
  });

  testWidgets('App shows firefighter dashboard when logged in as bombero', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(
        isLoggedIn: true,
        isBombero: true,
      ),
    );

    // Verify firefighter dashboard elements
    await tester.pumpAndSettle();
    // Aquí podrías verificar elementos específicos del FirefighterDashboard
  });
}