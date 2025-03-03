import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Controller/main_controller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class CreateAssignmentPage extends StatefulWidget {
  @override
  _CreateAssignmentPageState createState() => _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends State<CreateAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCourseId;
  int? _points;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String? _topic;
  String? _title;
  String? _instructions;
  List<dynamic> _courses = [];
  bool _isLoading = false;
  final MainController _controller = MainController();

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<String?> _getToken() async {
    final token = LocalStorageService.getGoogleAccessToken();
    if (token == null) {
      print(
          'Error: No valid OAuth token. Ensure the required scopes are enabled.');
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

      // Validate date and time selection
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

      final token = await _getToken();
      if (token == null) return;

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

      // Add due date and time directly in the courseWork object
      if (_dueDate != null && _dueTime != null) {
        requestBody['dueDate'] = {
          'year': _dueDate!.year,
          'month': _dueDate!.month,
          'day': _dueDate!.day,
        };
        requestBody['dueTime'] = {
          'hours': _dueTime!.hour,
          'minutes': _dueTime!.minute,
          'seconds': 0, // Required by API
        };
      }

      if (_topic != null && _topic!.isNotEmpty) {
        requestBody['topicId'] = _topic;
      }

      final body = jsonEncode(requestBody);

      print('Request body: $body');

      try {
        final response = await http.post(url, headers: headers, body: body);

        if (response.statusCode == 200) {
          print('Assignment created successfully!');
          Navigator.pop(context);
        } else {
          print('Failed to create assignment. Status: ${response.statusCode}');
          print('Error response: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Error creating assignment: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Exception during assignment creation: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Create Assignment'),
      // ),
      appBar: CustomAppBar(
          title: 'Create Assignment',
          userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Course'),
                      value: _selectedCourseId,
                      items: _courses.map((course) {
                        return DropdownMenuItem<String>(
                          value: course['id'],
                          child: Text(course['name'] ?? 'Unnamed Course'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCourseId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a course';
                        }
                        return null;
                      },
                      onSaved: (value) => _selectedCourseId = value,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Title'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                      onSaved: (value) => _title = value,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Instructions'),
                      onSaved: (value) => _instructions = value,
                      maxLines: 3,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Points'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter points';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onSaved: (value) => _points = int.parse(value!),
                    ),
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
                    TextFormField(
                      decoration:
                          InputDecoration(labelText: 'Topic (Optional)'),
                      onSaved: (value) => _topic = value,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _createAssignment,
                      child: Text('Create Assignment'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
