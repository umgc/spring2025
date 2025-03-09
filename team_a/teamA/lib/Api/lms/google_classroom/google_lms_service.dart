import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
  String apiURL = 'https://classroom.googleapis.com/v1'; // Base URL for your Google Classroom
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
        'https://www.googleapis.com/auth/classroom.profile.photos',
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

      profileImage = googleUser.photoUrl;

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
      courses = decodedJson.map((i) => Course.empty().fromGoogleJson(i)).toList();
    } else if (decodedJson is Map<String, dynamic>) {
      final courseList = decodedJson['courses'] as List<dynamic>;
      courses = courseList.map((i) => Course.empty().fromGoogleJson(i)).toList();
    } else {
      throw StateError('Unexpected response format from Moodle');
    }

    // Optionally fetch quizzes/essays for each course
    for (Course course in courses) {
      // set topic ids
      final responseTopics = await ApiService().httpGet(
        Uri.parse('https://classroom.googleapis.com/v1/courses/${course.id}/topics/'),
        headers: {'Authorization': 'Bearer $_userToken'},
      );
      
      var decodedResponseTopics = jsonDecode(responseTopics.body);

      if (decodedResponseTopics.containsKey('topic')) {
        List<dynamic> topics = decodedResponseTopics["topic"];

        // Iterate and capture topicIds
        for (var topic in topics) {
          if (topic['name'] == 'Quiz') {
            course.quizTopicId = int.parse(topic['topicId']);
              print('Id for quiz');
            print(topic['topicId']);
          } else if (topic['name'] == 'Essay') {
            course.essayTopicId = int.parse(topic['topicId']);
             print('Id for essay');
            print(topic['topicId']);
          }
        }
      }
      
      course.quizzes = await getQuizzes(course.id, topicId: course.quizTopicId);
      course.essays = await getEssays(course.id, topicId: course.essayTopicId);
    }

    return courses;
  }

  @override
  Future<List<Participant>> getCourseParticipants(String courseId) async {
    // TODO: implement google api code
    throw UnimplementedError();
  }

  // ****************************************************************************************
  // Quiz methods
  // ****************************************************************************************

  @override
  Future<void> importQuiz(String courseid, String quizXml) async {
    // TODO: implement google api code
    throw UnimplementedError();
  }

  @override
  Future<List<Quiz>> getQuizzes(int? courseID, {int? topicId}) async {
    if (_userToken == null) throw StateError('User not logged in to Google Classroom');

    
    final response = await ApiService().httpGet(
      Uri.parse('https://classroom.googleapis.com/v1/courses/$courseID/courseWork'),
      headers: {'Authorization': 'Bearer $_userToken'},
    );

    // print('quizlist: ${response.body}');

    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }

    final quizzesMap = jsonDecode(response.body) as Map<String, dynamic>;
    final decodedJson = quizzesMap['courseWork'] as List<dynamic>?;

    if (decodedJson == null) {
      return [];
    }
    
    List<Quiz> quizList = [];
    for (var item in decodedJson) {
      // If courseID is null, return all quizzes; otherwise filter by course
      if (courseID == null || int.parse(item['courseId']) == courseID) {
        if (topicId != null && item.containsKey('topicId')) {
          
          if (int.parse(item['topicId']) == topicId) {
            quizList.add(Quiz.fromGoogleJson(item));
           }
        }
      }
    }

    return quizList;
  }

