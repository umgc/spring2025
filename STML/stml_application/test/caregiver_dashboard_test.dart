import 'package:firebase_core/firebase_core.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/caregiver-dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Caregiver Dashboard Tests', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: CaregiverDashboardScreen()));
    await tester.pumpAndSettle();
    await tester.pump();
    TestWidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp();


    // Verify application's title
    expect(find.text('Caregiver Dashboard', skipOffstage: false), findsOneWidget);

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Care Recipients'), findsOneWidget);
    // Verify the task buttons are visible
    expect(find.widgetWithText(ElevatedButton, "Add New Care Recipient", skipOffstage: false), findsOneWidget);

  });
}
