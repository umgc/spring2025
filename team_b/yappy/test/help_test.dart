import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yappy/help.dart';
import 'package:yappy/tutorial_page.dart';

void main() {
  group('HelpApp Widget Tests', () {
    testWidgets('HelpApp renders HelpPage as the home screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const HelpApp());

      expect(find.byType(HelpPage), findsOneWidget);
    });
  });

  group('HelpPage Widget Tests', () {
    testWidgets('HelpPage has the correct background color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpPage(),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color.fromARGB(255, 0, 0, 0));
    });

    testWidgets('HelpPage displays the "Lets Yap about Yappy" title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpPage(),
        ),
      );

      expect(find.text('Lets Yap about Yappy'), findsOneWidget);
    });

    testWidgets('HelpPage displays the welcome message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpPage(),
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
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpPage(),
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
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpPage(),
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
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpPage(),
        ),
      );

      expect(find.text('Feedback for the Help Center'), findsOneWidget);

      await tester.tap(find.text('Feedback for the Help Center'));
      await tester.pump();

      expect(find.text('Feedback for the Help Center'), findsNWidgets(2));
    });
  });
}
