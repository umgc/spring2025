import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yappy/login_page.dart';
import 'package:yappy/sign_up_page.dart';

void main() {
  group('LoginPage Tests', () {
    testWidgets('renders all widgets properly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      // Assert
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('Sign-up'), findsOneWidget);
      expect(find.text('Terms and Conditions'), findsOneWidget);
    });

    testWidgets('navigates to SignUpPage when "Sign-up" button is pressed',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      // Act
      await tester.tap(find.text('Sign-up'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SignUpPage), findsOneWidget);
    });

    testWidgets('ensures TextFields update with input',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      // Act
      await tester.enterText(
          find.widgetWithText(TextField, 'Username'), 'testuser');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'password123');

      // Assert
      final usernameField = find.widgetWithText(TextField, 'Username');
      final passwordField = find.widgetWithText(TextField, 'Password');

      expect((tester.widget(usernameField) as TextField).controller?.text,
          'testuser');
      expect((tester.widget(passwordField) as TextField).controller?.text,
          'password123');
    });
  });
}
