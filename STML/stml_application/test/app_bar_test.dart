import 'package:memoryminder/src/features/caregiver-dashboard/presentation/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  testWidgets('Custom App Bar Tests', (WidgetTester tester) async {
    const appBarTitle = 'UNIT TEST';
    const appBar = CustomAppBar(
      title: appBarTitle,
    );

    // Build the widget to be tested
    await tester.pumpWidget(MaterialApp(home: Scaffold(appBar: appBar)));

    expect(find.text(appBarTitle, skipOffstage: false), findsOneWidget);
  });
}
