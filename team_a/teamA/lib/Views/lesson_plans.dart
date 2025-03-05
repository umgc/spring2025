import "package:flutter/material.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Api/lms/google_classroom/google_lms_service.dart";
import "package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart";
import "package:learninglens_app/Controller/custom_appbar.dart";
import "package:learninglens_app/Views/lesson.dart";
import "package:learninglens_app/beans/course.dart";
import "package:learninglens_app/beans/lesson_plan.dart";
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/llm_api.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class LessonPlans extends StatefulWidget {
  @override
  State createState() => _LessonPlanState();
}

class _LessonPlanState extends State {
  List<Course>? courses = [];
  String? selectedCourse;
  List<LessonPlan> lessonPlans = [];
  LessonPlan? selectedLessonPlan;
  bool isEditing = false;
  bool useAiGeneration = false;
  // String? selectedLLM;
  LlmType? selectedLLM;
  bool isSubmitDisabled = false; 
  String? selectedGradeLevel;



  final TextEditingController lessonPlanNameController = TextEditingController();
  final TextEditingController manualEntryController = TextEditingController();

  @override
  void dispose() {
    lessonPlanNameController.dispose();
    manualEntryController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    var userCourses = await LmsFactory.getLmsService().courses;
    setState(() {
      courses = userCourses;
    });
  }

  void _fetchLessonPlans(int courseId) async {
    List<LessonPlan> plans = await MoodleLmsService().getLessonPlans(courseId);
    setState(() {
      lessonPlans = plans;
    });
  }

  Future<void> generateLessonPlanWithAI() async {
    // final openApiKey = LocalStorageService.getOpenAIKey();
    // final grokApiKey = LocalStorageService.getGrokKey();
    // final perplexityApiKey = LocalStorageService.getPerplexityKey();

    try {
      final aiModel;
      // if (selectedLLM == 'ChatGPT') {
      //   aiModel = OpenAiLLM(openApiKey);
      // } else if (selectedLLM == 'Grok') {
      //   aiModel = GrokLLM(grokApiKey);
      // } else {
      //   aiModel = LlmApi(perplexityApiKey);
      // }
      if (selectedLLM == LlmType.CHATGPT) {
        aiModel = OpenAiLLM(LocalStorageService.getOpenAIKey());
      } else if (selectedLLM == LlmType.GROK) {
        aiModel = GrokLLM(LocalStorageService.getGrokKey());
      } else {
        aiModel = LlmApi(LocalStorageService.getPerplexityKey());
      }

      String prompt = "Generate an all text (no diagrams) lesson for ${lessonPlanNameController.text} for grade $selectedGradeLevel covering key topics like ${manualEntryController.text}. This lesson is WHAT THE STUDENT WILL SEE! This lesson will be viewed by students and students will use it to study from (which will help them write essays and take quizzes).";
      var result = await aiModel.postToLlm(prompt);

      setState(() {
        manualEntryController.text = result;
      });
    } catch (e) {
      print("Error generating lesson plan: $e");
    }
  }

  String _convertTextToHtml(String text) {
    return "<p>${text.replaceAll('\n\n', '</p><p>').replaceAll('\n', '<br>')}</p>";
  }

  String _stripHtmlTags(String htmlText) {
    return htmlText
        .replaceAll(RegExp(r'<p[^>]*>'), '\n\n') // Replace <p> with double line break
        .replaceAll(RegExp(r'</p>'), '') // Remove closing </p> tags
        .replaceAll(RegExp(r'<br\s*/?>'), '\n') // Replace <br> or <br/> with single line break
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove all other HTML tags
        .trim(); // Trim any extra newlines at the start or end
  }

