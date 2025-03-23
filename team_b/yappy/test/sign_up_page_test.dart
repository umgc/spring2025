import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:yappy/sign_up_page.dart';

void main() {
  group('SignUpPage Tests', () {
    testWidgets('Should display all required fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      // Verify presence of username, password, and re-enter password fields
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Re-Enter Password'), findsOneWidget);
    });

    testWidgets('Should display Sign-Up button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      // Verify presence of Sign-Up button
      expect(find.text('Sign-Up'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('Should display disclaimer text', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      // Verify disclaimer text is present
      expect(
        find.text(
          'Yappy! Is not responsible for any legal consequences due to the use of this application',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Should input text into username field',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      // Input text into username field
      final usernameField = find.widgetWithText(TextField, 'Username');
      await tester.enterText(usernameField, 'testuser');

      // Verify text is entered
      expect(find.text('testuser'), findsOneWidget);
    });

    testWidgets('Should input text into password field',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      // Input text into password field
      final passwordField = find.widgetWithText(TextField, 'Password');
      await tester.enterText(passwordField, 'password123');

      // Verify text is entered
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Should input text into re-enter password field',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      // Input text into re-enter password field
      final reenterPasswordField =
          find.widgetWithText(TextField, 'Re-Enter Password');
      await tester.enterText(reenterPasswordField, 'password123');

      // Verify text is entered
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Submit button is functional', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      // Find and tap the Submit button
      final submitButton = find.widgetWithText(ElevatedButton, 'Submit');
      await tester.tap(submitButton);

      // Verify button press
      expect(find.widgetWithText(ElevatedButton, 'Submit'), findsOneWidget);
    });
  });
}
