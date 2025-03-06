// test/ui/widgets/emergency_help_button_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoryminder/widgets/emergency_help_button.dart';

void main() {
  group('EmergencyHelpButton', () {
    testWidgets('shows loading state when pressed',
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

      await tester.tap(buttonFinder);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(wasPressed, true);
    });

    testWidgets('displays success state after successful operation',
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
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('displays error state after failed operation',
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
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.error), findsNothing);
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
      expect(buttonBox.height, greaterThanOrEqualTo(50));
    });
  });
}
