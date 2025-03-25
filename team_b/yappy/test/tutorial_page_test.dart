import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/transcription_box.dart';
import 'package:yappy/tutorial_page.dart';
import 'package:yappy/home_page.dart';

void main() {
  group('TutorialPage Tests', () {
    testWidgets('Should display ToolBar and Drawer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TutorialPage(),
        ),
      );

      // Verify ToolBar is displayed
      expect(find.byType(ToolBar), findsOneWidget);

      // Verify HamburgerDrawer is present
      final hamburgerIcon = find.byIcon(Icons.menu);
      await tester.tap(hamburgerIcon);
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('Should show first tutorial popup on load',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TutorialPage(),
        ),
      );

      // Wait for post-frame callback to execute
      await tester.pumpAndSettle();

      // Verify first popup is shown
      expect(
        find.text(
            "The button of the left is the Record button that allows you to record conversations and get a transcript in return."),
        findsOneWidget,
      );
    });

    testWidgets('Should navigate through tutorial popups',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TutorialPage(),
        ),
      );

      // Wait for first popup
      await tester.pumpAndSettle();
      expect(
          find.text(
              "The button of the left is the Record button that allows you to record conversations and get a transcript in return."),
          findsOneWidget);

      // Tap Next on first popup
      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      expect(
          find.text(
              "The second button will show you the days transcripts with broken down into details."),
          findsOneWidget);

      // Tap Next on second popup
      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      expect(
          find.text(
              "The third button will show you all transcripts and allow you to search, share, upload, download, and delete."),
          findsOneWidget);

      // Tap Next on third popup
      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();
      expect(
          find.text(
              "The fourth button will bring you to a chatbot that can search your transcripts to provide you information."),
          findsOneWidget);

      // Tap Finish on fourth popup
      await tester.tap(find.text("Finish"));
      await tester.pumpAndSettle();

      // Verify navigation to HomePage
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('Should display IndustryMenu and TranscriptionBox',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TutorialPage(),
        ),
      );

      // Verify IndustryMenu is displayed
      expect(find.byType(IndustryMenu), findsOneWidget);

      // Verify TranscriptionBox is displayed
      expect(find.byType(TranscriptionBox), findsOneWidget);
    });
  });
}
