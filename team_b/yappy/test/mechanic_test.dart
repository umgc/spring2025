import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yappy/audiowave_widget.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/mechanic.dart';
import 'package:yappy/search_bar_widget.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/transcription_box.dart';

void main() {
  testWidgets('MechanicalAidApp should have a MechanicalAidPage', (WidgetTester tester) async {
    await tester.pumpWidget(const MechanicalAidApp());

    expect(find.byType(MechanicalAidPage), findsOneWidget);
  });

  testWidgets('MechanicalAidPage should have a ToolBar', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MechanicalAidPage()));

    expect(find.byType(ToolBar), findsOneWidget);
  });

  testWidgets('MechanicalAidPage should have a SearchBarWidget and IndustryMenu', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MechanicalAidPage()));

    expect(find.byType(SearchBarWidget), findsOneWidget);
    expect(find.byType(IndustryMenu), findsOneWidget);
  });

  testWidgets('MechanicalAidPage should have AudiowaveWidget and TranscriptionBox', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MechanicalAidPage()));

    expect(find.byType(AudiowaveWidget), findsOneWidget);
    expect(find.byType(TranscriptionBox), findsOneWidget);
  });
}