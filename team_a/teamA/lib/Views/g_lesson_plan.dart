import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:learninglens_app/Api/llm/llm_api_modules_base.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Api/lms/google_classroom/google_classroom_api.dart";
import "package:learninglens_app/Controller/custom_appbar.dart";
import "package:learninglens_app/beans/course.dart";
import "package:learninglens_app/services/local_storage_service.dart";
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';
import 'package:logging/logging.dart';

class GoogleLessonPlans extends StatefulWidget {
  @override
  State createState() => _LessonPlanState();
}

class _LessonPlanState extends State<GoogleLessonPlans> {
  List<Course>? courses = [];
  String? selectedCourse;
  List<dynamic> courseworkMaterials = [];
  dynamic selectedMaterial;
  bool isEditing = false;
  bool useAiGeneration = false;
  String? selectedLLM;
  String? selectedGradeLevel;

  // Loading flags
  bool isLoadingCourses = false;
  bool isGeneratingAI = false;
  bool isSaving = false;
  bool isDeleting = false;
  bool isUpdating = false;

  final TextEditingController lessonPlanNameController = TextEditingController();
  final TextEditingController manualEntryController = TextEditingController();
  final TextEditingController aiPromptDetailsController = TextEditingController();
  final log = Logger('GoogleLessonPlans');
  final GoogleClassroomApi googleClassroomApi = GoogleClassroomApi();

