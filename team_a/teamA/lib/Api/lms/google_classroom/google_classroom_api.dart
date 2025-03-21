import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:learninglens_app/beans/lesson_plan.dart';
import 'package:logging/logging.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
class GoogleClassroomApi {
  // final MainController _controller = MainController(); ***** Not used *****

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
  Future<Map<String, dynamic>?> createForm(String? teacherFolderId, String title) async {
    final token = await _getToken();
    if (token == null) return null;

    final url = Uri.parse('https://forms.googleapis.com/v1/forms');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'info': {'title': title, 'documentTitle': title},
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print('teacherFolderId: $teacherFolderId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Move the folder to where GC expects it to be. 
        final driveUrl = Uri.https(
          'www.googleapis.com',
          '/drive/v3/files/${data['formId']}',
          {
            'addParents': teacherFolderId,
            'removeParents': 'root',
          },
        );
        final driveHeaders = {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        };
        final driveBody = jsonEncode({
          'addParents': teacherFolderId, // New parent folder
          'removeParents': 'root',
        });

        // Remove from root (optional: fetch current parents if needed)
        final driveResponse = await http.patch(
          driveUrl,
          headers: driveHeaders,
          body: driveBody,
        );
        print('***********************************************************************************');
        print("Drive Update Status: ${driveResponse.statusCode}");
        print("Drive Update Body: ${driveResponse.body}");

        
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
    print('Failed to obtain token.');
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
      print('Failed to create topic. Status code: ${response.statusCode}, Response: ${response.body}');
    }
  } catch (e) {
    print('Error creating topic: $e');
  }

