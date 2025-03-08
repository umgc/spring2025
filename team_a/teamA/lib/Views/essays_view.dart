import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Controller/essay_generator.dart";
import "package:learninglens_app/Views/view_submissions.dart";
import "package:learninglens_app/beans/assignment.dart";
import "package:learninglens_app/beans/participant.dart";
import 'package:learninglens_app/beans/quiz.dart';
import "package:learninglens_app/beans/course.dart";
import "package:learninglens_app/beans/question.dart";
import "package:learninglens_app/Controller/custom_appbar.dart";
import "package:learninglens_app/beans/submission_with_grade.dart";
import "package:learninglens_app/content_carousel.dart";

// The Page
class EssaysView extends StatefulWidget {
  EssaysView({super.key, this.essayID = 0, this.courseID = 0});
  final int essayID;
  final int? courseID;

  @override
  _EssaysState createState() => _EssaysState();
}

class _EssaysState extends State<EssaysView> {
  late Future<List<Assignment>> essays;
  Assignment? selectedEssay;
  late Future<List<SubmissionWithGrade>> futureSubmissionsWithGrades;
  late Future<List<Participant>> futureParticipants;

  @override
  void initState() {
    super.initState();
    essays = getAllEssays(widget.courseID);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Essays',
        onRefresh: () {
          setState(() {
            essays = getAllEssays(widget.courseID);
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
                                  if (essay.id == widget.essayID) {
                                    selectedEssay = essay;
                                  }
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
                                        futureSubmissionsWithGrades =
                                            LmsFactory.getLmsService()
                                                .getSubmissionsWithGrades(
                                                    selectedEssay?.id ?? 0);
                                        futureParticipants =
                                            LmsFactory.getLmsService()
                                                .getCourseParticipants(
                                                    selectedEssay?.courseId
                                                            .toString() ??
                                                        "");
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
                            child: selectedEssay == null && widget.essayID == 0
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
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                      'Student Submissions',
                                                      style: TextStyle(
                                                          fontSize: 20)),
                                                ),
                                                Expanded(
                                                  child: selectedEssay ==
                                                              null &&
                                                          widget.essayID == 0
                                                      ? Center(
                                                          child: Text(
                                                              'No essay selected'))
                                                      : SubmissionList(
                                                          key: ValueKey(
                                                              selectedEssay
                                                                      ?.id ??
                                                                  widget
                                                                      .essayID), // Add a Key to force rebuild
                                                          assignmentId:
                                                              selectedEssay
                                                                      ?.id ??
                                                                  widget
                                                                      .essayID,
                                                          courseId: selectedEssay
                                                                  ?.courseId
                                                                  .toString() ??
                                                              widget.courseID
                                                                  .toString(),
                                                        ),
                                                ),
                                              ],
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

// Helper function that pulls the quizzes from all the user's courses
Future<List<Assignment>> getAllEssays(int? courseID) async {
  List<Assignment> result = [];
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    if (courseID == 0 || courseID == null || c.id == courseID) {
      result.addAll(c.essays ?? []);
    }
  }
  return result;
}

// Helper function that gets the course number for the quiz
Course getCourse(int? courseID) {
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    if (c.id == courseID) {
      return c;
    }
  }
  throw "No course found.";
}
