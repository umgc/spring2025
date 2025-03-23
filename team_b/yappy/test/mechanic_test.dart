import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yappy/mechanic.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/transcription_box.dart';
import 'package:yappy/audiowave_widget.dart';

void main() {
  group('MechanicalAidPage Tests', () {
    testWidgets('renders MechanicalAidApp and MechanicalAidPage correctly',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const MechanicalAidApp());

      // Assert
      expect(find.byType(MechanicalAidApp), findsOneWidget);
      expect(find.byType(MechanicalAidPage), findsOneWidget);
    });

    testWidgets('renders IndustryMenu with title and icon',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(home: MechanicalAidPage()));

      // Act
      await tester.pumpAndSettle(); // Ensure all widgets are rendered

      // Assert
      expect(find.byType(IndustryMenu), findsOneWidget);
      expect(find.widgetWithText(IndustryMenu, 'Vehicle Maintenance'),
          findsOneWidget);
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
    });

    testWidgets('displays AudiowaveWidget and TranscriptionBox correctly',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(home: MechanicalAidPage()));

      // Act
      await tester.pumpAndSettle(); // Ensure all widgets are rendered

      // Assert
      expect(find.byType(AudiowaveWidget), findsOneWidget);
      expect(find.byType(TranscriptionBox), findsOneWidget);
    });
  });
}
