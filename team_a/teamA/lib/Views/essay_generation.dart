import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/constants/learning_lens.constants.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/essay_edit_page.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'dart:convert';
import '../Api/llm/perplexity_api.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';


// Required Components:
// 2 Dropdowns: 1 for the Grade Level and 1 for the Point Scale
// 3 Text Boxes: Standard/Objective, Assignment Description, Additional Customization for Rubric (Optional)
// Audio icon for each textbox for readback?
// Paper clip for each textbox for attachments?
// 2 Buttons: 1 Generate Essay Button, 1 Send to Moodle Button
// 1 Frame to show the rubric that was generated?

class EssayGeneration extends StatefulWidget {
  const EssayGeneration({super.key, required this.title});
  final String title;

  @override
  State<EssayGeneration> createState() => _EssayGenerationState();
}

class _EssayGenerationState extends State<EssayGeneration> 
{
    //Holds values for user input fields
  int _selectedPointScale = 3; // Default value
  String _selectedGradeLevel = LearningLensConstants.gradeLevels.last; // Default value for GradeLevelDropdown
  bool _isLoading = false;
  // String? selectedLLM = 'Perplexity'; // default
  LlmType? selectedLLM;

  // llm options
  final List<String> llmOptions = ['ChatGPT', 'CLAUDE', 'Perplexity'];

  // Variables to store the text inputs
  final TextEditingController _standardObjectiveController =
      TextEditingController();
  final TextEditingController _assignmentDescriptionController =
      TextEditingController();
  final TextEditingController _additionalCustomizationController =
      TextEditingController();

  dynamic globalRubric;
  dynamic rubricasjson;

  // api keys
  // final perplexityApiKey = LocalStorageService.getPerplexityKey();
  // final openApiKey = LocalStorageService.getOpenAIKey();
  // final claudeApiKey =  LocalStorageService.getClaudeKey();

  // event handlers
  void _handlePointScaleChanged(int? newValue) {
    setState(() {
      if (newValue != null) {
        _selectedPointScale = newValue;
      }
    });
  }

  // Function to store the selected grade level value
  void _handleGradeLevelChanged(String? newValue) {
    setState(() {
      if (newValue != null) {
        _selectedGradeLevel = newValue;
      }
    });
  }

  // Handle LLM Selection
  void _handleLLMChanged(LlmType? newValue) {
    setState(() {
      if (newValue != null) {
        selectedLLM = newValue;
      }
    });
  }

  // Get api key for selected LLM
  String getApiKey() {
    switch (selectedLLM) {
      case LlmType.CHATGPT:
        return LocalStorageService.getOpenAIKey();
      case LlmType.GROK:
        return LocalStorageService.getGrokKey();
      case LlmType.PERPLEXITY:
        return LocalStorageService.getPerplexityKey();
      default:
        return LocalStorageService.getOpenAIKey();
    }
  }

