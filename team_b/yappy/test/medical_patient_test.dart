import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yappy/medical_patient.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/transcription_box.dart';
import 'package:yappy/audiowave_widget.dart';

void main() {
  group('MedicalPatientPage Tests', () {
    testWidgets('renders MedicalPatientApp and MedicalPatientPage correctly',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const MedicalPatientApp());

      // Assert
      expect(find.byType(MedicalPatientApp), findsOneWidget);
      expect(find.byType(MedicalPatientPage), findsOneWidget);
    });

    testWidgets('renders IndustryMenu with correct title and icon',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(home: MedicalPatientPage()));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(IndustryMenu), findsOneWidget);
      expect(
          find.widgetWithText(IndustryMenu, 'Medical Patient'), findsOneWidget);
      expect(find.byIcon(Icons.local_pharmacy), findsOneWidget);
    });

    testWidgets('renders AudiowaveWidget and TranscriptionBox correctly',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(home: MedicalPatientPage()));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AudiowaveWidget), findsOneWidget);
      expect(find.byType(TranscriptionBox), findsOneWidget);
    });
  });
}
