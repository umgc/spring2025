import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yappy/contact_page.dart';
import 'package:yappy/tool_bar.dart';

void main() {
  testWidgets('ContactPage should have a ToolBar and HamburgerDrawer',
      (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(MaterialApp(home: ContactPage()));

    // Verify that ToolBar is in place
    expect(find.byType(ToolBar), findsOneWidget,
        reason: 'ToolBar should be visible');

    // Find the Scaffold widget and trigger openDrawer() on its context
    final scaffoldFinder = find.byType(Scaffold);

    // Use the `tester` to access the Scaffold and open the drawer directly
    final scaffoldState = tester.state<ScaffoldState>(scaffoldFinder);
    scaffoldState.openDrawer(); // This explicitly opens the drawer

    await tester.pumpAndSettle(); // Wait for the drawer to open

    // Verify that the HamburgerDrawer is visible after opening
    expect(find.byType(HamburgerDrawer), findsOneWidget,
        reason: 'HamburgerDrawer should be available');
  });

  testWidgets('Tapping the menu button should open the drawer',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: ContactPage()));

    // Drawer should not be visible initially
    expect(find.byType(Drawer), findsNothing);

    // Tap the menu button (leading icon in AppBar)
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle(); // Wait for animations

    // Drawer should be visible now
    expect(find.byType(Drawer), findsOneWidget);
  });
}
