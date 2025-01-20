import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/moodle_api_singleton.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Controller/beans.dart';
import '../content_carousel.dart';

//What we need:
//Two carousels, one for essays and the other for assessments.
//Additional information and buttons appear when a card is clicked.
//The essay cards have two buttons leading to submissions and assignment editing pages.
//The assessment cards have a button leading to the assessment editing page.
//Two buttons below that lead to the create essay and create assessment pages.

//Main Page
class ViewCourseContents extends StatefulWidget {
  final Course theCourse;
  ViewCourseContents(this.theCourse);

  @override
  State createState() {
    return _CourseState();
  }
}

class _CourseState extends State<ViewCourseContents> {
  late final String courseName;

  @override
  void initState() {
    super.initState();
    courseName = widget.theCourse.fullName;
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: CustomAppBar(title: 'Course Content', userprofileurl: MoodleApiSingleton().moodleProfileImage ?? ''),
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Keeps everything left-aligned
        children: [
          // Background for "Quizzes"
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.secondary,
            padding: const EdgeInsets.all(8.0), // Padding inside the container
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Space around the container
            child: Text(
              "Quizzes",
              style: TextStyle(
                fontSize: 32, 
                color: Theme.of(context).colorScheme.onSecondary, // Text color set for contrast
              ),
            ),
          ),
          ContentCarousel(
            'assessment', 
            widget.theCourse.quizzes,
            courseId: widget.theCourse.id,
          ),
          
          // Background for "Essays"
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.secondary,
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              "Essays",
              style: TextStyle(
                fontSize: 32, 
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
          ContentCarousel(
            'essay', 
            widget.theCourse.essays,
            courseId: widget.theCourse.id,
          ),
          
          // Responsive layout for the buttons
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Stack buttons vertically for narrow screens
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CreateButton('assessment'),
                    SizedBox(height: 8.0), // Space between buttons
                    CreateButton('essay'),
                  ],
                );
              } else {
                // Show buttons in a row for wide screens
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CreateButton('assessment'),
                    CreateButton('essay'),
                  ],
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}


}
