import "package:flutter/material.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/course.dart';
import "package:learninglens_app/Controller/custom_appbar.dart";
import "package:learninglens_app/beans/quiz_type.dart";
import "package:learninglens_app/content_carousel.dart";

//The Page
class AssessmentsView extends StatefulWidget {
  AssessmentsView({super.key});

  @override
  _AssessmentsState createState() => _AssessmentsState();
}

class _AssessmentsState extends State<AssessmentsView> {
  late Future<List<Quiz>?> quizzes;
  Quiz? selectedQuiz;
  List<Map<String, dynamic>> questionsData = [];

  @override
  void initState() {
    super.initState();
    quizzes = getAllQuizzes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Assessments',
        onRefresh: () {
          setState(() {
            quizzes = getAllQuizzes();
          });
        },
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      body: Column(
        children: [
          Row(children: [
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: CreateButton('assessment'))
          ]),
          Expanded(
            child: FutureBuilder<List<Quiz>?>(
              future: quizzes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading quizzes'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No quizzes found'));
                } else {
                  final quizList = snapshot.data!;

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
                                itemCount: quizList.length,
                                itemBuilder: (context, index) {
                                  final quiz = quizList[index];
                                  final activeCourse =
                                      getCourse(quiz.coursedId);

                                  return ListTile(
                                    title: Text(
                                        '${quiz.name} (${activeCourse.shortName}${activeCourse.courseId})'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Due: ${quiz.timeClose == null ? "No due date set" : Course.dateFormatted(quiz.timeClose!)}'),
                                      ],
                                    ),
                                    tileColor: selectedQuiz == quiz
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1)
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        selectedQuiz = quiz;
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
                            child: selectedQuiz == null
                                ? Center(
                                    child:
                                        Text('Select a quiz to view details'))
                                : Column(
                                    children: [
                                      Text('Questions',
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      FutureBuilder<List<QuestionType>?>(
                                        future: LmsFactory.getLmsService()
                                            .getQuestionsFromQuiz(
                                                selectedQuiz?.id ?? 0),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          } else if (snapshot.hasError) {
                                            return Center(
                                                child: Text(
                                                    'Error loading questions'));
                                          } else if (!snapshot.hasData ||
                                              snapshot.data!.isEmpty) {
                                            return Center(
                                                child:
                                                    Text('No questions found'));
                                          } else {
                                            final questionList = snapshot.data!;
                                            questionsData =
                                                questionList.map((question) {
                                              return {
                                                'questionNumber': question.name,
                                                'questionType':
                                                    question.questionType,
                                                'questionText':
                                                    question.questionText,
                                              };
                                            }).toList();

                                            return Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.grey),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              margin: EdgeInsets.all(8.0),
                                              child: DataTable(
                                                headingRowColor:
                                                    WidgetStateProperty.all(
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.1)),
                                                columns: const [
                                                  DataColumn(
                                                      label: Text(
                                                          'Question Number')),
                                                  DataColumn(
                                                      label: Text('Type')),
                                                  DataColumn(
                                                      label: Text(
                                                          'Question Text')),
                                                ],
                                                rows: questionsData.map((row) {
                                                  return DataRow(cells: [
                                                    DataCell(Text(
                                                        row['questionNumber']
                                                            .toString())),
                                                    DataCell(Text(
                                                        row['questionType']
                                                            .toString())),
                                                    DataCell(Text(
                                                        row['questionText']
                                                            .toString())),
                                                  ]);
                                                }).toList(),
                                              ),
                                            );
                                          }
                                        },
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
Future<List<Quiz>> getAllQuizzes() async {
  List<Quiz> result = [];
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    result.addAll(c.quizzes ?? []);
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
