// import 'dart:convert'; // For utf8 encoding
import 'dart:io' show File; // For non-web file I/O
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // For file saving on non-web platforms
// Needed for web file export, conditional import based upon user's platform.
import 'package:learninglens_app/stub/html_stub.dart'
    if (dart.library.html) 'dart:html' as html;


import 'package:pdf/widgets.dart' as pw; // PDF package
// import 'package:pdf/pdf.dart'; // PDF package
import 'package:excel/excel.dart'; // Excel package

// Import the LMS services using prefixes so that type checks work correctly.
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart' as moodle;
// import 'package:learninglens_app/Api/lms/google_classroom/google_lms_service.dart' as google;

import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
// import 'package:learninglens_app/Controller/main_controller.dart';
// import 'package:learninglens_app/Views/dashboard.dart';
// import 'package:learninglens_app/Views/user_settings.dart';

import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/participant.dart';
// import 'package:learninglens_app/beans/grade.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/quiz_type.dart';

/// Enum to represent export formats.
enum ExportFormat { pdf, excel }

/// AnalyticsPage displays the Analytics Dashboard where teachers can:
///  - View overall analytics data (live data fetched from the LMS)
///  - Generate a detailed report for essay assignments only (quizzes are omitted)
///  - Export the generated report as a valid PDF or Excel file
///    (using proper PDF/Excel libraries)
///  - View tables in fixed-height containers with visible scrollbars.
///
/// When a student is clicked in the breakdown table, a detail panel appears
/// on the right showing that student's assignment details (non-editable).
/// A simple wrapper to hold either an essay assignment or a quiz assignment.
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
  // Use the course's subject if available; otherwise default to "General".
  String? _selectedSubject;
  Assessment? _selectedAssessment;

  // Student breakdown report built from live LMS participant data.
  List<Map<String, dynamic>> _studentBreakdown = [];
  Map<String, dynamic>? _selectedStudent;

  // For quiz assessments, question breakdown data.
  List<QuestionType> _questionBreakdown = [];

  // LMS selection (from the AppBar dropdown).
  // String _selectedLMS = "Moodle Classroom"; ***** Not used *****

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
  // Fetches live data from the LMS.
  // It retrieves courses and, for the first course, fetches essays and quizzes,
  // combines them into an assessment list, and fetches participants.
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
          quizList = await (lmsService as moodle.MoodleLmsService).getQuizzes(_selectedCourse!.id);
        } catch (e) {
          print("getQuizzes not available or failed: $e");
        }
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
  // Builds the student breakdown report from live participant data.
  // If the selected assessment is a quiz, it also fetches its question breakdown.
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
        // grab the quiz grades
        int quizId = _selectedAssessment!.assessment.id;
        _participantsData = await (lmsService as moodle.MoodleLmsService)
            .getQuizGradesForParticipants(
                _selectedCourse!.id.toString(), quizId);
        _participantsData = _participantsData
            .where((i) => i.roles.contains('student'))
            .toList();
      } else if (isEssay()) {
        // grab the essay grades.
        int assignmentId = _selectedAssessment!.assessment.id;
        _participantsData = await (lmsService as moodle.MoodleLmsService)
            .getEssayGradesForParticipants(
                _selectedCourse!.id.toString(), assignmentId);
      } else {
        throw Exception("Unsupported Assessment Type");
      }

      getStudentBreakdown(_participantsData);

      // Fetch question breakdown if the selected assessment is a quiz
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
  // _saveReport:
  // Exports the generated report as PDF or Excel and saves it.
  // On web, triggers a download via an AnchorElement;
  // on non-web, writes to the chosen location.
  // ---------------------------------------------------------------------------
  Future<void> _saveReport() async {
    final format = await _chooseExportFormat();
    if (format == null) return;
    String extension = (format == ExportFormat.pdf) ? 'pdf' : 'xlsx';
    String defaultName = 'my_report.$extension';

    if (kIsWeb) {
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
        if (format == ExportFormat.pdf) {
          List<int> bytes = await _exportReportAsPdf();
          final file = File(savePath);
          await file.writeAsBytes(bytes);
        } else {
          List<int> bytes = await _exportReportAsExcel();
          final file = File(savePath);
          await file.writeAsBytes(bytes);
        }
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
  // _exportReportAsPdf:
  // Uses the pdf package to generate a PDF document containing the student breakdown
  // and, if applicable, the question breakdown.
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
            data: _studentBreakdown
                .map((student) => [
                      student['studentName'],
                      student['avgGrade'],
                      student['classRank'].toString(),
                      student['nationalComparison']
                    ])
                .toList(),
          ),
          if (isQuiz())
            pw.Column(children: [
              pw.SizedBox(height: 20),
              pw.Header(level: 0, child: pw.Text("Question Breakdown")),
              pw.Table.fromTextArray(
                headers: ['Q#', 'Type', 'Text'],
                data: _questionBreakdown
                    .map((q) => [q.id.toString(), q.questionType, q.questionText])
                    .toList(),
              ),
            ]),
        ],
      ),
    );
    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // _exportReportAsExcel:
  // Uses the excel package to generate an Excel file containing the student breakdown
  // and, if applicable, the question breakdown.
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
    if (_selectedAssessment == null || _selectedAssessment!.type != "quiz") {
      return const SizedBox.shrink();
    }
    if (_questionBreakdown.isEmpty) {
      return const Center(child: Text('No question breakdown available.'));
    }
    return SizedBox(
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
                  DataColumn(label: Text('Q#')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Text')),
                ],
                rows: _questionBreakdown.map((q) {
                  return DataRow(cells: [
                    DataCell(Text(q.id.toString())),
                    DataCell(Text(q.questionType)),
                    DataCell(Text(q.questionText)),
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
    List<Map<String, String>> detailData = _assessmentsData.map((assessment) {
      // For now, "Not Submitted" is used if there's no real grade data.
      String grade = "Not Submitted";
      return {
        'Assignment': assessment.name,
        'Grade': grade,
      };
    }).toList();

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
                Text(item['Assignment']!, style: const TextStyle(fontSize: 16)),
                Text(item['Grade']!, style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        }).toList(),
      ],
    );
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

  // get student breakdown
  void getStudentBreakdown(List<Participant> participantsData) {
    // Build student breakdown report.
    _studentBreakdown = _participantsData.map((participant) {
      // Retrieve grade from the fetched quiz data, otherwise use 'Not Submitted'
      double? grade = participant.avgGrade;

      String displayGrade =
          (grade != null) ? '${grade.toInt()}%' : 'Not Submitted';

      return {
        'id': participant.id,
        'studentName': participant.fullname,
        'avgGrade': displayGrade,
        'classRank': 0, // This will be updated after sorting
        'nationalComparison': 'N/A',
      };
    }).toList();

    _studentBreakdown.sort((a, b) {
      int aGrade = int.tryParse(a['avgGrade'].replaceAll('%', '')) ?? 0;
      int bGrade = int.tryParse(b['avgGrade'].replaceAll('%', '')) ?? 0;
      return bGrade.compareTo(aGrade);
    });

    // Assign class ranking based on sorted grades.
    for (int i = 0; i < _studentBreakdown.length; i++) {
      _studentBreakdown[i]['classRank'] = i + 1;
    }
  }

  bool isQuiz() {
    return _selectedAssessment != null && _selectedAssessment!.type == "quiz";
  }

  bool isEssay() {
    return _selectedAssessment != null && _selectedAssessment!.type == "essay";
  }

  /// Fetches question breakdown for quizzes, including the percentage of students who answered correctly.
  Future<void> _fetchQuestionBreakdown() async {
    if (isQuiz()) {
      try {
        int quizId = _selectedAssessment!.assessment.id;

        // fetch the assessment data 
        // data needed quiz question, percentage of answered correctly, etc.

        setState(() {}); // Refresh UI with new breakdown data
      } catch (e) {
        print("Failed to fetch question breakdown: $e");
      }
    }
  }
}
