import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/beans/submission_with_grade.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'view_submission_detail.dart';
import '../Api/llm/perplexity_api.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class SubmissionList extends StatefulWidget {
  final int assignmentId;
  final String courseId;

  SubmissionList({
    Key? key,
    required this.assignmentId,
    required this.courseId,
  }) : super(key: key);

  @override
  SubmissionListState createState() => SubmissionListState();
}

class SubmissionListState extends State<SubmissionList> {
  LmsInterface api = LmsFactory.getLmsService();
  Map<int, bool> isLoadingMap = {};
  Map<int, LlmType> llmSelectionMap = {};

  late Future<List<SubmissionWithGrade>> futureSubmissionsWithGrades =
      api.getSubmissionsWithGrades(widget.assignmentId);
  late Future<List<Participant>> futureParticipants =
      api.getCourseParticipants(widget.courseId);

  final LlmType defaultLlm = LlmType.PERPLEXITY;

  final perplexityApiKey = LocalStorageService.getPerplexityKey();
  final openApiKey = LocalStorageService.getOpenAIKey();
  final grokApiKey = LocalStorageService.getGrokKey();

  LlmType? selectedLLM;

  String filterOption = 'All Students';
  String fullNameFilter = '';

  String getApiKey(LlmType selectedLLM) {
    switch (selectedLLM) {
      case LlmType.CHATGPT:
        return openApiKey;
      case LlmType.GROK:
        return grokApiKey;
      default:
        return perplexityApiKey;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      futureSubmissionsWithGrades =
          api.getSubmissionsWithGrades(widget.assignmentId);
      futureParticipants = api.getCourseParticipants(widget.courseId);
    });
  }

  void _handleLLMChanged(int participantId, LlmType? newValue) {
    setState(() {
      if (newValue != null) {
        llmSelectionMap[participantId] = newValue;
      }
    });
  }

  void _handleFilterChanged(String? newValue) {
    setState(() {
      if (newValue != null) {
        filterOption = newValue;
      }
    });
  }

  void _handleFullNameFilterChanged(String newValue) {
    setState(() {
      fullNameFilter = newValue;
    });
  }

  // Widget to display the "under development" error with icon and back button
  Widget _buildUnderDevelopmentError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction, // Construction icon to indicate "under development"
            size: 60,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Submissions/Grading feature is currently not available for Google Classroom. Please reach out to the developer for more information.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Navigate back to the previous screen
            },
            child: Text('Back'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: filterOption,
                    decoration: InputDecoration(labelText: 'Submission Status'),
                    onChanged: _handleFilterChanged,
                    items: <String>['All Students', 'With Submission', 'Without Submission']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Filter by Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _handleFullNameFilterChanged,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FutureBuilder<List<Participant>>(
                  future: futureParticipants,
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Participant>> participantSnapshot) {
                    if (participantSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (participantSnapshot.hasError) {
                      if (participantSnapshot.error is UnimplementedError) {
                        return _buildUnderDevelopmentError(context);
                      }
                      return Center(
                          child: Text('Error: ${participantSnapshot.error}'));
                    } else if (!participantSnapshot.hasData ||
                        participantSnapshot.data!.isEmpty) {
                      return Center(child: Text('No participants found.'));
                    } else {
                      return FutureBuilder<List<SubmissionWithGrade>>(
                        future: futureSubmissionsWithGrades,
                        builder: (BuildContext context,
                            AsyncSnapshot<List<SubmissionWithGrade>>
                                submissionSnapshot) {
                          if (submissionSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (submissionSnapshot.hasError) {
                            if (submissionSnapshot.error is UnimplementedError) {
                              return _buildUnderDevelopmentError(context);
                            }
                            return Center(
                                child:
                                    Text('Error: ${submissionSnapshot.error}'));
                          } else {
                            List<Participant> participants =
                                participantSnapshot.data!;
                            List<SubmissionWithGrade> submissionsWithGrades =
                                submissionSnapshot.data ?? [];

                            participants.sort((a, b) {
                              int lastNameComparison =
                                  a.lastname.compareTo(b.lastname);
                              if (lastNameComparison != 0) {
                                return lastNameComparison;
                              } else {
                                return a.firstname.compareTo(b.firstname);
                              }
                            });

                            if (filterOption == 'With Submission') {
                              participants = participants.where((participant) {
                                return submissionsWithGrades.any((sub) =>
                                    sub.submission.userid == participant.id);
                              }).toList();
                            } else if (filterOption == 'Without Submission') {
                              participants = participants.where((participant) {
                                return !submissionsWithGrades.any((sub) =>
                                    sub.submission.userid == participant.id);
                              }).toList();
                            }

                            if (fullNameFilter.isNotEmpty) {
                              participants = participants.where((participant) {
                                return participant.fullname
                                    .toLowerCase()
                                    .contains(fullNameFilter.toLowerCase());
                              }).toList();
                            }

                            return SingleChildScrollView(
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                alignment: WrapAlignment.center,
                                children: participants.map((participant) {
                                  SubmissionWithGrade? submissionWithGrade =
                                      submissionsWithGrades
                                          .where((sub) =>
                                              sub.submission.userid ==
                                              participant.id)
                                          .firstOrNull;

                                  bool isLoading =
                                      isLoadingMap[participant.id] ?? false;
                                  LlmType selectedLLM = llmSelectionMap[
                                          participant.id] ??
                                      defaultLlm;
                                  return SizedBox(
                                    width: MediaQuery.of(context).size.width <
                                            450
                                        ? double.infinity
                                        : 450,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer,
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondaryContainer,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      margin: EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 16),
                                      child: Card(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer,
                                        elevation: 0,
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .onSecondary,
                                            child: Text(
                                              participant.fullname
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                              ),
                                            ),
                                          ),
                                          title: Text(participant.fullname),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (submissionWithGrade != null)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        'Grade Status: ${submissionWithGrade.submission.gradingStatus}'),
                                                    Text(
                                                        'Status: ${submissionWithGrade.submission.status}'),
                                                    Text(
                                                        'Submitted on: ${DateFormat('MMM d, yyyy h:mm a').format(submissionWithGrade.submission.submissionTime.toLocal())}'),
                                                    Text(
                                                        'Grade: ${submissionWithGrade.grade != null ? submissionWithGrade.grade!.grade.toString() : "Not graded yet"}'),
                                                    SizedBox(height: 6),
                                                    // DropdownButton<LlmType>(
                                                    DropdownButtonFormField<LlmType>(
                                                      value: selectedLLM,
                                                      decoration: InputDecoration(
                                                        labelText: 'AI',
                                                      ),
                                                      onChanged: (newValue) =>
                                                          _handleLLMChanged(
                                                              participant.id,
                                                              newValue),
                                                      items: LlmType.values
                                                          .map((LlmType llm) {
                                                        return DropdownMenuItem<
                                                            LlmType>(
                                                          value: llm,
                                                          enabled:
                                                              LocalStorageService
                                                                  .userHasLlmKey(
                                                                      llm),
                                                          child: Text(
                                                            llm.displayName,
                                                            style: TextStyle(
                                                              color: LocalStorageService
                                                                      .userHasLlmKey(
                                                                          llm)
                                                                  ? Colors
                                                                      .black87
                                                                  : Colors.grey,
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                    SizedBox(height: 4),
                                                  ],
                                                )
                                              else
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(height: 52),
                                                    Text('No Submission',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .error)),
                                                    SizedBox(height: 84),
                                                  ],
                                                ),
                                              SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  if (submissionWithGrade !=
                                                      null)
                                                    isLoading
                                                        ? CircularProgressIndicator()
                                                        : ElevatedButton(
                                                            onPressed:
                                                                () async {
                                                              try {
                                                                setState(() {
                                                                  isLoadingMap[
                                                                          participant
                                                                              .id] =
                                                                      true;
                                                                });

                                                                var submissionText =
                                                                    submissionWithGrade
                                                                        .submission
                                                                        .onlineText;
                                                                int? contextId =
                                                                    await LmsFactory
                                                                        .getLmsService()
                                                                        .getContextId(
                                                                            widget
                                                                                .assignmentId,
                                                                            widget
                                                                                .courseId);

                                                                var fetchedRubric;
                                                                if (contextId !=
                                                                    null) {
                                                                  fetchedRubric =
                                                                      await LmsFactory
                                                                          .getLmsService()
                                                                          .getRubric(widget
                                                                              .assignmentId
                                                                              .toString());
                                                                  if (fetchedRubric ==
                                                                      null) {
                                                                    print(
                                                                        'Failed to fetch rubric.');
                                                                    return;
                                                                  }
                                                                  fetchedRubric =
                                                                      jsonEncode(fetchedRubric
                                                                              ?.toJson() ??
                                                                          {});
                                                                }

                                                                String
                                                                    queryPrompt =
                                                                    '''
                                                  I am building a program that generates essay rubric assignments that teachers can distribute to students
                                                  who can then submit their responses to be graded. Here is an example format of a rubric roughly:
                                                  [
                                                      {
                                                          "id": 82,
                                                          "rubric_criteria": [
                                                              {
                                                                  "id": 52,
                                                                  "description": "Content",
                                                                  "levels": [
                                                                      {
                                                                          "id": 157,
                                                                          "score": 1,
                                                                          "definition": "Poor"
                                                                      },
                                                                      {
                                                                          "id": 156,
                                                                          "score": 3,
                                                                          "definition": "Good"
                                                                      },
                                                                      {
                                                                          "id": 155,
                                                                          "score": 5,
                                                                          "definition": "Excellent"
                                                                      }
                                                                  ]
                                                              },
                                                              {
                                                                  "id": 53,
                                                                  "description": "Clarity",
                                                                  "levels": [
                                                                      {
                                                                          "id": 160,
                                                                          "score": 1,
                                                                          "definition": "Unclear"
                                                                      },
                                                                      {
                                                                          "id": 159,
                                                                          "score": 3,
                                                                          "definition": "Somewhat Clear"
                                                                      },
                                                                      {
                                                                          "id": 158,
                                                                          "score": 5,
                                                                          "definition": "Very Clear"
                                                                      }
                                                                  ]
                                                              }
                                                          ]
                                                      }
                                                  ]

                                                  I have the following generated essay rubric:
                                                  Rubric: $fetchedRubric

                                                  Grade the following submission based on that rubric: 
                                                  Submission: $submissionText 

                                                  You must reply with a representation of the rubric in JSON format that matches this example format, 
                                                  obviously put your generated scores in and be specific with the remarks on the scoring and give specific examples from the 
                                                  submitted assignment that were either good or bad depending on the score given. Also cut out anything that is not
                                                  the json response. No extraneous comments outside that: 
                                                [
                                                  {
                                                      "criterionid": 67,
                                                      "criterion_description": "Content",
                                                      "levelid": 236,
                                                      "level_description": "Essay is mostly well-organized, with few issues in flow",
                                                      "score": 6,
                                                      "remark": "The essay has a clear structure and transitions between paragraphs. Each paragraph focuses on a different aspect of having a park, such as relaxation, activity, and aesthetics. However, there are a few places where the flow could be improved, like the transition between the third and fourth paragraphs."
                                                  },
                                                  {
                                                      "criterionid": 68,
                                                      "criterion_description": "Use of Evidence",
                                                      "levelid": 243,
                                                      "level_description": "Good use of evidence with occasional gaps",
                                                      "score": 6,
                                                      "remark": "The essay uses good evidence to support its claims, such as 'Spending time outside can make us feel happier and less anxious, which would help us do better in class.' However, there are occasional gaps where more specific or detailed evidence could strengthen the arguments further."
                                                  }
                                                ]
                                                ''';

                                                                String apiKey =
                                                                    getApiKey(
                                                                        selectedLLM);
                                                                dynamic
                                                                    llmInstance;
                                                                if (selectedLLM ==
                                                                    LlmType
                                                                        .CHATGPT) {
                                                                  llmInstance =
                                                                      OpenAiLLM(
                                                                          apiKey);
                                                                } else if (selectedLLM ==
                                                                    LlmType
                                                                        .GROK) {
                                                                  llmInstance =
                                                                      GrokLLM(
                                                                          apiKey);
                                                                } else {
                                                                  llmInstance =
                                                                      PerplexityLLM(
                                                                          apiKey);
                                                                }
                                                                dynamic
                                                                    gradedResponse =
                                                                    await llmInstance
                                                                        .postToLlm(
                                                                            queryPrompt);
                                                                gradedResponse =
                                                                    gradedResponse
                                                                        .replaceAll(
                                                                            '```json',
                                                                            '')
                                                                        .replaceAll(
                                                                            '```',
                                                                            '')
                                                                        .trim();
                                                                var results = await LmsFactory
                                                                    .getLmsService()
                                                                    .setRubricGrades(
                                                                        widget
                                                                            .assignmentId,
                                                                        participant
                                                                            .id,
                                                                        gradedResponse);
                                                                _fetchData();
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            SubmissionDetail(
                                                                      participant:
                                                                          participant,
                                                                      submission:
                                                                          submissionWithGrade
                                                                              .submission,
                                                                      courseId: widget
                                                                          .courseId,
                                                                    ),
                                                                  ),
                                                                );
                                                                print(
                                                                    'Results: $results');
                                                              } catch (e) {
                                                                print(
                                                                    'An error occurred: $e');
                                                              } finally {
                                                                setState(() {
                                                                  isLoadingMap[
                                                                          participant
                                                                              .id] =
                                                                      false;
                                                                });
                                                              }
                                                            },
                                                            child:
                                                                Text('Grade'),
                                                          ),
                                                  SizedBox(width: 8),
                                                  if (submissionWithGrade !=
                                                      null)
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                SubmissionDetail(
                                                              participant:
                                                                  participant,
                                                              submission:
                                                                  submissionWithGrade
                                                                      .submission,
                                                              courseId: widget
                                                                  .courseId,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child:
                                                          Text('View Details'),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          isThreeLine: true,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}