import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:learninglens_app/beans/g_question_form_data.dart';
import 'package:logger/logger.dart';
import 'package:learninglens_app/beans/quiz_type.dart';
import 'package:xml/xml.dart' as xml;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/submission_status.dart';
import 'package:learninglens_app/beans/grade.dart';
import 'package:learninglens_app/beans/submission.dart';
import 'package:learninglens_app/beans/submission_with_grade.dart';
import 'package:learninglens_app/beans/moodle_rubric.dart';
import 'package:learninglens_app/services/api_service.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/Api/lms/google_classroom/google_classroom_api.dart'; // Import the updated API

/// A Singleton class for Moodle API access implementing [LmsInterface].
class GoogleLmsService extends LmsInterface {
  // Needed??
  final GoogleClassroomApi _classroomApi = GoogleClassroomApi();

  // ****************************************************************************************
  // Static / Singleton internals
  // ****************************************************************************************

  static final GoogleLmsService _instance = GoogleLmsService._internal();

  /// The singleton accessor.
  factory GoogleLmsService() => _instance;

  /// Private named constructor.
  GoogleLmsService._internal();

  // ****************************************************************************************
  // Fields implementing LmsInterface
  // ****************************************************************************************

  @override
  String serverUrl = ''; // The Google REST endpoint

  // The user token is kept private (not in the interface).
  String? _userToken;

  @override
  String apiURL =
      'https://classroom.googleapis.com/v1'; // Base URL for your Google Classroom
  @override
  String? userName;
  @override
  String? firstName;
  @override
  String? lastName;
  @override
  String? siteName = 'Google Classroom';
  @override
  String? fullName;
  @override
  String? profileImage;
  @override
  List<Course>? courses;

  late GoogleSignIn _googleSignIn;

  // ****************************************************************************************
  // Auth / Login
  // ****************************************************************************************

  @override
  Future<void> login(String username, String password, String baseURL) {
    // TODO: implement google api code
    throw UnimplementedError();
  }

  Future<void> loginOath(String clientID) async {
    print('Logging in to Google Classroom...');

    _googleSignIn = GoogleSignIn(
      clientId: clientID,
      scopes: <String>[
        'email',
        'profile',
        'https://www.googleapis.com/auth/classroom.courses',
        'https://www.googleapis.com/auth/classroom.topics',
        'https://www.googleapis.com/auth/classroom.rosters',
        'https://www.googleapis.com/auth/classroom.coursework.students',
        'https://www.googleapis.com/auth/classroom.coursework.me',
        'https://www.googleapis.com/auth/classroom.courses.readonly',
        'https://www.googleapis.com/auth/forms.body',
        'https://www.googleapis.com/auth/forms.responses.readonly',
        'https://www.googleapis.com/auth/classroom.courseworkmaterials.readonly',
        'https://www.googleapis.com/auth/classroom.courseworkmaterials',
        'https://www.googleapis.com/auth/forms.body.readonly',
        'https://www.googleapis.com/auth/drive.file',
      ],
    );

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception("Google Sign-In was cancelled by the user.");
      }

      // Get the user's name
      userName = googleUser.email.split("@").first;
      fullName = googleUser.displayName ?? "Unknown User";

      List<String> nameParts = fullName!.split(" ");

      firstName = nameParts.isNotEmpty ? nameParts.first : "";
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";

      print('Welcome, ${firstName ?? 'User'}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      _userToken = googleAuth.accessToken;

      if (_userToken == null) {
        throw Exception("Failed to obtain access token.");
      }

      LocalStorageService.saveGoogleAccessToken(_userToken!);
    } catch (error) {
      print("Google Sign-In Error: $error");
      throw Exception("Google Sign-In failed: $error");
    }

    courses = await getUserCourses();

