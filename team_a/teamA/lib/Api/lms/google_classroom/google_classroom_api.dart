import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:learninglens_app/Controller/main_controller.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class GoogleClassroomApi {
  final MainController _controller = MainController();

  Future<String?> _getToken() async {
    final token = LocalStorageService.getGoogleAccessToken();
    if (token == null) {
      print(
          'Error: No valid OAuth token. Ensure the required scopes are enabled. Token null');
    }
    return token;
  }

  // -----------------------------------------------------------------------
  // Creates a new Google Form
  // -----------------------------------------------------------------------
  Future<Map<String, dynamic>?> createForm(String title) async {
    final token = await _getToken();
    if (token == null) return null;

    final url = Uri.parse('https://forms.googleapis.com/v1/forms');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'info': {'title': title, 'documentTitle': 'Untitled form'},
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Form creation failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error creating form: $e');
      return null;
    }
  }

  // -----------------------------------------------------------------------
  // Batches the update
  // -----------------------------------------------------------------------
  Future<Map<String, dynamic>?> batchUpdateForm(
      String formId, List<Map<String, dynamic>> requests) async {
    final token = await _getToken();
    if (token == null) return null;

    final url =
        Uri.parse('https://forms.googleapis.com/v1/forms/$formId:batchUpdate');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'requests': requests,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Form batch update failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error updating form settings: $e');
      return null;
    }
  }

 //Future<Map<String, dynamic>?> createAssignment(String courseid, String sectionid, String assignmentName, String startdate, String enddate, String rubricJson, String description);
  // -----------------------------------------------------------------------
// Creates a Classroom assignment and links the form
// -----------------------------------------------------------------------
  // Future<String?> createAssignment(String courseId, String title,
  //     String description, String responderUri, DateTime dueDate) async {
  //   //Change the date parameter to DateTime
  //   // Changed formId to responderUri in the parameters
  //   final token = await _getToken();
  //   if (token == null) return null;

  //   final url = Uri.parse(
  //       'https://classroom.googleapis.com/v1/courses/$courseId/courseWork');
  //   final headers = {
  //     'Authorization': 'Bearer $token',
  //     'Content-Type': 'application/json',
  //   };
  //   final year = dueDate.year;
  //   final month = dueDate.month;
  //   final day = dueDate.day;
  //   final hours = dueDate.hour;
  //   final minutes = dueDate.minute;

  //   final body = jsonEncode({
  //     "title": title,
  //     "description": description,
  //     "workType": "ASSIGNMENT",
  //     "state": "PUBLISHED",
  //     "dueDate": {"year": year, "month": month, "day": day},
  //     "dueTime": {"hours": hours, "minutes": minutes, "seconds": 0},
  //     "materials": [
  //       {
  //         "link": {"url": responderUri}
  //       } // Use the responderUri directly - THIS IS THE FIX!
  //     ]
  //   });

  //   try {
  //     final response = await http.post(url, headers: headers, body: body);

  //     print("Response Status: ${response.statusCode}");
  //     print("Response Body: ${response.body}");

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       final assignmentId = data['id'];
  //       print('Assignment created successfully with ID: $assignmentId');
  //       return assignmentId;
  //     } else {
  //       print('Assignment creation failed: ${response.statusCode}');
  //       return null;
  //     }
  //   } catch (e) {
  //     print('Error creating assignment: $e');
  //     return null;
  //   }
  // }

  Future<String?> createAssignment(String courseId, String title,
      String description, String responderUri, String dueDate) async {
    final log = Logger('GoogleClassroomApi creating Assignments');
    log.info('We are calling createAssignment from Google Classroom.');
    final token = await _getToken();
    if (token == null) return null;

    final url = Uri.parse(
        'https://classroom.googleapis.com/v1/courses/$courseId/courseWork');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Parse the dueDate string to extract year, month, day, hours, and minutes
    List<String> dateParts = dueDate.split('-');
    int year = int.parse(dateParts[0]);
    int month = int.parse(dateParts[1]);
    int day = int.parse(dateParts[2]);
    int hours = int.parse(dateParts[3]);
    int minutes = int.parse(dateParts[4]);
   String? topicId = await getTopicId(courseId, 'Quiz') ?? '755868506953';

   print('topic id is : $topicId');
    
   //String? topicId ='755868506953';
  

    final body = jsonEncode({
      "title": title,
      "description": description,
      "topicId": topicId,
      "workType": "ASSIGNMENT",
      "state": "PUBLISHED",
      "dueDate": {"year": year, "month": month, "day": day},
      "dueTime": {"hours": hours, "minutes": minutes, "seconds": 0},
      "materials": [
        {
          "link": {"url": responderUri}
        } // Use the responderUri directly - THIS IS THE FIX!
      ]
    });

print('body for creating assignment is  : $body');
    try {
      final response = await http.post(url, headers: headers, body: body);

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assignmentId = data['id'];
        print('Assignment created successfully with ID: $assignmentId');
        return assignmentId;
      } else {
      
        print('Assignment creation failed inside createAssignment method : ${response.statusCode}');
         print(response.body);
        return null;
      }
    } catch (e) {
      print('Error creating assignment: $e');
      return null;
    }
  }
  
  Future<String?> getTopicIdByCreating(String courseId, String title) async {
  final log = Logger('GoogleClassroomApi creating Topics');
  log.info('Calling createTopic from Google Classroom.');

  // Obtain the OAuth2 token 
    final token = await _getToken();
  if (token == null) {
    log.severe('Failed to obtain token.');
    return null;
  }

  final url = Uri.parse('https://classroom.googleapis.com/v1/courses/$courseId/topics');
  final headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
  final body = jsonEncode({
    "name": title,
  });

  try {
    // Make the POST request to create the topic
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      // Parse the response and extract the topicId
      final data = jsonDecode(response.body);
      return data['topicId'];
    } else {
      log.severe('Failed to create topic. Status code: ${response.statusCode}, Response: ${response.body}');
    }
  } catch (e) {
    log.severe('Error creating topic: $e');
  }

  return null;
}
Future<String?> getTopicId(String courseId, String title) async {
  final log = Logger('GoogleClassroomApi getting TopicId');
  log.info('Calling listTopics from Google Classroom.');

  final token = await _getToken();
  if (token == null) {
    log.severe('Failed to obtain token.');
    return null;
  }

  final url = Uri.parse('https://classroom.googleapis.com/v1/courses/$courseId/topics');
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  try {
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final topics = data['topic'] as List<dynamic>;
      
      for (var topic in topics) {
        if (topic['name'] == title) {
          return topic['topicId'];
        }
      }
      
      log.warning('Topic with name "$title" not found. So i need to create a new topic');
      return getTopicIdByCreating(courseId, title);
    } else {
      log.severe('Failed to list topics. Status code: ${response.statusCode}, Response: ${response.body}');
    }
  } catch (e) {
    log.severe('Error listing topics: $e');
  }

  return null;
}


}
