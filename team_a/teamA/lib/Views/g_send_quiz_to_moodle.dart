import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/google_classroom/google_lms_service.dart'; // Import GoogleApiService
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Controller/g_bean.dart';
import 'package:learninglens_app/Views/dashboard.dart';
import 'package:learninglens_app/Views/g_courses.dart';
import 'package:learninglens_app/controller/main_controller.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import '../Api/lms/moodle/moodle_lms_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class QuizSendToGoogle extends StatefulWidget {
  final Quiz quiz;
  QuizSendToGoogle({required this.quiz});

  @override
  QuizSendToGoogleState createState() => QuizSendToGoogleState();
}

class QuizSendToGoogleState extends State<QuizSendToGoogle> {
  // Submission form dates
  String selectedDaySubmission = '01';
  String selectedMonthSubmission = 'January';
  String selectedYearSubmission = '2025';
  String selectedHourSubmission = '00';
  String selectedMinuteSubmission = '00';
  late String quizasxml;
  late MoodleLmsService api;
  //List<Course> courses = [];
  String selectedCourse = 'Select a course';

  List<GCourse> courses = []; // Change from List<dynamic>
  bool _isLoading = false;
  final MainController _controller = MainController();

  @override
  void initState() {
    super.initState();
    quizNameController = TextEditingController(text: widget.quiz.name ?? '');
    quizQuestionsController = TextEditingController();
    quizasxml = widget.quiz.toXmlString();
    _fetchCourses();
  }

  Future<String?> _getToken() async {
    final token = LocalStorageService.getGoogleAccessToken();
    if (token == null) {
      print(
          'Error: No valid OAuth token. Ensure the required scopes are enabled.');
    }
    return token;
  }

