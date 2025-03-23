import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yappy/medical_doctor.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/transcription_box.dart';
import 'package:yappy/audiowave_widget.dart';

void main() {
  group('MedicalDoctorPage Tests', () {
    testWidgets('renders MedicalDoctorApp and MedicalDoctorPage correctly',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const MedicalDoctorApp());

      // Assert
      expect(find.byType(MedicalDoctorApp), findsOneWidget);
      expect(find.byType(MedicalDoctorPage), findsOneWidget);
    });

    testWidgets('renders IndustryMenu with correct title and icon',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(home: MedicalDoctorPage()));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(IndustryMenu), findsOneWidget);
      expect(
          find.widgetWithText(IndustryMenu, 'Medical Doctor'), findsOneWidget);
      expect(find.byIcon(Icons.medical_services), findsOneWidget);
    });

    testWidgets('renders AudiowaveWidget and TranscriptionBox',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(home: MedicalDoctorPage()));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AudiowaveWidget), findsOneWidget);
      expect(find.byType(TranscriptionBox), findsOneWidget);
    });
  });
}
