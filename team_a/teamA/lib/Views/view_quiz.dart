import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/beans/quiz_type.dart';

class ViewQuiz extends StatelessWidget {
  final int quizId;
  final bool showAppBar = false;

  ViewQuiz({required this.quizId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? CustomAppBar(
              title: 'Assessments',
              userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
            )
          : null,
      body: SingleChildScrollView(
          child: Center(
        child: Column(
          children: [
            Text('Questions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            FutureBuilder<List<QuestionType>?>(
              future: LmsFactory.getLmsService().getQuestionsFromQuiz(quizId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading questions'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No questions found'));
                } else {
                  final questionList = snapshot.data!;
                  List<Map<String, dynamic>> questionsData = [];
                  questionsData = questionList.map((question) {
                    return {
                      'questionNumber': question.name,
                      'questionType': question.questionType,
                      'questionText': question.questionText,
                    };
                  }).toList();

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      margin: EdgeInsets.all(8.0),
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1)),
                        columns: const [
                          DataColumn(label: Text('Question No.')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Question Text')),
                        ],
                        rows: questionsData.map((row) {
                          return DataRow(cells: [
                            DataCell(
                              SizedBox(
                                width: 90,
                                child: Text(
                                  row['questionNumber'].toString(),
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 90,
                                child: Text(
                                  row['questionType'].toString(),
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                child: Text(
                                  row['questionText'].toString(),
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 4,
                                ),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      )),
    );
  }
}
