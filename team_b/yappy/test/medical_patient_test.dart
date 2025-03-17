import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yappy/audiowave_widget.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/medical_patient.dart';
import 'package:yappy/search_bar_widget.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/transcription_box.dart';

void main() {
  testWidgets('MedicalPatientApp should have a MedicalPatientPage', (WidgetTester tester) async {
    await tester.pumpWidget(const MedicalPatientApp());

    expect(find.byType(MedicalPatientPage), findsOneWidget);
  });

  testWidgets('MedicalPatientPage should have a ToolBar', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MedicalPatientPage()));

    expect(find.byType(ToolBar), findsOneWidget);
  });

  testWidgets('MedicalPatientPage should have a SearchBarWidget and IndustryMenu', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MedicalPatientPage()));

    expect(find.byType(SearchBarWidget), findsOneWidget);
    expect(find.byType(IndustryMenu), findsOneWidget);
  });

  testWidgets('MedicalPatientPage should have AudiowaveWidget and TranscriptionBox', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MedicalPatientPage()));

    expect(find.byType(AudiowaveWidget), findsOneWidget);
    expect(find.byType(TranscriptionBox), findsOneWidget);
  });
}