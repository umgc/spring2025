import "package:flutter/material.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Controller/essay_generator.dart";
import "package:learninglens_app/beans/assignment.dart";
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/question.dart';
import "package:learninglens_app/Controller/custom_appbar.dart";
import "package:learninglens_app/content_carousel.dart";

//The Page
class EssaysView extends StatefulWidget {
  EssaysView({super.key});

  @override
  _EssaysState createState() => _EssaysState();
}

class _EssaysState extends State<EssaysView> {
  late Future<List<Assignment>> essays;
  Assignment? selectedEssay;

  @override
  void initState() {
    super.initState();
    essays = getAllEssays();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Essays',
        onRefresh: () {
          setState(() {
            essays = getAllEssays();
          });
        },
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      body: Column(
        children: [
          Row(children: [
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: CreateButton('essay'))
          ]),
          Expanded(
            child: FutureBuilder<List<Assignment>>(
              future: essays,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading essays'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No essays found'));
                } else {
                  final essayList = snapshot.data!;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                itemCount: essayList.length,
                                itemBuilder: (context, index) {
                                  final essay = essayList[index];
                                  final activeCourse =
                                      getCourse(essay.courseId);

                                  return ListTile(
                                    title: Text(
                                        '${essay.name} (${activeCourse.shortName}${activeCourse.courseId})'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Due: ${essay.dueDate == null ? "No due date set" : Course.dateFormatted(essay.dueDate!)}'),
                                      ],
                                    ),
                                    tileColor: selectedEssay == essay
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1)
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        selectedEssay = essay;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),

                          // Right-side course details (quiz questions)
                          Expanded(
                            flex: 2,
                            child: selectedEssay == null
                                ? Center(
                                    child:
                                        Text('Select an essay to view details'))
                                : Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        margin: EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text('Essay Prompt',
                                                        style: TextStyle(
                                                            fontSize: 20))),
                                                Text(selectedEssay
                                                        ?.description ??
                                                    "No description found."),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.grey),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          margin: EdgeInsets.all(8.0),
                                          child: Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Text(
                                                          'Student Submissions',
                                                          style: TextStyle(
                                                              fontSize: 20))),
                                                  Text(
                                                      '${selectedEssay?.submissionsWithGrades == null ? "No submissions found." : selectedEssay?.submissionsWithGrades.toString()}')
                                                ],
                                              ),
                                            ),
                                          ),
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
          ),
        ],
      ),
    );
  }
}

//Helper function that pulls the quizzes from all the user's courses
Future<List<Assignment>> getAllEssays() async {
  List<Assignment> result = [];
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    result.addAll(c.essays ?? []);
  }
  return result;
}

//Debug function that prints out the number of courses and essays
/*
Future<List<Assignment>> getAllEssays() async {
  List<Assignment> result = [];
  var courses = LmsFactory.getLmsService().courses;
  print('DEBUG: Found ${courses?.length ?? 0} courses.');
  for (Course c in courses ?? []) {
    print('DEBUG: Course ${c.id} (${c.shortName}) has ${c.essays?.length ?? 0} essays.');
    result.addAll(c.essays ?? []);
  }
  print('DEBUG: Total essays aggregated: ${result.length}');
  return result;
}*/

String getQuestionListAsString(Quiz? selectedQuiz) {
  String result = "";

  for (Question q in selectedQuiz?.questionList ?? []) {
    result += q.toString();
  }

  return result.isEmpty ? "There are no quiz questions." : result;
}

//Helper function that gets the course number for the quiz
Course getCourse(int? courseID) {
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    if (c.id == courseID) {
      return c;
    }
  }
  throw "No course found.";
}
