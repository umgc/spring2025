import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learninglens_app/Views/dashboard.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await dotenv.load(fileName: ".env");
    await LocalStorageService.init();
  });

  testWidgets('Buttons should be disabled when user cannot access the app', (WidgetTester tester) async {
    // Manually override static methods

    // except Local
    expect(LocalStorageService.isLoggedIntoMoodle(), false);

    await tester.pumpWidget(
      const MaterialApp(
        home: TeacherDashboard(),
      ),
    );

    // Find all buttons
    final coursesButton = find.text('Courses');
    final essaysButton = find.text('Essays');
    final iepButton = find.text('IEP');
    final analyticsButton = find.text('Analytics');
    final lessonPlanButton = find.text('Lesson Plan');
    final assessmentsButton = find.text('Assessments');

    // Verify that all buttons are disabled, to verify this is working. change isNull to isNotNull. 
    expect(tester.widget<ElevatedButton>(find.ancestor(of: coursesButton, matching: find.byType(ElevatedButton))).onPressed, isNull);
    expect(tester.widget<ElevatedButton>(find.ancestor(of: essaysButton, matching: find.byType(ElevatedButton))).onPressed, isNull);
    expect(tester.widget<ElevatedButton>(find.ancestor(of: iepButton, matching: find.byType(ElevatedButton))).onPressed, isNull);
    expect(tester.widget<ElevatedButton>(find.ancestor(of: analyticsButton, matching: find.byType(ElevatedButton))).onPressed, isNull);
    expect(tester.widget<ElevatedButton>(find.ancestor(of: lessonPlanButton, matching: find.byType(ElevatedButton))).onPressed, isNull);
    expect(tester.widget<ElevatedButton>(find.ancestor(of: assessmentsButton, matching: find.byType(ElevatedButton))).onPressed, isNull);
  });
}
