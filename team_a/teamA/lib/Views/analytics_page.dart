import 'dart:convert'; // For utf8 encoding
import 'dart:io' show File; // For non-web file I/O
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // For file saving on non-web platforms
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
// For web file export:
import 'dart:html' as html;

import 'package:pdf/widgets.dart' as pw; // PDF package
import 'package:pdf/pdf.dart'; // PDF package
import 'package:excel/excel.dart'; // Excel package

import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Controller/main_controller.dart';
import 'package:learninglens_app/Views/dashboard.dart';
import 'package:learninglens_app/Views/g_courses.dart';
import 'package:learninglens_app/Views/user_settings.dart';
import 'package:learninglens_app/Views/g_dashboard.dart';

/// Enum to represent export formats.
enum ExportFormat { pdf, excel }

/// AnalyticsPage displays the Analytics Dashboard where teachers can:
///  - View overall analytics data (either hard-coded for testing or live data)
///  - Generate a detailed report (assignment breakdown + student breakdown)
///  - Export the generated report as a valid PDF or Excel file to a chosen location
///    (using proper PDF/Excel libraries)
///  - View tables in fixed-height containers with visible scrollbars.
///  
/// To switch from test data to live data:
///   1. Comment out the test data block in _fetchAnalyticsData().
///   2. Uncomment the live API call block below it.
///   The live block produces the same keys ('source', 'totalCourses', 'studentPerformance',
///   'iepProgress', 'courseEngagement') so that the rest of the page functions identically.
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // Holds top-level analytics data.
  Map<String, dynamic>? analyticsData;
  bool isLoading = false;
  String errorMsg = '';

  // Report generation selections.
  String? selectedCourse;
  String? selectedSubject;
  String? selectedAssignment;

  // Hard-coded sample data for combo boxes.
  final List<String> _courses = ['MAT144', 'ENG101', 'SCI202'];
  final List<String> _subjects = ['Shape Area and Volume', 'Grammar Basics', 'Chemistry'];
  final List<String> _assignments = ['Quiz - Assessment', 'Essay Assignment', 'Lab Report'];

  // Hard-coded sample data for the generated report (assignment breakdown).
  List<Map<String, dynamic>> _generatedReport = [];

  // Hard-coded sample data for the student breakdown.
  List<Map<String, dynamic>> _studentBreakdown = [];

  // Holds the selected student for detailed view.
  Map<String, dynamic>? _selectedStudent;

  // LMS selection for the AppBar dropdown.
  String _selectedLMS = "Moodle Classroom";

  // Scroll controllers for the tables.
  late ScrollController _verticalReportController;
  late ScrollController _horizontalReportController;
  late ScrollController _verticalStudentController;
  late ScrollController _horizontalStudentController;

  @override
  void initState() {
    super.initState();
    // Optionally auto-fetch analytics data here:
    // _fetchAnalyticsData();

    _verticalReportController = ScrollController();
    _horizontalReportController = ScrollController();
    _verticalStudentController = ScrollController();
    _horizontalStudentController = ScrollController();
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
  // This block uses hard-coded values for testing purposes.
  // When ready for live data, comment out this block and uncomment the live API call block below.
  // ---------------------------------------------------------------------------
  Future<void> _fetchAnalyticsData() async {
    setState(() {
      isLoading = true;
      errorMsg = '';
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      analyticsData = {
        'source': 'Test Data',
        'totalCourses': 3,
        'studentPerformance': '90% Average Performance',
        'iepProgress': '80% Progress',
        'courseEngagement': 'High Engagement',
      };
      isLoading = false;
    });
  }

  /*
  // ---------------------------------------------------------------------------
  // Live API Call Code (Comment out above block to use this)
  // ---------------------------------------------------------------------------
  Future<void> _fetchAnalyticsData() async {
    setState(() {
      isLoading = true;
      errorMsg = '';
    });
    try {
      final controller = MainController();
      if (controller.isLoggedInMoodle) {
        final moodleApi = MoodleApiSingleton();
        List courses = await moodleApi.getUserCourses();
        int totalCourses = courses.length;
        setState(() {
          analyticsData = {
            'source': 'Moodle',
            'totalCourses': totalCourses,
            'studentPerformance': 'Moodle Performance Data',
            'iepProgress': 'Moodle IEP Data',
            'courseEngagement': 'Moodle Engagement Metrics',
          };
        });
      } else if (controller.isLoggedInGoogleClassroom) {
        final googleApi = GoogleClassroomApi();
        List courses = await googleApi.getUserCourses();
        int totalCourses = courses.length;
        setState(() {
          analyticsData = {
            'source': 'Google Classroom',
            'totalCourses': totalCourses,
            'studentPerformance': 'Google Classroom Performance Data',
            'iepProgress': 'Google Classroom IEP Data',
            'courseEngagement': 'Google Classroom Engagement Metrics',
          };
        });
      } else {
        setState(() {
          analyticsData = null;
          errorMsg = 'Please ensure you are properly logged into an LMS.';
        });
      }
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
  */

  // ---------------------------------------------------------------------------
  // _generateReport:
  // Generates 20 rows of assignment breakdown and 20 rows of student breakdown data.
  // For the student breakdown, the data is sorted by average grade in descending order,
  // so that the highest average is ranked number 1.
  // ---------------------------------------------------------------------------
  void _generateReport() {
    setState(() {
      isLoading = true;
      errorMsg = '';
      _generatedReport.clear();
      _studentBreakdown.clear();
      _selectedStudent = null; // Clear any previous selection.
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
        // Generate 20 rows for assignment breakdown.
        _generatedReport = List.generate(20, (index) {
          List<String> types = ['T/F', 'Mult. Choice', 'Short Ans'];
          return {
            'questionNumber': index + 1,
            'type': types[index % types.length],
            'timeSec': 20 + index,
            'percentCorrect': '${70 + (index % 20)}%',
            'percentPartiallyCorrect': (index % 3 == 0) ? 'n/a' : '${(index % 15) + 5}%',
          };
        });
        // Generate 20 rows for student breakdown with numeric average grade.
        List<Map<String, dynamic>> students = List.generate(20, (index) {
          int grade = 75 + (index % 25);
          int comparison = (index % 5) - 2;
          String compText = comparison >= 0 
              ? '+$comparison% above national avg' 
              : '$comparison% below national avg';
          return {
            'studentName': 'Student ${index + 1}',
            'avgGrade': grade, // Stored as int for sorting.
            'nationalComparison': compText,
          };
        });
        // Sort students in descending order by avgGrade.
        students.sort((a, b) => b['avgGrade'].compareTo(a['avgGrade']));
        // Assign classRank based on sorted order and convert avgGrade to string.
        for (int i = 0; i < students.length; i++) {
          students[i]['classRank'] = i + 1;
          students[i]['avgGrade'] = '${students[i]['avgGrade']}%';
        }
        _studentBreakdown = students;
      });
    });
  }

  // ---------------------------------------------------------------------------
  // _exportReportAsPdf:
  // Uses the pdf package to generate a PDF document containing both the generated report
  // and student breakdown tables. Returns the PDF as a list of bytes.
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

  // ---------------------------------------------------------------------------
  // _exportReportAsExcel:
  // Uses the excel package to generate an Excel file with two sheets:
  // one for the generated report and one for the student breakdown.
  // Returns the Excel document as a list of bytes.
  // ---------------------------------------------------------------------------
  Future<List<int>> _exportReportAsExcel() async {
    var excel = Excel.createExcel();
    // Sheet for Generated Report.
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
    // Sheet for Student Breakdown.
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
  // _saveReport:
  // Exports the generated report as PDF or Excel and saves it.
  // On web, triggers a download via an AnchorElement; on non-web, writes to the chosen location.
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
  // _buildReportForm:
  // Displays combo boxes for selecting course, subject, and assignment,
  // along with Generate and Export buttons.
  // The Export button is enabled only when report data exists.
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
          DropdownButtonFormField<String>(
            value: selectedCourse,
            decoration: const InputDecoration(labelText: 'Course'),
            items: _courses.map((course) {
              return DropdownMenuItem(value: course, child: Text(course));
            }).toList(),
            onChanged: (val) {
              setState(() {
                selectedCourse = val;
              });
            },
          ),
          DropdownButtonFormField<String>(
            value: selectedSubject,
            decoration: const InputDecoration(labelText: 'Subject'),
            items: _subjects.map((subject) {
              return DropdownMenuItem(value: subject, child: Text(subject));
            }).toList(),
            onChanged: (val) {
              setState(() {
                selectedSubject = val;
              });
            },
          ),
          DropdownButtonFormField<String>(
            value: selectedAssignment,
            decoration: const InputDecoration(labelText: 'Assignment'),
            items: _assignments.map((assignment) {
              return DropdownMenuItem(value: assignment, child: Text(assignment));
            }).toList(),
            onChanged: (val) {
              setState(() {
                selectedAssignment = val;
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
  // Displays the assignment breakdown table in a fixed-height container with
  // both vertical and horizontal scrolling and visible scrollbars.
  // ---------------------------------------------------------------------------
  Widget _buildGeneratedReport() {
    if (_generatedReport.isEmpty && !isLoading) {
      return const Center(child: Text('No report generated yet.'));
    }
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox(
      height: 300, // Fixed height container for the table.
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
  // Displays the student breakdown table and a detail panel side-by-side.
  // The student names are underlined and clickable.
  // Tapping a name updates the detail panel with that student's detailed grades.
  // ---------------------------------------------------------------------------
  Widget _buildStudentBreakdown() {
    if (_studentBreakdown.isEmpty && !isLoading) {
      return const Center(child: Text('No student breakdown available.'));
    }
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Build the student table with clickable (hyperlinked) names.
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
                    // Underlined hyperlink for student name.
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

    // Build the detail panel for the selected student.
    Widget detailPanel = Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: _buildStudentDetail(),
    );

    // Return a Row with the table on the left and the detail panel on the right.
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
  // If no student is selected, a placeholder message is shown.
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
    // For demonstration, we simulate detailed data.
    // In a real application, fetch or compute the student's detailed grades.
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
  // Combines the report form (left) with the generated report (right),
  // and places the student breakdown (with detail panel) below.
  // ---------------------------------------------------------------------------
  Widget _buildReportGeneratorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // Center the row horizontally.
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
  // Builds the overall page content, centering the analytics summary and including
  // the report generator section.
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
          // Combined section for report generation and student breakdown.
          _buildReportGeneratorSection(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _buildCustomAppBar:
  // Builds a custom AppBar for the Analytics page that mirrors the TeacherDashboard's
  // navigation (back, home, settings, LMS dropdown). This version is used for testing.
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildCustomAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      title: const Text('Analytics Dashboard'),
      centerTitle: true,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Flexible(
            child: IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => TeacherDashboard()),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedLMS,
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white),
            items: <String>['Moodle Classroom', 'Google Classroom']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedLMS = newValue;
                });
                if (_selectedLMS == 'Google Classroom') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => GoogleTeacherDashboard()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => TeacherDashboard()),
                  );
                }
              }
            },
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserSettings()),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: InkWell(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.network(
                    LmsFactory.getLmsService().profileImage ?? '',
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
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
  // build:
  // Sets up the Scaffold using the custom AppBar, the main content,
  // and a FloatingActionButton at the bottom-right for testing refresh.
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildCustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildContent(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: _fetchAnalyticsData,
        child: const Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Test Refresh',
      ),
    );
  }
}
