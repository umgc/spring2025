import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoryminder/src/features/stml_user_dashboard/presentation/stml_user_dashboard.dart';

void main() {
  testWidgets('STML User Dashboard Tests', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: STMLUserDashboardScreen()));
    await tester.pumpAndSettle();
    await tester.pump();

    // Verify application's title
    expect(find.text('My Dashboard', skipOffstage: false), findsOneWidget);

    // Verify the buttons are visible
    expect(find.widgetWithText(ElevatedButton, "Take Me Home", skipOffstage: false), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "HELP", skipOffstage: false), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Gallery", skipOffstage: false), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "My Tasks", skipOffstage: false), findsOneWidget);

  });
}
