import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/beans/course.dart';
import '../content_carousel.dart';

class CourseList extends StatefulWidget {
  CourseList({super.key});

  @override
  _CourseListState createState() => _CourseListState();
}

class _CourseListState extends State<CourseList> {
  final LmsInterface api = LmsFactory.getLmsService();
  late Future<List<Course>> courses;
  Course? selectedCourse;

  @override
  void initState() {
    super.initState();
    courses = api.getUserCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Courses',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
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
                return Row(
                  children: [
                    // Left-side course list with border
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        margin: EdgeInsets.all(8.0),
                        child: ListView.builder(
                          itemCount: courseList.length,
                          itemBuilder: (context, index) {
                            final course = courseList[index];
                            return ListTile(
                              title: Text(course.fullName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${course.shortName}${course.courseId}'),
                                  Text('${Course.dateFormatted(course.startdate)} - ${Course.dateFormatted(course.enddate)}'),                 
                                ],
                              ),
                              tileColor: selectedCourse == course 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
                                  : null,
                              onTap: () {
                                setState(() {
                                  selectedCourse = course;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    // Right-side course details (essays and quizzes)
                    Expanded(
                      flex: 2,
                      child: selectedCourse == null
                          ? Center(child: Text('Select a course to view details'))
                          : Column(
                              key: ValueKey(selectedCourse!.id), // Force rebuild on course change
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Essays section
                                Container(
                                  width: double.infinity,
                                  color: Theme.of(context).colorScheme.secondary,
                                  padding: const EdgeInsets.all(8.0),
                                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                  child: Text(
                                    "Essays",
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: Theme.of(context).colorScheme.onSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ContentCarousel(
                                    'essay',
                                    selectedCourse!.essays,
                                    courseId: selectedCourse!.id,
                                  ),
                                ),

                                // Quizzes section
                                Container(
                                  width: double.infinity,
                                  color: Theme.of(context).colorScheme.secondary,
                                  padding: const EdgeInsets.all(8.0),
                                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                  child: Text(
                                    "Quizzes",
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: Theme.of(context).colorScheme.onSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ContentCarousel(
                                    'assessment',
                                    selectedCourse!.quizzes,
                                    courseId: selectedCourse!.id,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }
}
