import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/google_classroom/google_classroom_api.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Controller/main_controller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class CreateAssignmentPage extends StatefulWidget {
  GoogleClassroomApi _googleClassroomApi = GoogleClassroomApi();

  @override
  _CreateAssignmentPageState createState() => _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends State<CreateAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCourseId;
  int? _points;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  final String _topic = 'Essay'; // Made static with fixed value
  String? _title;
  String? _instructions;
  List<dynamic> _courses = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  final MainController _controller = MainController();

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<String?> _getToken() async {
    final token = LocalStorageService.getGoogleAccessToken();
    if (token == null) {
      print('Error: No valid OAuth token. Ensure the required scopes are enabled.');
    }
    return token;
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    final token = await _getToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://classroom.googleapis.com/v1/courses'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      setState(() => _courses = jsonDecode(response.body)['courses'] ?? []);
    } else {
      print('Courses fetch error: ${response.statusCode}');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectDueTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  Future<void> _createAssignment() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if ((_dueDate != null && _dueTime == null) || 
          (_dueDate == null && _dueTime != null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select both due date and time.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      final token = await _getToken();
      if (token == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      final url = Uri.parse(
          'https://classroom.googleapis.com/v1/courses/$_selectedCourseId/courseWork');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      Map<String, dynamic> requestBody = {
        'title': _title,
        'description': _instructions,
        'state': 'PUBLISHED',
        'workType': 'ASSIGNMENT',
        'maxPoints': _points,
      };

      if (_dueDate != null && _dueTime != null) {
        requestBody['dueDate'] = {
          'year': _dueDate!.year,
          'month': _dueDate!.month,
          'day': _dueDate!.day,
        };
        requestBody['dueTime'] = {
          'hours': _dueTime!.hour,
          'minutes': _dueTime!.minute,
          'seconds': 0,
        };
      }

      String? topicIdNew = await widget._googleClassroomApi.getTopicId(_selectedCourseId!, _topic);
      if (topicIdNew != null) {
        requestBody['topicId'] = topicIdNew;
      }

      final body = jsonEncode(requestBody);

      try {
        final response = await http.post(url, headers: headers, body: body);

        if (response.statusCode == 200) {
          print('Assignment created successfully!');
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating assignment: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Assignment',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Course',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCourseId,
                          items: _courses.map((course) {
                            return DropdownMenuItem<String>(
                              value: course['id'],
                              child: Text(course['name'] ?? 'Unnamed Course'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCourseId = value);
                          },
                          validator: (value) =>
                              value == null ? 'Please select a course' : null,
                          onSaved: (value) => _selectedCourseId = value,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter a title' : null,
                          onSaved: (value) => _title = value,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Instructions',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          onSaved: (value) => _instructions = value,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Points',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value!.isEmpty) return 'Please enter points';
                            if (int.tryParse(value) == null)
                              return 'Please enter a valid number';
                            return null;
                          },
                          onSaved: (value) => _points = int.parse(value!),
                        ),
                        SizedBox(height: 16),
                        ListTile(
                          title: Text(_dueDate == null
                              ? 'Select Due Date'
                              : 'Due Date: ${DateFormat('yyyy-MM-dd').format(_dueDate!)}'),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () => _selectDueDate(context),
                        ),
                        ListTile(
                          title: Text(_dueTime == null
                              ? 'Select Due Time'
                              : 'Due Time: ${_dueTime!.format(context)}'),
                          trailing: Icon(Icons.access_time),
                          onTap: () => _selectDueTime(context),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Assessment Type: $_topic',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _createAssignment,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('Create Assignment'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}