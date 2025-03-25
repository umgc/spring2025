import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/Views/dashboard.dart';
import 'dart:convert';

class EssayAssignmentSettings extends StatefulWidget {
  final String updatedJson;
  final String description;

  EssayAssignmentSettings(this.updatedJson, this.description);

  @override
  EssayAssignmentSettingsState createState() => EssayAssignmentSettingsState();
}

class EssayAssignmentSettingsState extends State<EssayAssignmentSettings> {
  // Global key for the form
  final _formKey = GlobalKey<FormState>();

  // Date selection variables for "Allow submissions from"
  String selectedDaySubmission = '01';
  String selectedMonthSubmission = 'January';
  String selectedYearSubmission = '2025';
  String selectedHourSubmission = '00';
  String selectedMinuteSubmission = '00';

  // Date selection variables for "Due date"
  String selectedDayDue = '01';
  String selectedMonthDue = 'January';
  String selectedYearDue = '2025';
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

  TextEditingController _assignmentNameController = TextEditingController();
  TextEditingController _assignmentSectionController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  // List of courses fetched from the controller
  List<Course> courses = [];
  String selectedCourse = 'Select a course';

  @override
  void initState() {
    super.initState();
    fetchCourses(); // Fetch courses on page load
    populateHeadersAndRows();
    _descriptionController = TextEditingController(text: widget.description);
  }

  // Fetch courses from the controller
  Future<void> fetchCourses() async {
    try {
      List<Course>? courseList = LmsFactory.getLmsService().courses;
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

  // Headers and Rows for Rubric Display
  List headers = [];
  List rows = [];

  // Function to populate headers and rows for rubric display
  void populateHeadersAndRows() {
    try {
      Map<String, dynamic> jsonData = jsonDecode(widget.updatedJson);

      List<dynamic> levels =
          List<dynamic>.from(jsonData['criteria'][0]['levels'] as List);
      headers = [
        {"title": 'Criteria', 'index': 1, 'key': 'name'},
      ];

      for (int i = 0; i < levels.length; i++) {
        headers.add({
          "title": '${levels[i]['score']}', // The score (5, 3, 1) as headers
          'index': i + 2,
          'key': 'level_$i'
        });
      }

      rows = (jsonData['criteria'] ?? []).map((criterion) {
        Map<String, dynamic> row = {
          "name": criterion['description'],
        };

        for (int i = 0; i < (criterion['levels'] as List).length; i++) {
          row['level_$i'] = (criterion['levels'] as List)[i]['definition'];
        }

        return row;
      }).toList();
    } catch (e) {
      //  debugPrint('Error parsing rubric JSON: $e');// i dnt want to see this jason rubrick on console.this wass for testing only
    }

    setState(() {});
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
        //  debugPrint('Selected course: $selectedCourse');//i dnt want to see this on console.this wass for testing only
      },
      items: [
        DropdownMenuItem<String>(
          value: 'Select a course',
          child: Text('Select a course'),
        ),
        ...courses.map<DropdownMenuItem<String>>((Course course) {
          return DropdownMenuItem<String>(
            value: course.fullName,
            child: Text(course.fullName),
          );
          //   }).toList(),/// trying to see if warning go away safia
        }),
      ],
      isExpanded: true,
    );
  }

