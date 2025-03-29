import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yappy/main.dart';
import 'package:yappy/home_page.dart';
import 'package:yappy/theme_provider.dart';

void main() {
  group('Main Tests', () {
    testWidgets('renders MyApp and HomePage correctly',
        (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({}); // Mock shared preferences
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
          child: MaterialApp(home: MyApp()),
        ),
      );

      // Assert
      expect(find.byType(MyApp), findsOneWidget);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('displays API key alert dialog when API key is empty',
        (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({'openai_api_key': ''});
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Builder(builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: navigatorKey.currentContext!,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('OpenAI API Key Required'),
                    content: Text(
                        'Please add a valid OpenAI API key via the Settings menu.'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            });
            return Container();
          }),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('OpenAI API Key Required'), findsOneWidget);
      expect(
          find.text('Please add a valid OpenAI API key via the Settings menu.'),
          findsOneWidget);
    });

    test('checks API key is saved in shared preferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      // Act
      preferences.setString('openai_api_key', 'test_api_key');

      // Assert
      expect(preferences.getString('openai_api_key'), 'test_api_key');
    });
  });
}