  return null;
}
Future<String?> getTopicId(String courseId, String title) async {
  final log = Logger('GoogleClassroomApi getting TopicId');
  log.info('Calling listTopics from Google Classroom.');

  final token = await _getToken();
  if (token == null) {
    print('Failed to obtain token.');
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
      print('Failed to list topics. Status code: ${response.statusCode}, Response: ${response.body}');
    }
  } catch (e) {
    print('Error listing topics: $e');
  }

  return null;
}
/*
 Future<void> createCourseWorkMaterial(String courseId, String accessToken, String title, ) async {
      final url = Uri.parse('https://classroom.googleapis.com/v1/courses/$courseId/courseWorkMaterials');

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        "title": "My New Course Material",
        "description": "This is a description of the material.",
        "materials": [
          {
            "link": {
              "url": "https://example.com/material"
            }
          }
        ],
        "state": "PUBLISHED",
        "scheduledTime": "2024-03-15T10:00:00Z",
        "topicId": "your_topic_id"
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // Success! The course work material was created.
        print('Course work material created successfully!');
        print(response.body); // You might want to parse the response JSON here.
      } else {
        // Error! Something went wrong.
        print('Error creating course work material: ${response.statusCode}');
        print(response.body);
      }
    }
*/
  // -----------------------------------------------------------------------
  // Course Work Realated Methods
  // -----------------------------------------------------------------------


  Future<String?> createCourseWorkMaterial(String courseId, String title, String description, String materialUrl,
      {String? topicId, DateTime? scheduledTime}) async {
    print('Creating material: $title');

    final accessToken = await _getToken();
    if (accessToken == null) return null;

    final googleClassroomApi = GoogleClassroomApi();
    String? topicID = await googleClassroomApi.getTopicId(courseId, "Lesson Plans");

    final url = Uri.parse('https://classroom.googleapis.com/v1/courses/$courseId/courseWorkMaterials');
    final headers = {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'};
    final body = jsonEncode({
      "title": title,
      "description": description,
      "state": "PUBLISHED",
      if (scheduledTime != null) "scheduledTime": scheduledTime.toUtc().toIso8601String(),
      if (topicID != null) "topicId": topicID,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['id'];
      } else {
        print('Error creating material: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error creating material: $e');
      return null;
    }
  }

/*
Future<void> updateCourseWorkMaterial(String courseId, String materialId, String? title, String? description,
    {String? topicId, DateTime? scheduledTime, String? state}) async {
  print('Updating material: $materialId');

  final accessToken = await _getToken();
  if (accessToken == null) return;

  final url = Uri.parse('https://classroom.googleapis.com/v1/courses/$courseId/courseWorkMaterials/$materialId');
  print('Update URL: $url');

  final updateMask = _generateUpdateMask(title, description, topicId, scheduledTime, state);
  final headers = {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
    'updateMask': updateMask,
  };
  print('Update Mask: $updateMask');

  final Map<String, dynamic> requestBody = {};
  if (title != null) requestBody["title"] = title;
  if (description != null) requestBody["description"] = description;
  // if (state != null) requestBody["state"] = state;
  // if (scheduledTime != null) requestBody["scheduledTime"] = scheduledTime.toUtc().toIso8601String();
  // if (topicId != null) requestBody["topicId"] = topicId;

  final body = jsonEncode(requestBody);

  print('Request Body:=> $body');

  try {
    print('Inside the try block');
    final response = await http.patch(url, headers: headers, body: body);
    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      getLessonPlan(courseId);
    } else {
      print('Error updating material: ${response.statusCode}');
    }
  } catch (e) {
    print('Error updating material: $e');
  }
}
*/
Future<void> updateCourseWorkMaterial(
    String courseId,
    String materialId,
    String? title,
    String? description, {
    String? topicId,
    DateTime? scheduledTime,
    String? state,
  }) async {
  print('Updating material: $materialId');

  final accessToken = await _getToken();
  if (accessToken == null) {
    print('No valid access token found.');
    return;
  }

  // Generate the updateMask
  final updateMask = _generateUpdateMask(title, description, topicId, scheduledTime, state);
  final url = Uri.parse(
      'https://classroom.googleapis.com/v1/courses/$courseId/courseWorkMaterials/$materialId?updateMask=$updateMask');
  print('Update URL: $url');

  final headers = {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };

  final Map<String, dynamic> requestBody = {};
  if (title != null) requestBody["title"] = title;
  if (description != null) requestBody["description"] = description;
  // Uncomment and use these if needed
  // if (state != null) requestBody["state"] = state;
  // if (scheduledTime != null) requestBody["scheduledTime"] = scheduledTime.toUtc().toIso8601String();
  // if (topicId != null) requestBody["topicId"] = topicId;

  final body = jsonEncode(requestBody);
  print('Request Body: $body');

  final client = http.Client();
  try {
    final response = await client.patch(url, headers: headers, body: body);
    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      print('Material updated successfully.');
      // Note: We’ll refresh the UI in the calling code, not here
    } else {
      print('Error updating material: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Detailed error updating material: $e');
  } finally {
    client.close();
  }
}

// Helper method to generate updateMask (unchanged)
String _generateUpdateMask(String? title, String? description, String? topicId, DateTime? scheduledTime, String? state) {
  List<String> fields = [];
  if (title != null) fields.add('title');
  if (description != null) fields.add('description');
  if (topicId != null) fields.add('topicId');
  if (scheduledTime != null) fields.add('scheduledTime');
  if (state != null) fields.add('state');
  return fields.join(',');
}

  Future<void> deleteCourseWorkMaterial(String courseId, String materialId) async {
    print('Deleting material:  $materialId');
    final accessToken = await _getToken();
    if (accessToken == null) return;

    final url = Uri.parse('https://classroom.googleapis.com/v1/courses/$courseId/courseWorkMaterials/$materialId');
    final headers = {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'};

    try {
      final response = await http.delete(url, headers: headers);

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 204) {
        getLessonPlan(courseId);
      } else {
        print('Error deleting material: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting material: $e');
    }
  }



Future<void> getLessonPlan(String courseId) async {
  LessonPlan lessonPlan = LessonPlan.empty();
  try {
    final accessToken = await _getToken();
    if (accessToken == null) return;

    final url = Uri.parse('https://classroom.googleapis.com/v1/courses/$courseId/courseWorkMaterials');
    final headers = {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'};
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data.containsKey('courseWorkMaterial')) {
        List<LessonPlan> lessonPlans = (data['courseWorkMaterial'] as List)
            .map((item) => lessonPlan.fromGoogleJson(item as Map<String, dynamic>))
            .toList();

        print('Lesson Plans: $lessonPlans');
      } else {
        print('No coursework materials found.');
      }
    } else {
      print('Error loading coursework materials: ${response.statusCode}');
    }
  } catch (e) {
    print('Error loading coursework materials: $e');
  }
}


// -----------------------------------------------------------------------
// retrive the quiz questions
// -----------------------------------------------------------------------
  Future<Map<String, dynamic>?> getQuizQuestions(String courseId, String quizId) async {
    final token = await _getToken();
    if (token == null) return null;

    final url = Uri.parse('https://classroom.googleapis.com/v1/courses/$courseId/courseWork/$quizId');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Quiz questions retrieval failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error retrieving quiz questions: $e');
      return null;
    }
  }

  // -----------------------------------------------------------------------
  // Updates the course work
  // -----------------------------------------------------------------------
  Future<Map<String, dynamic>?> updateCourseWork(String courseId, String courseWorkId, String title, String description,
      String? dueDate, String? dueTime, String? rubricJson, String? state) async {
    final token = await _getToken();
    if (token == null) return null;

    final url = Uri.parse('https://classroom.googleapis.com/v1/courses/$courseId/courseWork/$courseWorkId');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'dueTime': dueTime,
      'rubric': rubricJson,
      'state': state,
    });

    try {
      final response = await http.put(url, headers: headers, body: body);

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Course work update failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error updating course work: $e');
      return null;
    }
  }

  // -----------------------------------------------------------------------

  // Method to retrieve Google Form questions from an assignment
  // -----------------------------------------------------------------------
  

