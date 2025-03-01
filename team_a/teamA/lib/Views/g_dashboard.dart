import 'dart:math';

import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/essays_view.dart';
import 'package:learninglens_app/Views/g_assignment_home.dart';
import 'package:learninglens_app/Views/g_courses.dart';
import 'package:learninglens_app/notifiers/login_notifier.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:provider/provider.dart';

class GoogleTeacherDashboard extends StatelessWidget {
  const GoogleTeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if the user can access the app (logged in + has an LLM key)
    final bool canAccessApp = canUserAccessApp(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Learning Lens',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // 1) The Banner:
          // Show this banner if the user doesn't meet the access requirements
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

          // 2) The Main Content:
          // Use Expanded so the LayoutBuilder can fill the rest of the screen.
          Expanded(
            child: LayoutBuilder(
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
          ),
        ],
      ),
    );
  }

  /// Checks if user is logged in and has an LLM key
  bool canUserAccessApp(BuildContext context) {
    bool isLoggedIn = LocalStorageService.isLoggedIntoGoogle();
    bool hasLLMKey = LocalStorageService.hasLLMKey();
    return isLoggedIn && hasLLMKey;
  }

  // ---------- DESKTOP LAYOUT ----------
  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints) {
    final double screenWidth = constraints.maxWidth;

    // Base sizes for left and right buttons
    double baseButtonSize = screenWidth * 0.15;
    double baseButtonFontSize = screenWidth * 0.015;
    double baseDescriptionFontSize = screenWidth * 0.015;

    // Sizes for the middle button (20% larger)
    double middleButtonSize = baseButtonSize * 1.2;
    double middleButtonFontSize = baseButtonFontSize * 1.2;
    double middleDescriptionFontSize = baseDescriptionFontSize * 1.1;

    // Clamp the sizes to reasonable min/max
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
              'Teacher Google Dashboard',
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
    );
  }

  // ---------- MOBILE LAYOUT ----------
  Widget _buildMobileLayout(BuildContext context, BoxConstraints constraints) {
    final double screenWidth = constraints.maxWidth;

    // Base sizes for buttons
    double baseButtonSize = screenWidth * 0.4;
    double baseButtonFontSize = screenWidth * 0.045;
    double baseDescriptionFontSize = screenWidth * 0.04;

    // Sizes for the middle button (10% larger)
    double middleButtonSize = baseButtonSize * 1.1;
    double middleButtonFontSize = baseButtonFontSize * 1.1;
    double middleDescriptionFontSize = baseDescriptionFontSize * 1.05;

    // Clamp the sizes
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

  // ---------- GRID LAYOUT (Shared by Desktop & Mobile) ----------
  Widget _buildGridLayout(BuildContext context, BoxConstraints constraints) {
    final double screenWidth = constraints.maxWidth;

    // Base sizes
    double baseButtonSize = screenWidth * 0.15;
    double baseButtonFontSize = screenWidth * 0.015;
    double baseDescriptionFontSize = screenWidth * 0.015;

    // Clamp the sizes
    baseButtonSize = baseButtonSize.clamp(80.0, 150.0);
    baseButtonFontSize = baseButtonFontSize.clamp(12.0, 18.0);
    baseDescriptionFontSize = baseDescriptionFontSize.clamp(12.0, 18.0);

    // Determine if user can access the app
    bool canAccessApp = canUserAccessApp(context);

    // Original button data (6 items)
    List<Map<String, dynamic>> buttonData = [
      {
        'title': 'Courses',
        'description': 'View available courses.',
        'onPressed': !canAccessApp
            ? null
            : () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => GoogleCourses())),
        'color': Colors.blue,
      },
      // {
      //   'title': 'Essays',
      //   'description': 'View or grade essays.',
      //   'onPressed': !canAccessApp
      //       ? null
      //       : () => Navigator.push(
      //           context, MaterialPageRoute(builder: (context) => EssaysView())),
      //   'color': Colors.red,
      // },
      // {
      //   'title': 'IEP',
      //   'description': 'Manage Individualized Education Plans.',
      //   'onPressed': !canAccessApp ? null : () {}, // Add navigation
      //   'color': Colors.green,
      // },
      // {
      //   'title': 'Analytics',
      //   'description': 'View performance analytics.',
      //   'onPressed': !canAccessApp ? null : () {}, // Add navigation
      //   'color': Colors.cyan,
      // },
      // {
      //   'title': 'Lesson Plan',
      //   'description': 'Create and manage lesson plans.',
      //   'onPressed': !canAccessApp ? null : () {}, // Add navigation
      //   'color': Colors.purple,
      // },
      {
        'title': 'Assessments',
        'description': 'Create or view assessments.',
        'onPressed': !canAccessApp
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => GoogleClassAssignments())),
        'color': Colors.orange,
      },
    ];

    // The 3x2 grid
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Row 1: (Courses, Essays)
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

          // // Row 2: (IEP, Analytics)
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Expanded(
          //       child: _buildResponsiveColumn(
          //         context,
          //         buttonData[2]['description'],
          //         buttonData[2]['title'],
          //         baseDescriptionFontSize,
          //         baseButtonSize,
          //         baseButtonFontSize,
          //         buttonData[2]['onPressed'],
          //         buttonData[2]['color'],
          //       ),
          //     ),
          //     const SizedBox(width: 20),
          //     Expanded(
          //       child: _buildResponsiveColumn(
          //         context,
          //         buttonData[3]['description'],
          //         buttonData[3]['title'],
          //         baseDescriptionFontSize,
          //         baseButtonSize,
          //         baseButtonFontSize,
          //         buttonData[3]['onPressed'],
          //         buttonData[3]['color'],
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 20),

          // // Row 3: (Lesson Plan, Assessments)
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Expanded(
          //       child: _buildResponsiveColumn(
          //         context,
          //         buttonData[4]['description'],
          //         buttonData[4]['title'],
          //         baseDescriptionFontSize,
          //         baseButtonSize,
          //         baseButtonFontSize,
          //         buttonData[4]['onPressed'],
          //         buttonData[4]['color'],
          //       ),
          //     ),
          //     const SizedBox(width: 20),
          //     Expanded(
          //       child: _buildResponsiveColumn(
          //         context,
          //         buttonData[5]['description'],
          //         buttonData[5]['title'],
          //         baseDescriptionFontSize,
          //         baseButtonSize,
          //         baseButtonFontSize,
          //         buttonData[5]['onPressed'],
          //         buttonData[5]['color'],
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  // Helper widget to build a text description + circular button
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
          width: buttonSize * 1.5, // Ensures text doesn't overflow
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

  // Circular button builder
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
        color: buttonColor, // Outer color
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
        margin: EdgeInsets.all(size * 0.1), // Outer ring
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white, // Inner color
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
