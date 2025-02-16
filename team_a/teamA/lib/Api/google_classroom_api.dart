import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:learninglens_app/Controller/main_controller.dart';

class GoogleClassroomApi {
  final String classroomApiUrl = 'https://classroom.googleapis.com/v1/courses';
  final String formsApiUrl =
      'https://forms.googleapis.com/v1/forms'; // Base URL for Forms API
  final MainController _controller = MainController();

  // Scopes needed.  Add the forms scope.  Make sure these are enabled in your Google Cloud project.
  final List<String> _scopes = [
    'https://www.googleapis.com/auth/classroom.courses.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.me',
    'https://www.googleapis.com/auth/classroom.coursework.students',
    'https://www.googleapis.com/auth/forms.body', // Add the Forms API scope
    'https://www.googleapis.com/auth/forms.responses.readonly'
  ];

  // Fetch OAuth token
  Future<String?> _getToken() async {
    final token = await _controller.getAccessToken(scopes: _scopes);
    if (token == null) {
      print('Error: OAuth token not found. Ensure scopes are enabled.');
    }
    return token;
  }

  // -----------------------------------------------------------------------
  // NEW: Create a Google Form
  // -----------------------------------------------------------------------
  Future<String?> createForm(String title) async {
    final token = await _getToken();
    if (token == null) {
      print('Error: Unable to retrieve token. Aborting form creation.');
      return null;
    }

    final url = Uri.parse(formsApiUrl);
    final requestBody = jsonEncode({
      'info': {'title': title}
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final formId = data['formId']?.toString();
        print('Form created successfully with ID: $formId');
        return formId;
      } else {
        print('Form creation failed with status: ${response.statusCode}');
        print('Error details: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during form creation: $e');
      return null;
    }
  }

  // -----------------------------------------------------------------------
  // NEW: Add a question to the form (example: multiple choice)
  // -----------------------------------------------------------------------
  Future<bool> addQuestion(
      String formId, String questionText, List<String> options) async {
    final token = await _getToken();
    if (token == null) {
      print('Error: Unable to retrieve token. Aborting question creation.');
      return false;
    }

    final url = Uri.parse(
        '$formsApiUrl/$formId:batchUpdate'); // Use batch update for modifications
    final requestBody = jsonEncode({
      "requests": [
        {
          "createItem": {
            "item": {
              "title": questionText,
              "questionItem": {
                "question": {
                  "required": true,
                  "choiceQuestion": {
                    "type":
                        "RADIO", // Multiple choice (yes/no would also use RADIO)
                    "options":
                        options.map((option) => {"value": option}).toList(),
                  }
                }
              },
            },
            "location": {"index": 0} // Add at the beginning
          }
        }
      ]
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Question added successfully');
        return true;
      } else {
        print('Question addition failed with status: ${response.statusCode}');
        print('Error details: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during question addition: $e');
      return false;
    }
  }

  // -----------------------------------------------------------------------
  // NEW: Add a short answer question
  // -----------------------------------------------------------------------
  Future<bool> addShortAnswerQuestion(
      String formId, String questionText) async {
    final token = await _getToken();
    if (token == null) {
      print('Error: Unable to retrieve token. Aborting question creation.');
      return false;
    }

    final url = Uri.parse('$formsApiUrl/$formId:batchUpdate');
    final requestBody = jsonEncode({
      "requests": [
        {
          "createItem": {
            "item": {
              "title": questionText,
              "questionItem": {
                "question": {
                  "required": true,
                  "textQuestion": {} // For short answer
                }
              },
            },
            "location": {"index": 0} // Add at the beginning
          }
        }
      ]
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Short answer question added successfully');
        return true;
      } else {
        print('Question addition failed with status: ${response.statusCode}');
        print('Error details: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during question addition: $e');
      return false;
    }
  }

  // -----------------------------------------------------------------------
  // Modified: Create Assignment (now links to the Form)
  // -----------------------------------------------------------------------
  Future<String?> createAssignment(
    String courseId,
    String title,
    String description,
    String formId, // The ID of the Google Form
    String dueDateTime,
  ) async {
    final token = await _getToken();
    if (token == null) {
      print('Error: Unable to retrieve token. Aborting assignment creation.');
      return null;
    }

    final url = Uri.parse('$classroomApiUrl/$courseId/courseWork');
    final requestBody = jsonEncode({
      'title': title,
      'description': description,
      'workType': 'ASSIGNMENT',
      'state': 'PUBLISHED',
      'dueDate': {
        //Fix the format of the due date
        'year': dueDateTime.split('-')[0],
        'month': dueDateTime.split('-')[1],
        'day': dueDateTime.split('-')[2],
      },
      'dueTime': {
        'hours': dueDateTime.split('-')[3],
        'minutes': dueDateTime.split('-')[4],
        'seconds': 0
      },
      'materials': [
        // Attach the form as a material
        {
          'link': {
            'url':
                'https://docs.google.com/forms/d/e/$formId' // Construct the form URL
          }
        }
      ],
    });

    print('Request Body: $requestBody');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assignmentId = data['id']?.toString();
        print('Assignment created successfully with ID: $assignmentId');
        return assignmentId;
      } else {
        print('Assignment creation failed with status: ${response.statusCode}');
        print('Error details: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during assignment creation: $e');
      return null;
    }
  }
}
