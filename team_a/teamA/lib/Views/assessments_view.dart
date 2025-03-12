import "package:flutter/material.dart";
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import 'package:learninglens_app/Api/lms/google_classroom/google_lms_service.dart';
import 'package:learninglens_app/beans/g_question_form_data.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/course.dart';
import "package:learninglens_app/Controller/custom_appbar.dart";
import "package:learninglens_app/beans/quiz_type.dart";
// For HTTP requests
import 'package:learninglens_app/content_carousel.dart';

import 'package:learninglens_app/services/local_storage_service.dart'; // For JSON decoding

class AssessmentsView extends StatefulWidget {
  AssessmentsView({super.key});

  @override
  _AssessmentsState createState() => _AssessmentsState();
}

class _AssessmentsState extends State<AssessmentsView> {
  late Future<List<Quiz>?> quizzes;
  Quiz? selectedQuiz;
  List<Map<String, dynamic>> questionsData = [];
  Future<FormData>? _formDataFuture;
  GoogleLmsService googleLmsService = GoogleLmsService();

  @override
  void initState() {
    super.initState();
    //quizzes = getAllQuizzes();
    _refreshQuizzes();
  }

  // Check if Moodle is selected
  bool isMoodle() {
    // Replace with your actual implementation
    return LocalStorageService.getSelectedClassroom() == LmsType.MOODLE;
  }

 // Method to refresh quizzes
  void _refreshQuizzes() {
    setState(() {
      quizzes = getAllQuizzes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Assessments',
        onRefresh: _refreshQuizzes,
       
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      body: Column(
        children: [
          Row(children: [
            Padding(
                padding: const EdgeInsets.all(4.0),
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
                          // Left-side quiz list
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
                                        if (!isMoodle()) {
                                          _formDataFuture =
                                              googleLmsService.getAssignmentFormQuestions(
                                                  quiz.coursedId.toString(),
                                                  quiz.id.toString());
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),

                          // Right-side content
                          Expanded(
                            flex: 2,
                            child: selectedQuiz == null
                                ? Center(
                                    child:
                                        Text('Select a quiz to view details'))
                                : isMoodle()
                                    ? _buildMoodleContent()
                                    : _buildGoogleContent(),
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

  // Moodle content (existing table)
  Widget _buildMoodleContent() {
    return Column(
      children: [
        Text('Questions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        FutureBuilder<List<QuestionType>?>(
          future: LmsFactory.getLmsService()
              .getQuestionsFromQuiz(selectedQuiz?.id ?? 0),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error loading questions'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No questions found'));
            } else {
              final questionList = snapshot.data!;
              questionsData = questionList.map((question) {
                return {
                  'questionNumber': question.name,
                  'questionType': question.questionType,
                  'questionText': question.questionText,
                };
              }).toList();

              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                margin: EdgeInsets.all(8.0),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                  columns: const [
                    DataColumn(label: Text('Question Number')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Question Text')),
                  ],
                  rows: questionsData.map((row) {
                    return DataRow(cells: [
                      DataCell(Text(row['questionNumber'].toString())),
                      DataCell(Text(row['questionType'].toString())),
                      DataCell(Text(row['questionText'].toString())),
                    ]);
                  }).toList(),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  // Google content (DynamicForm)
  Widget _buildGoogleContent() {
    return FutureBuilder<FormData>(
      future: _formDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.questions.isNotEmpty) {
          return DynamicForm(formData: snapshot.data!);
        } else {
          return Center(child: Text('No questions found in the Google Form.'));
        }
      },
    );
  }
}

// Helper functions remain unchanged
Future<List<Quiz>> getAllQuizzes() async {
  print("Getting all quizzes");
  List<Quiz> result = [];
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    result.addAll(c.quizzes ?? []);
  }
  return result;
}

Course getCourse(int? courseID) {
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    if (c.id == courseID) {
      return c;
    }
  }
  throw "No course found.";
}

// Include DynamicForm widget as provided
class DynamicForm extends StatelessWidget {
  final FormData formData;

  const DynamicForm({super.key, required this.formData});

  String _getQuestionType(List<String> options) {
    if (options.isEmpty) {
      return 'Short Answer';
    } else if (options.length == 2) {
      return 'True/False';
    } else {
      return 'Multiple Choice';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  formData.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                ),
              ),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Start Date: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(formData.startDate ?? 'N/A'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('End Date: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(formData.endDate ?? 'N/A'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Form URL: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () async {
                              // URL launching logic here
                            },
                            child: Text(
                              formData.formUrl ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Status: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(formData.status ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          dataRowHeight: 60,
                          headingRowColor: MaterialStateProperty.all(
                              Colors.blueAccent.withOpacity(0.1)),
                          border: TableBorder.all(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                          columns: const [
                            DataColumn(
                              label: Center(
                                child: Text('Question No.',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataColumn(
                              label: Center(
                                child: Text('Question',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataColumn(
                              label: Center(
                                child: Text('Type',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataColumn(
                              label: Center(
                                child: Text('Options',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                          rows: formData.questions.asMap().entries.map((entry) {
                            int index = entry.key + 1;
                            QuestionData questionData = entry.value;
                            return DataRow(cells: [
                              DataCell(Text('$index')),
                              DataCell(
                                SizedBox(
                                  width: 400,
                                  child: Text(
                                    questionData.question,
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _getQuestionType(questionData.options),
                                  style: TextStyle(
                                    color: _getQuestionType(
                                                questionData.options) ==
                                            'Short Answer'
                                        ? Colors.green
                                        : _getQuestionType(
                                                    questionData.options) ==
                                                'True/False'
                                            ? Colors.orange
                                            : Colors.purple,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 300,
                                  child: Text(
                                    questionData.options.isEmpty
                                        ? 'N/A'
                                        : questionData.options.join(', '),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}