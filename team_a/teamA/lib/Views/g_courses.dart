import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/moodle_api_singleton.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Controller/main_controller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learninglens_app/Views/g_assignment_create.dart';
import 'package:learninglens_app/Views/g_quiz_generator.dart';

class GoogleCourses extends StatefulWidget {
  @override
  _GoogleCoursesState createState() => _GoogleCoursesState();
}

class _GoogleCoursesState extends State<GoogleCourses> {
  List<dynamic> _courses = [];
  List<dynamic> _assignments = [];
  bool _isLoading = false;
  final MainController _controller = MainController();
  String selectedCourseId = '';

  @override
  void initState() {
    super.initState();
    _fetchCourses();
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

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    final token = await _getToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://classroom.googleapis.com/v1/courses'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      setState(() => _courses = jsonDecode(response.body)['courses'] ?? []);
    } else {
      print('Courses fetch error: ${response.statusCode}');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchAssignments(String courseId) async {
    setState(() => _isLoading = true);
    final token = await _getToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse(
          'https://classroom.googleapis.com/v1/courses/$courseId/courseWork'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      setState(
          () => _assignments = jsonDecode(response.body)['courseWork'] ?? []);
    } else {
      print('Assignments fetch error: ${response.statusCode}');
      print('Error details: ${response.body}');
    }
    setState(() => _isLoading = false);
  }

  void _navigateToAddQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateAssessmentGoogle()),
    );

    // Implement navigation to add quiz page
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
      // appBar: AppBar(
      //   title: Text(
      //     'Google Classroom',
      //   ),
      //   backgroundColor: Colors.blue,
      // ),
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
                            'Available Courses',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _courses.length,
                            itemBuilder: (context, index) {
                              final course = _courses[index];
                              return Card(
                                color: selectedCourseId == course['id']
                                    ? Colors.blue.shade100
                                    : null,
                                child: ListTile(
                                  leading: Icon(Icons.class_),
                                  title:
                                      Text(course['name'] ?? 'Unnamed Course'),
                                  subtitle: course['description'] != null &&
                                          course['description'].isNotEmpty
                                      ? Text(course['description'])
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'Section: ${course['section'] ?? 'N/A'}'),
                                            Text(
                                                'Status: ${course['status'] ?? 'N/A'}'),
                                            Text(
                                                'Room: ${course['room'] ?? 'N/A'}'),
                                            Text(
                                                'Created: ${course['creationTime'] ?? 'N/A'}'),
                                          ],
                                        ),
                                  onTap: () {
                                    setState(
                                        () => selectedCourseId = course['id']);
                                    _fetchAssignments(course['id']);
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
                            'Assignments',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Add Quiz and Add Assignment buttons in a row
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
                        if (selectedCourseId.isEmpty)
                          Expanded(
                            child: Center(
                              child:
                                  Text('Select a course to view assignments'),
                            ),
                          )
                        else if (_assignments.isEmpty)
                          Expanded(
                            child: Center(
                              child: Text('No assignments found.'),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: _assignments.length,
                              itemBuilder: (context, index) {
                                final assignment = _assignments[index];
                                return Card(
                                  child: ListTile(
                                    leading: Icon(Icons.assignment),
                                    title:
                                        Text(assignment['title'] ?? 'No title'),
                                    subtitle: Text(assignment['description'] ??
                                        'No description'),
                                  ),
                                );
                              },
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
