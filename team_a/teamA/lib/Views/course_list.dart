import 'package:flutter/material.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/course_content.dart';
import 'package:learninglens_app/Controller/beans.dart';
import '../Api/moodle_api_singleton.dart';

// This is the course list UI
class CourseList extends StatelessWidget {
  final MoodleApiSingleton api = MoodleApiSingleton();
  late final Future<List<Course>> courses;

  CourseList({super.key}) {
    courses = api.getUserCourses();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Courses', userprofileurl: MoodleApiSingleton().moodleProfileImage ?? ''),
      body: FutureBuilder<List<Course>>(
        future: courses,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading courses'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No courses found'));
          } else {
            final courseList = snapshot.data!;

            return LayoutBuilder(
              builder: (context, constraints) {
                // Calculate number of columns based on screen width
                int columns = constraints.maxWidth > 600 ? 2 : 1;

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns, // 1 column for narrow, 2 for wide
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3, // Aspect ratio for the cards
                  ),
                  itemCount: courseList.length,
                  itemBuilder: (context, index) {
                    final course = courseList[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          // Button onPressed Action (e.g., navigate to course details)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewCourseContents(course),
                            ),
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.secondaryContainer),
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                                side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3.0, // Adjust the width to make the border thicker
                                ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            course.fullName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            course.shortName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
