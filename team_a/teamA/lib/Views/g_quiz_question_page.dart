import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/google_classroom/google_lms_service.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/beans/g_question_form_data.dart';
import 'dart:convert';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // Added for clipboard functionality

// Dynamic form widget with table inside a card
class DynamicForm extends StatelessWidget {
  final FormData formData;

  const DynamicForm({super.key, required this.formData});

  // Determine question type based on options
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  formData.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              // Card containing assignment details and table
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Assignment Details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Start Date: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(formData.startDate ?? 'N/A'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'End Date: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(formData.endDate ?? 'N/A'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Form URL: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (formData.formUrl != null) {
                                final Uri url = Uri.parse(formData.formUrl!);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Cannot launch URL')),
                                  );
                                }
                              }
                            },
                            child: Text(
                              formData.formUrl ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          if (formData.formUrl != null) ...[
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: formData.formUrl!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('URL copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Status: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(formData.status ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Table
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
                                child: Text(
                                  'Question No.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Center(
                                child: Text(
                                  'Question',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Center(
                                child: Text(
                                  'Type',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Center(
                                child: Text(
                                  'Options',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
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

// Updated QuizQuestionPage
class QuizQuestionPage extends StatefulWidget {
  final String coursedId;
  final String assessmentId;

  const QuizQuestionPage(
      {super.key, required this.coursedId, required this.assessmentId});

  @override
  State<QuizQuestionPage> createState() => _QuizQuestionPageState();
}

class _QuizQuestionPageState extends State<QuizQuestionPage> {
  late Future<FormData> _formDataFuture;

  @override
  void initState() {
    super.initState();
    print(
        'Course ID from QuizQuestion Page: ${widget.coursedId}, Assessment ID from QuizQuestion Page: ${widget.assessmentId}');
    GoogleLmsService googleLmsService = GoogleLmsService();
    _formDataFuture = googleLmsService.getAssignmentFormQuestions(
        widget.coursedId, widget.assessmentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Quiz Questions',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      body: FutureBuilder<FormData>(
        future: _formDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error.toString()}',
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.questions.isNotEmpty) {
            return DynamicForm(formData: snapshot.data!);
          } else {
            return const Center(
              child: Text(
                'No questions found in the Google Form.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
        },
      ),
    );
  }
}
