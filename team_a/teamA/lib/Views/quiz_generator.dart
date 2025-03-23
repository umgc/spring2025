import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learninglens_app/Api/llm/prompt_engine.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';
import 'package:learninglens_app/Api/lms/constants/learning_lens.constants.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/beans/assignment_form.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'edit_questions.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';

class CreateAssessment extends StatefulWidget {
  static TextEditingController nameController = TextEditingController();
  static TextEditingController descriptionController = TextEditingController();
  static TextEditingController subjectController = TextEditingController();
  static TextEditingController multipleChoiceController =
      TextEditingController();
  static TextEditingController trueFalseController = TextEditingController();
  static TextEditingController shortAnswerController = TextEditingController();
  static TextEditingController topicController = TextEditingController();
  static TextEditingController llmController = TextEditingController();

  CreateAssessment();

  @override
  State createState() {
    return _AssessmentState();
  }
}

class _AssessmentState extends State<CreateAssessment> {
  double paddingHeight = 16.0, paddingWidth = 32;
  bool isAdvancedModeOnGetFromGlobalVarsLater = false;
  final _formKey = GlobalKey<FormState>();
  String? selectedSubject, selectedGradeLevel;
  LlmType? selectedLLM;
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
      // Parse question counts, defaulting to 0 if empty
      int multipleChoiceCount =
          int.tryParse(fields['multipleChoice']!.text) ?? 0;
      int trueFalseCount = int.tryParse(fields['trueFalse']!.text) ?? 0;
      int shortAnswerCount = int.tryParse(fields['shortAns']!.text) ?? 0;

      // Check if at least one type of question is greater than 1
      if (multipleChoiceCount <= 0 &&
          trueFalseCount <= 0 &&
          shortAnswerCount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Please ensure at least one type of question has a count greater than 0.'),
          ),
        );
        return;
      }

      AssignmentForm af = AssignmentForm(
        subject: selectedSubject != null
            ? selectedSubject.toString()
            : fields['subject']!.text,
        topic: fields['description']!.text,
        gradeLevel: selectedGradeLevel.toString(),
        title: fields['name']!.text,
        trueFalseCount: trueFalseCount,
        shortAnswerCount: shortAnswerCount,
        multipleChoiceCount: multipleChoiceCount,
        maximumGrade: 100,
      );
      generateQuestions(af);
    }
  }

  Future<void> generateQuestions(AssignmentForm af) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final aiModel;
      if (selectedLLM == LlmType.CHATGPT) {
        aiModel = OpenAiLLM(LocalStorageService.getOpenAIKey());
      } else if (selectedLLM == LlmType.GROK) {
        aiModel = GrokLLM(LocalStorageService.getGrokKey());
      } else if (selectedLLM == LlmType.PERPLEXITY) {
        aiModel = PerplexityLLM(LocalStorageService.getPerplexityKey());
      } else {
        aiModel = OpenAiLLM(LocalStorageService.getOpenAIKey());
      }
      var result = await aiModel.postToLlm(PromptEngine.generatePrompt(af));
      if (result.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => EditQuestions(result)));
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
        onRefresh: () {
          // _loadCourses();
        },
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: paddingHeight),
                                  Text(
                                    'Generating Quiz Questions...',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.black54),
                                  )
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              child: Table(
                                columnWidths: const {0: FlexColumnWidth(2)},
                                children: [
                                  TableRow(children: [
                                    SizedBox(height: paddingHeight)
                                  ]),
                                  TableRow(children: [
                                    TextEntry._('Assessment Name', true,
                                        CreateAssessment.nameController)
                                  ]),
                                  TableRow(children: [
                                    SizedBox(height: paddingHeight)
                                  ]),
                                  TableRow(children: [
                                    TextEntry._(
                                      'Description',
                                      false,
                                      CreateAssessment.descriptionController,
                                      isTextArea: true,
                                    )
                                  ]),
                                  TableRow(children: [
                                    SizedBox(height: paddingHeight)
                                  ]),
                                  TableRow(children: [
                                    isAdvancedModeOnGetFromGlobalVarsLater
                                        ? TextEntry._('Question Subject', true,
                                            CreateAssessment.subjectController)
                                        : DropdownButtonFormField<String>(
                                            value: selectedSubject,
                                            decoration: const InputDecoration(
                                                labelText: "Select Subject"),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                selectedSubject = newValue;
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null) {
                                                return 'Please select a subject.';
                                              }
                                              return null;
                                            },
                                            items:
                                                _subjects.map((String value) {
                                              return DropdownMenuItem(
                                                  value: value,
                                                  child: Text(value));
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
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Please select a grade level.';
                                        }
                                        return null;
                                      },
                                      items: LearningLensConstants.gradeLevels
                                          .map((String value) {
                                        return DropdownMenuItem(
                                            value: value, child: Text(value));
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
                                        CreateAssessment
                                            .multipleChoiceController)
                                  ]),
                                  TableRow(children: [
                                    SizedBox(height: paddingHeight)
                                  ]),
                                  TableRow(children: [
                                    NumberEntry._(
                                        'Total True / False Questions',
                                        true,
                                        CreateAssessment.trueFalseController)
                                  ]),
                                  TableRow(children: [
                                    SizedBox(height: paddingHeight)
                                  ]),
                                  TableRow(children: [
                                    NumberEntry._(
                                        'Total Short Answer Questions',
                                        true,
                                        CreateAssessment.shortAnswerController)
                                  ]),
                                ],
                              ),
                            ),
                    )
                  ],
                ),
              ),
              SizedBox(width: paddingWidth),
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: paddingHeight),
                    Text(
                      "Choose a total number of questions equal to four or five times the number of students in the course to guarantee unique quizzes per student",
                    ),
                    SizedBox(height: paddingHeight),
                    DropdownButtonFormField<LlmType>(
                      value: selectedLLM,
                      decoration:
                          const InputDecoration(labelText: "Select Model"),
                      onChanged: (LlmType? newValue) {
                        setState(() {
                          selectedLLM = newValue;
                          CreateAssessment.llmController.text =
                              newValue!.displayName;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select an LLM model to generate the quiz.';
                        }
                        return null;
                      },
                      items: LlmType.values.map((LlmType llm) {
                        return DropdownMenuItem<LlmType>(
                          value: llm,
                          enabled: LocalStorageService.userHasLlmKey(llm),
                          child: Text(
                            llm.displayName,
                            style: TextStyle(
                              color: LocalStorageService.userHasLlmKey(llm)
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: paddingHeight),
                    ElevatedButton(
                      onPressed: () => generateQuiz({
                        "name": CreateAssessment.nameController,
                        "description": CreateAssessment.descriptionController,
                        "subject": CreateAssessment.subjectController,
                        "multipleChoice":
                            CreateAssessment.multipleChoiceController,
                        "trueFalse": CreateAssessment.trueFalseController,
                        "shortAns": CreateAssessment.shortAnswerController,
                      }),
                      child: Text("Submit"),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
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
        if (value == null || value.isEmpty) {
          controller.text = '0'; // Default to 0 if empty
          return null;
        }
        int? numValue = int.tryParse(value);
        if (numValue == null) {
          return 'Please enter a valid number for $title.';
        }
        return null;
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: title,
      ),
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
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: title,
      ),
      maxLines: isTextArea ? 6 : 1,
    );
  }
}
