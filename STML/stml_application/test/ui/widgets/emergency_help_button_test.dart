// test/ui/widgets/emergency_help_button_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoryminder/widgets/emergency_help_button.dart';

void main() {
  group('EmergencyHelpButton', () {
    testWidgets('shows loading state and feedback message when pressed',
        (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EmergencyHelpButton(
                onPressed: () async {
                  wasPressed = true;
                  await Future.delayed(const Duration(seconds: 1));
                  return true;
                },
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);

      // Verify initial state
      expect(find.text('EMERGENCY HELP'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Tap the button
      await tester.tap(buttonFinder);
      await tester.pump();

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      // Verify success state
      expect(find.text('Help is on the way!'), findsOneWidget);
      expect(wasPressed, true);
    });

    testWidgets('displays success message after successful operation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EmergencyHelpButton(
                onPressed: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                  return true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Help is on the way!'), findsOneWidget);
      final successText = find.text('Help is on the way!');
      final textWidget = tester.widget<Text>(successText);
      expect(textWidget.style?.color, Colors.green);
    });

    testWidgets('displays pending message after unconfirmed operation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EmergencyHelpButton(
                onPressed: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                  return false;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Request sent but no confirmation received.'),
        findsOneWidget,
      );
    });

    testWidgets('displays error message on exception',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EmergencyHelpButton(
                onPressed: () async {
                  throw Exception('Test error');
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to send help request. Please try again.'),
        findsOneWidget,
      );
      final errorText =
          find.text('Failed to send help request. Please try again.');
      final textWidget = tester.widget<Text>(errorText);
      expect(textWidget.style?.color, Colors.red);
    });

    testWidgets('is disabled while processing', (WidgetTester tester) async {
      int pressCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EmergencyHelpButton(
                onPressed: () async {
                  pressCount++;
                  await Future.delayed(const Duration(seconds: 1));
                  return true;
                },
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ElevatedButton);

      await tester.tap(buttonFinder);
      await tester.pump();

      // Try to tap again while processing
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(pressCount, 1);
    });

    testWidgets('maintains proper size constraints',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EmergencyHelpButton(
                onPressed: () async => true,
              ),
            ),
          ),
        ),
      );

      final buttonBox = tester.getSize(find.byType(ElevatedButton));
      expect(buttonBox.width, greaterThanOrEqualTo(200));
      expect(buttonBox.height, greaterThanOrEqualTo(60));
    });

    testWidgets('supports custom text messages', (WidgetTester tester) async {
      const customButtonText = 'URGENT HELP';
      const customSuccessMessage = 'Assistance is coming';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EmergencyHelpButton(
                buttonText: customButtonText,
                successMessage: customSuccessMessage,
                onPressed: () async => true,
              ),
            ),
          ),
        ),
      );

      expect(find.text(customButtonText), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text(customSuccessMessage), findsOneWidget);
    });
  });
}
