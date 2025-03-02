import "package:flutter/material.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Api/lms/google_classroom/google_lms_service.dart";
import "package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart";
import "package:learninglens_app/Controller/custom_appbar.dart";
import "package:learninglens_app/Views/lesson.dart";
import "package:learninglens_app/beans/course.dart";
import "package:learninglens_app/beans/lesson_plan.dart";

class LessonPlans extends StatefulWidget {
  @override
  State createState() => _LessonPlanState();
}

class _LessonPlanState extends State {
  List<Course>? courses = [];
  String? selectedCourse;
  List<LessonPlan> lessonPlans = [];
  LessonPlan? selectedLessonPlan;

  final TextEditingController lessonPlanNameController = TextEditingController();
  final TextEditingController manualEntryController = TextEditingController();

  @override
  void dispose() {
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
    var userCourses = await LmsFactory.getLmsService().courses;
    setState(() {
      courses = userCourses;
    });
  }

  void _fetchLessonPlans(int courseId) async {
    List<LessonPlan> plans = await MoodleLmsService().getLessonPlans(courseId);
    setState(() {
      lessonPlans = plans;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Lesson Plans',
          onRefresh: _loadCourses,
          userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add New Lesson Plan',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedCourse,
                        items: courses?.map<DropdownMenuItem<String>>((course) {
                              return DropdownMenuItem<String>(
                                value: course.id.toString(),
                                child: Text(course.fullName),
                              );
                            }).toList() ??
                            [],
                        onChanged: (value) {
                          setState(() {
                            selectedCourse = value;
                            _fetchLessonPlans(int.parse(value!));
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Course',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: lessonPlanNameController,
                        decoration: InputDecoration(
                          labelText: 'Lesson Plan Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: manualEntryController,
                        maxLines: 8,
                        decoration: InputDecoration(
                          labelText: 'Enter Lesson Plan Manually',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (selectedCourse != null) {
                            Lesson newLp = Lesson(
                              lessonPlanName: lessonPlanNameController.text,
                              courseId: int.parse(selectedCourse!),
                              content: manualEntryController.text,
                            );
                            newLp.saveLessonLocally();
                            bool success = await newLp.submitLesson();
                            print(success ? 'Lesson plan sent successfully' : 'Lesson plan send failed');
                            _fetchLessonPlans(int.parse(selectedCourse!));
                            lessonPlanNameController.clear();
                            manualEntryController.clear();
                          }
                        },
                        child: Text('Submit'),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Existing Lesson Plans',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Lesson Plan')),
                              DataColumn(label: Text('Select')),
                            ],
                            rows: lessonPlans.map((plan) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(plan.name)),
                                  DataCell(Container(
                                    width: MediaQuery.of(context).size.width * 0.25,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Text(plan.intro),
                                    ),
                                  )),
                                  DataCell(Checkbox(
                                    value: selectedLessonPlan == plan,
                                    onChanged: (bool? selected) {
                                      setState(() {
                                        selectedLessonPlan = selected! ? plan : null;
                                      });
                                    },
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await MoodleLmsService().deleteLessonPlan(selectedLessonPlan!.id);
                              _fetchLessonPlans(int.parse(selectedCourse!));
                            },
                            child: Text('Delete Selected'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await MoodleLmsService().updateLessonPlan(
                                lessonId: selectedLessonPlan!.id,
                                name: "Updated Lesson Name",
                                intro: "This is the new introduction text.",
                                available: 1672531200,
                                deadline: 1675132800,
                              );
                              _fetchLessonPlans(int.parse(selectedCourse!));
                            },
                            child: Text('Edit Selected'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