  void _showLessonPlanDialog(LessonPlan plan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(plan.name), // Display Lesson Plan Name
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4, // Adjust width
              child: Text(_stripHtmlTags(plan.intro), textAlign: TextAlign.left),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Lesson Plans',
          onRefresh: _loadCourses,
          userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add New Lesson Plan',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedCourse,
                        items: courses?.map<DropdownMenuItem<String>>((course) {
                              return DropdownMenuItem<String>(
                                value: course.id.toString(),
                                child: Text(course.fullName),
                              );
                            }).toList() ??
                            [],
                        onChanged: (value) {
                          setState(() {
                            selectedCourse = value;
                            _fetchLessonPlans(int.parse(value!));
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Course',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: lessonPlanNameController,
                        decoration: InputDecoration(
                          labelText: 'Lesson Plan Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>( // Changed LlmType to String
                        decoration: const InputDecoration(
                          labelText: 'Select Grade Level',
                          border: OutlineInputBorder(),
                          ),
                        value: selectedGradeLevel, // This is where you bind to the selected value
                        items: <String>['9', '10', '11', '12'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedGradeLevel = newValue;
                          });
                        },
                      ),
                      TextField(
                        controller: manualEntryController,
                        maxLines: 8,
                        decoration: InputDecoration(
                          labelText: 'Enter Lesson Plan Manually',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),

                      CheckboxListTile(
                        title: Text("Generate Lesson Plan with AI"),
                        value: useAiGeneration,
                        onChanged: (bool? value) {
                          setState(() {
                            useAiGeneration = value!;
                            if (!useAiGeneration) {
                              selectedLLM = null; // Reset dropdown when unchecked
                            }
                          });
                        },
                      ),

                      DropdownButtonFormField<LlmType>(
                        value: selectedLLM,
                        decoration: const InputDecoration(labelText: "Select AI Model"),
                        onChanged: useAiGeneration ? (LlmType? newValue) {
                          setState(() {
                            selectedLLM = newValue;
                          });
                        } : null, // Disables interaction when checkbox is unchecked
                        // items: ['ChatGPT', 'Grok', 'Perplexity'].map((String value) {
                        //   return DropdownMenuItem<String>(
                        //     value: value,
                        //     child: Text(value),
                        //   );
                        // }).toList(),
                        items: LlmType.values.map((LlmType llm) {
                          return DropdownMenuItem<LlmType>(
                            value: llm,
                            child: Text(llm.displayName),
                          );
                        }).toList(),
                        disabledHint: Text("Enable AI to select a model"), // Greyed-out text when disabled
                      ),

                      ElevatedButton(
                        onPressed: isSubmitDisabled
                            ? null // Disable the button
                            : () async {
                                if (selectedCourse != null) {
                                  if (useAiGeneration) {
                                    await generateLessonPlanWithAI();
                                  }
                                  Lesson newLp = Lesson(
                                    lessonPlanName: lessonPlanNameController.text,
                                    courseId: int.parse(selectedCourse!),
                                    content: _convertTextToHtml(manualEntryController.text),
                                  );
                                  newLp.saveLessonLocally();
                                  bool success = await newLp.submitLesson();
                                  print(success ? 'Lesson plan sent successfully' : 'Lesson plan send failed');
                                  _fetchLessonPlans(int.parse(selectedCourse!));
                                  lessonPlanNameController.clear();
                                  manualEntryController.clear();
                                }
                              },
                        child: Text('Submit'),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Existing Lesson Plans',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 10, // Reduce spacing between columns
                            columns: [
                              DataColumn(
                                label: SizedBox(
                                  width: 100, // Reduce width of Name column
                                  child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 200, // Reduce width of Lesson Plan column
                                  child: Text('Lesson Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              DataColumn(label: Text('Select', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('View', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: lessonPlans.map((plan) {
                              bool isSelected = selectedLessonPlan == plan;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: 150), // Limit Name column width
                                      child: Text(
                                        plan.name,
                                        overflow: TextOverflow.ellipsis, // Adds "..." if text is too long
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: 250), // Limit Lesson Plan content width
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: Text(
                                          _stripHtmlTags(plan.intro),
                                          maxLines: 3, // Show only 3 lines, add scroll for longer text
                                          overflow: TextOverflow.ellipsis, // Adds "..." if content is too long
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? selected) {
                                      setState(() {
                                        selectedLessonPlan = selected! ? plan : null;
                                      });
                                    },
                                  )),
                                  DataCell(
                                    ElevatedButton(
                                      onPressed: () {
                                        _showLessonPlanDialog(plan);
                                      },
                                      child: Text("View"),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: selectedLessonPlan != null
                                ? () async {
                                    await MoodleLmsService().deleteLessonPlan(selectedLessonPlan!.id);
                                    _fetchLessonPlans(int.parse(selectedCourse!));
                                    setState(() {
                                      selectedLessonPlan = null;
                                    });
                                  }
                                : null,
                            child: Text('Delete Selected'),
                          ),
                          ElevatedButton(
                            onPressed: selectedLessonPlan != null
                                ? () {
                                    setState(() {
                                      isEditing = true;
                                      lessonPlanNameController.text = selectedLessonPlan!.name;
                                      manualEntryController.text = _stripHtmlTags(selectedLessonPlan!.intro);
                                      isSubmitDisabled = true;
                                    });
                                    
                                  }
                                : null,
                            child: Text('Edit Selected'),
                          ),
                          ElevatedButton(
                            onPressed: isEditing
                                ? () async {
                                    String manualEntryToHtml = _convertTextToHtml(manualEntryController.text);
                                    await MoodleLmsService().updateLessonPlan(
                                      lessonId: selectedLessonPlan!.id,
                                      name: lessonPlanNameController.text,
                                      intro: manualEntryToHtml,
                                      available: 1672531200, //dummy value
                                      deadline: 1675132800, //dummy value
                                    );
                                    _fetchLessonPlans(int.parse(selectedCourse!));
                                    lessonPlanNameController.clear();
                                    manualEntryController.clear();
                                    
                                    setState(() {
                                      selectedLessonPlan = null; // Reset selection
                                      isEditing = false; // Exit editing mode
                                      isSubmitDisabled = false;
                                    });
                                  }
                                : null,
                            child: Text('Save Edits'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