    // for (Course course in courses!) {
    //   print('teacherFolderId: ${course.teacherFolderId}');
    // }
  }

  @override
  bool isLoggedIn() {
    return _userToken != null;
  }

  String getGoogleAccessToken() {
    return _userToken!;
  }

  @override
  Future<bool> isUserTeacher(List<Course> moodleCourses) async {
    // TODO: implement google api code
    throw UnimplementedError();
  }

  @override
  void logout() {
    print('Logging out of Google...');
    _googleSignIn.signOut();
    resetLMSUserInfo();
  }

  @override
  void resetLMSUserInfo() {
    // Clear all user-related fields
    _userToken = null;
    apiURL = '';
    userName = null;
    firstName = null;
    lastName = null;
    siteName = null;
    fullName = null;
    profileImage = null;
    courses = [];
  }

  // ****************************************************************************************
  // Course-related methods
  // ****************************************************************************************

  @override
  Future<List<Course>> getCourses() async {
    // TODO: implement google api code
    // Never called??
    throw UnimplementedError();
  }

  @override
  Future<List<Course>> getUserCourses() async {
    if (_userToken == null) throw StateError('User not logged in to Google');

    final response = await ApiService().httpGet(
      Uri.parse('https://classroom.googleapis.com/v1/courses'),
      headers: {'Authorization': 'Bearer $_userToken'},
    );

    // TODO: remove after testing.
    // print('Google: ${response.body}');

    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }

    final decodedJson = jsonDecode(response.body);
    List<Course> courses;

    // The response can be either a List or a Map with a 'courses' key
    if (decodedJson is List) {
      courses =
          decodedJson.map((i) => Course.empty().fromGoogleJson(i)).toList();
    } else if (decodedJson is Map<String, dynamic>) {
      final courseList = decodedJson['courses'] as List<dynamic>;
      courses =
          courseList.map((i) => Course.empty().fromGoogleJson(i)).toList();
    } else {
      throw StateError('Unexpected response format from Moodle');
    }

    // Optionally fetch quizzes/essays for each course
    for (Course course in courses) {
      // set topic ids
      final responseTopics = await ApiService().httpGet(
        Uri.parse(
            'https://classroom.googleapis.com/v1/courses/${course.id}/topics/'),
        headers: {'Authorization': 'Bearer $_userToken'},
      );

      var decodedResponseTopics = jsonDecode(responseTopics.body);

      if (decodedResponseTopics.containsKey('topic')) {
        List<dynamic> topics = decodedResponseTopics["topic"];

        // Iterate and capture topicIds
        for (var topic in topics) {
          if (topic['name'] == 'Quiz') {
            course.quizTopicId = int.parse(topic['topicId']);
            //   print('Id for quiz');
            // print(topic['topicId']);
          } else if (topic['name'] == 'Essay') {
            course.essayTopicId = int.parse(topic['topicId']);
            //  print('Id for essay');
            // print(topic['topicId']);
          }
        }
      }

      course.quizzes = await getQuizzes(course.id, topicId: course.quizTopicId);
      // print('Quizzes for course ${course.id}: ${course.quizzes}');
      course.essays = await getEssays(course.id, topicId: course.essayTopicId);
      // print('Essays for course ${course.id}: ${course.essays}');
    }

    return courses;
  }

  @override
  Future<List<Participant>> getCourseParticipants(String courseId) async {
    if (_userToken == null) {
      throw StateError('User not logged in to Google Classroom');
    }

    final List<Participant> participants = [];

    // Fetch students
    final studentsResponse = await ApiService().httpGet(
      Uri.parse(apiURL + '/courses/$courseId/students'),
      headers: {'Authorization': 'Bearer $_userToken'},
    );

    if (studentsResponse.statusCode == 200) {
      final studentsJson = jsonDecode(studentsResponse.body);
      if (studentsJson.containsKey('students')) {
        for (var student in studentsJson['students']) {
          participants.add(Participant(
            id: student['userId']
                .hashCode, // Google Classroom does not provide numeric IDs
            fullname: student['profile']['name']['fullName'],
            firstname: student['profile']['name']['givenName'],
            lastname: student['profile']['name']['familyName'],
            roles: ['student'],
          ));
        }
      }
    } else {
      throw HttpException('Failed to fetch students: ${studentsResponse.body}');
    }

    // Fetch teachers
    final teachersResponse = await ApiService().httpGet(
      Uri.parse(apiURL + '/courses/$courseId/teachers'),
      headers: {'Authorization': 'Bearer $_userToken'},
    );

    if (teachersResponse.statusCode == 200) {
      final teachersJson = jsonDecode(teachersResponse.body);
      if (teachersJson.containsKey('teachers')) {
        for (var teacher in teachersJson['teachers']) {
          participants.add(Participant(
            id: teacher['userId'].hashCode,
            fullname: teacher['profile']['name']['fullName'],
            firstname: teacher['profile']['name']['givenName'],
            lastname: teacher['profile']['name']['familyName'],
            roles: ['teacher'],
          ));
        }
      }
    } else {
      throw HttpException('Failed to fetch teachers: ${teachersResponse.body}');
    }

    return participants;
  }

  // ****************************************************************************************
  // Quiz methods
  // ****************************************************************************************

  @override
  Future<void> importQuiz(String courseid, String quizXml) async {
    // TODO: implement google api code
    throw UnimplementedError(
        'This feature is not supported by Google Classroom. Please contact the developer.');
  }

  @override
  Future<List<Quiz>> getQuizzes(int? courseID, {int? topicId}) async {
    if (_userToken == null)
      throw StateError('User not logged in to Google Classroom');

    final response = await ApiService().httpGet(
      Uri.parse(
          'https://classroom.googleapis.com/v1/courses/$courseID/courseWork'),
      headers: {'Authorization': 'Bearer $_userToken'},
    );

    // print('quizlist: ${response.body}');

    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }

    // print('Getting quizzes from Google Classroom...');
    // print(response.body);

    final quizzesMap = jsonDecode(response.body) as Map<String, dynamic>;
    final decodedJson = quizzesMap['courseWork'] as List<dynamic>?;

    if (decodedJson == null) {
      return [];
    }

    List<Quiz> quizList = [];
    for (var item in decodedJson) {
      // print('Item: $item');
      // If courseID is null, return all quizzes; otherwise filter by course
      if (courseID == null || int.parse(item['courseId']) == courseID) {
        if (topicId != null && item.containsKey('topicId')) {
          if (int.parse(item['topicId']) == topicId) {
            quizList.add(Quiz.fromGoogleJson(item));
          }
        }
      }
    }

    // print('I am getting this quiz list: $quizList');

    return quizList;
  }

  @override
  Future<int?> createQuiz(String courseid, String quizname, String quizintro,
      String sectionid, String timeopen, String timeclose) async {
    print('Creating quiz in Google Classroom...');
    print('Course ID: $courseid');
    print('Quiz Name: $quizname');
    print('Quiz Intro: $quizintro');
    print('Section ID: $sectionid');
    print('Time Open: $timeopen');
    print('Time Close: $timeclose');

    try {
      // Convert timeopen to ISO 8601 format
      String formattedTimeOpen = DateTime.parse(timeopen).toIso8601String();

      String? assignmentId = await createAssignmentHelper(
          courseid, quizname, quizintro, sectionid, formattedTimeOpen);

      if (assignmentId != null) {
        return int.parse(assignmentId);
      } else {
        print('Failed to create quiz');
        return null;
      }
    } catch (e) {
      print('Error creating quiz: $e');
      return null;
    }
  }

  Future<String?> createAssignmentHelper(String courseId, String title,
      String description, String responderUri, String dueDate) async {
    print('Creating assignment in Google Classroom... Inside helper');
    print('Course ID: $courseId');
    print('Title: $title');
    print('Description: $description');
    print('Responder URI: $responderUri');
    print('Due Date: $dueDate');

    final token = _userToken;
    if (token == null) {
      print('User token is null');
      return null;
    }

    final url = Uri.parse(
        'https://classroom.googleapis.com/v1/courses/$courseId/courseWork');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Parse the dueDate string
    DateTime parsedDate = DateTime.parse(dueDate);

    final body = jsonEncode({
      "title": title,
      "description": description,
      "workType": "ASSIGNMENT",
      "state": "PUBLISHED",
      "dueDate": {
        "year": parsedDate.year,
        "month": parsedDate.month,
        "day": parsedDate.day
      },
      "dueTime": {
        "hours": parsedDate.hour,
        "minutes": parsedDate.minute,
        "seconds": 0
      },
      "materials": [
        {
          "link": {"url": responderUri}
        }
      ]
    });

    // Print request details
    print('Request URL: $url');
    print('Request Headers: $headers');
    print('Request Body: $body');

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
        print('Assignment creation failed: ${response.statusCode}');
        print('Error message: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating assignment: $e');
      return null;
    }
  }

  @override
  Future<String> addRandomQuestions(
      String categoryid, String quizid, String numquestions) async {
    print('Adding random questions to quiz...');
    print('Category ID: $categoryid');
    // TODO: implement google api code
    throw UnimplementedError(
        'This feature is not supported by Google Classroom. Please contact the developer.');
  }

  @override
  Future<int?> importQuizQuestions(String courseid, String quizXml) async {
    print('Importing quiz questions...');
    print('Course ID: $courseid');
    print('Quiz XML: $quizXml');
    // TODO: implement google api code
    throw UnimplementedError(
        'This feature is not supported by Google Classroom. Please contact the developer.');
  }

  @override
  Future<List<QuestionType>> getQuestionsFromQuiz(int quizId) async {
    // TODO: implement google api code
    throw UnimplementedError(
        'This feature is not supported by Google Classroom. Please contact the developer.');
  }

  Future<FormData> getAssignmentFormQuestions(
      String coursedId, String courseWorkId) async {
    print(
        'Fetching form questions for course $coursedId, coursework $courseWorkId...');
    try {
      final accessToken = await _getToken();
      if (accessToken == null) {
        throw Exception('No access token found. Please log in again.');
      }

      final courseworkUrl =
          'https://classroom.googleapis.com/v1/courses/$coursedId/courseWork/$courseWorkId';
      final courseworkResponse = await http.get(
        Uri.parse(courseworkUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (courseworkResponse.statusCode != 200) {
        throw Exception(
            'Failed to fetch coursework: ${courseworkResponse.statusCode} - ${courseworkResponse.body}');
      }

      final courseworkData = jsonDecode(courseworkResponse.body);
      print('Coursework data: $courseworkData');

      String? formUrl;
      if (courseworkData['materials'] != null &&
          courseworkData['materials'].isNotEmpty) {
        for (var material in courseworkData['materials']) {
          if (material['link'] != null && material['link']['url'] != null) {
            final url = material['link']['url'];
            if (url.contains('docs.google.com/forms')) {
              formUrl = url;
              break;
            }
          }
          if (material['form'] != null && material['form']['formUrl'] != null) {
            final url = material['form']['formUrl'];
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
      print('Extracted Form URL: $formUrl');

      // Extract and format dates to YYYY-MM-DD
      String? startDate;
      if (courseworkData['creationTime'] != null) {
        final dateTime = DateTime.parse(courseworkData['creationTime']);
        startDate =
            '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      }

      String? endDate;
      if (courseworkData['dueDate'] != null) {
        final dueDate = courseworkData['dueDate'];
        endDate =
            '${dueDate['year']}-${dueDate['month'].toString().padLeft(2, '0')}-${dueDate['day'].toString().padLeft(2, '0')}';
      }

      String? status = courseworkData['state'];

      final formId = await getFormIdFromViewformUrl(formUrl, accessToken);
      if (formId == null) {
        throw Exception('Failed to retrieve Form ID from viewform URL');
      }
      print('Form ID: $formId');

      final formsUrl = 'https://forms.googleapis.com/v1/forms/$formId';
      final formsResponse = await http.get(
        Uri.parse(formsUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (formsResponse.statusCode != 200) {
        throw Exception(
            'Failed to fetch form: ${formsResponse.statusCode} - ${formsResponse.body}');
      }

      final formData = jsonDecode(formsResponse.body);
      print('Form data: $formData');

      String title = formData['info']?['title'] ?? 'Untitled Form';
      List<QuestionData> questions = [];
      if (formData['items'] != null) {
        for (var item in formData['items']) {
          if (item['questionItem'] != null &&
              item['questionItem']['question'] != null) {
            String questionText = item['title'] ?? 'Unnamed Question';
            List<String> options = [];
            if (item['questionItem']['question']['choiceQuestion'] != null) {
              var choiceQuestion =
                  item['questionItem']['question']['choiceQuestion'];
              if (choiceQuestion['options'] != null) {
                for (var option in choiceQuestion['options']) {
                  options.add(option['value'] ?? 'No Option');
                }
              }
            }
            questions
                .add(QuestionData(question: questionText, options: options));
          }
        }
      }

      return FormData(
        title: title,
        questions: questions,
        startDate: startDate,
        endDate: endDate,
        formUrl: formUrl,
        status: status,
      );
    } catch (e) {
      print('Error retrieving form questions: $e');
      return FormData(title: 'Error', questions: []);
    }
  }

  Future<String?> getFormIdFromViewformUrl(
      String viewformUrl, String accessToken) async {
    try {
      final publicKey = viewformUrl.split('/d/e/')[1].split('/')[0];
      print('Public key: $publicKey');

      final driveUrl = 'https://www.googleapis.com/drive/v3/files'
          '?q=mimeType="application/vnd.google-apps.form"'
          '&fields=files(id,name)'
          '&spaces=drive';
      final driveResponse = await http.get(
        Uri.parse(driveUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (driveResponse.statusCode != 200) {
        throw Exception('Failed to fetch Drive files: ${driveResponse.body}');
      }

      final driveData = jsonDecode(driveResponse.body);
      print('Drive data: $driveData');

      for (var file in driveData['files']) {
        final fileId = file['id'];
        print('Checking file ID: $fileId');

        final formsUrl = 'https://forms.googleapis.com/v1/forms/$fileId';
        final formResponse = await http.get(
          Uri.parse(formsUrl),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );

        if (formResponse.statusCode == 200) {
          final formData = jsonDecode(formResponse.body);
          final responderUri = formData['responderUri'];
          print('Responder URI for $fileId: $responderUri');

          if (responderUri != null && responderUri.contains(publicKey)) {
            print('Matched form ID: $fileId');
            return fileId;
          }
        } else {
          print('Failed to fetch form $fileId: ${formResponse.statusCode}');
        }
      }

      throw Exception(
          'No matching form found in Drive for the provided viewform URL');
    } catch (e) {
      print('Error fetching Form ID from Drive: $e');
      return null;
    }
  }

  Future<String?> _getToken() async {
    final token = LocalStorageService.getGoogleAccessToken();
    if (token == null) {
      print(
          'Error: No valid OAuth token. Ensure the required scopes are enabled. Token null');
    }
    return token;
  }

  // ****************************************************************************************
  // Assignment methods
  // ****************************************************************************************

  @override
  Future<List<Assignment>> getEssays(int? courseID, {int? topicId}) async {
    if (_userToken == null)
      throw StateError('User not logged in to Google Classroom');

    final response = await ApiService().httpGet(
      Uri.parse(
          'https://classroom.googleapis.com/v1/courses/$courseID/courseWork'),
      headers: {'Authorization': 'Bearer $_userToken'},
    );

    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }

    final essaysMap = jsonDecode(response.body) as Map<String, dynamic>;
    final decodedJson = essaysMap['courseWork'] as List<dynamic>?;

    if (decodedJson == null) {
      return [];
    }

    List<Assignment> essayList = [];
    for (var item in decodedJson) {
      // If courseID is null, return all quizzes; otherwise filter by course
      if (courseID == null || int.parse(item['courseId']) == courseID) {
        if (topicId != null && item.containsKey('topicId')) {
          if (int.parse(item['topicId']) == topicId) {
            essayList.add(Assignment.empty().fromGoogleJson(item));
          }
        }
      }
    }

    return essayList;
  }

  @override
  Future<Map<String, dynamic>?> createAssignment(
    String courseid,
    String sectionid,
    String assignmentName,
    String startdate,
    String enddate,
    String rubricJson,
    String description,
  ) async {
    print('Creating assignment...');
    print('Course ID: $courseid');
    print('Section ID: $sectionid');
    print('Assignment Name: $assignmentName');
    print('Start Date: $startdate');
    print('End Date: $enddate');
    // TODO: implement google api code
    throw UnimplementedError();
  }

  @override
  Future<int?> getContextId(int assignmentId, String courseId) async {
    print('Getting context ID...');
    print('Assignment ID: $assignmentId');
    print('Course ID: $courseId');
    // TODO: implement google api code
    throw UnimplementedError(
        'This feature is not supported by Google Classroom. Please contact the developer.');
  }

  // ****************************************************************************************
  // Submissions and grading
  // ****************************************************************************************

  @override
  Future<List<Submission>> getAssignmentSubmissions(int assignmentId) async {
    print('Getting assignment submissions...');
    print('Assignment ID: $assignmentId');
    // TODO: implement google api code
    throw UnimplementedError(
        'This feature is not supported by Google Classroom. Please contact the developer.');
  }

  @override
  Future<List<SubmissionWithGrade>> getSubmissionsWithGrades(
      int assignmentId) async {
    print('Getting submissions with grades...');
    print('Assignment ID: $assignmentId');

    // TODO: implement google api code
    throw UnimplementedError(
        'This feature is not supported by Google Classroom. Please contact the developer.');
  }

  @override
  Future<SubmissionStatus?> getSubmissionStatus(
      int assignmentId, int userId) async {
    print('Getting submission status...');
    print('Assignment ID: $assignmentId');
    print('User ID: $userId');
    // TODO: implement google api code
    throw UnimplementedError(
        'This feature is not supported by Google Classroom. Please contact the developer.');
  }

  @override
  Future<List<Grade>> getAssignmentGrades(int assignmentId) async {
    print('Getting assignment grades...');
    print('Assignment ID: $assignmentId');
    // TODO: implement google api code
    throw UnimplementedError(
        'This feature is not supported by Google Classroom. Please contact the developer.');
  }

  @override
  Future<bool> setRubricGrades(
      int assignmentId, int userId, String jsonGrades) async {
    print('Setting rubric grades...');
    print('Assignment ID: $assignmentId');
    print('User ID: $userId');
    // TODO: implement google api code
    throw UnimplementedError(
        'This feature is not supported by Google Classroom. Please contact the developer.');
  }

  @override
  Future<List<dynamic>> getRubricGrades(int assignmentId, int userid) async {
    print('Getting rubric grades...');
    print('Assignment ID: $assignmentId');
    print('User ID: $userid');
    // TODO: implement google api code
    throw UnimplementedError(
        'This feature is not supported by Google Classroom. Please contact the developer.');
  }

  @override
  Grade? findGradeForUser(List<Grade> grades, int userId) {
    print('Finding grade for user...');
    print('User ID: $userId');

    // TODO: implement google api code
    throw UnimplementedError(
        'This feature is not supported by Google Classroom. Please contact the developer.');
  }

  // ****************************************************************************************
  // Rubric retrieval
  // ****************************************************************************************

  @override
  Future<MoodleRubric?> getRubric(String assignmentid) async {
    // TODO: implement google api code
    print('Getting rubric...');
    print('Assignment ID: $assignmentid');
    throw UnimplementedError(
        'This feature is not supported by Google Classroom. Please contact the developer.');
  }
  // ****************************************************************************************
  // Quiz creation and assignment with Answer Key
  //Short answer question 10 Points
  //Multiple choice question 10 Points
  //True/False question 5 Points

  // ****************************************************************************************

  Future<bool> createAndAssignQuizFromXml(
    String courseId,
    String quizName,
    String quizDescription,
    String quizAsXml,
    String dueDate,
  ) async {
    try {
      if (quizAsXml.isEmpty) {
        print('Error: quizAsXml is empty.');
        return false;
      }

      final document = xml.XmlDocument.parse(quizAsXml);
      final questions = document.findAllElements('question').toList();
      String? teacherFolderId;

      for (Course course in courses!) {
        if (course.id == int.parse(courseId)) {
          teacherFolderId = course.teacherFolderId;
        }
      }

      Map<String, dynamic>? formResponse =
          await _classroomApi.createForm(teacherFolderId, quizName);
      if (formResponse == null) {
        print('Error: Failed to create Google Form.');
        return false;
      }

      final String formId = formResponse['formId'];
      final String responderUri = formResponse['responderUri'];

      List<Map<String, dynamic>> requests = [];
      requests.add({
        'updateSettings': {
          'settings': {
            'emailCollectionType': 'DO_NOT_COLLECT',
            'quizSettings': {'isQuiz': true}
          },
          'updateMask': 'email_collection_type,quiz_settings',
        }
      });

      // Parse and add questions with answer keys and points
      for (var questionElement in questions) {
        String questionType = questionElement.getAttribute('type') ?? 'unknown';
        String questionText = questionElement
                .getElement('questiontext')
                ?.getElement('text')
                ?.text ??
            '';

        if (questionType == 'category') {
          print(
              'Warning: Unsupported question type: $questionType. Skipping question.');
          continue;
        }
        switch (questionType) {
          case 'multichoice':
            int points = 10; // Set multichoice to 10 points
            List<String> options = [];
            List<int> correctAnswerIndices = [];
            var answerElements =
                questionElement.findAllElements('answer').toList();
            for (int i = 0; i < answerElements.length; i++) {
              var answerElement = answerElements[i];
              String optionText = answerElement.getElement('text')?.text ?? '';
              options.add(optionText);
              if (answerElement.getAttribute('fraction') == '100') {
                correctAnswerIndices.add(i);
              }
            }
            requests.add(_createMultipleChoiceQuestionRequest(
                questionText, options, correctAnswerIndices, points));
            break;
          case 'truefalse':
            int points = 5; // Set truefalse to 5 points
            String correctAnswer = questionElement
                    .findAllElements('answer')
                    .firstWhere((e) => e.getAttribute('fraction') == '100')
                    .getElement('text')
                    ?.text ??
                'True';
            requests.add(_createTrueFalseQuestionRequest(
                questionText, correctAnswer, points));
            break;
          case 'shortanswer':
            int points = 10; // Set shortanswer to 10 point
            String correctAnswer = questionElement
                    .findAllElements('answer')
                    .first
                    .getElement('text')
                    ?.text ??
                '';
            requests.add(_createShortAnswerQuestionRequest(
                questionText, correctAnswer, points));
            break;
          default:
            print('Warning: Unsupported question type: $questionType');
        }
      }

      Map<String, dynamic>? batchResponse =
          await _classroomApi.batchUpdateForm(formId, requests);
      if (batchResponse == null) {
        print('Error: Failed to update Google Form.');
        return false;
      }

      String? assignmentId = await _classroomApi.createAssignment(
        courseId,
        quizName,
        quizDescription,
        responderUri,
        dueDate,
      );

      if (assignmentId == null) {
        print('Error: Failed to create Classroom assignment.');
        return false;
      }

      print(
          'Quiz created and assigned successfully! Assignment ID: $assignmentId');
      return true;
    } catch (e) {
      print('Error during quiz creation and assignment: $e');
      return false;
    }
  }

  Map<String, dynamic> _createMultipleChoiceQuestionRequest(String questionText,
      List<String> options, List<int> correctAnswerIndices, int points) {
    List<Map<String, dynamic>> choices = [];
    for (String option in options) {
      choices.add({'value': option});
    }

    return {
      'createItem': {
        'item': {
          'title': questionText,
          'questionItem': {
            'question': {
              'required': true,
              'choiceQuestion': {
                'type': 'RADIO',
                'options': choices,
              },
              'grading': {
                'pointValue': points,
                'correctAnswers': {
                  'answers': correctAnswerIndices
                      .map((index) => {'value': options[index]})
                      .toList(),
                },
              },
            },
          },
        },
        'location': {'index': 0},
      },
    };
  }

  Map<String, dynamic> _createTrueFalseQuestionRequest(
      String questionText, String correctAnswer, int points) {
    List<String> options = ["True", "False"];
    return {
      'createItem': {
        'item': {
          'title': questionText,
          'questionItem': {
            'question': {
              'required': true,
              'choiceQuestion': {
                'type': 'RADIO',
                'options': [
                  {'value': 'True'},
                  {'value': 'False'},
                ],
              },
              'grading': {
                'pointValue': points,
                'correctAnswers': {
                  'answers': [
                    {'value': correctAnswer},
                  ],
                },
              },
            },
          },
        },
        'location': {'index': 0},
      },
    };
  }

  Map<String, dynamic> _createShortAnswerQuestionRequest(
      String questionText, String correctAnswer, int points) {
    return {
      'createItem': {
        'item': {
          'title': questionText,
          'questionItem': {
            'question': {
              'required': true,
              'textQuestion': {},
              'grading': {
                'pointValue': points,
                'correctAnswers': {
                  'answers': [
                    {'value': correctAnswer},
                  ],
                },
              },
            },
          },
        },
        'location': {'index': 0},
      },
    };
  }

  @override
  Future<List<Participant>> getQuizGradesForParticipants(
      String courseId, int quizId) {
    // TODO: implement getQuizGradesForParticipants
    throw UnimplementedError();
  }
}
