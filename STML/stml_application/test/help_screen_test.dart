import 'package:memoryminder/src/features/help/presentation/help_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Help Screen Tests', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: HelpScreen()));
    await tester.pumpAndSettle();
    await tester.pump();

    // Verify application's title
    expect(find.text('HELP', skipOffstage: false), findsOneWidget);

    expect(find.text('HELP is on the way!!!'), findsOneWidget);


  });
}
