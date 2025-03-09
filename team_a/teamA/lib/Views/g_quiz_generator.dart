// ignore: unused_import
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learninglens_app/Api/llm/prompt_engine.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/beans/assignment_form.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/g_edit_questions.dart';
import 'package:learninglens_app/Api/llm/claudeai_api.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';

class CreateAssessmentGoogle extends StatefulWidget {
  static TextEditingController nameController = TextEditingController();
  static TextEditingController descriptionController = TextEditingController();
  static TextEditingController subjectController = TextEditingController();
  static TextEditingController multipleChoiceController =
      TextEditingController();
  static TextEditingController trueFalseController = TextEditingController();
  static TextEditingController shortAnswerController = TextEditingController();
  static TextEditingController topicController = TextEditingController();
  CreateAssessmentGoogle();

  @override
  State createState() {
    return _AssessmentState();
  }
}

class _AssessmentState extends State<CreateAssessmentGoogle> {
  double paddingHeight = 16.0, paddingWidth = 32;
  bool isAdvancedModeOnGetFromGlobalVarsLater = false;
  final _formKey = GlobalKey<FormState>();
  String? selectedLLM, selectedSubject, selectedGradeLevel;
  List<String> _gradeLevels = ['9th', '10th', '11th', '12th'];
  List<String> _subjects = [
    'Math',
    'Science',
    'Language Arts',
    'Social Studies',
    'Health',
    'Art',
    'Music'
  ];
  bool _isLoading = false;
  _AssessmentState();

  void generateQuiz(Map<String, TextEditingController> fields) {
    if (_formKey.currentState!.validate()) {
      AssignmentForm af = AssignmentForm(
          subject: selectedSubject != null
              ? selectedSubject.toString()
              : fields['subject']!.text,
          topic: fields['description']!.text,
          gradeLevel:
              selectedGradeLevel.toString(), // Get these programatically?
          title: fields['name']!.text,
          trueFalseCount: int.parse(fields['trueFalse']!.text),
          shortAnswerCount: int.parse(fields['shortAns']!.text),
          multipleChoiceCount: int.parse(fields['multipleChoice']!.text),
          maximumGrade: 100);
      generateQuestions(af);
    }
  }

