import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/care_recipient_profile.dart';

void main() {
  testWidgets('Care Recipient Profile Screen Tests', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    const careRecipientId = '1';
    final careRecipientData = {
    'firstName': 'Unit', 'lastName': 'Test', 'emergencyContacts': []};

    await tester.pumpWidget(MaterialApp(
      home: CareRecipientProfileScreen(
        careRecipientId: careRecipientId,
        careRecipientData: careRecipientData,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.pump();

    // Verify application's title
    expect(find.text('Recipient Profile', skipOffstage: false), findsOneWidget);


    // Verify the buttons are visible
    expect(find.widgetWithText(ElevatedButton, "Health Metrics", skipOffstage: false), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Tasks", skipOffstage: false), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Location", skipOffstage: false), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Update Profile", skipOffstage: false), findsOneWidget);


  });
}
