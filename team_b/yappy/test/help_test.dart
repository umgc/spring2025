import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yappy/help.dart';
import 'package:yappy/tutorial_page.dart';
import 'package:yappy/theme_provider.dart';

void main() {
  group('HelpApp Widget Tests', () {
    testWidgets('HelpApp renders HelpPage as the home screen',
        (WidgetTester tester) async {
      // Build the widget with a ThemeProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
          child: MaterialApp(home: HelpApp()),
        ),
      );

      expect(find.byType(HelpPage), findsOneWidget);
    });
  });

  group('HelpPage Widget Tests', () {
    testWidgets('HelpPage displays the "Lets Yap about Yappy" title',
        (WidgetTester tester) async {
      // Build the widget with a ThemeProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
          child: MaterialApp(home: HelpPage()),
        ),
      );

      expect(find.text('Lets Yap about Yappy'), findsOneWidget);
    });

    testWidgets('HelpPage displays the welcome message',
        (WidgetTester tester) async {
      // Build the widget with a ThemeProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
          child: MaterialApp(home: HelpPage()),
        ),
      );

      expect(
        find.text(
          'Welcome to Yappy! If this is your first time and need help with using Yappy, please select the button below.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'HelpPage displays "It\'s my first time" button and navigates to TutorialPage',
        (WidgetTester tester) async {
      // Build the widget with a ThemeProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
          child: MaterialApp(home: HelpPage()),
        ),
      );

      expect(find.text('It\'s my first time'), findsOneWidget);

      await tester.tap(find.text('It\'s my first time'));
      await tester.pumpAndSettle();

      expect(find.byType(TutorialPage), findsOneWidget);
    });

    testWidgets(
        'HelpPage displays "Report a problem" button and shows alert dialog',
        (WidgetTester tester) async {
      // Build the widget with a ThemeProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
          child: MaterialApp(home: HelpPage()),
        ),
      );

      expect(find.text('Report a problem'), findsOneWidget);

      await tester.tap(find.text('Report a problem'));
      await tester.pump();

      expect(find.text('Report a Problem'), findsOneWidget);
      expect(find.text('Please call: +1-800-123-4567'), findsOneWidget);
    });

    testWidgets(
        'HelpPage displays "Feedback for the Help Center" button and shows alert dialog',
        (WidgetTester tester) async {
      // Build the widget with a ThemeProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
          child: MaterialApp(home: HelpPage()),
        ),
      );

      final buttonFinder = find.text('Feedback for the Help Center');

      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();

      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pump();

      expect(buttonFinder, findsNWidgets(2));
    });
  });
}
