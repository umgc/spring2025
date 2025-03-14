import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/analytics_page.dart';
import 'package:learninglens_app/Views/assessments_view.dart';
import 'package:learninglens_app/Views/course_list.dart';
import 'package:learninglens_app/Views/essays_view.dart';
import 'package:learninglens_app/Views/about_page.dart';
import 'package:learninglens_app/Views/g_lesson_plan.dart';
import 'package:learninglens_app/Views/iep_page.dart';
import 'package:learninglens_app/Views/lesson_plans.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final bool canAccessApp = canUserAccessApp(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Learning Lens',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          if (!canAccessApp)
            Container(
              color: Colors.red[700],
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "This application requires an LMS to be logged in and an LLM Key to function properly.",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return _buildDesktopLayout(context, constraints);
                } else {
                  return _buildMobileLayout(context, constraints);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AboutPage()),
                  );
                },
                child: const Text("About Learning Lens"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool canUserAccessApp(BuildContext context) {
    bool isLoggedIntoGoogleClassroom = LocalStorageService.isLoggedIntoGoogle() && LocalStorageService.hasLLMKey();
    bool isLoggedIntoMoodle = LocalStorageService.isLoggedIntoMoodle() && LocalStorageService.hasLLMKey();
    return isMoodle() ? isLoggedIntoMoodle : isLoggedIntoGoogleClassroom;
  }

  String getClassroom() {
    return LocalStorageService.getSelectedClassroom() == LmsType.MOODLE ? 'Moodle' : 'Google';
  }

  bool isMoodle() {
    print(LocalStorageService.getSelectedClassroom());
    return LocalStorageService.getSelectedClassroom() == LmsType.MOODLE;
  }

  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints) {
    final double screenWidth = constraints.maxWidth;

    double baseButtonSize = screenWidth * 0.15;
    double baseButtonFontSize = screenWidth * 0.015;
    double baseDescriptionFontSize = screenWidth * 0.015;

    double middleButtonSize = baseButtonSize * 1.2;
    double middleButtonFontSize = baseButtonFontSize * 1.2;
    double middleDescriptionFontSize = baseDescriptionFontSize * 1.1;

    baseButtonSize = baseButtonSize.clamp(80.0, 150.0);
    baseButtonFontSize = baseButtonFontSize.clamp(12.0, 18.0);
    baseDescriptionFontSize = baseDescriptionFontSize.clamp(12.0, 18.0);

    middleButtonSize = middleButtonSize.clamp(96.0, 180.0);
    middleButtonFontSize = middleButtonFontSize.clamp(14.0, 20.0);
    middleDescriptionFontSize = middleDescriptionFontSize.clamp(13.0, 20.0);

    double titleFontSize = screenWidth * 0.03;
    titleFontSize = titleFontSize.clamp(20.0, 32.0);

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Teacher ${getClassroom()} Dashboard',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome, ${LmsFactory.getLmsService().firstName ?? 'User'}',
                style: TextStyle(
                  fontSize: titleFontSize * 0.7,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _buildGridLayout(context, constraints),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, BoxConstraints constraints) {
    final double screenWidth = constraints.maxWidth;

    double baseButtonSize = screenWidth * 0.35; // Reduced from 0.4
    double baseButtonFontSize = screenWidth * 0.04; // Reduced from 0.045
    double baseDescriptionFontSize = screenWidth * 0.035; // Reduced from 0.04

    double middleButtonSize = baseButtonSize * 1.1;
    double middleButtonFontSize = baseButtonFontSize * 1.1;
    double middleDescriptionFontSize = baseDescriptionFontSize * 1.05;

    baseButtonSize = baseButtonSize.clamp(70.0, 120.0); // Reduced max size
    baseButtonFontSize = baseButtonFontSize.clamp(10.0, 14.0); // Reduced max size
    baseDescriptionFontSize = baseDescriptionFontSize.clamp(10.0, 14.0); // Reduced max size

    middleButtonSize = middleButtonSize.clamp(77.0, 132.0);
    middleButtonFontSize = middleButtonFontSize.clamp(11.0, 16.0);
    middleDescriptionFontSize = middleDescriptionFontSize.clamp(11.0, 15.0);

    double titleFontSize = screenWidth * 0.06;
    titleFontSize = titleFontSize.clamp(16.0, 22.0); // Reduced max size

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced from 16.0
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Teacher Dashboard',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8), // Reduced from 12
              Text(
                'Welcome, ${LmsFactory.getLmsService().firstName ?? 'User'}',
                style: TextStyle(
                  fontSize: titleFontSize * 0.7,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12), // Reduced from 20
              _buildGridLayout(context, constraints),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context, BoxConstraints constraints) {
    final double screenWidth = constraints.maxWidth;

    double baseButtonSize = screenWidth * 0.15;
    double baseButtonFontSize = screenWidth * 0.015;
    double baseDescriptionFontSize = screenWidth * 0.015;

    baseButtonSize = baseButtonSize.clamp(70.0, 130.0); // Reduced max size
    baseButtonFontSize = baseButtonFontSize.clamp(10.0, 16.0); // Reduced max size
    baseDescriptionFontSize = baseDescriptionFontSize.clamp(10.0, 16.0); // Reduced max size

    bool canAccessApp = canUserAccessApp(context);
    bool isMoodleSelected = isMoodle();

    List<Map<String, dynamic>> buttonData = [
      {
        'title': 'Courses',
        'description': 'View available courses.',
        'onPressed': !canAccessApp
            ? null
            : () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => CourseList())),
        'color': Colors.blue,
      },
      {
        'title': 'Essays',
        'description': 'View or grade essays.',
        'onPressed': !canAccessApp
            ? null
            : () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => EssaysView())),
        'color': Colors.red,
      },
      {
        'title': 'IEP',
        'description': 'Manage Individualized Education Plans.',
        'onPressed': !canAccessApp || !isMoodleSelected
            ? null
            : () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => IepPage())),
        'color': !isMoodleSelected ? Colors.grey : Colors.green,
      },
      {
        'title': 'Analytics',
        'description': 'View performance analytics.',
        'onPressed': !canAccessApp || !isMoodleSelected
            ? null
            : () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => AnalyticsPage())),
        'color': !isMoodleSelected ? Colors.grey : Colors.cyan,
      },
      {
        'title': 'Lesson Plan',
        'description': 'Create and manage lesson plans.',
        'onPressed': !canAccessApp
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => !isMoodleSelected
                        ? GoogleLessonPlans()
                        : LessonPlans(),
                  ),
                ),
        'color': Colors.purple,
      },
      {
        'title': 'Assessments',
        'description': 'Create or view assessments.',
        'onPressed': !canAccessApp
            ? null
            : () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => AssessmentsView())),
        'color': Colors.orange,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(12.0), // Reduced from 16.0
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _buildResponsiveColumn(
                  context,
                  buttonData[0]['description'],
                  buttonData[0]['title'],
                  baseDescriptionFontSize,
                  baseButtonSize,
                  baseButtonFontSize,
                  buttonData[0]['onPressed'],
                  buttonData[0]['color'],
                ),
              ),
              const SizedBox(width: 12), // Reduced from 20
              Expanded(
                child: _buildResponsiveColumn(
                  context,
                  buttonData[1]['description'],
                  buttonData[1]['title'],
                  baseDescriptionFontSize,
                  baseButtonSize,
                  baseButtonFontSize,
                  buttonData[1]['onPressed'],
                  buttonData[1]['color'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced from 20
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _buildResponsiveColumn(
                  context,
                  buttonData[2]['description'],
                  buttonData[2]['title'],
                  baseDescriptionFontSize,
                  baseButtonSize,
                  baseButtonFontSize,
                  buttonData[2]['onPressed'],
                  buttonData[2]['color'],
                ),
              ),
              const SizedBox(width: 12), // Reduced from 20
              Expanded(
                child: _buildResponsiveColumn(
                  context,
                  buttonData[3]['description'],
                  buttonData[3]['title'],
                  baseDescriptionFontSize,
                  baseButtonSize,
                  baseButtonFontSize,
                  buttonData[3]['onPressed'],
                  buttonData[3]['color'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced from 20
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _buildResponsiveColumn(
                  context,
                  buttonData[4]['description'],
                  buttonData[4]['title'],
                  baseDescriptionFontSize,
                  baseButtonSize,
                  baseButtonFontSize,
                  buttonData[4]['onPressed'],
                  buttonData[4]['color'],
                ),
              ),
              const SizedBox(width: 12), // Reduced from 20
              Expanded(
                child: _buildResponsiveColumn(
                  context,
                  buttonData[5]['description'],
                  buttonData[5]['title'],
                  baseDescriptionFontSize,
                  baseButtonSize,
                  baseButtonFontSize,
                  buttonData[5]['onPressed'],
                  buttonData[5]['color'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveColumn(
    BuildContext context,
    String description,
    String title,
    double descriptionFontSize,
    double buttonSize,
    double buttonFontSize,
    void Function()? onPressed,
    Color buttonColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: buttonSize * 1.5,
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: descriptionFontSize,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 8), // Reduced from 10
        _buildDashboardButton(
          context,
          title,
          buttonSize,
          buttonFontSize,
          onPressed,
          buttonColor,
        ),
      ],
    );
  }

  Widget _buildDashboardButton(
    BuildContext context,
    String title,
    double size,
    double fontSize,
    void Function()? onPressed,
    Color buttonColor,
  ) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: buttonColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey[500]!,
            offset: const Offset(4, 4),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(size * 0.1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey[600]!,
              offset: const Offset(4, 4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Colors.transparent,
            padding: EdgeInsets.all(size * 0.15),
            shadowColor: Colors.transparent,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}