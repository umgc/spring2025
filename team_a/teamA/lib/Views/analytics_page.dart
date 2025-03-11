import 'dart:io' show File; // For non-web file I/O
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // For file saving on non-web platforms
import 'package:learninglens_app/beans/question_stat_type.dart';
import 'package:learninglens_app/stub/html_stub.dart'
    if (dart.library.html) 'dart:html' as html;

import 'package:pdf/widgets.dart' as pw; // PDF package
import 'package:excel/excel.dart'; // Excel package

// Import the LMS services using prefixes so that type checks work correctly.
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart' as moodle;
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';

import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/quiz_type.dart';

/// Enum to represent export formats.
enum ExportFormat { pdf, excel }

/// A simple wrapper to hold either an essay assignment or a quiz.
/// The `type` property distinguishes between the two.
class Assessment {
  final dynamic assessment; // Either an Assignment (essay) or a Quiz.
  final String type; // "essay" or "quiz"

  Assessment({required this.assessment, required this.type});

  String get name {
    if (type == "essay") {
      return (assessment as Assignment).name;
    } else {
      return (assessment as Quiz).name ?? 'Unknown Quiz';
    }
  }

  int get id {
    if (type == "essay") {
      return (assessment as Assignment).id ?? 0;
    } else {
      return (assessment as Quiz).id ?? 0;
    }
  }
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final lmsService = LmsFactory.getLmsService();
  // Live analytics data fetched from the LMS.
  Map<String, dynamic>? analyticsData;
  bool isLoading = false;
  String errorMsg = '';

  // Live data for dropdowns.
  List<Course> _coursesData = [];
  List<Assessment> _assessmentsData = [];
  List<Participant> _participantsData = [];

  // Selections from dropdowns.
  Course? _selectedCourse;
  String? _selectedSubject;
  Assessment? _selectedAssessment;

  // Student breakdown report built from live LMS participant data.
  List<Map<String, dynamic>> _studentBreakdown = [];
  Map<String, dynamic>? _selectedStudent;

  // For quiz assessments, question breakdown data.
  List<QuestionStatsType> _questionBreakdown = [];

  // Scroll controllers for tables.
  late ScrollController _verticalStudentController;
  late ScrollController _horizontalStudentController;
  late ScrollController _verticalQuestionController;
  late ScrollController _horizontalQuestionController;

  @override
  void initState() {
    super.initState();
    _verticalStudentController = ScrollController();
    _horizontalStudentController = ScrollController();
    _verticalQuestionController = ScrollController();
    _horizontalQuestionController = ScrollController();
    _fetchAnalyticsData();
  }

