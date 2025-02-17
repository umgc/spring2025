import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/moodle_api_singleton.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Controller/main_controller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learninglens_app/Views/g_assignment_create.dart';
import 'package:learninglens_app/Views/g_assignment_details.dart';
import 'package:learninglens_app/Views/g_assignment_list.dart';
import 'package:learninglens_app/Views/g_quiz_generator.dart';

class GoogleClassAssignments extends StatefulWidget {
  @override
  _GoogleClassAssignmentsState createState() => _GoogleClassAssignmentsState();
}

class _GoogleClassAssignmentsState extends State<GoogleClassAssignments> {
  List<dynamic> _courses = [];
  List<dynamic> _allAssignments = [];
  dynamic _selectedAssignment;
  bool _isLoading = false;
  final MainController _controller = MainController();

  @override
  void initState() {
    super.initState();
    _fetchAllCoursesAndAssignments();
  }

  Future<String?> _getToken() async {
    final token = await _controller.getAccessToken(scopes: [
      'https://www.googleapis.com/auth/classroom.courses.readonly',
      'https://www.googleapis.com/auth/classroom.coursework.me',
      'https://www.googleapis.com/auth/classroom.coursework.students'
          'https://www.googleapis.com/auth/forms.body',
      'https://www.googleapis.com/auth/forms.responses.readonly'
    ]);
    if (token == null) {
      print(
          'Error: No valid OAuth token. Ensure the required scopes are enabled.');
    }
    return token;
  }

  Future<void> _fetchAllCoursesAndAssignments() async {
    setState(() => _isLoading = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final coursesResponse = await http.get(
        Uri.parse('https://classroom.googleapis.com/v1/courses'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (coursesResponse.statusCode == 200) {
        final coursesData =
            jsonDecode(coursesResponse.body)['courses'] as List<dynamic>?;
        if (coursesData != null) {
          _courses = coursesData;
          // Fetch assignments for each course
          for (var course in _courses) {
            await _fetchAssignmentsForCourse(course['id'], token);
          }
        }
      } else {
        print('Courses fetch error: ${coursesResponse.statusCode}');
      }
    } catch (e) {
      print('Error fetching courses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAssignmentsForCourse(String courseId, String token) async {
    try {
      final assignmentsResponse = await http.get(
        Uri.parse(
            'https://classroom.googleapis.com/v1/courses/$courseId/courseWork'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (assignmentsResponse.statusCode == 200) {
        final assignmentsData =
            jsonDecode(assignmentsResponse.body)['courseWork']
                as List<dynamic>?;
        if (assignmentsData != null) {
          setState(() {
            _allAssignments
                .addAll(assignmentsData); // Add to all assignments list
          });
        }
      } else {
        print(
            'Assignments fetch error for course $courseId: ${assignmentsResponse.statusCode}');
      }
    } catch (e) {
      print('Error fetching assignments for course $courseId: $e');
    }
  }

  void _navigateToAddQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateAssessmentGoogle()),
    );
    print('Navigating to Add Quiz page');
  }

  void _navigateToAddAssignment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateAssignmentPage()),
    );
    print('Navigating to Create Assignment page');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Google Classroom',
          userprofileurl: MoodleApiSingleton().moodleProfileImage ?? ''),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    margin: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'All Assignments',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _allAssignments.length,
                            itemBuilder: (context, index) {
                              final assignment = _allAssignments[index];
                              return Card(
                                child: ListTile(
                                  leading: Icon(Icons.assignment),
                                  title:
                                      Text(assignment['title'] ?? 'No title'),
                                  subtitle: Text(assignment['description'] ??
                                      'No description'),
                                  onTap: () {
                                    setState(() {
                                      _selectedAssignment = assignment;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Card(
                    margin: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Assignment Details',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _navigateToAddQuiz,
                                icon: Icon(Icons.quiz),
                                label: Text('Add Quiz'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: _navigateToAddAssignment,
                                icon: Icon(Icons.assignment),
                                label: Text('Add Assignment'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _selectedAssignment != null
                              ? AssignmentDetailsPage(
                                  assignment:
                                      _selectedAssignment) // Use the AssignmentDisplayPage
                              : Center(
                                  child: Text(
                                      'Select an assignment to view details'),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