  Future<void> generateQuestions(AssignmentForm af) async {
    final perplexityApiKey = LocalStorageService.getPerplexityKey();
    final openApiKey = LocalStorageService.getOpenAIKey();
    // final claudApiKey = LocalStorageService.getClaudeKey();
    try {
      setState(() {
        _isLoading = true;
      });
      final aiModel;
      if (selectedLLM == 'ChatGPT') {
        aiModel = OpenAiLLM(openApiKey);
      } else if (selectedLLM == 'Perplexity') {
        aiModel = ClaudeAiAPI(perplexityApiKey);
      } else {
        // aiModel = OpenAiLLM(perplexityApiKey);
        aiModel = PerplexityLLM(perplexityApiKey);
      }
      var result = await aiModel.postToLlm(PromptEngine.generatePrompt(af));
      if (result.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EditQuestionsGoogle(result)));
      }
    } catch (e) {
      print("Failure sending request to LLM: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
            title: 'Create Assessment',
            userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                            child: _isLoading
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(
                                          height: paddingHeight,
                                        ),
                                        Text(
                                          'Generating Quiz Questions...',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.black54),
                                        )
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: Table(columnWidths: const {
                                    0: FlexColumnWidth(2)
                                  }, children: [
                                    TableRow(children: [
                                      SizedBox(height: paddingHeight)
                                    ]),
                                    TableRow(children: [
                                      TextEntry._('Assessment Name', true,
                                          CreateAssessmentGoogle.nameController)
                                    ]),
                                    TableRow(children: [
                                      SizedBox(height: paddingHeight)
                                    ]),
                                    TableRow(children: [
                                      TextEntry._(
                                        'Description',
                                        false,
                                        CreateAssessmentGoogle
                                            .descriptionController,
                                        isTextArea: true,
                                      )
                                    ]),
                                    TableRow(children: [
                                      SizedBox(height: paddingHeight)
                                    ]),
                                    TableRow(children: [
                                      isAdvancedModeOnGetFromGlobalVarsLater
                                          ? TextEntry._(
                                              'Question Subject',
                                              true,
                                              CreateAssessmentGoogle
                                                  .subjectController)
                                          : DropdownButtonFormField<String>(
                                              value: selectedSubject,
                                              decoration: const InputDecoration(
                                                  labelText: "Select Subject"),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedSubject = newValue;
                                                });
                                              },
                                              items:
                                                  _subjects.map((String value) {
                                                return DropdownMenuItem(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                            )
                                    ]),
                                    TableRow(children: [
                                      SizedBox(height: paddingHeight)
                                    ]),
                                    TableRow(children: [
                                      DropdownButtonFormField<String>(
                                        value: selectedGradeLevel,
                                        decoration: const InputDecoration(
                                            labelText: "Select Grade Level"),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedGradeLevel = newValue;
                                          });
                                        },
                                        items: _gradeLevels.map((String value) {
                                          return DropdownMenuItem(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                      )
                                    ]),
                                    TableRow(children: [
                                      SizedBox(height: paddingHeight)
                                    ]),
                                    TableRow(children: [
                                      NumberEntry._(
                                          'Total Multiple Choice Questions',
                                          true,
                                          CreateAssessmentGoogle
                                              .multipleChoiceController)
                                    ]),
                                    TableRow(children: [
                                      SizedBox(height: paddingHeight)
                                    ]),
                                    TableRow(children: [
                                      NumberEntry._(
                                          'Total True / False Questions',
                                          true,
                                          CreateAssessmentGoogle
                                              .trueFalseController)
                                    ]),
                                    TableRow(children: [
                                      SizedBox(height: paddingHeight)
                                    ]),
                                    TableRow(children: [
                                      NumberEntry._(
                                          'Total Short Answer Questions',
                                          true,
                                          CreateAssessmentGoogle
                                              .shortAnswerController)
                                    ]),
                                  ])))
                      ],
                    )),
                SizedBox(width: paddingWidth),
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: paddingHeight),
                      Text(
                          "Choose a total number of questions equal to four or five times the number of students in the course to guarantee unique quizzes per student"),
                      SizedBox(height: paddingHeight),
                      DropdownButtonFormField<String>(
                          value: selectedLLM,
                          decoration:
                              const InputDecoration(labelText: "Select Model"),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedLLM = newValue;
                            });
                          },
                          items: ['ChatGPT', 'CLAUDE', 'Perplexity']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList()),
                      SizedBox(height: paddingHeight),
                      ElevatedButton(
                          onPressed: () => generateQuiz({
                                "name": CreateAssessmentGoogle.nameController,
                                "description": CreateAssessmentGoogle
                                    .descriptionController,
                                "subject":
                                    CreateAssessmentGoogle.subjectController,
                                "multipleChoice": CreateAssessmentGoogle
                                    .multipleChoiceController,
                                "trueFalse":
                                    CreateAssessmentGoogle.trueFalseController,
                                "shortAns":
                                    CreateAssessmentGoogle.shortAnswerController
                              }),
                          child: Text("Submit"))
                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }
}

class NumberEntry extends StatelessWidget {
  final String title;
  final bool needsValidation;
  final TextEditingController controller;

  NumberEntry._(this.title, this.needsValidation, this.controller);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (needsValidation && (value == null || value.isEmpty)) {
          controller.text = '0';
        }
        return null;
      },
      decoration:
          InputDecoration(border: OutlineInputBorder(), labelText: title),
    );
  }
}

class TextEntry extends StatelessWidget {
  final String title;
  final bool needsValidation, isTextArea;
  final TextEditingController controller;

  TextEntry._(this.title, this.needsValidation, this.controller,
      {this.isTextArea = false});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: (value) {
        if (needsValidation && (value == null || value.isEmpty)) {
          return 'Please enter a value for $title';
        }
        return null;
      },
      decoration:
          InputDecoration(border: OutlineInputBorder(), labelText: title),
      maxLines: isTextArea ? 6 : 1,
    );
  }
}
