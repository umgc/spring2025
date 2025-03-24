import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/google_classroom/google_lms_service.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/dashboard.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import '../Api/lms/moodle/moodle_lms_service.dart'; // Make sure this path is correct

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
  String selectedYearSubmission = '2025'; // Start from 2025
  String selectedHourSubmission = '00';
  String selectedMinuteSubmission = '00';
  late String quizasxml;
  late MoodleLmsService api;
  List<Course> courses = [];
  String selectedCourse = 'Select a course';

  LmsType? lmsType;
  bool isLoading = false; // Added to track loading state

  @override
  void initState() {
    super.initState();
    quizNameController = TextEditingController(text: widget.quiz.name ?? '');
    quizQuestionsController = TextEditingController();
    quizasxml = widget.quiz.toXmlString();
    fetchCourses();
    _getLmsType(); // Fetch LMS type on init
  }

  // Fetch LMS type from local storage
  Future<void> _getLmsType() async {
    LmsType retrievedLmsType = LocalStorageService.getSelectedClassroom();
    setState(() {
      lmsType = retrievedLmsType;
    });
  }

  // Fetch courses from the controller
  Future<void> fetchCourses() async {
    try {
      List<Course>? courseList = LmsFactory.getLmsService().courses;
      setState(() {
        courses = courseList ?? [];
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
      value: selectedCourse == 'Select a course' ? null : selectedCourse,
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
  String selectedYearDue = '2025'; // Start from 2025
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
  List<String> years = ['2025', '2026', '2027']; // Years starting from 2025
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
                  'Assign Quiz',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
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
              keyboardType: TextInputType.number, // Set keyboard type to number
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly // Allow only digits
              ],
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
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (lmsType == LmsType.MOODLE)
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              setState(() {
                                isLoading = true;
                              });

                              if (selectedCourse == 'Select a course') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Please select a course to proceed.')),
                                );
                                setState(() {
                                  isLoading = false;
                                });
                                return;
                              }

                              try {
                                DateTime submissionDate = DateTime(
                                  int.parse(selectedYearSubmission),
                                  months.indexOf(selectedMonthSubmission) + 1,
                                  int.parse(selectedDaySubmission),
                                  int.parse(selectedHourSubmission),
                                  int.parse(selectedMinuteSubmission),
                                );

                                DateTime dueDate = DateTime(
                                  int.parse(selectedYearDue),
                                  months.indexOf(selectedMonthDue) + 1,
                                  int.parse(selectedDayDue),
                                  int.parse(selectedHourDue),
                                  int.parse(selectedMinuteDue),
                                );

                                String formattedDueDate =
                                    "${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}-${dueDate.hour.toString().padLeft(2, '0')}-${dueDate.minute.toString().padLeft(2, '0')}";

                                var quizid = await LmsFactory.getLmsService()
                                    .createQuiz(
                                  selectedCourse,
                                  widget.quiz.name ?? 'Quiz Name',
                                  widget.quiz.description ?? 'Quiz Description',
                                  quizSectionController.text,
                                  '$selectedDaySubmission $selectedMonthSubmission $selectedYearSubmission $selectedHourSubmission:$selectedMinuteSubmission',
                                  '$selectedDayDue $selectedMonthDue $selectedYearDue $selectedHourDue:$selectedMinuteDue',
                                );
                                print('Quiz ID: $quizid');

                                var categoryid = await LmsFactory.getLmsService()
                                    .importQuizQuestions(
                                        selectedCourse, quizasxml);
                                print('Category ID: $categoryid');

                                var randomresult = await LmsFactory.getLmsService()
                                    .addRandomQuestions(
                                        categoryid.toString(),
                                        quizid.toString(),
                                        quizQuestionsController.text);
                                print('Random Result: $randomresult');

                                if (randomresult == 'true') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Quiz submitted successfully to Moodle!')),
                                  );
                                  await Future.delayed(Duration(seconds: 2));
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
                                    SnackBar(
                                        content: Text(
                                            'Failed to update grades in Moodle.')),
                                  );
                                }
                              } catch (e) {
                                print('Error during quiz creation: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('An error occurred: ${e}')),
                                );
                              } finally {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                      child: isLoading
                          ? CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              'Send to Moodle',
                              textDirection: TextDirection.ltr,
                            ),
                    ),
                  if (lmsType == LmsType.GOOGLE)
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              setState(() {
                                isLoading = true;
                              });

                              if (selectedCourse == 'Select a course') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Please select a course to proceed.')),
                                );
                                setState(() {
                                  isLoading = false;
                                });
                                return;
                              }

                              try {
                                DateTime submissionDate = DateTime(
                                  int.parse(selectedYearSubmission),
                                  months.indexOf(selectedMonthSubmission) + 1,
                                  int.parse(selectedDaySubmission),
                                  int.parse(selectedHourSubmission),
                                  int.parse(selectedMinuteSubmission),
                                );

                                DateTime dueDate = DateTime(
                                  int.parse(selectedYearDue),
                                  months.indexOf(selectedMonthDue) + 1,
                                  int.parse(selectedDayDue),
                                  int.parse(selectedHourDue),
                                  int.parse(selectedMinuteDue),
                                );

                                String formattedDueDate =
                                    "${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}-${dueDate.hour.toString().padLeft(2, '0')}-${dueDate.minute.toString().padLeft(2, '0')}";

                                bool success = await GoogleLmsService()
                                    .createAndAssignQuizFromXml(
                                  selectedCourse,
                                  quizNameController.text,
                                  widget.quiz.description ?? 'Quiz Description',
                                  quizasxml,
                                  formattedDueDate,
                                );
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Quiz submitted successfully to Google Classroom!')),
                                  );
                                  await Future.delayed(Duration(seconds: 2));
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
                                    SnackBar(
                                        content: Text(
                                            'Failed to create quiz in Google Classroom.')),
                                  );
                                }
                              } catch (e) {
                                print('Error during quiz creation: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('An error occurred: ${e}')),
                                );
                              } finally {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                      child: isLoading
                          ? CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              'Send to Google Classroom',
                              textDirection: TextDirection.ltr,
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      ValueChanged<String?> onMinuteChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Row(
          children: [
            DropdownButton<String>(
              value: selectedDay,
              onChanged: isEnabled ? onDayChanged : null,
              items: days.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(width: 5),
            DropdownButton<String>(
              value: selectedMonth,
              onChanged: isEnabled ? onMonthChanged : null,
              items: months.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(width: 5),
            DropdownButton<String>(
              value: selectedYear,
              onChanged: isEnabled ? onYearChanged : null,
              items: years.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(width: 5),
            DropdownButton<String>(
              value: selectedHour,
              onChanged: isEnabled ? onHourChanged : null,
              items: hours.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(width: 5),
            DropdownButton<String>(
              value: selectedMinute,
              onChanged: isEnabled ? onMinuteChanged : null,
              items: minutes.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget sectionTitle({required String title}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
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