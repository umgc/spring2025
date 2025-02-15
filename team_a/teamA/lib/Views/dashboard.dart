import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/moodle_api_singleton.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/assessments_view.dart';
import 'package:learninglens_app/Views/course_list.dart';
import 'package:learninglens_app/Views/essays_view.dart';
import 'package:learninglens_app/notifiers/login_notifier.dart';
import 'package:provider/provider.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Learning Lens',
          userprofileurl: MoodleApiSingleton().moodleProfileImage ?? ''),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Large screen (desktop or large tablet)
            return _buildDesktopLayout(context, constraints);
          } else {
            // Small screen (mobile)
            return _buildMobileLayout(context, constraints);
          }
        },
      ),
    );
  }

  // Desktop layout
  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints) {
    final double screenWidth = constraints.maxWidth;

    // Base sizes for left and right buttons
    double baseButtonSize = screenWidth * 0.15;
    double baseButtonFontSize = screenWidth * 0.015;
    double baseDescriptionFontSize = screenWidth * 0.015;

    // Sizes for the middle button (larger than others)
    double middleButtonSize = baseButtonSize * 1.2; // 20% larger
    double middleButtonFontSize = baseButtonFontSize * 1.2;
    double middleDescriptionFontSize = baseDescriptionFontSize * 1.1;

    // Clamp the sizes to reasonable minimum and maximum values
    baseButtonSize = baseButtonSize.clamp(80.0, 150.0);
    baseButtonFontSize = baseButtonFontSize.clamp(12.0, 18.0);
    baseDescriptionFontSize = baseDescriptionFontSize.clamp(12.0, 18.0);

    middleButtonSize = middleButtonSize.clamp(96.0, 180.0);
    middleButtonFontSize = middleButtonFontSize.clamp(14.0, 20.0);
    middleDescriptionFontSize = middleDescriptionFontSize.clamp(13.0, 20.0);

    // Title font size
    double titleFontSize = screenWidth * 0.03;
    titleFontSize = titleFontSize.clamp(20.0, 32.0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 12),
            Text(
              'Welcome, ${MoodleApiSingleton().moodleFirstName ?? 'User'}',
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
    );
  }

  // Mobile layout
  Widget _buildMobileLayout(BuildContext context, BoxConstraints constraints) {
    final double screenWidth = constraints.maxWidth;

    // Base sizes for buttons
    double baseButtonSize = screenWidth * 0.4;
    double baseButtonFontSize = screenWidth * 0.045;
    double baseDescriptionFontSize = screenWidth * 0.04;

    // Sizes for the middle button (larger than others)
    double middleButtonSize = baseButtonSize * 1.1; // 10% larger
    double middleButtonFontSize = baseButtonFontSize * 1.1;
    double middleDescriptionFontSize = baseDescriptionFontSize * 1.05;

    // Clamp the sizes to reasonable minimum and maximum values
    baseButtonSize = baseButtonSize.clamp(80.0, 140.0);
    baseButtonFontSize = baseButtonFontSize.clamp(12.0, 16.0);
    baseDescriptionFontSize = baseDescriptionFontSize.clamp(12.0, 16.0);

    middleButtonSize = middleButtonSize.clamp(88.0, 154.0);
    middleButtonFontSize = middleButtonFontSize.clamp(13.0, 18.0);
    middleDescriptionFontSize = middleDescriptionFontSize.clamp(13.0, 17.0);

    // Title font size
    double titleFontSize = screenWidth * 0.06;
    titleFontSize = titleFontSize.clamp(18.0, 24.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
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
              const SizedBox(height: 12),
              Text(
                'Welcome, ${MoodleApiSingleton().moodleFirstName ?? 'User'}',
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

  Widget _buildGridLayout(BuildContext context, BoxConstraints constraints) {
    final double screenWidth = constraints.maxWidth;

    // Base sizes for buttons
    double baseButtonSize = screenWidth * 0.15;
    double baseButtonFontSize = screenWidth * 0.015;
    double baseDescriptionFontSize = screenWidth * 0.015;

    // Clamp the sizes to reasonable minimum and maximum values
    baseButtonSize = baseButtonSize.clamp(80.0, 150.0);
    baseButtonFontSize = baseButtonFontSize.clamp(12.0, 18.0);
    baseDescriptionFontSize = baseDescriptionFontSize.clamp(12.0, 18.0);

    bool isLoggedin = Provider.of<LoginNotifier>(context).isLoggedIn; // Use provider

    print('isLoggedin: $isLoggedin');

    List<Map<String, dynamic>> buttonData = [
      {
        'title': 'Courses',
        'description': 'View available courses.',
        'onPressed': !isLoggedin ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => CourseList())),
        'color': Colors.blue, // Blue
      },
      {
        'title': 'Essays',
        'description': 'View or grade essays.',
        'onPressed': !isLoggedin ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => EssaysView())),
        'color': Colors.red, // Red
      },
      {
        'title': 'IEP',
        'description': 'Manage Individualized Education Plans.',
        'onPressed': !isLoggedin ? null : () {}, // Add navigation
        'color': Colors.green, // Green
      },
      {
        'title': 'Analytics',
        'description': 'View performance analytics.',
        'onPressed': !isLoggedin ? null : () {}, // Add navigation
        'color': Colors.cyan, // Cyan
      },
      {
        'title': 'Lesson Plan',
        'description': 'Create and manage lesson plans.',
        'onPressed': () {}, // Add navigation
        'color': Colors.purple, // Purple

      },
      {
        'title': 'Assessments',
        'description': 'Create or view assessments.',
        'onPressed': !isLoggedin ? null :  () => Navigator.push(context,MaterialPageRoute(builder: (context) => AssessmentsView())),
        'color': Colors.orange, // Orange
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // First row (2 buttons)
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
              const SizedBox(width: 20),
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
          const SizedBox(height: 20),

          // Second row (2 buttons)
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
              const SizedBox(width: 20),
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
          const SizedBox(height: 20),

          // Third row (2 buttons)
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
              const SizedBox(width: 20),
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

  // Responsive Column for both layouts
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
      children: [
        SizedBox(
          width: buttonSize * 1.5, // Ensure text doesn't overflow
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: descriptionFontSize,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildDashboardButton(
            context, title, buttonSize, buttonFontSize, onPressed, buttonColor),
      ],
    );
  }

  // Widget to build circular buttons
  Widget _buildDashboardButton(
    BuildContext context,
    String title,
    double size,
    double fontSize,
    void Function()? onPressed,
    Color buttonColor
  ) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: buttonColor, // Outer white border color
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
        margin: EdgeInsets.all(size * 0.1), // Adjusted for responsive border
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white, // Inner white color
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
            padding: EdgeInsets.all(size * 0.15), // Responsive padding
            shadowColor: Colors.transparent,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
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
