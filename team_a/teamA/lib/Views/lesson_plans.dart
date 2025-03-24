import "package:flutter/material.dart";
import "package:learninglens_app/Api/lms/constants/learning_lens.constants.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart";
import "package:learninglens_app/Controller/custom_appbar.dart";
import "package:learninglens_app/Views/lesson.dart";
import "package:learninglens_app/beans/course.dart";
import "package:learninglens_app/beans/lesson_plan.dart";
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'dart:convert';

// Define a constant for grade levels

class LessonPlans extends StatefulWidget {
  @override
  State createState() => _LessonPlanState();
}

class _LessonPlanState extends State<LessonPlans> {
  List<Course>? courses = [];
  String? selectedCourse;
  List<LessonPlan> lessonPlans = [];
  LessonPlan? selectedLessonPlan;
  bool isEditing = false;
  bool useAiGeneration = false;
  LlmType? selectedLLM;
  bool isSubmitDisabled = false;
  String? selectedGradeLevel;
  bool isSubmitting = false;

  //final ScrollController _scrollController = ScrollController();
  List<ScrollController> _scrollControllers = [];

  final TextEditingController lessonPlanNameController = TextEditingController();
  final TextEditingController manualEntryController = TextEditingController();
  final TextEditingController additionalPromptController = TextEditingController(); // New controller
  bool showAiPromptSection = false; // New state variable to control visibility
  bool isGeneratingLesson = false; // New state variable for loading state

  @override
  void dispose() {
    lessonPlanNameController.dispose();
    manualEntryController.dispose();
    additionalPromptController.dispose();
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCourses(); // Load courses when the widget initializes
  }

  Future<void> _loadCourses() async {
    try {
      var userCourses = await LmsFactory.getLmsService().courses;
      setState(() {
        courses = userCourses; // Update the state with fetched courses
      });
    } catch (e) {
      print("Error loading courses: $e");
    }
  }

  void _fetchLessonPlans(int courseId) async {
    List<LessonPlan> plans = await MoodleLmsService().getLessonPlans(courseId);
    setState(() {
      lessonPlans = plans;
      _scrollControllers = List.generate(
        lessonPlans.length,
        (index) => ScrollController(),
        growable: true,
      );
    });
  }

  String normalizeText(String text) {
  return text
      .replaceAll('â', "'") // Replace garbled curly apostrophe with a plain apostrophe
      .replaceAll('’', "'")   // Replace Unicode curly apostrophe with a plain apostrophe
      .replaceAll('“', '"')   // Replace Unicode left double quotation mark
      .replaceAll('”', '"')   // Replace Unicode right double quotation mark
      .replaceAll('‘', "'")   // Replace Unicode left single quotation mark
      .replaceAll('’', "'");  // Replace Unicode right single quotation mark
}

  Future<void> generateLessonPlanWithAI() async {
  try {
    final aiModel;
    if (selectedLLM == LlmType.CHATGPT) {
      aiModel = OpenAiLLM(LocalStorageService.getOpenAIKey());
    } else if (selectedLLM == LlmType.GROK) {
      aiModel = GrokLLM(LocalStorageService.getGrokKey());
    } else {
      aiModel = PerplexityLLM(LocalStorageService.getPerplexityKey());
    }

    String prompt = """Generate an all text (no diagrams) lesson of less than 500 words for ${lessonPlanNameController.text} for grade $selectedGradeLevel covering key topics like ${manualEntryController.text}. ${additionalPromptController.text}. This lesson is WHAT THE STUDENT WILL SEE! This lesson will be viewed by students and students will use it to study from (which will help them write essays and take quizzes). IMPORTANT: Do not use any Markdown syntax (e.g., #, *, **, etc.). Use plain text only.""";
    var result = await aiModel.postToLlm(prompt);

    String normalizedText = utf8.decode(result.codeUnits);

    setState(() {
      manualEntryController.text = normalizeText(normalizedText); // Update the manual entry textbox with the AI response
    });
  } catch (e) {
    print("Error generating lesson plan: $e");
    setState(() {
      isGeneratingLesson = false; // Ensure loading spinner is hidden on error
    });
  }
}

  String _convertTextToHtml(String text) {
    return "<p>${text.replaceAll('\n\n', '</p><p>').replaceAll('\n', '<br>')}</p>";
  }