Future<List<String>> getAssignmentFormQuestions(String? courseId, String? courseWorkId) async {
  //  "courseId": "750797786103",
  //"id": "757589683856",
  try {
    // Step 1: Retrieve the stored access token
    final token = await _getToken();
    print('Token: $token'); // Debug output

    if (token == null) {
      throw Exception('No access token found. Please log in again.');
    }

    // Step 2: Fetch assignment details from Google Classroom API
    final courseworkUrl =
        'https://classroom.googleapis.com/v1/courses/$courseId/courseWork/$courseWorkId';
    final courseworkResponse = await http.get(
      Uri.parse(courseworkUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Coursework URL: $courseworkUrl'); // Debug output
    print('Coursework Response: ${courseworkResponse.body}'); // Debug output

    if (courseworkResponse.statusCode != 200) {
      throw Exception(
          'Failed to fetch coursework: ${courseworkResponse.statusCode} - ${courseworkResponse.body}');
    }

    final courseworkData = jsonDecode(courseworkResponse.body);
    print('Coursework Data: $courseworkData'); // Debug output

    // Step 3: Extract Form URL from materials
    String? formUrl;
    if (courseworkData['materials'] != null && courseworkData['materials'].isNotEmpty) {
      for (var material in courseworkData['materials']) {
        if (material['link'] != null && material['link']['url'] != null) {
          final url = material['link']['url'];
          if (url.contains('docs.google.com/forms')) {
            formUrl = url;
            break;
          }
        }
      }
    }

    if (formUrl == null) {
      throw Exception('No Google Form found in assignment materials.');
    }
    print('Form URL: $formUrl'); // Debug output

    // Step 4: Extract Form ID from the URL
    final formId = formUrl.split('/d/e/')[1].split('/')[0];
    print('Form ID: $formId'); // Debug output

    // Step 5: Fetch form details from Google Forms API
    final formsUrl = 'https://forms.googleapis.com/v1/forms/$formId';
    final formsResponse = await http.get(
      Uri.parse(formsUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (formsResponse.statusCode != 200) {
      throw Exception(
          'Failed to fetch form: ${formsResponse.statusCode} - ${formsResponse.body}');
    }

    final formData = jsonDecode(formsResponse.body);
    print('Form Data: $formData'); // Debug output

    // Step 6: Extract questions from the form
    List<String> questions = [];
    if (formData['items'] != null) {
      for (var item in formData['items']) {
        if (item['questionItem'] != null && item['questionItem']['question'] != null) {
          questions.add(item['questionItem']['question']['text']);
        }
      }
    }

    return questions;
  } catch (e) {
    print('Error retrieving form questions: $e');
    return [];
  }
}



}
