import 'package:flutter/material.dart';
import 'package:learninglens_app/Controller/beans.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/dashboard.dart';
import '../Api/moodle_api_singleton.dart';

class QuizMoodle extends StatefulWidget {
  final Quiz quiz;
  QuizMoodle({required this.quiz});

  @override
  QuizMoodleState createState() => QuizMoodleState();
}

class QuizMoodleState extends State<QuizMoodle> {
  // Submission form dates
  String selectedDaySubmission = '01';
  String selectedMonthSubmission = 'January';
  String selectedYearSubmission = '2024';
  String selectedHourSubmission = '00';
  String selectedMinuteSubmission = '00';
  late String quizasxml;
  late MoodleApiSingleton api;
  List<Course> courses = [];
  String selectedCourse = 'Select a course';

  @override
  void initState() {
    super.initState();
    quizNameController = TextEditingController(text: widget.quiz.name ?? '');
    quizQuestionsController = TextEditingController();
    quizasxml = widget.quiz.toXmlString();
    fetchCourses();
  }

// Fetch courses from the controller
  Future<void> fetchCourses() async {
    try {
      List<Course>? courseList = MoodleApiSingleton().moodleCourses;
      setState(() {
        courses = courseList ?? [];
        // Don't auto-select any course here, leave it to the user to select.
        selectedCourse = 'Select a course';
      });
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      setState(() {
        selectedCourse = 'No courses available'; // Handle the empty case
      });
    }
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
        ...courses.map<DropdownMenuItem<String>>((Course course) {
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
  String selectedYearDue = '2024';
  String selectedHourDue = '00';
  String selectedMinuteDue = '00';

  // Checkbox states
  bool isSubmissionEnabled = true;
  bool isDueDateEnabled = true;

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
  List<String> years = ['2023', '2024', '2025'];
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
          userprofileurl: MoodleApiSingleton().moodleProfileImage ?? ''),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Text(
                  'Send Quiz to Moodle',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 30),

// Assuming 'courses' is now a regular list of Course objects, not a Future.
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
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  Checkbox(
                      value: isSubmissionEnabled,
                      onChanged: (value) {
                        setState(() {
                          isSubmissionEnabled = value!;
                        });
                      }),
                  Text('Enable'),
                  SizedBox(width: 10),
                  _buildDropdown(
                      'Allow Submissions From Date:',
                      selectedDaySubmission,
                      selectedMonthSubmission,
                      selectedYearSubmission,
                      selectedHourSubmission,
                      selectedMinuteSubmission,
                      isSubmissionEnabled, (String? newValue) {
                    setState(() {
                      selectedDaySubmission = newValue!;
                    });
                  }, (String? newValue) {
                    setState(() {
                      selectedMonthSubmission = newValue!;
                    });
                  }, (String? newValue) {
                    setState(() {
                      selectedYearSubmission = newValue!;
                    });
                  }, (String? newValue) {
                    setState(() {
                      selectedHourSubmission = newValue!;
                    });
                  }, (String? newValue) {
                    setState(() {
                      selectedMinuteSubmission = newValue!;
                    });
                  }),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Due Date
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
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
                      isDueDateEnabled, (String? newValue) {
                    setState(() {
                      selectedDayDue = newValue!;
                    });
                  }, (String? newValue) {
                    setState(() {
                      selectedMonthDue = newValue!;
                    });
                  }, (String? newValue) {
                    setState(() {
                      selectedYearDue = newValue!;
                    });
                  }, (String? newValue) {
                    setState(() {
                      selectedHourDue = newValue!;
                    });
                  }, (String? newValue) {
                    setState(() {
                      selectedMinuteDue = newValue!;
                    });
                  }),
                ],
              ),
            ),
            SizedBox(height: 16),

            // // Grading Section
            // sectionTitle(title: 'Grade'),
            // SizedBox(height: 15),

            // sectionTitle(title: 'Grade Categories:'),
            // DropdownButton<String>(
            //   value: selectedCategory,
            //   icon: Icon(Icons.keyboard_arrow_down),
            //   items: categoryItems.map((String item) {
            //     return DropdownMenuItem<String>(
            //       value: item,
            //       child: Text(item),
            //     );
            //   }).toList(),
            //   onChanged: (String? newValue) {
            //     setState(() {
            //       selectedCategory = newValue!;
            //     });
            //   },
            // ),
            // SizedBox(height: 16),

            // sectionTitle(title: 'Grade to Pass:'),
            // TextField(
            //   controller: gradeController,
            //   decoration: InputDecoration(
            //     labelText: 'Enter grade',
            //     border: OutlineInputBorder(),
            //   ),
            // ),
            // SizedBox(height: 16),

            // sectionTitle(title: 'Attempts Allowed:'),
            // DropdownButton<String>(
            //   value: selectedAttempt,
            //   icon: Icon(Icons.keyboard_arrow_down),
            //   items: attemptItems.map((String attempt) {
            //     return DropdownMenuItem<String>(
            //       value: attempt,
            //       child: Text(attempt),
            //     );
            //   }).toList(),
            //   onChanged: (String? newValue) {
            //     setState(() {
            //       selectedAttempt = newValue!;
            //     });
            //   },
            // ),
            // SizedBox(height: 16),

            // sectionTitle(title: 'Grading Method:'),
            // DropdownButton<String>(
            //   value: selectedGradingMethod,
            //   icon: Icon(Icons.keyboard_arrow_down),
            //   items: gradingMethodItems.map((String method) {
            //     return DropdownMenuItem<String>(
            //       value: method,
            //       child: Text(method),
            //     );
            //   }).toList(),
            //   onChanged: (String? newValue) {
            //     setState(() {
            //       selectedGradingMethod = newValue!;
            //     });
            //   },
            // ),
            // SizedBox(height: 16),

            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      var quizid = await MoodleApiSingleton().createQuiz(
                        selectedCourse,
                        widget.quiz.name ?? 'Quiz Name',
                        widget.quiz.description ?? 'Quiz Description',
                        quizSectionController.text,
                        '$selectedDaySubmission $selectedMonthSubmission $selectedYearSubmission $selectedHourSubmission:$selectedMinuteSubmission',
                        '$selectedDayDue $selectedMonthDue $selectedYearDue $selectedHourDue:$selectedMinuteDue',
                      );
                      print('Quiz ID: $quizid');
                      var categoryid = await MoodleApiSingleton()
                          .importQuizQuestions(selectedCourse, quizasxml);
                      print('Category ID: $categoryid');
                      var randomresult = await MoodleApiSingleton()
                          .addRandomQuestions(categoryid.toString(),
                              quizid.toString(), quizQuestionsController.text);
                      print('Random Result: $randomresult');

                      if (mounted) {
                        if (randomresult == 'true') {
                          final snackBar = SnackBar(
                            content: Text('Quiz submitted successfully!'),
                            duration: Duration(seconds: 2),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          await Future.delayed(snackBar.duration);
                          if (mounted) {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeacherDashboard(),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update grades.')),
                          );
                        }
                      }
                    },
                    child: Text(
                      'Send to Moodle',
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     // Back to quiz action
                  //     Navigator.pop(context);
                  //   },
                  //   child: Text(
                  //     'Go back to update quiz',
                  //     textDirection: TextDirection.ltr,
                  //   ),
                  // ),
                ],
              ),
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
            SizedBox(width: 8),
          ],
        ),
      ],
    );
  }
}

// Dropdown Button Builder
Widget _buildDropdownButton(List<String> items, String selectedValue,
    ValueChanged<String?> onChanged, bool isEnabled) {
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

// Section Title Widget
Widget sectionTitle({required String title}) {
  return Text(
    title,
    textDirection: TextDirection.ltr,
    style: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
}