@override
  Future<int?> createQuiz(
      String courseid,
      String quizname,
      String quizintro,
      String sectionid,
      String timeopen,
      String timeclose) async {
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
    throw UnimplementedError();
  }

  @override
  Future<int?> importQuizQuestions(String courseid, String quizXml) async {
    print('Importing quiz questions...');
    print('Course ID: $courseid');
    print('Quiz XML: $quizXml');
    // TODO: implement google api code
    throw UnimplementedError();
  }

  @override
  Future<List<QuestionType>> getQuestionsFromQuiz(int quizId) async {
    // TODO: implement google api code
    throw UnimplementedError();
  }

  // ****************************************************************************************
  // Assignment methods
  // ****************************************************************************************

  @override
  Future<List<Assignment>> getEssays(int? courseID, {int? topicId}) async {
    if (_userToken == null) throw StateError('User not logged in to Google Classroom');

    
    final response = await ApiService().httpGet(
      Uri.parse('https://classroom.googleapis.com/v1/courses/$courseID/courseWork'),
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
    throw UnimplementedError();
  }

  // ****************************************************************************************
  // Submissions and grading
  // ****************************************************************************************

  @override
  Future<List<Submission>> getAssignmentSubmissions(int assignmentId) async {
    print('Getting assignment submissions...');
    print('Assignment ID: $assignmentId');
    // TODO: implement google api code
    throw UnimplementedError();
  }

  @override
  Future<List<SubmissionWithGrade>> getSubmissionsWithGrades(
      int assignmentId) async {
    print('Getting submissions with grades...');
    print('Assignment ID: $assignmentId');

    // TODO: implement google api code
    throw UnimplementedError();
  }

  @override
  Future<SubmissionStatus?> getSubmissionStatus(
      int assignmentId, int userId) async {
    print('Getting submission status...');
    print('Assignment ID: $assignmentId');
    print('User ID: $userId');
    // TODO: implement google api code
    throw UnimplementedError();
  }

  @override
  Future<List<Grade>> getAssignmentGrades(int assignmentId) async {
    print('Getting assignment grades...');
    print('Assignment ID: $assignmentId');
    // TODO: implement google api code
    throw UnimplementedError();
  }

  @override
  Future<bool> setRubricGrades(int assignmentId, int userId, String jsonGrades) async {
    print('Setting rubric grades...');
    print('Assignment ID: $assignmentId');
    print('User ID: $userId');
    // TODO: implement google api code
    throw UnimplementedError();
  }

  @override
  Future<List<dynamic>> getRubricGrades(int assignmentId, int userid) async {
    print('Getting rubric grades...');
    print('Assignment ID: $assignmentId');
    print('User ID: $userid');
    // TODO: implement google api code
    throw UnimplementedError();
  }

  @override
  Grade? findGradeForUser(List<Grade> grades, int userId) {
    print('Finding grade for user...');
    print('User ID: $userId');

    // TODO: implement google api code
    throw UnimplementedError();
  }

  // ****************************************************************************************
  // Rubric retrieval
  // ****************************************************************************************

  @override
  Future<MoodleRubric?> getRubric(String assignmentid) async {
    // TODO: implement google api code
    print('Getting rubric...');
    print('Assignment ID: $assignmentid');
    throw UnimplementedError();
  }

// -----------------------------------------------------------------------
// Parses XML quiz data and creates/assigns the quiz
// -----------------------------------------------------------------------
  Future<bool> createAndAssignQuizFromXml(
    String courseId,
    String quizName,
    String quizDescription,
    String quizAsXml, // The XML string
    String dueDate, // Format: YYYY-MM-DD-HH-MM
  ) async {
    try {
      // 0. Check if the quizAsXml is empty
      if (quizAsXml.isEmpty) {
        print('Error: quizAsXml is empty.');
        return false;
      }
      print('quizAsXml: $quizAsXml');
      // 1. Parse the XML
      final document = xml.XmlDocument.parse(quizAsXml);
      final questions = document.findAllElements('question').toList();

      // 2. Create the Google Form
      Map<String, dynamic>? formResponse =
          await _classroomApi.createForm(quizName);
      if (formResponse == null) {
        print('Error: Failed to create Google Form.');
        return false;
      }

      final String formId = formResponse['formId'];
      final String responderUri = formResponse['responderUri'];

      // 3. Prepare the batch request for settings updates and question addition
      List<Map<String, dynamic>> requests = [];

      // Add request to update the form settings
      requests.add({
        'updateSettings': {
          'settings': {
            'emailCollectionType': 'DO_NOT_COLLECT',
            'quizSettings': {'isQuiz': true}
          },
          'updateMask': 'email_collection_type,quiz_settings',
        }
      });

      // 4. Add requests for adding questions to the form
      for (var questionElement in questions) {
        String questionType = questionElement.getAttribute('type') ?? 'unknown';
        String questionText = questionElement
                .getElement('questiontext')
                ?.getElement('text')
                ?.text ??
            '';

        // skip category questions
        if (questionType == 'category') {
          print(
              'Warning: Unsupported question type: $questionType. Skipping question.');
          continue; // Skip to the next question
        }

        switch (questionType) {
          case 'multichoice':
            List<String> options = [];
            var answerElements =
                questionElement.findAllElements('answer').toList();
            for (var answerElement in answerElements) {
              options.add(answerElement.getElement('text')?.text ?? '');
            }
            requests.add(
                _createMultipleChoiceQuestionRequest(questionText, options));
            break;
          case 'truefalse':
            requests.add(_createTrueFalseQuestionRequest(questionText));
            break;
          case 'shortanswer':
            requests.add(_createShortAnswerQuestionRequest(questionText));
            break;
          default:
            print('Warning: Unsupported question type: $questionType');
        }
      }

      // 5. Send the batch update request
      Map<String, dynamic>? batchResponse =
          await _classroomApi.batchUpdateForm(formId, requests);
      if (batchResponse == null) {
        print('Error: Failed to update Google Form.');
        return false;
      }

      // 6. Create the Classroom assignment and link the form
      String? assignmentId = await _classroomApi.createAssignment(
        courseId,
        quizName,
        quizDescription,
        responderUri, // Pass the responderUri
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

  // Helper function to create a multiple choice question request
  Map<String, dynamic> _createMultipleChoiceQuestionRequest(
      String questionText, List<String> options) {
    List<Map<String, dynamic>> choices = [];
    for (String option in options) {
      choices.add({
        'value': option,
      });
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
              }
            }
          }
        },
        'location': {'index': 0}
      }
    };
  }

  // Helper function to create a true/false question request
  Map<String, dynamic> _createTrueFalseQuestionRequest(String questionText) {
    return _createMultipleChoiceQuestionRequest(
        questionText, ["True", "False"]);
  }

  // Helper function to create a short answer question request
  Map<String, dynamic> _createShortAnswerQuestionRequest(String questionText) {
    return {
      'createItem': {
        'item': {
          'title': questionText,
          'questionItem': {
            'question': {
              'required': true,
              'textQuestion': {},
            }
          }
        },
        'location': {'index': 0}
      }
    };
  }
}