  Future<dynamic> pingApi(String inputs) async {
    try {
      setState(() {
        _isLoading = true; // Set loading state to true
      });

      String apiKey =
          getApiKey(); // Get the correct API key based on the selected LLM
      if (apiKey.isEmpty) {
        throw Exception("API key is missing");
      }

      // Dynamically instantiate the appropriate LLM class based on the selectedLLM
      dynamic llmInstance;
      if (selectedLLM == LlmType.CHATGPT) {
        llmInstance = OpenAiLLM(getApiKey());
      } else if (selectedLLM == LlmType.GROK) {
        llmInstance = GrokLLM(getApiKey());
      } else if (selectedLLM == LlmType.PERPLEXITY) {
        llmInstance = PerplexityLLM(getApiKey()); // Perplexity API class
      } else {
        throw Exception('Invalid LLM selected.');
      }

      String queryPrompt = '''
        I am building a program that creates rubrics when provided with assignment information. I will provide you with the following information about the assignment that needs a rubric:
        Difficulty level, point scale, assignment objective, assignment description. You may also receive additional customization rules.
        Using this information, you will reply with a rubric that includes 4 criteria. Your reply must only contain the JSON information, and begin with a {.
        Remove any ``` from your output.

        You must reply with a representation of the rubric in JSON format that exactly matches this format: 
        {
            "criteria": [
                {
                    "description": #CriteriaName,
                    "levels": [
                        { "definition": #CriteriaDef, "score": #ScoreValue },
                    ]
                }
          ]
        }
        #CriteriaName must be replaced with the name of the criteria.
        #CriteriaDef must be replaced with a detailed description of what meeting that criteria would look like for each scale value.
        #ScoreValue must be replaced with a number representing the score. The score for the lowest scale value will be 0, and the scores will increase by 1 for each scale.
        You should create as many "levels" objects as there are point scale values.
        Make sure the JSON exactly matches the format above, or you will receive an error.
        Do not include any additional information in your response.
        Here is the assignment information:
        $inputs
      ''';
      globalRubric = await llmInstance.postToLlm(queryPrompt);
      globalRubric = globalRubric.replaceAll('```', '').trim();
      return jsonDecode(globalRubric);
    } catch (e) {
      print("Error in API request: $e");
      return null;
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state to false
      });
    }
  }

  String getSelectedResponses() {
    return '''
      Selected Grade Level: $_selectedGradeLevel
      Selected Point Scale: $_selectedPointScale
      Standard / Objective: ${_standardObjectiveController.text}
      Assignment Description: ${_assignmentDescriptionController.text}
      Additional Customization: ${_additionalCustomizationController.text}
    ''';
  }

  @override
  void dispose() {
    // Dispose the controllers when the widget is removed from the widget tree
    _standardObjectiveController.dispose();
    _assignmentDescriptionController.dispose();
    _additionalCustomizationController.dispose();
    super.dispose();
  }
  _EssayGenerationState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Create Essay Rubric', userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          // Using Row to split screen into two sections
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Left Column
            Expanded(
              flex:
                  2, // This controls the space for the left side, bigger ratio
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text("Rubric Generator",
                      style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 16),

                  // Grade Level Dropdown
                  GradeLevelDropdown(
                    selectedGradeLevel: _selectedGradeLevel,
                    onChanged: _handleGradeLevelChanged,
                  ),

                  const SizedBox(height: 16),

                  // Point Scale Dropdown
                  PointScaleDropdown(
                    selectedPointScale: _selectedPointScale,
                    onChanged: _handlePointScaleChanged,
                  ),

                  const SizedBox(height: 16),

                  // LLM Selection Dropdown
                  DropdownButton<LlmType>(
                    value: selectedLLM,
                    onChanged: _handleLLMChanged,
                    // items: <String>['Perplexity', 'OpenAI', 'Claude']
                    //     .map<DropdownMenuItem<String>>((String value) {
                    //   return DropdownMenuItem<String>(
                    //     value: value,
                    //     child: Text(value),
                    //   );
                    // }).toList(),
                    items: LlmType.values.map((LlmType llm) {
                      return DropdownMenuItem<LlmType>(
                        value: llm,
                        enabled: LocalStorageService.userHasLlmKey(llm),
                        child: Text(llm.displayName, style: TextStyle(
                          color: LocalStorageService.userHasLlmKey(llm) ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      );
                    }).toList()
                  ),

                  const SizedBox(height: 16),

                  // Standard/objective
                  TextBox(
                    label: "Standard / Objective",
                    // icon: Icons.mic,
                    // secondaryIcon: Icons.attachment,
                    initialValue: '',
                    onChanged: (newValue) {
                      _standardObjectiveController.text = newValue!;
                    },
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Assignment description
                  TextBox(
                    label: "Assignment Description",
                    // icon: Icons.mic,
                    // secondaryIcon: Icons.attachment,
                    initialValue: '',
                    onChanged: (newValue) {
                      _assignmentDescriptionController.text = newValue!;
                    },
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Additional customization
                  TextBox(
                    label: "Additional Customization for Rubric (Optional)",
                    // icon: Icons.mic,
                    // secondaryIcon: Icons.attachment,
                    initialValue: '',
                    onChanged: (newValue) {
                      _additionalCustomizationController.text = newValue!;
                    },
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),

                  // Generate Button
                  Button(
                    'essay',
                    onPressed: () {
                      final result = getSelectedResponses();

                      pingApi(result).then((dynamic results) {
                        setState(() {
                          rubricasjson = globalRubric;
                          globalRubric = results; // Store the rubric
                        });
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 32), // Adds space between the two columns

            // Right Side
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 600,
                    color: Colors.grey[200],
                    child:
                        _isLoading // Make the container dependent on the isLoading var
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(), // Loading spinner
                                    SizedBox(height: 16),
                                    Text(
                                      "Generating Rubric...", // Display this text when we start loading
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              )
                            : globalRubric != null &&
                                    globalRubric['criteria'] != null
                                ? SingleChildScrollView(
                                    child: Table(
                                      border: TableBorder
                                          .all(), // Adds border to the table cells
                                      columnWidths: const {
                                        0: FlexColumnWidth(
                                            1), // Description column
                                        // Dynamically add scores per column
                                      },
                                      children: [
                                        TableRow(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                'Criteria',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                            ),

                                            // Dynamically create score level headers
                                            for (var level in globalRubric[
                                                    'criteria'][0][
                                                'levels']) // Assuming all criteria have the same number of levels
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  '${level['score']}',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                          ],
                                        ),

                                        // Create rows
                                        for (var criteria
                                            in globalRubric['criteria']) ...[
                                          TableRow(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  criteria['description'],
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),

                                              // Add score levels for each column
                                              for (var level
                                                  in criteria['levels'])
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    '${level['definition']}',
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      "No Rubric Data Available",
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.black54),
                                    ),
                                  ),
                  ),
                  const SizedBox(height: 16),
                  // Send to Moodle Button
                  Button(
                    "assessment",
                    onPressed: rubricasjson != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EssayEditPage(rubricasjson, _assignmentDescriptionController.text),
                              ),
                            );
                          }
                        : null, // Disable button when rubricasjson is null
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Create Class for Buttons
class Button extends StatelessWidget {
  // Fields in this widget subclass are marked final
  final String type;
  final String text;
  final String filters = "";
  final VoidCallback? onPressed;
  Button._(this.type, this.text, {this.onPressed});

  factory Button(String type, {VoidCallback? onPressed}) {
    if (type == "assessment") {
      return Button._(
        type,
        "Continue (Edit Rubric)",
        onPressed: onPressed,
      );
    } else if (type == "essay") {
      return Button._(
        type,
        "Generate Rubric",
        onPressed: onPressed,
      );
    } else {
      return Button._(type, "");
    }
  }
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.create), Text(text)],
        ));
  }
}

