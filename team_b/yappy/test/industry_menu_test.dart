import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yappy/industry_menu.dart';

void main() {
  testWidgets('IndustryMenu displays title and icons', (WidgetTester tester) async {
    // Build the IndustryMenu widget.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IndustryMenu(title: 'Industry Title', icon: Icons.business),
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
        body: IndustryMenu(title: 'Industry Title', icon: Icons.business),
      ),
    ));

    // Tap the transcript history button.
    await tester.tap(find.byIcon(Icons.file_copy));
    await tester.pump();

    // Verify that the transcripts are displayed.
    expect(find.byIcon(Icons.description), findsNWidgets(2));
  });
}