  @override
  void dispose() {
    lessonPlanNameController.dispose();
    manualEntryController.dispose();
    aiPromptDetailsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<String?> _getToken() async {
    final token = LocalStorageService.getGoogleAccessToken();
    if (token == null) {
      log.severe('Error: No valid OAuth token.');
    }
    return token;
  }

  Future<void> _loadCourses() async {
    setState(() {
      isLoadingCourses = true;
    });
    try {
      List<Course> fetchedCourses = await LmsFactory.getLmsService().getUserCourses();
      setState(() {
        courses = fetchedCourses;
        selectedCourse = null;
      });
    } catch (e) {
      log.severe('Failed to load courses: $e');
    } finally {
      setState(() {
        isLoadingCourses = false;
      });
    }
  }

  Future<void> _loadLessonPlan(String courseId) async {
    try {
      final accessToken = await _getToken();
      if (accessToken == null) return;

      final url = Uri.parse('https://classroom.googleapis.com/v1/courses/$courseId/courseWorkMaterials');
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      };
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          courseworkMaterials = data['courseWorkMaterial'] ?? [];
          selectedMaterial = null;
          isEditing = false;
        });
      } else {
        print('Error loading coursework materials: ${response.statusCode}');
        setState(() {
          courseworkMaterials = [];
        });
      }
    } catch (e) {
      print('Error loading coursework materials: $e');
      setState(() {
        courseworkMaterials = [];
      });
    }
  }

  Future<void> generateLessonPlanWithAI() async {
    setState(() {
      isGeneratingAI = true;
    });

    final openApiKey = LocalStorageService.getOpenAIKey();
    final grokApiKey = LocalStorageService.getGrokKey();
    final perplexityApiKey = LocalStorageService.getPerplexityKey();

    try {
      late final LLM aiModel;
      switch (selectedLLM) {
        case 'ChatGPT':
          aiModel = OpenAiLLM(openApiKey);
          break;
        case 'Grok':
          aiModel = GrokLLM(grokApiKey); 
          break;
        case 'Perplexity':
          aiModel = PerplexityLLM(perplexityApiKey);
          break;
        default:
          throw Exception('Unsupported AI model: $selectedLLM');
      }

      // String prompt =
      //     "Generate a lesson plan for ${selectedGradeLevel == 'K' ? 'Kindergarten' : '${selectedGradeLevel}th grade'} ${lessonPlanNameController.text} "
      //     "covering key topics like ${manualEntryController.text}. Additional details: ${aiPromptDetailsController.text}. "
      //     "Keep it within 500 words.";

  String prompt = "Create a concise, all-text lesson plan for ${lessonPlanNameController.text} for grade ${selectedGradeLevel == 'K' ? 'Kindergarten' : selectedGradeLevel} covering ${manualEntryController.text}. ${aiPromptDetailsController.text}. Write it as student-facing content for studying, essays, and quizzes. Use plain text, no Markdown, in 500 words.";
      //String prompt = "Generate an all text lesson plan for ${lessonPlanNameController.text} for grade ${selectedGradeLevel == 'K' ? 'Kindergarten' : selectedGradeLevel} covering key topics like ${manualEntryController.text}. ${aiPromptDetailsController.text}. This lesson is WHAT THE STUDENT WILL SEE! It will be viewed by students to study from for essays and quizzes. Do not use Markdown syntax. Keep to 500 words.";

      var result = await aiModel.generate(prompt);
      setState(() {
        manualEntryController.text = result;
      });
    } catch (e) {
      log.severe("Error generating lesson plan: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate lesson plan: $e')),
      );
    } finally {
      setState(() {
        isGeneratingAI = false;
      });
    }
  }

  void _showLessonPlanDialog(dynamic lessonPlan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(lessonPlan['title'] ?? 'Untitled'),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              child: Text(lessonPlan['description'] ?? '', textAlign: TextAlign.left),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _clearFormFields() {
    lessonPlanNameController.clear();
    manualEntryController.clear();
    aiPromptDetailsController.clear();
    setState(() {
      selectedGradeLevel = null;
      useAiGeneration = false;
      selectedLLM = null;
      isEditing = false;
      selectedMaterial = null;
    });
  }

  bool _canSubmit() {
    return selectedCourse != null &&
        selectedGradeLevel != null &&
        lessonPlanNameController.text.isNotEmpty &&
        manualEntryController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Lesson Plans',
        onRefresh: _loadCourses,
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      body: isLoadingCourses
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add New Lesson Plan',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: selectedCourse,
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text('Select Course'),
                              ),
                              ...(courses?.map<DropdownMenuItem<String>>((course) {
                                    return DropdownMenuItem<String>(
                                      value: course.id.toString(),
                                      child: Text(course.fullName),
                                    );
                                  }).toList() ??
                                  [])
                            ],
                            onChanged: (value) async {
                              setState(() {
                                selectedCourse = value;
                              });
                              if (value != null) {
                                await _loadLessonPlan(value);
                              }
                            },
                            decoration: InputDecoration(labelText: 'Course', border: OutlineInputBorder()),
                          ),
                          SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: selectedGradeLevel,
                            items: ['K', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12']
                                .map<DropdownMenuItem<String>>((grade) {
                              return DropdownMenuItem<String>(
                                value: grade,
                                child: Text(grade == 'K' 
                                    ? 'Kindergarten' 
                                    : '$grade${grade == '1' ? 'st' : grade == '2' ? 'nd' : grade == '3' ? 'rd' : 'th'} Grade'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedGradeLevel = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Grade Level',
                              border: OutlineInputBorder(),
                              errorText: selectedGradeLevel == null && isSaving ? 'Grade Level is required' : null,
                            ),
                            validator: (value) => value == null ? 'Required' : null,
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: lessonPlanNameController,
                            decoration: InputDecoration(
                              labelText: 'Lesson Plan Name',
                              border: OutlineInputBorder(),
                              errorText: lessonPlanNameController.text.isEmpty && (isSaving || isGeneratingAI)
                                  ? 'Lesson Plan Name is required'
                                  : null,
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                          SizedBox(height: 20),
                          CheckboxListTile(
                            title: Text("Generate Lesson Plan with AI"),
                            value: useAiGeneration,
                            onChanged: (bool? value) {
                              setState(() {
                                useAiGeneration = value!;
                                if (!useAiGeneration) {
                                  selectedLLM = null;
                                  manualEntryController.clear();
                                  aiPromptDetailsController.clear();
                                }
                              });
                            },
                          ),
                          if (useAiGeneration)
                            Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: selectedLLM,
                                  decoration: const InputDecoration(labelText: "Select AI Model"),
                                  onChanged: (String? newValue) => setState(() => selectedLLM = newValue),
                                  items: ['ChatGPT', 'Grok', 'Perplexity'].map((String value) {
                                    return DropdownMenuItem<String>(value: value, child: Text(value));
                                  }).toList(),
                                ),
                                SizedBox(height: 20),
                                TextField(
                                  controller: aiPromptDetailsController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'Additional Details for AI Prompt',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: selectedLLM != null &&
                                          selectedGradeLevel != null &&
                                          lessonPlanNameController.text.isNotEmpty
                                      ? () async {
                                          await generateLessonPlanWithAI();
                                        }
                                      : null,
                                  child: isGeneratingAI
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text('Generate Lesson Plan'),
                                ),
                              ],
                            ),
                          SizedBox(height: 20),
                          TextField(
                            controller: manualEntryController,
                            maxLines: 8,
                            decoration: InputDecoration(
                              labelText: 'Enter/Edit Lesson Plan',
                              border: OutlineInputBorder(),
                              errorText: manualEntryController.text.isEmpty && isSaving
                                  ? 'Lesson Plan details are required'
                                  : null,
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _canSubmit()
                                ? () async {
                                    setState(() {
                                      isSaving = true;
                                    });
                                    String? materialId = await googleClassroomApi.createCourseWorkMaterial(
                                      selectedCourse!,
                                      lessonPlanNameController.text,
                                      manualEntryController.text,
                                      "https://example.com",
                                    );
                                    if (materialId != null) {
                                      await _loadLessonPlan(selectedCourse!);
                                      _clearFormFields();
                                    }
                                    setState(() {
                                      isSaving = false;
                                    });
                                  }
                                : null,
                            child: isSaving
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text('Submit'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Existing Lesson Plans',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8.0)),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 20,
                                columns: [
                                  DataColumn(
                                      label: SizedBox(
                                          width: 150,
                                          child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)))),
                                  DataColumn(
                                      label: SizedBox(
                                          width: 300,
                                          child:
                                              Text('Lesson Plan', style: TextStyle(fontWeight: FontWeight.bold)))),
                                  DataColumn(
                                      label: Text('Select', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('View', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: courseworkMaterials.map((material) {
                                  bool isSelected = selectedMaterial == material;
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: BoxConstraints(maxWidth: 150),
                                          child: Text(material['title'] ?? 'Untitled',
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: BoxConstraints(maxWidth: 300),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.vertical,
                                            child: Text(material['description'] ?? '',
                                                maxLines: 3, overflow: TextOverflow.ellipsis),
                                          ),
                                        ),
                                      ),
                                      DataCell(Checkbox(
                                        value: isSelected,
                                        onChanged: (bool? selected) {
                                          setState(() {
                                            selectedMaterial = selected! ? material : null;
                                            if (selectedMaterial != null) {
                                              lessonPlanNameController.text = selectedMaterial['title'] ?? '';
                                              manualEntryController.text = selectedMaterial['description'] ?? '';
                                              isEditing = false;
                                            } else {
                                              _clearFormFields();
                                            }
                                          });
                                        },
                                      )),
                                      DataCell(ElevatedButton(
                                        onPressed: () => _showLessonPlanDialog(material),
                                        child: Text("View"),
                                      )),
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
                                onPressed: selectedMaterial != null
                                    ? () async {
                                        setState(() {
                                          isDeleting = true;
                                        });
                                        await googleClassroomApi.deleteCourseWorkMaterial(
                                            selectedCourse!, selectedMaterial['id']);
                                        await _loadLessonPlan(selectedCourse!);
                                        _clearFormFields();
                                        setState(() {
                                          isDeleting = false;
                                        });
                                      }
                                    : null,
                                child: isDeleting
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text('Delete Selected'),
                              ),
                              ElevatedButton(
                                onPressed: selectedMaterial != null
                                    ? () => setState(() {
                                        isEditing = true;
                                        lessonPlanNameController.text = selectedMaterial['title'] ?? '';
                                        manualEntryController.text = selectedMaterial['description'] ?? '';
                                      })
                                    : null,
                                child: Text('Edit Selected'),
                              ),
                              ElevatedButton(
                                onPressed: isEditing && selectedMaterial != null
                                    ? () async {
                                        setState(() {
                                          isUpdating = true;
                                        });
                                        try {
                                          await googleClassroomApi.updateCourseWorkMaterial(
                                            selectedCourse!,
                                            selectedMaterial['id'],
                                            lessonPlanNameController.text,
                                            manualEntryController.text,
                                          );
                                          await _loadLessonPlan(selectedCourse!);
                                          _clearFormFields();
                                        } catch (e) {
                                          print('Error during update: $e');
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to update lesson plan: $e')),
                                          );
                                        } finally {
                                          setState(() {
                                            isUpdating = false;
                                          });
                                        }
                                      }
                                    : null,
                                child: isUpdating
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text('Save Update'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}