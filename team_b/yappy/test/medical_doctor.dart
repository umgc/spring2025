import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yappy/audiowave_widget.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/medical_doctor.dart';
import 'package:yappy/search_bar_widget.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/transcription_box.dart';

void main() {
  testWidgets('MedicalDoctorApp should have a MedicalDoctorPage', (WidgetTester tester) async {
    await tester.pumpWidget(const MedicalDoctorApp());

    expect(find.byType(MedicalDoctorPage), findsOneWidget);
  });

  testWidgets('MedicalDoctorPage should have a ToolBar', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MedicalDoctorPage()));

    expect(find.byType(ToolBar), findsOneWidget);
  });

  testWidgets('MedicalDoctorPage should have a SearchBarWidget and IndustryMenu', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MedicalDoctorPage()));

    expect(find.byType(SearchBarWidget), findsOneWidget);
    expect(find.byType(IndustryMenu), findsOneWidget);
  });

  testWidgets('MedicalDoctorPage should have AudiowaveWidget and TranscriptionBox', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MedicalDoctorPage()));

    expect(find.byType(AudiowaveWidget), findsOneWidget);
    expect(find.byType(TranscriptionBox), findsOneWidget);
  });
}