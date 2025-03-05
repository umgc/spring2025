import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Controller/essay_generator.dart";
import "package:learninglens_app/Views/view_submissions.dart";
import "package:learninglens_app/beans/assignment.dart";
import "package:learninglens_app/beans/participant.dart";
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/question.dart';
import "package:learninglens_app/Controller/custom_appbar.dart";
import "package:learninglens_app/beans/submission_with_grade.dart";
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
  late Future<List<SubmissionWithGrade>> futureSubmissionsWithGrades;
  late Future<List<Participant>> futureParticipants;
  List<Map<String, dynamic>> submissionsData = [];

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
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
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
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                      maxHeight:
                                                          250), //testing width
                                                  child: FutureBuilder<
                                                      List<
                                                          SubmissionWithGrade>>(
                                                    future:
                                                        futureSubmissionsWithGrades,
                                                    builder: (BuildContext
                                                            context,
                                                        AsyncSnapshot<
                                                                List<
                                                                    SubmissionWithGrade>>
                                                            submissionSnapshot) {
                                                      if (submissionSnapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return Center(
                                                            child:
                                                                CircularProgressIndicator());
                                                      } else if (submissionSnapshot
                                                          .hasError) {
                                                        return Center(
                                                            child: Text(
                                                                'Error: ${submissionSnapshot.error}'));
                                                      } else if (!submissionSnapshot
                                                              .hasData ||
                                                          submissionSnapshot
                                                              .data!.isEmpty) {
                                                        return Center(
                                                            child: Text(
                                                                'No submissions found'));
                                                      } else {
                                                        List<SubmissionWithGrade>
                                                            submissionsWithGrades =
                                                            submissionSnapshot
                                                                    .data ??
                                                                [];
                                                        submissionsData =
                                                            submissionsWithGrades
                                                                .map(
                                                                    (submission) {
                                                          return {
                                                            'studentName':
                                                                submission
                                                                    .submission
                                                                    .userid,
                                                            'submittedDate':
                                                                submission
                                                                    .submission
                                                                    .submissionTime
                                                                    .toLocal(),
                                                            'status': submission
                                                                .submission
                                                                .gradingStatus,
                                                            'response':
                                                                submission
                                                                    .submission
                                                                    .onlineText,
                                                            'grade': submission
                                                                .grade?.grade,
                                                          };
                                                        }).toList();

                                                        return Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border.all(
                                                                color: Colors
                                                                    .grey),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                          ),
                                                          margin:
                                                              EdgeInsets.all(
                                                                  8.0),
                                                          child:
                                                              SingleChildScrollView(
                                                            scrollDirection:
                                                                Axis.horizontal,
                                                            child: DataTable(
                                                              headingRowColor: MaterialStateProperty
                                                                  .all(Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .primary
                                                                      .withOpacity(
                                                                          0.1)),
                                                              columns: const [
                                                                DataColumn(
                                                                    label: Text(
                                                                        'Student')),
                                                                DataColumn(
                                                                    label: Text(
                                                                        'Submitted Date')),
                                                                DataColumn(
                                                                    label: Text(
                                                                        'Status')),
                                                                DataColumn(
                                                                    label: Text(
                                                                        'Grade')),
                                                                DataColumn(
                                                                    label: Text(
                                                                        'Response')),
                                                              ],
                                                              rows:
                                                                  submissionsData
                                                                      .map(
                                                                          (row) {
                                                                return DataRow(
                                                                    cells: [
                                                                      DataCell(Text(
                                                                          row['studentName']
                                                                              .toString())),
                                                                      DataCell(Text(DateFormat(
                                                                              'M/dd/yy')
                                                                          .format(
                                                                              row['submittedDate'])
                                                                          .toString())),
                                                                      DataCell(Text(
                                                                          row['status']
                                                                              .toString())),
                                                                      DataCell(Text(
                                                                          row['grade']
                                                                              .toString())),
                                                                      DataCell(Text(
                                                                          row['response']
                                                                              .toString())),
                                                                    ]);
                                                              }).toList(),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
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

//Helper function that pulls the quizzes from all the user's courses
Future<List<Assignment>> getAllEssays() async {
  List<Assignment> result = [];
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    result.addAll(c.essays ?? []);
  }
  return result;
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
