import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yappy/audiowave_widget.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/restaurant.dart';
import 'package:yappy/search_bar_widget.dart';
import 'package:yappy/theme_provider.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/transcription_box.dart';

void main() {
  testWidgets('RestaurantApp should have a RestaurantPage', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: MaterialApp(home: RestaurantPage()),
      ),
    );

    expect(find.byType(RestaurantPage), findsOneWidget);
  });

  testWidgets('RestaurantPage should have a ToolBar', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: MaterialApp(home: RestaurantPage()),
      ),
    );

    expect(find.byType(ToolBar), findsOneWidget);
  });

  testWidgets('RestaurantPage should have a SearchBarWidget and IndustryMenu', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: MaterialApp(home: RestaurantPage()),
      ),
    );

    expect(find.byType(SearchBarWidget), findsOneWidget);
    expect(find.byType(IndustryMenu), findsOneWidget);
  });

  testWidgets('RestaurantPage should have AudiowaveWidget and TranscriptionBox', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: MaterialApp(home: RestaurantPage()),
      ),
    );

    expect(find.byType(AudiowaveWidget), findsOneWidget);
    expect(find.byType(TranscriptionBox), findsOneWidget);
  });
}