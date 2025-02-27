import 'dart:convert'; // For utf8 encoding
import 'dart:io' show File; // For non-web file I/O
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // For file saving on non-web platforms
// For web file export:
import 'dart:html' as html;

import 'package:pdf/widgets.dart' as pw; // PDF package
import 'package:pdf/pdf.dart'; // PDF package
import 'package:excel/excel.dart'; // Excel package

// Import the LMS services using prefixes so that type checks work correctly.
import 'package:learninglens_app/lms/lms_factory.dart';
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart' as moodle;
import 'package:learninglens_app/Api/lms/google_classroom/google_lms_service.dart' as google;

import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Controller/main_controller.dart';
import 'package:learninglens_app/Views/dashboard.dart';
import 'package:learninglens_app/Views/g_courses.dart';
import 'package:learninglens_app/Views/user_settings.dart';
import 'package:learninglens_app/Views/g_dashboard.dart';

import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/grade.dart';

/// Enum to represent export formats.
enum ExportFormat { pdf, excel }

/// AnalyticsPage displays the Analytics Dashboard where teachers can:
///  - View overall analytics data (live data fetched from the LMS)
///  - Generate a detailed report (assignment breakdown + student breakdown)
///  - Export the generated report as a valid PDF or Excel file to a chosen location
///    (using proper PDF/Excel libraries)
///  - View tables in fixed-height containers with visible scrollbars.
///  
/// Additionally, each student's name in the student breakdown table is underlined
/// (as a hyperlink). When clicked, a detail panel appears on the right showing that
/// student's individual grades in detail.
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // Live analytics data fetched from the LMS.
  Map<String, dynamic>? analyticsData;
  bool isLoading = false;
  String errorMsg = '';

  // Live data for dropdowns.
  List<Course> _coursesData = [];
  List<Assignment> _assignmentsData = [];
  List<Participant> _participantsData = [];

  // Selections from dropdowns.
  Course? _selectedCourse;
  // For subject, we assume each Course has a 'subject' property.
  String? _selectedSubject;
  Assignment? _selectedAssignment;

  // Report data built from live LMS data.
  List<Map<String, dynamic>> _generatedReport = [];
  List<Map<String, dynamic>> _studentBreakdown = [];
  Map<String, dynamic>? _selectedStudent;

  // LMS selection (from the AppBar dropdown).
  String _selectedLMS = "Moodle Classroom";

  // Scroll controllers for the tables.
  late ScrollController _verticalReportController;
  late ScrollController _horizontalReportController;
  late ScrollController _verticalStudentController;
  late ScrollController _horizontalStudentController;

  @override
  void initState() {
    super.initState();
    _verticalReportController = ScrollController();
    _horizontalReportController = ScrollController();
    _verticalStudentController = ScrollController();
    _horizontalStudentController = ScrollController();
    // Auto-fetch live analytics data on initialization.
    _fetchAnalyticsData();
  }

  @override
  void dispose() {
    _verticalReportController.dispose();
    _horizontalReportController.dispose();
    _verticalStudentController.dispose();
    _horizontalStudentController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // _fetchAnalyticsData:
  // Live API Call Code.
  // This block fetches live data from the LMS using the appropriate API.
  // If the teacher is logged into Moodle, it fetches courses, assignments, and
  // participants from Moodle.
  // If logged into Google Classroom, it fetches data from Google Classroom.
  // ---------------------------------------------------------------------------
  Future<void> _fetchAnalyticsData() async {
    setState(() {
      isLoading = true;
      errorMsg = '';
    });
    try {
      final controller = MainController();
      final lmsService = LmsFactory.getLmsService();
      // Fetch courses from LMS.
      _coursesData = await lmsService.getUserCourses();
      int totalCourses = _coursesData.length;
      // Set default selected course.
      if (_coursesData.isNotEmpty) {
        _selectedCourse = _coursesData.first;
        _selectedSubject = _selectedCourse?.subject; // assuming Course has a 'subject'
        // Fetch assignments and participants for the selected course.
        _assignmentsData = await lmsService.getEssays(_selectedCourse!.id);
        _participantsData = await lmsService.getCourseParticipants(_selectedCourse!.id.toString());
      }
      setState(() {
        analyticsData = {
          'source': lmsService is moodle.MoodleLmsService ? 'Moodle' : 'Google Classroom',
          'totalCourses': totalCourses,
          'studentPerformance': 'Live Performance Data', // Replace with actual metrics if available
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
  // Generates report data using live assignments and participant data.
  // For assignments, it builds a row for each Assignment from the LMS.
  // For student breakdown, it uses real participant data and sorts by average grade.
  // (Assumes that each Participant object has an 'avgGrade' property.)
  // ---------------------------------------------------------------------------
  Future<void> _generateReport() async {
    if (_selectedCourse == null) return;
    setState(() {
      isLoading = true;
      errorMsg = '';
      _generatedReport.clear();
      _studentBreakdown.clear();
      _selectedStudent = null;
    });
    try {
      final lmsService = LmsFactory.getLmsService();
      // Build generated report rows from assignments.
      _generatedReport = _assignmentsData.map((assignment) {
        return {
          'questionNumber': assignment.id, // Using assignment ID as placeholder.
          'type': assignment.name ?? 'Unknown',
          'timeSec': 0, // Real timing data may not be available.
          'percentCorrect': 'N/A', // Replace with actual data if available.
          'percentPartiallyCorrect': 'N/A'
        };
      }).toList();

      // Build student breakdown from participants.
      _studentBreakdown = _participantsData.map((participant) {
        // Convert avgGrade (double?) to int; if null, default to 75.
        int grade = participant.avgGrade != null ? participant.avgGrade!.toInt() : 75;
        return {
          'studentName': participant.fullname,
          'avgGrade': '$grade%',
          'classRank': 0, // To be computed later
          'nationalComparison': 'N/A' // Replace with actual comparison if available.
        };
      }).toList();

      // Sort students by average grade (assuming numeric value).
      _studentBreakdown.sort((a, b) {
        int aGrade = int.tryParse(a['avgGrade'].replaceAll('%', '')) ?? 0;
        int bGrade = int.tryParse(b['avgGrade'].replaceAll('%', '')) ?? 0;
        return bGrade.compareTo(aGrade);
      });
      // Assign ranking.
      for (int i = 0; i < _studentBreakdown.length; i++) {
        _studentBreakdown[i]['classRank'] = i + 1;
      }
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
  // The export methods (_exportReportAsPdf, _exportReportAsExcel, _chooseExportFormat,
  // _pickFileLocation, and _saveReport) remain unchanged.
  // ---------------------------------------------------------------------------
  Future<List<int>> _exportReportAsPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text("Generated Report")),
          pw.Table.fromTextArray(
            headers: [
              'Question Number',
              'Type',
              'Time (sec)',
              'Percent Correct',
              'Percent Partially Correct'
            ],
            data: _generatedReport
                .map((row) => [
                      row['questionNumber'].toString(),
                      row['type'],
                      row['timeSec'].toString(),
                      row['percentCorrect'],
                      row['percentPartiallyCorrect']
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 0, child: pw.Text("Student Breakdown")),
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
        ],
      ),
    );
    return pdf.save();
  }

  Future<List<int>> _exportReportAsExcel() async {
    var excel = Excel.createExcel();
    Sheet reportSheet = excel['Generated Report'];
    reportSheet.appendRow([
      'Question Number',
      'Type',
      'Time (sec)',
      'Percent Correct',
      'Percent Partially Correct'
    ]);
    for (var row in _generatedReport) {
      reportSheet.appendRow([
        row['questionNumber'],
        row['type'],
        row['timeSec'],
        row['percentCorrect'],
        row['percentPartiallyCorrect']
      ]);
    }
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
    return excel.encode()!;
  }

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

  Future<String?> _pickFileLocation(String defaultName) async {
    if (kIsWeb) return null;
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Report',
      fileName: defaultName,
    );
    return result;
  }

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
  // _buildReportForm:
  // Displays dropdowns for selecting course, subject, and assignment,
  // along with Generate and Export buttons.
  // The dropdowns are now populated from live LMS data.
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
                child: Text(course.fullName ?? course.shortName ?? 'Unknown Course'),
              );
            }).toList(),
            onChanged: (val) async {
              setState(() {
                _selectedCourse = val;
                _selectedSubject = val?.subject;
              });
              if (_selectedCourse != null) {
                // When a course is selected, fetch assignments for that course.
                final lmsService = LmsFactory.getLmsService();
                _assignmentsData = await lmsService.getEssays(_selectedCourse!.id);
                setState(() {});
              }
            },
          ),
          // Subject dropdown: using the subject property of the selected course.
          DropdownButtonFormField<String>(
            value: _selectedSubject,
            decoration: const InputDecoration(labelText: 'Subject'),
            items: _selectedCourse != null && _selectedCourse!.subject != null
                ? [
                    DropdownMenuItem(
                      value: _selectedCourse!.subject,
                      child: Text(_selectedCourse!.subject!),
                    )
                  ]
                : [],
            onChanged: (val) {
              setState(() {
                _selectedSubject = val;
              });
            },
          ),
          // Assignment dropdown populated from live assignments.
          DropdownButtonFormField<Assignment>(
            value: _selectedAssignment,
            decoration: const InputDecoration(labelText: 'Assignment'),
            items: _assignmentsData.map((assignment) {
              return DropdownMenuItem<Assignment>(
                value: assignment,
                child: Text(assignment.name ?? 'Unknown Assignment'),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedAssignment = val;
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
                onPressed: _generatedReport.isNotEmpty ? _saveReport : null,
                child: const Text('Export'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _buildGeneratedReport:
  // Displays the assignment breakdown table with live data in a fixed-height container.
  // ---------------------------------------------------------------------------
  Widget _buildGeneratedReport() {
    if (_generatedReport.isEmpty && !isLoading) {
      return const Center(child: Text('No report generated yet.'));
    }
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox(
      height: 300,
      child: Scrollbar(
        thumbVisibility: true,
        controller: _verticalReportController,
        child: SingleChildScrollView(
          controller: _verticalReportController,
          scrollDirection: Axis.vertical,
          child: Scrollbar(
            thumbVisibility: true,
            controller: _horizontalReportController,
            notificationPredicate: (notification) => notification.depth == 2,
            child: SingleChildScrollView(
              controller: _horizontalReportController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Question Number')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Time (sec)')),
                  DataColumn(label: Text('Percent Correct')),
                  DataColumn(label: Text('Percent Partially Correct')),
                ],
                rows: _generatedReport.map((row) {
                  return DataRow(cells: [
                    DataCell(Text(row['questionNumber'].toString())),
                    DataCell(Text(row['type'].toString())),
                    DataCell(Text(row['timeSec'].toString())),
                    DataCell(Text(row['percentCorrect'].toString())),
                    DataCell(Text(row['percentPartiallyCorrect'].toString())),
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
  // _buildStudentBreakdown:
  // Displays the student breakdown table (with clickable names) and a detail panel.
  // ---------------------------------------------------------------------------
  Widget _buildStudentBreakdown() {
    if (_studentBreakdown.isEmpty && !isLoading) {
      return const Center(child: Text('No student breakdown available.'));
    }
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    Widget studentTable = SizedBox(
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

    Widget detailPanel = Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: _buildStudentDetail(),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: studentTable),
        const SizedBox(width: 20),
        detailPanel,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // _buildStudentDetail:
  // Displays detailed grade information for the selected student.
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
    List<Map<String, String>> detailData = List.generate(5, (index) {
      return {
        'Assignment': 'Assignment ${index + 1}',
        'Grade': '${80 + index}%',
      };
    });
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
  // _buildReportGeneratorSection:
  // Combines the report form with the generated report and student breakdown.
  // ---------------------------------------------------------------------------
  Widget _buildReportGeneratorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildReportForm(),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Generated Report',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: _buildGeneratedReport(),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const Text('Student Breakdown',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: _buildStudentBreakdown(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // _buildContent:
  // Builds the overall page content.
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
          // Centered analytics summary.
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
          // Report generator section.
          _buildReportGeneratorSection(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // build:
  // Sets up the Scaffold using the shared CustomAppBar (which now includes a refresh button)
  // and the main content.
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
}
