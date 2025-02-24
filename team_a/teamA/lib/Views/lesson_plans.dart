import "package:flutter/material.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Controller/custom_appbar.dart";
import "package:learninglens_app/beans/course.dart";
import "package:learninglens_app/beans/lesson_plan.dart";

///
/// Template for views
/// Need to change the class name to the name based on the view you
/// are creating to include the constructor as well.
/// Need to change the class that extends State as well. Make sure
/// that the createState function returns the same name.
///
/// The CustomAppBar is already included, but you will need to update
/// the title string.
///
/// The content for the page begins in the children array. There is
/// a single text box as a place holder.
///
/// To add your view to the rest of the app, you will have to add it
/// to the dashboard.dart file. On line ~213, there is a List called
/// buttonData. You will need to update the 'onPressed' section with
/// your new template. You can see examples that Derek has already
/// done on other buttons.
///
class LessonPlans extends StatefulWidget {
  LessonPlans();

  @override
  State createState() {
    return _LessonPlanState();
  }
}

class _LessonPlanState extends State {
  List<Course>? courses = []; // To store the courses list
  String? selectedCourse; // To track the selected course

  final TextEditingController lessonPlanNameController =
      TextEditingController();
  final TextEditingController manualEntryController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    lessonPlanNameController.dispose();
    manualEntryController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    // Fetch courses from the API
    var userCourses = await LmsFactory.getLmsService().courses;
    setState(() {
      courses = userCourses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
            title: 'Lesson Plans',
            userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
        body: SingleChildScrollView(
          child: Row(
            children: [
              // Left side - Add New Lesson Plan
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Lesson Plan',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),

                      // Lesson Plan Name
                      TextField(
                        controller: lessonPlanNameController,
                        decoration: InputDecoration(
                          labelText: 'Lesson Plan Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Course Combo Box
                      DropdownButtonFormField<String>(
                        value: selectedCourse,
                        items: courses?.map<DropdownMenuItem<String>>((course) {
                              return DropdownMenuItem<String>(
                                value: course.id
                                    .toString(), // Use 'id' for selection value
                                child: Text(course
                                    .fullName), // Use 'fullName' for display text
                              );
                            }).toList() ??
                            [], // If courses is null, return an empty list
                        onChanged: (value) {
                          setState(() {
                            selectedCourse = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Course',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),

                      // File Upload Section
                      ElevatedButton(
                        onPressed: () {
                          // NEED TO ADD LOGIC!
                        },
                        child: Text('Upload Lesson Plan File'),
                      ),

                      // OR Label
                      Center(
                        child: Text(
                          '- OR -',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Enter Lesson Plan Manually
                      TextField(
                        controller: manualEntryController,
                        maxLines: 8,
                        decoration: InputDecoration(
                          labelText: 'Enter Lesson Plan Manually',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Submit Button
                      ElevatedButton(
                        onPressed: () async {
                          // Submit logic here
                          if (selectedCourse != null) {
                            LessonPlan newLp = LessonPlan(
                              lessonPlanName: lessonPlanNameController.text,
                              courseId: int.parse(selectedCourse!),
                              content: manualEntryController.text,
                              //filePath: null
                            );

                            newLp.saveLessonPlanLocally();

                            bool success = await newLp.submitLessonPlan();
                            if (success) {
                              print('lesson plan sent successfully');
                            } else {
                              print('lesson plan send fail');
                            }
                          }
                        },
                        child: Text('SUBMIT'),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 20),

              // Right side - Existing Lesson Plans
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Existing Lesson Plans',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),

                    // Table Frame
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Lesson Plan Name')),
                          DataColumn(label: Text('Course')),
                          DataColumn(label: Text('Attached File?')),
                          DataColumn(label: Text('Select')),
                        ],
                        rows: [
                          // Example row data
                          DataRow(cells: [
                            DataCell(Text('Plan 1')),
                            DataCell(Text('Course 1')),
                            DataCell(Text('Yes')),
                            DataCell(Checkbox(
                                value: false, onChanged: (bool? value) {})),
                          ]),
                          DataRow(cells: [
                            DataCell(Text('Plan 2')),
                            DataCell(Text('Course 2')),
                            DataCell(Text('No')),
                            DataCell(Checkbox(
                                value: false, onChanged: (bool? value) {})),
                          ]),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // DELETE and SHOW buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Delete selected logic
                          },
                          child: Text('DELETE SELECTED'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Show selected logic
                          },
                          child: Text('SHOW SELECTED'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