  @override
  void dispose() {
    _verticalStudentController.dispose();
    _horizontalStudentController.dispose();
    _verticalQuestionController.dispose();
    _horizontalQuestionController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // _fetchAnalyticsData:
  // Fetches live data from the LMS (courses, initial quizzes/essays).
  // ---------------------------------------------------------------------------
  Future<void> _fetchAnalyticsData() async {
    setState(() {
      isLoading = true;
      errorMsg = '';
    });
    try {
      _coursesData = await lmsService.getUserCourses();
      int totalCourses = _coursesData.length;
      if (_coursesData.isNotEmpty) {
        _selectedCourse = _coursesData.first;
        _selectedSubject = _selectedCourse!.subject ?? "General";
        // Fetch essays.
        List<Assignment> essayList = await lmsService.getEssays(_selectedCourse!.id);
        // Fetch quizzes (if available).
        List<Quiz> quizList = [];
        try {
          quizList = await (lmsService as moodle.MoodleLmsService)
              .getQuizzes(_selectedCourse!.id);
        } catch (e) {
          print("getQuizzes not available or failed: $e");
        }
        // Combine them into one list
        _assessmentsData = [
          ...essayList.map((a) => Assessment(assessment: a, type: "essay")),
          ...quizList.map((q) => Assessment(assessment: q, type: "quiz"))
        ];
        if (_assessmentsData.isNotEmpty) {
          _selectedAssessment = _assessmentsData.first;
        }
      }
      setState(() {
        analyticsData = {
          'source': lmsService is moodle.MoodleLmsService ? 'Moodle' : 'Google Classroom',
          'totalCourses': totalCourses,
          'studentPerformance': 'Live Performance Data',
          'iepProgress': 'Live IEP Data',
          'courseEngagement': 'Live Engagement Metrics',
        };
      });
    } catch (e) {
      setState(() {
        errorMsg = 'Failed to load analytics data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // _generateReport:
  // Builds the student breakdown for the currently selected assessment only
  // (i.e., one quiz or essay).
  // ---------------------------------------------------------------------------
  Future<void> _generateReport() async {
    if (_selectedCourse == null) return;
    setState(() {
      isLoading = true;
      errorMsg = '';
      _studentBreakdown.clear();
      _questionBreakdown.clear();
      _selectedStudent = null;
    });

    try {
      if (isQuiz()) {
        // Grab participants for this quiz
        int quizId = _selectedAssessment!.assessment.id;
        _participantsData = await (lmsService as moodle.MoodleLmsService)
            .getQuizGradesForParticipants(_selectedCourse!.id.toString(), quizId);

        // Filter out non-students, if needed
        _participantsData = _participantsData
            .where((i) => i.roles.contains('student'))
            .toList();
      } else if (isEssay()) {
        // Grab participants for this essay
        int assignmentId = _selectedAssessment!.assessment.id;
        _participantsData = await (lmsService as moodle.MoodleLmsService)
            .getEssayGradesForParticipants(_selectedCourse!.id.toString(), assignmentId);
      } else {
        throw Exception("Unsupported Assessment Type");
      }

      // Build the table shown in the "Student Breakdown" section
      getStudentBreakdown(_participantsData);

      // If it's a quiz, also fetch the question breakdown
      await _fetchQuestionBreakdown();
    } catch (e) {
      setState(() {
        errorMsg = 'Failed to generate report: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // getStudentBreakdown:
  // Builds `_studentBreakdown` from the given participant list for the currently
  // selected assessment only.
  // ---------------------------------------------------------------------------
  void getStudentBreakdown(List<Participant> participantsData) {
    _studentBreakdown = participantsData.map((participant) {
      double? grade = participant.avgGrade;
      String displayGrade =
          (grade != null) ? '${grade.toInt()}%' : '0%';

      return {
        'id': participant.id,
        'studentName': participant.fullname,
        'avgGrade': displayGrade,
        'classRank': 0, // This will be updated after sorting
        'nationalComparison': 'N/A',
      };
    }).toList();

    // Sort descending by numeric grade
    _studentBreakdown.sort((a, b) {
      int aGrade = int.tryParse(a['avgGrade'].replaceAll('%', '')) ?? 0;
      int bGrade = int.tryParse(b['avgGrade'].replaceAll('%', '')) ?? 0;
      return bGrade.compareTo(aGrade);
    });

    // Assign a 1-based rank
    for (int i = 0; i < _studentBreakdown.length; i++) {
      _studentBreakdown[i]['classRank'] = i + 1;
    }
  }

  // ---------------------------------------------------------------------------
  // _saveReport:
  // Exports the generated report as PDF or Excel (only for the single
  // selected assessment).
  // ---------------------------------------------------------------------------
  Future<void> _saveReport() async {
    final format = await _chooseExportFormat();
    if (format == null) return;
    String extension = (format == ExportFormat.pdf) ? 'pdf' : 'xlsx';
    String defaultName = 'my_report.$extension';

    if (kIsWeb) {
      // Build bytes
      List<int> bytes = (format == ExportFormat.pdf)
          ? await _exportReportAsPdf()
          : await _exportReportAsExcel();
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..style.display = 'none'
        ..download = defaultName;
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report exported as $extension via browser download.')),
      );
    } else {
      final savePath = await _pickFileLocation(defaultName);
      if (savePath == null) return;
      try {
        List<int> bytes = (format == ExportFormat.pdf)
            ? await _exportReportAsPdf()
            : await _exportReportAsExcel();
        final file = File(savePath);
        await file.writeAsBytes(bytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved as $extension at:\n$savePath')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save report: $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // _chooseExportFormat:
  // Prompts the user to select whether to export the report as PDF or Excel.
  // ---------------------------------------------------------------------------
  Future<ExportFormat?> _chooseExportFormat() async {
    return showDialog<ExportFormat>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Export Format'),
          content: const Text('Would you like to export the report as PDF or Excel?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ExportFormat.pdf),
              child: const Text('PDF'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ExportFormat.excel),
              child: const Text('Excel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // _exportReportAsPdf: Exports only the single assessment's data stored in
  // _studentBreakdown (and questionBreakdown if quiz).
  // ---------------------------------------------------------------------------
  Future<List<int>> _exportReportAsPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text("Student Breakdown Report")),
          pw.Table.fromTextArray(
            headers: [
              'Student Name',
              'Average Grade',
              'Class Rank',
              'National Comparison'
            ],
            data: _studentBreakdown.map((student) => [
              student['studentName'],
              student['avgGrade'],
              student['classRank'].toString(),
              student['nationalComparison']
            ]).toList(),
          ),
          if (isQuiz())
            pw.Column(children: [
              pw.SizedBox(height: 20),
              pw.Header(level: 0, child: pw.Text("Question Breakdown")),
              pw.Table.fromTextArray(
                headers: ['Q#', 'Type', 'Text'],
                data: _questionBreakdown.map((q) => [
                  q.id.toString(),
                  q.questionType,
                  q.questionText
                ]).toList(),
              ),
            ]),
        ],
      ),
    );
    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // _exportReportAsExcel: Exports only the single assessment's data stored in
  // _studentBreakdown (and questionBreakdown if quiz).
  // ---------------------------------------------------------------------------
  Future<List<int>> _exportReportAsExcel() async {
    var excel = Excel.createExcel();
    Sheet studentSheet = excel['Student Breakdown'];
    studentSheet.appendRow([
      'Student Name',
      'Average Grade',
      'Class Rank',
      'National Comparison'
    ]);
    for (var student in _studentBreakdown) {
      studentSheet.appendRow([
        student['studentName'],
        student['avgGrade'],
        student['classRank'],
        student['nationalComparison']
      ]);
    }
    if (isQuiz()) {
      Sheet questionSheet = excel['Question Breakdown'];
      questionSheet.appendRow(['Q#', 'Type', 'Text']);
      for (var q in _questionBreakdown) {
        questionSheet.appendRow([
          q.id,
          q.questionType,
          q.questionText,
        ]);
      }
    }
    return excel.encode()!;
  }

  // ---------------------------------------------------------------------------
  // _pickFileLocation:
  // For non-web platforms, uses FilePicker to let the user choose a save location.
  // On web, file saving is handled via an AnchorElement.
  // ---------------------------------------------------------------------------
   Future<String?> _pickFileLocation(String defaultName) async {
    if (kIsWeb) return null;
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Report',
      fileName: defaultName,
    );
    return result;
  }

  // ---------------------------------------------------------------------------
  // _buildReportForm:
  // Displays dropdowns for selecting course, subject, and assessment,
  // along with Generate and Export buttons.
  // ---------------------------------------------------------------------------
  Widget _buildReportForm() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Generate New Report',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          // Course dropdown populated with live courses.
          DropdownButtonFormField<Course>(
            value: _selectedCourse,
            decoration: const InputDecoration(labelText: 'Course'),
            items: _coursesData.map((course) {
              return DropdownMenuItem<Course>(
                value: course,
                child: Text(course.fullName.isNotEmpty
                    ? course.fullName
                    : course.shortName),
              );
            }).toList(),
            onChanged: (val) async {
              setState(() {
                _selectedCourse = val;
                _selectedSubject = val?.subject ?? "General";
              });
              if (_selectedCourse != null) {
                // Fetch essays and quizzes, then combine them.
                List<Assignment> essays = await lmsService.getEssays(_selectedCourse!.id);
                List<Quiz> quizzes = [];
                try {
                  quizzes = await (lmsService as dynamic).getQuizzes(_selectedCourse!.id);
                 } catch (e) {
                  print("getQuizzes not available or failed: $e");
                }
                _assessmentsData = [
                  ...essays.map((a) => Assessment(assessment: a, type: "essay")),
                  ...quizzes.map((q) => Assessment(assessment: q, type: "quiz"))
                ];
                if (_assessmentsData.isNotEmpty) {
                  _selectedAssessment = _assessmentsData.first;
                }
                setState(() {});
              }
            },
          ),
          // Subject dropdown: only if the selected course provides a subject.
          if (_selectedCourse != null)
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: [
                DropdownMenuItem(
                  value: _selectedSubject,
                  child: Text(_selectedSubject ?? "General"),
                )
              ],
              onChanged: (val) {
                setState(() {
                  _selectedSubject = val;
                });
              },
            ),
          // Assessment dropdown populated from live assessments.
          DropdownButtonFormField<Assessment>(
            value: _selectedAssessment,
            decoration: const InputDecoration(labelText: 'Assessment'),
            items: _assessmentsData.map((assessment) {
              return DropdownMenuItem<Assessment>(
                value: assessment,
                child: Text('${assessment.name} (${assessment.type.toUpperCase()})'),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedAssessment = val;
                // Clear question breakdown when assessment changes.
                _questionBreakdown.clear();
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _generateReport,
                child: const Text('Generate'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _studentBreakdown.isNotEmpty ? _saveReport : null,
                child: const Text('Export'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _buildQuestionBreakdown:
  // Displays the question breakdown table for quiz assessments.
  // This is shown only when a quiz is selected.
  // ---------------------------------------------------------------------------
 Widget _buildQuestionBreakdown() {
    if (isEssay()) {
      return const SizedBox.shrink();
    }
    if (_questionBreakdown.isEmpty) {
      return const Center(child: Text('No question breakdown available.'));
    }

    // Example hard-coded or computed stats.
    // Replace these with real calculations if you have them:
    final double averageGrade = getAverageGrade();
    final int numSubmittedQuizzes = getTotalSubmittedQuizzes();     
    final int numStudentsInClass = _studentBreakdown.length;       

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ====== ADDED SECTION ======
        Text('Average Grade: $averageGrade%'),
        Text('Number of Submitted Quizzes: $numSubmittedQuizzes'),
        Text('Number of Students in Class: $numStudentsInClass'),
        const SizedBox(height: 16),
        // ====== END ADDED SECTION ======

        SizedBox(
          height: 200,
          child: Scrollbar(
            thumbVisibility: true,
            controller: _verticalQuestionController,
            child: SingleChildScrollView(
              controller: _verticalQuestionController,
              scrollDirection: Axis.vertical,
              child: Scrollbar(
                thumbVisibility: true,
                controller: _horizontalQuestionController,
                notificationPredicate: (notification) => notification.depth == 2,
                child: SingleChildScrollView(
                  controller: _horizontalQuestionController,
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Question Type')),
                      DataColumn(label: Text('Question')),
                      DataColumn(label: Text('% Answered Correct')),
                      DataColumn(label: Text('# of Correct')),
                      DataColumn(label: Text('# of Incorrect')),
                      DataColumn(label: Text('# of Total Attempts')),
                    ],
                    rows: _questionBreakdown.map((q) {
                      return DataRow(cells: [
                        DataCell(Text(q.id.toString())),
                        DataCell(Text(q.questionType)),
                        DataCell(Text(q.questionText)),
                        DataCell(Text("${computePercentCorrect(q).toStringAsFixed(2)}%")),
                        DataCell(Text(q.numCorrect.toString())),
                        DataCell(Text(q.numIncorrect.toString())),
                        DataCell(Text(q.totalAttempts.toString())),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // ---------------------------------------------------------------------------
  // _buildStudentTable:
  // Returns ONLY the table of student data. The detail panel is separate.
 // ---------------------------------------------------------------------------
  Widget _buildStudentTable() {
    if (_studentBreakdown.isEmpty && !isLoading) {
      return const Center(child: Text('No student breakdown available.'));
    }
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox(
      height: 300,
      child: Scrollbar(
        thumbVisibility: true,
        controller: _verticalStudentController,
        child: SingleChildScrollView(
          controller: _verticalStudentController,
          scrollDirection: Axis.vertical,
          child: Scrollbar(
            thumbVisibility: true,
            controller: _horizontalStudentController,
            notificationPredicate: (notification) => notification.depth == 2,
            child: SingleChildScrollView(
              controller: _horizontalStudentController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Student Name')),
                  DataColumn(label: Text('Average Grade')),
                  DataColumn(label: Text('Class Rank')),
                  DataColumn(label: Text('National Comparison')),
                ],
                rows: _studentBreakdown.map((student) {
                  return DataRow(cells: [
                    DataCell(
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedStudent = student;
                          });
                        },
                        child: Text(
                          student['studentName'].toString(),
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(student['avgGrade'].toString())),
                    DataCell(Text(student['classRank'].toString())),
                    DataCell(Text(student['nationalComparison'].toString())),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _buildStudentDetail:
  // Displays the selected student's detail info in the bottom-right quadrant.
  // ---------------------------------------------------------------------------
  Widget _buildStudentDetail() {
    if (_selectedStudent == null) {
      return const Center(
        child: Text(
          'Select a student to see detailed grades.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    int studentId = _selectedStudent!['id'];

    return FutureBuilder<List<Map<String, String>>>(
      future: _fetchAllAssessmentsForStudent(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading grades: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No data available for student $studentId.');
        }

        List<Map<String, String>> detailData = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details for ${_selectedStudent!['studentName']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...detailData.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${item['Assessment']} (${item['Type']})",
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      item['Grade']!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helper function to fetch ALL assessments (quiz or essay) for ONE student.
  // It loops over _assessmentsData and calls the correct Moodle service for each.
  // ---------------------------------------------------------------------------
  Future<List<Map<String, String>>> _fetchAllAssessmentsForStudent(int studentId) async {
    if (_selectedCourse == null) return [];

    // We'll gather up a list of async calls in futureList
    List<Future<Map<String, String>>> futureList = [];

    for (var assessment in _assessmentsData) {
      futureList.add(() async {
        String gradeStr = "0%";

        if (isQuiz()) {
          // Fetch participants for this quiz
          final participants = await (lmsService as moodle.MoodleLmsService)
              .getQuizGradesForParticipants(
                _selectedCourse!.id.toString(),
                assessment.id,
              );
          // Filter for this student
          final participant = participants.firstWhere(
            (p) => p.id == studentId,
            orElse: () => Participant.empty(),
          );
          if (participant.avgGrade != null) {
            gradeStr = "${participant.avgGrade!.toInt()}%";
          }
        } else if (assessment.type == "essay") {
          // Fetch participants for this essay
          final participants = await (lmsService as moodle.MoodleLmsService)
              .getEssayGradesForParticipants(
                _selectedCourse!.id.toString(),
                assessment.id,
              );
          // Filter for this student
          final participant = participants.firstWhere(
            (p) => p.id == studentId,
            orElse: () => Participant.empty(),
          );
          if (participant.avgGrade != null) {
            gradeStr = "${participant.avgGrade!.toInt()}%";
          }
        }

        // Return a map with the assessment name, type, and computed grade
        return {
          'Assessment': assessment.name,
          'Type': assessment.type.toUpperCase(),
          'Grade': gradeStr,
        };
      }());
    }

    // Wait for all those calls to finish
    return Future.wait(futureList);
  }

  // ---------------------------------------------------------------------------
  // If the user selected a quiz, fetch a question breakdown for that quiz.
  // ---------------------------------------------------------------------------
  Future<void> _fetchQuestionBreakdown() async {
    if (isQuiz()) {
      try {
        int quizId = _selectedAssessment!.assessment.id;
        _questionBreakdown = await (lmsService as dynamic)
            .getQuestionStatsFromQuiz(quizId);

        setState(() {}); // Refresh UI with new breakdown
      } catch (e) {
        print("Failed to fetch question breakdown: $e");
      }
    }
  }

  bool isQuiz() {
    return _selectedAssessment != null && _selectedAssessment!.type == "quiz";
  }

  bool isEssay() {
    return _selectedAssessment != null && _selectedAssessment!.type == "essay";
  }

  // ---------------------------------------------------------------------------
  // _buildMainGrid:
  // Creates a 2×2 grid layout:
  //  Top-left: Report form
  //  Bottom-left: Student breakdown table
  //  Top-right: Question breakdown
  //  Bottom-right: Selected student detail
  // ---------------------------------------------------------------------------
  Widget _buildMainGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top-left: the form
              _buildReportForm(),
              const SizedBox(height: 20),

              // Bottom-left: label + student table
              const Text(
                'Student Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: _buildStudentTable(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Right Column
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top-right: label + question breakdown
              const Text(
                'Question Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: _buildQuestionBreakdown(),
              ),
              const SizedBox(height: 20),

              // Bottom-right: label + detail panel
              const Text(
                'Student Detail',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: _buildStudentDetail(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // _buildContent:
  // Builds the overall page content including analytics summary and the 2x2 grid.
  // ---------------------------------------------------------------------------
  Widget _buildContent() {
    if (isLoading && analyticsData == null && errorMsg.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMsg.isNotEmpty) {
      return Center(child: Text(errorMsg));
    }
    if (analyticsData == null) {
      return const Center(child: Text('No analytics data available yet.'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // Analytics summary.
          Center(
            child: Column(
              children: [
                Text('Analytics Source: ${analyticsData!['source']}',
                    style: const TextStyle(fontSize: 16)),
                Text('Total Courses: ${analyticsData!['totalCourses']}',
                    style: const TextStyle(fontSize: 16)),
                Text('Student Performance: ${analyticsData!['studentPerformance']}',
                    style: const TextStyle(fontSize: 16)),
                Text('IEP Progress: ${analyticsData!['iepProgress']}',
                    style: const TextStyle(fontSize: 16)),
                Text('Course Engagement: ${analyticsData!['courseEngagement']}',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 2x2 grid view
          _buildMainGrid(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // build:
  // Sets up the Scaffold using the shared CustomAppBar and the main content.
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Analytics Dashboard',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
        onRefresh: _fetchAnalyticsData,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildContent(),
      ),
    );
  }
  
  /**
   * Computes the percentage a question is answered correctly.
   * Correct Percentage = ((numcorrect + numpartial) / totalattempts) * 100
   */
  double computePercentCorrect(QuestionStatsType q) {
    if (q.totalAttempts == 0) return 0.0; // Avoid division by zero
    return ((q.numCorrect + q.numPartial) / q.totalAttempts) * 100;
  }
  
  // loop over all the studentBreadkdown and get all of the avgGrades
  double getAverageGrade() {
    // short circuit the method If there's no data, just return 0 to avoid division by zero.
    if (_studentBreakdown.isEmpty) {
      return 0.0;
    }

    double sum = 0.0;

    // loop over every student and grab there avgGrade (technically it is a their grade)
    for (var student in _studentBreakdown) {
      // Extract the "avgGrade" field
      String? gradeStr = student['avgGrade'];

      // If the field is missing or invalid, skip it.
      if (gradeStr == null || gradeStr.isEmpty) {
        continue;
      }

      // Remove the percent sign, parse as double.
      gradeStr = gradeStr.replaceAll('%', '');
      double? numericGrade = double.tryParse(gradeStr);

      // Accumulate the parsed numeric grade, defaulting to 0 if parse fails.
      sum += numericGrade ?? 0.0;
    }

    // Divide by number of students to get average.
    return sum / _studentBreakdown.length;
  }
  
  /// Returns the total number of quizzes submitted for the current quiz
  /// by dividing the sum of all question attempts by the count of questions.
  /// 
  /// For each question Q:
  ///   totalAttemptsForQ = (Q.numCorrect + Q.numIncorrect + Q.numPartial)
  /// Then:
  ///   totalQuizSubmissions = grandTotalAttemptsAcrossAllQuestions / numberOfQuestions
  int getTotalSubmittedQuizzes() {
    if (_questionBreakdown.isEmpty) {
      return 0;
    }

    double grandTotalAttempts = 0;
    int questionCount = _questionBreakdown.length;

    for (QuestionStatsType q in _questionBreakdown) {
      grandTotalAttempts += (q.numCorrect + q.numIncorrect + q.numPartial);
    }

    // If for some reason questionCount is 0, avoid division by zero
    if (questionCount == 0) return 0;

    // Divide total attempts by question count to get # of submissions
    double submissions = grandTotalAttempts / questionCount;

    // Round to an integer or use floor/ceil if preferred
    return submissions.round();
  }

}
