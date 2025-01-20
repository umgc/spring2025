import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Views/view_submissions.dart';
import 'package:learninglens_app/Controller/beans.dart';
import '../Api/moodle_api_singleton.dart';
import 'dart:math';

class SubmissionDetail extends StatefulWidget {
  final Participant participant;
  final Submission submission;
  final String courseId;

  SubmissionDetail(
      {required this.participant,
      required this.submission,
      required this.courseId});

  @override
  SubmissionDetailState createState() => SubmissionDetailState();
}

class SubmissionDetailState extends State<SubmissionDetail> {
  MoodleRubric? rubric;
  List? scores;
  bool isLoading = true;
  String errorMessage = '';
  Map<int, int> selectedLevels = {}; // Map to store selected levels
  Map<int, String> remarks = {}; // Map to store remarks
  Map<int, TextEditingController> remarkControllers =
      {}; // Controllers for each remark

  @override
  void initState() {
    super.initState();
    fetchRubric();
  }

  Future<void> fetchRubric() async {
    int? contextId = await MoodleApiSingleton()
        .getContextId(widget.submission.assignmentId, widget.courseId);
    if (contextId != null) {
      var fetchedRubric = await MoodleApiSingleton()
          .getRubric(widget.submission.assignmentId.toString());
      var submissionScores = await MoodleApiSingleton().getRubricGrades(
          widget.submission.assignmentId, widget.participant.id);

      setState(() {
        rubric = fetchedRubric;
        scores = submissionScores;
        // Populate selectedLevels and remarks from submissionScores
        for (var score in scores!) {
          selectedLevels[score['criterionid']] = score['levelid'];
          remarks[score['criterionid']] = score['remark'] ?? '';
          remarkControllers[score['criterionid']] =
              TextEditingController(text: remarks[score['criterionid']]);
        }
        isLoading = false;
      });

      if (fetchedRubric == null) {
        setState(() {
          errorMessage = 'No rubric available for this assignment.';
        });
      }
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to retrieve context ID for the assignment.';
      });
    }
  }

  // Save updated submission scores and remarks as JSON
  void saveSubmissionScores() async {
    List<Map<String, dynamic>> updatedScores = [];
    selectedLevels.forEach((criterionid, levelid) {
      updatedScores.add({
        'criterionid': criterionid,
        'levelid': levelid,
        'remark': remarks[criterionid] ?? ''
      });
    });

    String jsonScores = jsonEncode(updatedScores);
    print('Updated Submission Scores and Remarks: $jsonScores');
    // Handle further actions like saving to a database or API here.
    // SubmissionListState? submissionListState = context.findAncestorStateOfType<SubmissionListState>();
    bool results = await MoodleApiSingleton().setRubricGrades(
        widget.submission.assignmentId, widget.participant.id, jsonScores);
    print('Results: $results');
    if (mounted) {
      if (results) {
        final snackBar = SnackBar(
          content: Text('Grades updated successfully!'),
          duration: Duration(seconds: 2),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        await Future.delayed(snackBar.duration);
        if (mounted) {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SubmissionList(
                assignmentId: widget.submission.assignmentId,
                courseId: widget.courseId,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update grades.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Submission Details', userprofileurl: MoodleApiSingleton().moodleProfileImage ?? ''),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User ID
                    Text(
                      widget.participant.fullname,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),

                    // Status
                    Text(
                      'Status: ${widget.submission.status}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),

                    // Submission Time
                    Text(
                      'Submitted on: ${widget.submission.submissionTime.toLocal()}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),

                    // Online Text
                    Text(
                      'Online Text:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    widget.submission.onlineText.isNotEmpty 
                        ? Text(
                            widget.submission.onlineText.replaceAll(RegExp(r"<[^>]*>"), ""),
                            style: TextStyle(fontSize: 16),
                          )
                        : Text(
                            'No content provided.',
                            style: TextStyle(
                                fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                    SizedBox(height: 16),

                    // Rubric Section
                    rubric != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rubric:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),

                              // Rubric table (replace rubricTable with new table)
                              buildInteractiveRubricTable(),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: saveSubmissionScores,
                                child: Text('Save'),
                              ),
                            ],
                          )
                        : errorMessage.isNotEmpty
                            ? Text(
                                errorMessage,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.red),
                              )
                            : Text(
                                'No rubric available.',
                                style: TextStyle(
                                    fontSize: 16, fontStyle: FontStyle.italic),
                              ),
                  ],
                ),
              ),
            ),
    );
  }

// Interactive rubric table with dynamic width expansion
  Widget buildInteractiveRubricTable() {
    if (rubric == null)
      return Container(); // No rubric, return an empty container

    List<TableRow> tableRows = [];

    // First row: Header row with scores and remarks
    tableRows.add(
      TableRow(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        children: [
          TableCell(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Criteria',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
          ...rubric!.criteria.first.levels.map((level) {
            return TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    '${level.score} pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            );
          }).toList(),
          TableCell(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Remarks',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ],
      ),
    );

    // Add rows for each criterion
    for (var criterion in rubric!.criteria) {
      tableRows.add(
        TableRow(
          children: [
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  criterion.description,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
            ...criterion.levels.map((level) {
              bool isSelected = selectedLevels[criterion.id] == level.id;
              return TableCell(
                verticalAlignment: TableCellVerticalAlignment.fill,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedLevels[criterion.id] = level.id;
                    });
                  },
                  child: Container(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                        : Colors.transparent,
                    padding: EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        level.description,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ),
              );
            }),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: remarkControllers[criterion.id],
                  onChanged: (text) {
                    remarks[criterion.id] = text;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter remark',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 4,
                  maxLines: 6,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double minWidth = 800;
        double tableWidth = max(minWidth, constraints.maxWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.vertical, // Enable vertical scrolling
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Enable horizontal scrolling
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: tableWidth),
              child: Table(
                border: TableBorder.all(
                    color: Colors.black,
                    width: 1.0), // Outer border for the table
                columnWidths: {
                  0: FlexColumnWidth(.5), // Criteria column
                  for (int i = 1;
                      i <= rubric!.criteria.first.levels.length;
                      i++)
                    i: FlexColumnWidth(1), // Score columns
                  rubric!.criteria.first.levels.length + 1:
                      FlexColumnWidth(1.8), // Remarks column
                },
                children: tableRows,
              ),
            ),
          ),
        );
      },
    );
  }
}