class TextBox extends StatefulWidget {
  // Create stateful widget to maintain persistence in textboxes from events
  final String label;
  // final IconData icon;
  // final IconData secondaryIcon;
  final String initialValue;
  final ValueChanged<String?> onChanged;
  final int maxLines;

  const TextBox({
    super.key,
    required this.label,
    // required this.icon,
    // required this.secondaryIcon,
    required this.initialValue,
    required this.onChanged,
    this.maxLines = 1,
  });

  @override
  TextBoxState createState() => TextBoxState();
}

class TextBoxState extends State<TextBox> {
  // State within
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller with initial value
    _controller = TextEditingController(text: widget.initialValue);
    // Listen for changes
    _controller.addListener(() {
      widget.onChanged(_controller.text); // Call the passed onChanged function
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller, // Use the controller initialized in initState
      maxLines: widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.label,
        // prefixIcon: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          // children: [
          //   Icon(widget.icon),
          //   SizedBox(height: 4),
          //   Icon(widget.secondaryIcon),
          // ],
        // ),
      ),
    );
  }
}

class PointScaleDropdown extends StatelessWidget {
  final int selectedPointScale;
  // We need to store the value of the int the user inputs
  final ValueChanged<int?> onChanged;

  const PointScaleDropdown({
    Key? key,
    required this.selectedPointScale,
    required this.onChanged,
  }) : super(key: key);

  void _handleValueChanged(int? newValue) {
    // Additional Logic
    onChanged(newValue); // Call the passed onChanged function
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(labelText: "Point Scale"),
      value: selectedPointScale,
      items: [1, 2, 3, 4, 5].map((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text(value.toString()),
        );
      }).toList(),
      onChanged: _handleValueChanged,
    );
  }
}

class GradeLevelDropdown extends StatelessWidget {
  final String selectedGradeLevel;
  // We need to store the value of the string the user inputs
  final ValueChanged<String?> onChanged;

  const GradeLevelDropdown({
    Key? key,
    required this.selectedGradeLevel,
    required this.onChanged,
  }) : super(key: key);

  void _handleTextChanged(String? newValue) {
    // Additional Logic
    onChanged(newValue); // Call the passed onChanged function
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: "Grade Level"),
      value: selectedGradeLevel.isNotEmpty ? selectedGradeLevel : null,
      items: LearningLensConstants.gradeLevels
          .map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: _handleTextChanged,
    );
  }
}