  String _stripHtmlTags(String htmlText) {
    return htmlText
        .replaceAll(RegExp(r'<p[^>]*>'), '\n\n')
        .replaceAll(RegExp(r'</p>'), '')
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
  }

  void _showLessonPlanDialog(LessonPlan plan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(plan.name),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              child: Text(_stripHtmlTags(plan.intro), textAlign: TextAlign.left),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
          onRefresh: _loadCourses, // Refresh courses when the app bar is refreshed
          userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
      body: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isNarrowScreen = constraints.maxWidth <= 805; // Breakpoint for narrow screens
            bool isMediumScreen = constraints.maxWidth > 805 && constraints.maxWidth <= 1170; // Breakpoint for medium screens

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add New Lesson Plan Section
                if (!isNarrowScreen)
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
                                  }).toList() ?? [],
                              onChanged: (value) {
                                setState(() {
                                  selectedCourse = value;
                                  _fetchLessonPlans(int.parse(value!));
                                  lessonPlanNameController.clear();
                                  manualEntryController.clear();
                                  additionalPromptController.clear(); 
                                  selectedLLM = null; 
                                  isEditing = false;
                                  isSubmitDisabled = false;
                                  useAiGeneration = false;
                                  showAiPromptSection = false;
                                  selectedGradeLevel = null;
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
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Grade Level',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedGradeLevel,
                              items: LearningLensConstants.gradeLevels.map((String value) {
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
                            SizedBox(height: 20),

                            // AI and Manual Generation Options
                            // Inside the build method, where the AI generation options are defined
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CheckboxListTile(
                                  title: Text("Generate Lesson Plan with AI"),
                                  value: useAiGeneration,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      useAiGeneration = value!;
                                      showAiPromptSection = useAiGeneration; // Show/hide the new section
                                      if (!useAiGeneration) {
                                        selectedLLM = null; // Reset dropdown when unchecked
                                      }
                                    });
                                  },
                                ),

                                if (useAiGeneration)
                                  DropdownButtonFormField<LlmType>(
                                    value: selectedLLM,
                                    decoration: const InputDecoration(labelText: "Select AI Model"),
                                    onChanged: (LlmType? newValue) {
                                      setState(() {
                                        selectedLLM = newValue;
                                      });
                                    },
                                    items: LlmType.values.map((LlmType llm) {
                                      return DropdownMenuItem<LlmType>(
                                        value: llm,
                                        enabled: LocalStorageService.userHasLlmKey(llm),
                                        child: Text(llm.displayName, style: TextStyle(
                                          color: LocalStorageService.userHasLlmKey(llm) ? Colors.black87 : Colors.grey,
                                        )),
                                      );
                                    }).toList(),
                                    disabledHint: Text("Enable AI to select a model"),
                                  ),

                                // New UI elements for additional AI prompt
                                if (showAiPromptSection)
                                  Column(
                                    children: [
                                      SizedBox(height: 20),
                                      TextField(
                                        controller: additionalPromptController,
                                        maxLines: 4, // Half the height of the manual entry textbox
                                        decoration: InputDecoration(
                                          labelText: "Enter any additional prompts for the AI model to customize your lesson",
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      ElevatedButton(
                                        onPressed: isGeneratingLesson || selectedLLM == null
                                            ? null
                                            : () async {
                                                setState(() {
                                                  isGeneratingLesson = true; // Show loading spinner
                                                });

                                                await generateLessonPlanWithAI(); // Call the AI generation logic

                                                setState(() {
                                                  isGeneratingLesson = false; // Hide loading spinner
                                                });
                                              },
                                        child: isGeneratingLesson
                                            ? SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : Text("Generate Lesson Plan"),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            SizedBox(height: 20),

                            // Textbox for Lesson Plan Content
                            TextField(
                              controller: manualEntryController,
                              maxLines: 8,
                              decoration: InputDecoration(
                                labelText: useAiGeneration
                                    ? "Edit the AI-generated lesson plan"
                                    : "Enter Lesson Plan Manually",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Submit Button
                            ElevatedButton(
                              onPressed: isSubmitDisabled || isSubmitting
                                  ? null
                                  : () async {
                                      setState(() {
                                        isSubmitting = true;
                                      });

                                      if (selectedCourse != null) {
                                        Lesson newLp = Lesson(
                                          lessonPlanName: lessonPlanNameController.text,
                                          courseId: int.parse(selectedCourse!),
                                          content: _convertTextToHtml(manualEntryController.text),
                                        );
                                        bool success = await newLp.submitLesson();
                                        print(success ? 'Lesson plan sent successfully' : 'Lesson plan send failed');
                                        _fetchLessonPlans(int.parse(selectedCourse!));
                                        lessonPlanNameController.clear();
                                        manualEntryController.clear();
                                        additionalPromptController.clear();
                                        selectedLLM = null;
                                        useAiGeneration = false;
                                        
                                      }

                                      setState(() {
                                        isSubmitting = false;
                                      });
                                    },
                              child: isSubmitting
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text('Submit'),
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
                                  columnSpacing: 10,
                                  columns: [
                                    DataColumn(
                                      label: SizedBox(
                                        width: 100,
                                        child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    if (!isMediumScreen) // Hide Lesson Plan column for medium screens
                                      DataColumn(
                                        label: SizedBox(
                                          width: 200,
                                          child: Text('Lesson Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    DataColumn(
                                      label: Text('Select', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    DataColumn(
                                      label: Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                  rows: lessonPlans.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    LessonPlan plan = entry.value;
                                    bool isSelected = selectedLessonPlan == plan;
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          ConstrainedBox(
                                            constraints: BoxConstraints(maxWidth: 150),
                                            child: Text(
                                              plan.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        if (!isMediumScreen) // Hide Lesson Plan column for medium screens
                                          DataCell(
                                            ConstrainedBox(
                                              constraints: BoxConstraints(maxWidth: 250),
                                              child: Container(
                                                height: 60, // Fixed height to maintain row size
                                                child: Scrollbar(
                                                  controller: _scrollControllers[index], // Add a ScrollController
                                                  child: SingleChildScrollView(
                                                    controller: _scrollControllers[index], // Add a ScrollController
                                                    scrollDirection: Axis.vertical,
                                                    child: Text(
                                                      _stripHtmlTags(plan.intro),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        DataCell(
                                          Checkbox(
                                            value: isSelected,
                                            onChanged: (bool? selected) {
                                              setState(() {
                                                selectedLessonPlan = selected! ? plan : null;
                                              });
                                            },
                                          ),
                                        ),
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
                                  onPressed: selectedLessonPlan != null && !isEditing
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
                                  onPressed: selectedLessonPlan != null && !isEditing
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
                                          additionalPromptController.clear();
                                          selectedLLM = null;
                                          useAiGeneration = false;

                                          setState(() {
                                            selectedLessonPlan = null;
                                            isEditing = false;
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

                // For Narrow Screens (805px or less)
                if (isNarrowScreen)
                  Column(
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
                            }).toList() ?? [],
                        onChanged: (value) {
                          setState(() {
                            selectedCourse = value;
                            _fetchLessonPlans(int.parse(value!));
                            lessonPlanNameController.clear();
                            manualEntryController.clear();
                            additionalPromptController.clear(); 
                            additionalPromptController.clear();
                            selectedLLM = null; 
                            isEditing = false;
                            isSubmitDisabled = false;
                            useAiGeneration = false;
                            showAiPromptSection = false;
                            selectedGradeLevel = null;
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
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Grade Level',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedGradeLevel,
                        items: LearningLensConstants.gradeLevels.map((String value) {
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
                      SizedBox(height: 20),

                      // AI and Manual Generation Options
                      // Inside the build method, where the AI generation options are defined
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: Text("Generate Lesson Plan with AI"),
                            value: useAiGeneration,
                            onChanged: (bool? value) {
                              setState(() {
                                useAiGeneration = value!;
                                showAiPromptSection = useAiGeneration; // Show/hide the new section
                                if (!useAiGeneration) {
                                  selectedLLM = null; // Reset dropdown when unchecked
                                }
                              });
                            },
                          ),

                          if (useAiGeneration)
                            DropdownButtonFormField<LlmType>(
                              value: selectedLLM,
                              decoration: const InputDecoration(labelText: "Select AI Model"),
                              onChanged: (LlmType? newValue) {
                                setState(() {
                                  selectedLLM = newValue;
                                });
                              },
                              items: LlmType.values.map((LlmType llm) {
                                return DropdownMenuItem<LlmType>(
                                  value: llm,
                                  enabled: LocalStorageService.userHasLlmKey(llm),
                                  child: Text(llm.displayName, style: TextStyle(
                                    color: LocalStorageService.userHasLlmKey(llm) ? Colors.black87 : Colors.grey,
                                  )),
                                );
                              }).toList(),
                              disabledHint: Text("Enable AI to select a model"),
                            ),

                          // New UI elements for additional AI prompt
                          if (showAiPromptSection)
                            Column(
                              children: [
                                SizedBox(height: 20),
                                TextField(
                                  controller: additionalPromptController,
                                  maxLines: 4, // Half the height of the manual entry textbox
                                  decoration: InputDecoration(
                                    labelText: "Enter any additional prompts for the AI model to customize your lesson",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: isGeneratingLesson || selectedLLM == null
                                      ? null
                                      : () async {
                                          setState(() {
                                            isGeneratingLesson = true; // Show loading spinner
                                          });

                                          await generateLessonPlanWithAI(); // Call the AI generation logic

                                          setState(() {
                                            isGeneratingLesson = false; // Hide loading spinner
                                          });
                                        },
                                  child: isGeneratingLesson
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text("Generate Lesson Plan"),
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Textbox for Lesson Plan Content
                      TextField(
                        controller: manualEntryController,
                        maxLines: 8,
                        decoration: InputDecoration(
                          labelText: useAiGeneration
                              ? "Edit the AI-generated lesson plan"
                              : "Enter the Lesson Plan Manually",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Submit Button
                      ElevatedButton(
                        onPressed: isSubmitDisabled || isSubmitting
                            ? null
                            : () async {
                                setState(() {
                                  isSubmitting = true;
                                });

                                if (selectedCourse != null) {
                                  Lesson newLp = Lesson(
                                    lessonPlanName: lessonPlanNameController.text,
                                    courseId: int.parse(selectedCourse!),
                                    content: _convertTextToHtml(manualEntryController.text),
                                  );
                                  bool success = await newLp.submitLesson();
                                  print(success ? 'Lesson plan sent successfully' : 'Lesson plan send failed');
                                  _fetchLessonPlans(int.parse(selectedCourse!));
                                  lessonPlanNameController.clear();
                                  manualEntryController.clear();
                                  lessonPlanNameController.clear();
                                  manualEntryController.clear();
                                  additionalPromptController.clear(); 
                                  selectedLLM = null; 
                                  isEditing = false;
                                  isSubmitDisabled = false;
                                  useAiGeneration = false;
                                  showAiPromptSection = false;
                                  selectedGradeLevel = null;
                                }

                                setState(() {
                                  isSubmitting = false;
                                });
                              },
                        child: isSubmitting
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text('Submit'),
                      ),
                      SizedBox(height: 20),

                      // Existing Lesson Plans Section for Narrow Screens
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
                            columnSpacing: 10,
                            columns: [
                              DataColumn(
                                label: SizedBox(
                                  width: 100,
                                  child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              if (!isMediumScreen) // Hide Lesson Plan column for medium screens
                                DataColumn(
                                  label: SizedBox(
                                    width: 200,
                                    child: Text('Lesson Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              DataColumn(
                                label: Text('Select', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                            rows: lessonPlans.asMap().entries.map((entry) {
                              int index = entry.key;
                              LessonPlan plan = entry.value;
                              bool isSelected = selectedLessonPlan == plan;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: 150),
                                      child: Text(
                                        plan.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  if (!isMediumScreen) // Hide Lesson Plan column for medium screens
                                    DataCell(
                                      ConstrainedBox(
                                        constraints: BoxConstraints(maxWidth: 250),
                                        child: Container(
                                          height: 60, // Fixed height to maintain row size
                                          child: Scrollbar(
                                            controller: _scrollControllers[index], // Add a ScrollController
                                            child: SingleChildScrollView(
                                              controller: _scrollControllers[index], // Add a ScrollController
                                              scrollDirection: Axis.vertical,
                                              child: Text(
                                                _stripHtmlTags(plan.intro),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  DataCell(
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (bool? selected) {
                                        setState(() {
                                          selectedLessonPlan = selected! ? plan : null;
                                        });
                                      },
                                    ),
                                  ),
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
                            onPressed: selectedLessonPlan != null && !isEditing
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
                            onPressed: selectedLessonPlan != null && !isEditing
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
                                      selectedLessonPlan = null;
                                      isEditing = false;
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
              ],
            );
          },
        ),
      ),
    );
  }
}