import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/speech_state.dart';
import 'package:yappy/services/model_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final SpeechState speechState = SpeechState();
  final ModelManager modelManager = ModelManager();
  testWidgets('IndustryMenu displays title and icons', (WidgetTester tester) async {
    // Build the IndustryMenu widget.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IndustryMenu(title: 'Industry Title', icon: Icons.business, speechState: speechState, modelManager: modelManager),
      ),
    ));

    // Verify that the title is displayed.
    expect(find.text('Industry Title'), findsOneWidget);

    // Verify that the chat icon is displayed.
    expect(find.byIcon(Icons.chat), findsOneWidget);

    // Verify that the industry-specific icon is displayed.
    expect(find.byIcon(Icons.business), findsOneWidget);

    // Verify that the transcript history icon is displayed.
    expect(find.byIcon(Icons.file_copy), findsOneWidget);
  });

  testWidgets('IndustryMenu transcript history button shows transcripts', (WidgetTester tester) async {
    // Build the IndustryMenu widget.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IndustryMenu(title: 'Industry Title', icon: Icons.business, speechState: speechState, modelManager: modelManager),
      ),
    ));

    // Tap the transcript history button.
    await tester.tap(find.byIcon(Icons.file_copy));
    await tester.pumpAndSettle();

    // Verify that the transcripts are displayed.
    expect(find.byType(ListTile), findsNWidgets(2));
  });
}