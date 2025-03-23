import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yappy/restaurant.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/transcription_box.dart';
import 'package:yappy/audiowave_widget.dart';

void main() {
  group('RestaurantPage Tests', () {
    testWidgets('renders RestaurantPage correctly',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(home: RestaurantPage()));

      // Assert
      expect(find.byType(RestaurantPage), findsOneWidget);
    });

    testWidgets('renders IndustryMenu with correct title and icon',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(home: RestaurantPage()));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(IndustryMenu), findsOneWidget);
      expect(find.widgetWithText(IndustryMenu, 'Restaurant'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });

    testWidgets('renders AudiowaveWidget and TranscriptionBox',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(home: RestaurantPage()));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AudiowaveWidget), findsOneWidget);
      expect(find.byType(TranscriptionBox), findsOneWidget);
    });
  });
}