  // Custom Widget to build rubric table without editable package
  Widget buildRubricTable() {
    return Table(
      border: TableBorder.all(),
      children: [
        TableRow(children: [
          _buildTableCell('Criteria'),
          for (var header in headers.skip(1)) _buildTableCell(header['title']),
        ]),
        for (var row in rows)
          TableRow(children: [
            _buildTableCell(row['name']),
            for (var i = 0; i < headers.length - 1; i++)
              _buildTableCell(row['level_$i']),
          ]),
      ],
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Function to validate if the availability date selections are not default values
  bool _validateAvailabilityDates() {
    if (selectedDaySubmission == '01' &&
        selectedMonthSubmission == 'January' &&
        selectedYearSubmission == '2025' &&
        selectedHourSubmission == '00' &&
        selectedMinuteSubmission == '00') {
      return false; // If the default date for submission is selected, return false
    }

    if (selectedDayDue == '01' &&
        selectedMonthDue == 'January' &&
        selectedYearDue == '2025' &&
        selectedHourDue == '00' &&
        selectedMinuteDue == '00') {
      return false; // If the default due date is selected, return false
    }

    return true; // If both dates have been customized, validation passes
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;

        // Example: Calculate sizes dynamically based on screen width
        double buttonWidth =
            screenWidth * 0.4; // Buttons take 40% of screen width
        double descriptionHeight = screenWidth *
            0.2; // Description box takes 20% of screen width height

        return Scaffold(
          appBar: CustomAppBar(
              title: 'Assign Essay',
              userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(14.0),
            child: Form(
              key: _formKey, // Assigning the global form key
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14.0),
                      child: Text(
                        'Send Essay to Moodle',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  sectionTitle(title: 'General'),
                  _buildCourseDropdown(),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _assignmentSectionController,
                    decoration: InputDecoration(
                      labelText: 'Section Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number, // Set keyboard type to number
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly // Allow only digits
                    ],
                    // Adding validator to ensure section number is not empty
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a section number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _assignmentNameController,
                    decoration: InputDecoration(
                      labelText: 'Assignment name',
                      border: OutlineInputBorder(),
                    ),
                    // Adding validator to ensure assignment name is not empty
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an assignment name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  sectionTitle(title: 'Rubric'),
                  buildRubricTable(),
                  SizedBox(height: 20),
                  sectionTitle(title: 'Description'),
                  Container(
                    height: descriptionHeight, // Responsive height
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: null, // Allows multiline input
                      expands: true,
                      decoration: InputDecoration(
                        hintText: 'Enter description here.',
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description cannot be empty';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  sectionTitle(title: 'Availability'),
                  SizedBox(height: 14),
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
                      Expanded(
                        child: _buildDropdown(
                          'Allow submissions from',
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
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
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
                      Expanded(
                        child: _buildDropdown(
                          'Due date',
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
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: buttonWidth, // Responsive button width
                        child: ElevatedButton(
                          onPressed: () async {
                            // Validate the form before submitting
                            if (_formKey.currentState!.validate() &&
                                _descriptionController.text.trim().isNotEmpty &&
                                _validateAvailabilityDates()) {
                              var api = LmsFactory.getLmsService();
                              bool? token = api.isLoggedIn();

                              if (token) {
                                String courseId = courses
                                    .firstWhere((course) =>
                                        course.fullName == selectedCourse)
                                    .id
                                    .toString();
                                String assignmentName =
                                    _assignmentNameController.text;
                                String sectionNumber =
                                    _assignmentSectionController.text;
                                String description = _descriptionController.text.trim();
                                String dueDate =
                                    '$selectedDayDue $selectedMonthDue $selectedYearDue $selectedHourDue:$selectedMinuteDue';
                                String allowSubmissionFrom =
                                    '$selectedDaySubmission $selectedMonthSubmission $selectedYearSubmission $selectedHourSubmission:$selectedMinuteSubmission';

                                await api.createAssignment(
                                  courseId,
                                  sectionNumber, // Section ID
                                  assignmentName,
                                  allowSubmissionFrom,
                                  dueDate,
                                  widget.updatedJson,
                                  description,
                                );


                      if (mounted) {
                  
                          final snackBar = SnackBar(
                            content: Text('Assignment submitted successfully!'),
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

                          }


                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Failed to retrieve user token.')));
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      'Please fill out all fields and ensure a course, description, and valid availability dates are selected.')));
                            }
                          },
                          child: Text('Send to Moodle'),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth, // Responsive button width
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Go Back to Edit Essay'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Dropdown Builder for each section
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
        Wrap(
          spacing: 10.0, // Space between dropdowns
          runSpacing: 8.0, // Space between rows when wrapping
          children: [
            _buildDropdownButton(days, selectedDay, onDayChanged, isEnabled),
            _buildDropdownButton(
                months, selectedMonth, onMonthChanged, isEnabled),
            _buildDropdownButton(years, selectedYear, onYearChanged, isEnabled),
            _buildDropdownButton(hours, selectedHour, onHourChanged, isEnabled),
            _buildDropdownButton(
                minutes, selectedMinute, onMinuteChanged, isEnabled),
          ],
        ),
      ],
    );
  }

  // Dropdown Button Builder
  Widget _buildDropdownButton(List<String> items, String selectedValue,
      ValueChanged<String?> onChanged, bool isEnabled) {
    return SizedBox(
      width: 103, // Adjust width as necessary
      child: DropdownButton<String>(
        value: selectedValue,
        onChanged: isEnabled ? onChanged : null,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  // Section Title Widget
  Widget sectionTitle({required String title}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
