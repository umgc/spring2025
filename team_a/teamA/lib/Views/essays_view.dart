import "package:flutter/material.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Views/view_submissions.dart";
import "package:learninglens_app/beans/assignment.dart";
import "package:learninglens_app/beans/participant.dart";
import "package:learninglens_app/beans/course.dart";
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
  String? submissionError; // To store error message for submissions
  String? participantError; // To store error message for participants

  @override
  void initState() {
    super.initState();
    essays = getAllEssays(widget.courseID);
    // Initialize with placeholder futures to avoid null errors
    futureSubmissionsWithGrades = Future.value([]);
    futureParticipants = Future.value([]);
  }

  // Helper method to fetch submissions with error handling
  Future<List<SubmissionWithGrade>> fetchSubmissionsWithGrades(
      int essayId) async {
    try {
      return await LmsFactory.getLmsService().getSubmissionsWithGrades(essayId);
    } on UnimplementedError catch (e) {
      setState(() {
        submissionError =
            "Submissions/Grading feature is currently not available for Google Classroom. Please reach out to the developer for more information.";
      });
      return []; // Return empty list to avoid breaking the FutureBuilder
    } catch (e) {
      setState(() {
        submissionError = "Error fetching submissions: $e";
      });
      return [];
    }
  }

  // Helper method to fetch participants with error handling
  Future<List<Participant>> fetchCourseParticipants(String courseId) async {
    try {
      return await LmsFactory.getLmsService().getCourseParticipants(courseId);
    } on UnimplementedError catch (e) {
      setState(() {
        participantError = "Participants feature is not yet implemented.";
      });
      return []; // Return empty list to avoid breaking the FutureBuilder
    } catch (e) {
      setState(() {
        participantError = "Error fetching participants: $e";
      });
      return [];
    }
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
                                        submissionError = null; // Reset error
                                        participantError = null; // Reset error
                                        futureSubmissionsWithGrades =
                                            fetchSubmissionsWithGrades(
                                                essay.id!);
                                        futureParticipants =
                                            fetchCourseParticipants(
                                                essay.courseId.toString());
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
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
                                                    getEssay(widget.essayID,
                                                            widget.courseID)
                                                        ?.description ??
                                                    "No description is available."),
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
                                                  child: submissionError != null
                                                      ? Center(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .construction, // Under development icon
                                                                size: 48.0,
                                                                color: Colors
                                                                    .orange,
                                                              ),
                                                              SizedBox(
                                                                  height: 16.0),
                                                              Text(
                                                                submissionError!,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      16.0,
                                                                  color: Colors
                                                                          .grey[
                                                                      700],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      : SubmissionList(
                                                          key: ValueKey(
                                                              selectedEssay
                                                                      ?.id ??
                                                                  widget
                                                                      .essayID),
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

Assignment? getEssay(int? essayID, int? courseID) {
  Assignment? result;
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    if (courseID == 0 || courseID == null || c.id == courseID) {
      for (Assignment a in c.essays ?? []) {
        if (a.id == essayID) {
          result = a;
        }
      }
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