  Future<void> _fetchCourses() async {
    print("Fetching courses... inside _fetchCourses");
    setState(() => _isLoading = true);
    final token = await _getToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://classroom.googleapis.com/v1/courses'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<GCourse> loadedCourses = (data['courses'] as List)
          .map((courseJson) => GCourse.fromJson(courseJson))
          .toList();

      setState(() => courses = loadedCourses);
    } else {
      print('Courses fetch error: ${response.statusCode}');
    }
    setState(() => _isLoading = false);
  }

  // Dropdown to display courses with "Select a course" as the default option
  DropdownButtonFormField<String> _buildCourseDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCourse == 'Select a course'
          ? null
          : selectedCourse, // Set initial value to null if 'Select a course'
      decoration: InputDecoration(
        labelText: 'Course name',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value == 'Select a course') {
          return 'Please select a course';
        }
        return null;
      },
      onChanged: (String? newValue) {
        setState(() {
          selectedCourse = newValue!;
        });
        debugPrint('Selected course: $selectedCourse');
      },
      items: [
        DropdownMenuItem<String>(
          value: 'Select a course',
          child: Text('Select a course'),
        ),
        // ...courses.map<DropdownMenuItem<String>>((Course course) {
        ...courses.map((course) {
          // Remove explicit <DropdownMenuItem<String>> type parameter

          return DropdownMenuItem<String>(
            value: course.id.toString(),
            child: Text(course.fullName),
          );
        }),
      ],
      isExpanded: true,
    );
  }

  // Due date selection
  String selectedDayDue = '01';
  String selectedMonthDue = 'January';
  String selectedYearDue = '2025';
  String selectedHourDue = '00';
  String selectedMinuteDue = '00';

  // Checkbox states
  bool isSubmissionEnabled = true;
  bool isDueDateEnabled = true;
  // Lists for dropdowns
  List<String> days =
      List.generate(31, (index) => (index + 1).toString().padLeft(2, '0'));
  List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  List<String> years = ['2025', '2026', '2027'];
  List<String> hours =
      List.generate(24, (index) => index.toString().padLeft(2, '0'));
  List<String> minutes =
      List.generate(60, (index) => index.toString().padLeft(2, '0'));
  // Initial selected values for dropdowns
  String selectedCategory = 'No Category Selected';
  String selectedAttempt = 'No attempt limit';
  String selectedGradingMethod = 'No grading method selected';

  // Lists of static items for dropdowns
  var categoryItems = [
    'No Category Selected',
    'Category 1',
    'Category 2',
    'Category 3'
  ];
  var attemptItems = [
    'No attempt limit',
    'Unlimited',
    'First',
    'Second',
    'Last'
  ];
  var gradingMethodItems = [
    'No grading method selected',
    'Highest Grade',
    'Average Grade',
    'Low Grade'
  ];

  late TextEditingController quizNameController;
  TextEditingController gradeController = TextEditingController();
  late TextEditingController quizQuestionsController;
  TextEditingController quizSectionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Assign Assessment',
          userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Text(
                  'Send Quiz to Google Classroom',
                  textAlign: TextAlign
                      .center, // Changed from textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.normal),
                ),
              ),
            ),
            SizedBox(height: 30),

            sectionTitle(title: 'Course Name'),
            _buildCourseDropdown(),

            SizedBox(height: 15),

            sectionTitle(title: 'Quiz Name'),
            SizedBox(height: 15),
            TextField(
              controller: quizNameController,
              decoration: InputDecoration(
                labelText: 'Quiz name',
                border: OutlineInputBorder(),
              ),
              enabled: false,
            ),
            SizedBox(height: 15),

            sectionTitle(title: 'Section Number'),
            SizedBox(height: 15),
            TextField(
              controller: quizSectionController,
              decoration: InputDecoration(
                labelText: 'Course Section Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),

            sectionTitle(title: 'Number of Questions'),
            SizedBox(height: 15),
            TextField(
              controller: quizQuestionsController,
              decoration: InputDecoration(
                labelText: 'Number of questions',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),

            sectionTitle(title: 'Availability'),
            SizedBox(height: 15),

            // Submission Date
            Row(
              children: [
                Checkbox(
                  value: isSubmissionEnabled,
                  onChanged: (value) {
                    setState(() {
                      isSubmissionEnabled = value!;
                    });
                  },
                ),
                Text('Enable'),
                SizedBox(width: 10),
                _buildDropdown(
                  'Allow Submissions From Date:',
                  selectedDaySubmission,
                  selectedMonthSubmission,
                  selectedYearSubmission,
                  selectedHourSubmission,
                  selectedMinuteSubmission,
                  isSubmissionEnabled,
                  (String? newValue) {
                    setState(() {
                      selectedDaySubmission = newValue!;
                    });
                  },
                  (String? newValue) {
                    setState(() {
                      selectedMonthSubmission = newValue!;
                    });
                  },
                  (String? newValue) {
                    setState(() {
                      selectedYearSubmission = newValue!;
                    });
                  },
                  (String? newValue) {
                    setState(() {
                      selectedHourSubmission = newValue!;
                    });
                  },
                  (String? newValue) {
                    setState(() {
                      selectedMinuteSubmission = newValue!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),

            // Due Date
            Row(
              children: [
                Checkbox(
                  value: isDueDateEnabled,
                  onChanged: (value) {
                    setState(() {
                      isDueDateEnabled = value!;
                    });
                  },
                ),
                Text('Enable'),
                SizedBox(width: 10),
                _buildDropdown(
                  'Due Date:',
                  selectedDayDue,
                  selectedMonthDue,
                  selectedYearDue,
                  selectedHourDue,
                  selectedMinuteDue,
                  isDueDateEnabled,
                  (String? newValue) {
                    setState(() {
                      selectedDayDue = newValue!;
                    });
                  },
                  (String? newValue) {
                    setState(() {
                      selectedMonthDue = newValue!;
                    });
                  },
                  (String? newValue) {
                    setState(() {
                      selectedYearDue = newValue!;
                    });
                  },
                  (String? newValue) {
                    setState(() {
                      selectedHourDue = newValue!;
                    });
                  },
                  (String? newValue) {
                    setState(() {
                      selectedMinuteDue = newValue!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // 1. Convert month to integer
                    int monthNumber = months.indexOf(selectedMonthDue) + 1;

                    // 2. Format the due date
                    String dueDate =
                        '$selectedYearDue-$monthNumber-${selectedDayDue.padLeft(2, '0')}-$selectedHourDue-$selectedMinuteDue';

                    // 3. Call GoogleApiService.createAndAssignQuizFromXml
                    GoogleLmsService googleApiService = GoogleLmsService();
                    bool success =
                        await googleApiService.createAndAssignQuizFromXml(
                      selectedCourse, // courseId
                      quizNameController.text, // quizName
                      'Quiz Description', // quizDescription (You might want to get this from the UI)
                      quizasxml, // quizAsXml (Your XML quiz data)
                      dueDate, // dueDate
                    );

                    if (success) {
                      // Display success message
                      print("Quiz created and assigned successfully!");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Quiz submitted successfully!')),
                      );

                      // Navigate to GoogleCourses or another screen as needed
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GoogleCourses()),
                      );
                    } else {
                      // Display error message
                      print("Failed to create and assign quiz.");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Failed to create and assign quiz.')),
                      );
                    }
                  },
                  child: Text(
                    'Send to Google Classroom',
                    textAlign: TextAlign
                        .center, // Changed from textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Dropdown Builder
  Widget _buildDropdown(
    String label,
    String selectedDay,
    String selectedMonth,
    String selectedYear,
    String selectedHour,
    String selectedMinute,
    bool isEnabled,
    ValueChanged<String?> onDayChanged,
    ValueChanged<String?> onMonthChanged,
    ValueChanged<String?> onYearChanged,
    ValueChanged<String?> onHourChanged,
    ValueChanged<String?> onMinuteChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Row(
          children: [
            _buildDropdownButton(days, selectedDay, onDayChanged, isEnabled),
            SizedBox(width: 8),
            _buildDropdownButton(
                months, selectedMonth, onMonthChanged, isEnabled),
            SizedBox(width: 8),
            _buildDropdownButton(years, selectedYear, onYearChanged, isEnabled),
            SizedBox(width: 8),
            _buildDropdownButton(hours, selectedHour, onHourChanged, isEnabled),
            SizedBox(width: 8),
            _buildDropdownButton(
                minutes, selectedMinute, onMinuteChanged, isEnabled),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownButton(
    List<String> items,
    String selectedValue,
    ValueChanged<String?> onChanged,
    bool isEnabled,
  ) {
    return DropdownButton<String>(
      value: selectedValue,
      onChanged: isEnabled ? onChanged : null,
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget sectionTitle({required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
