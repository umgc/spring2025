import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yappy/home_page.dart';
import 'package:yappy/theme_provider.dart';
import 'package:yappy/tutorial_page.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('HomePage Tests', () {
    testWidgets('displays all buttons on the HomePage',
        (WidgetTester tester) async {
            // Build the widget with a ThemeProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
          child: MaterialApp(home: HomePage()),
        ),
      );

      // Assert
      expect(find.text('Restaurant'), findsOneWidget);
      expect(find.text('Vehicle Maintenance'), findsOneWidget);
      expect(find.text('Medical Doctor'), findsOneWidget);
      expect(find.text('Medical Patient'), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('navigates to TutorialPage on first-time user dialog "Yes"',
        (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({'isFirstTime': true});
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
          child: MaterialApp(home: HomePage()),
        ),
      );

      // Act
      await tester.pump();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TutorialPage), findsOneWidget);
    });

    testWidgets(
        'does not show first-time user dialog if "isFirstTime" is false',
        (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({'isFirstTime': false});
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
          child: MaterialApp(home: HomePage()),
        ),
      );

      // Assert
      expect(find.text('Welcome!'), findsNothing);
    });
  });
}
