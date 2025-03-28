import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yappy/theme_provider.dart';
import 'package:yappy/transcription_box.dart';

void main() {
  group('TranscriptionBox Tests', () {
    late TextEditingController textEditingController;

    setUp(() {
      textEditingController = TextEditingController();
    });

    testWidgets('Should display the transcription box',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
            child: MaterialApp(home: Scaffold(
              body: TranscriptionBox(controller: textEditingController),
            ),
          ),
        ),
      );

      // Verify the transcription box is displayed
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Transcription will appear here...'), findsOneWidget);
    });

    testWidgets('Should update text in transcription box',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
            child: MaterialApp(home: Scaffold(
              body: TranscriptionBox(controller: textEditingController),
            ),
          ),
        ),
      );

      // Set text in the controller
      textEditingController.text = 'Sample transcription text';
      await tester.pumpAndSettle();

      // Verify the text is displayed
      expect(find.text('Sample transcription text'), findsOneWidget);
    });

    testWidgets('Should display scroll bar when content overflows',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
            child: MaterialApp(home: Scaffold(
              body: TranscriptionBox(controller: textEditingController),
            ),
          ),
        ),
      );

      // Add long text to simulate overflow
      textEditingController.text = 'Line 1\n' * 50;
      await tester.pumpAndSettle();

      // Verify scroll bar is visible
      expect(find.byType(Scrollbar), findsOneWidget);
    });
  });
}
