import 'dart:convert';
import 'dart:io';
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

/// A Singleton class for Moodle API access implementing [LmsInterface].
class MoodleLmsService implements LmsInterface {
  // ****************************************************************************************
  // Static / Singleton internals
  // ****************************************************************************************

  static final MoodleLmsService _instance = MoodleLmsService._internal();

  /// The singleton accessor.
  factory MoodleLmsService() => _instance;

  /// Private named constructor.
  MoodleLmsService._internal();

  // ****************************************************************************************
  // Fields implementing ApiSingletonInterface
  // ****************************************************************************************

  @override
  String serverUrl = '/webservice/rest/server.php'; // The Moodle REST endpoint

  // The user token is kept private (not in the interface).
  String? _userToken;

  @override
  String apiURL =
      ''; // Base URL for your Moodle instance, e.g. "https://yourmoodle.com"
  @override
  String? userName;
  @override
  String? firstName;
  @override
  String? lastName;
  @override
  String? siteName;
  @override
  String? fullName;
  @override
  String? profileImage;
  @override
  List<Course>? courses;

  // ****************************************************************************************
  // Auth / Login
  // ****************************************************************************************

  @override
  Future<void> login(String username, String password, String baseURL) async {
    print('Logging in to Moodle...');

    // 1) Obtain the token by calling Moodle's login/token.php
    final response = await ApiService().httpGet(Uri.parse(
        '$baseURL/login/token.php?username=$username&password=$password&service=moodle_mobile_app'));

    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data.containsKey('error')) {
      throw HttpException(data['error']);
    }

    // Store token locally
    _userToken = data['token'];
    apiURL = baseURL;

    // 2) Retrieve user info
    final userinforesponse =
        await ApiService().httpPost(Uri.parse(apiURL + serverUrl), body: {
      'wstoken': _userToken,
      'wsfunction': 'core_webservice_get_site_info',
      'moodlewsrestformat': 'json',
    });

    if (userinforesponse.statusCode != 200) {
      throw HttpException(userinforesponse.body);
    }

    // 3) Parse user info
    final userData = jsonDecode(userinforesponse.body) as Map<String, dynamic>;
    userName = userData['username'];
    firstName = userData['firstname'];
    lastName = userData['lastname'];
    siteName = userData['sitename'];
    fullName = userData['fullname'];
    profileImage = userData['userpictureurl'];

    // 4) Optionally load user courses right away
    courses = await getUserCourses();
  }

  @override
  bool isLoggedIn() {
    return _userToken != null;
  }

  @override
  Future<bool> isUserTeacher(List<Course> moodleCourses) async {
    // Check each course to see if the user has a teacher role
    for (var course in moodleCourses) {
      final rolesResponse =
          await ApiService().httpPost(Uri.parse(apiURL + serverUrl), body: {
        'wstoken': _userToken,
        'wsfunction': 'core_enrol_get_enrolled_users',
        'courseid': course.id.toString(),
        'moodlewsrestformat': 'json',
      });

      if (rolesResponse.statusCode != 200) {
        throw Exception('Failed to load roles for course ${course.id}');
      }

      // If the user has roleid == 3 or 4, they are teacher-like roles
      final users = jsonDecode(rolesResponse.body) as List<dynamic>;
      for (var user in users) {
        if (user['username'].toString() == userName) {
          for (var role in user['roles']) {
            if (role['roleid'] == 3 || role['roleid'] == 4) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  @override
  void logout() {
    print('Logging out of Moodle...');
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
    // Returns all courses on the Moodle site (requires admin or special permissions)
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    final response =
        await ApiService().httpPost(Uri.parse(apiURL + serverUrl), body: {
      'wstoken': _userToken,
      'wsfunction': 'core_course_get_courses',
      'moodlewsrestformat': 'json',
    });

    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }

    final listData = jsonDecode(response.body) as List<dynamic>;
    return listData.map((i) => Course.empty().fromMoodleJson(i)).toList();
  }

  @override
  Future<List<Course>> getUserCourses() async {
    // Returns courses the user is enrolled in
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    final response =
        await ApiService().httpPost(Uri.parse(apiURL + serverUrl), body: {
      'wstoken': _userToken,
      'wsfunction':
          'core_course_get_enrolled_courses_by_timeline_classification',
      'classification': 'inprogress',
      'moodlewsrestformat': 'json',
    });

    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }

    final decodedJson = jsonDecode(response.body);
    List<Course> userCourses;

    // The response can be either a List or a Map with a 'courses' key
    if (decodedJson is List) {
      userCourses =
          decodedJson.map((i) => Course.empty().fromMoodleJson(i)).toList();
    } else if (decodedJson is Map<String, dynamic>) {
      final courseList = decodedJson['courses'] as List<dynamic>;
      userCourses =
          courseList.map((i) => Course.empty().fromMoodleJson(i)).toList();
    } else {
      throw StateError('Unexpected response format from Moodle');
    }

    // Optionally fetch quizzes/essays for each course
    for (Course c in userCourses) {
      c.quizzes = await getQuizzes(c.id);
      c.essays = await getEssays(c.id);
    }
    return userCourses;
  }

  @override
  Future<List<Participant>> getCourseParticipants(String courseId) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    final response =
        await ApiService().httpPost(Uri.parse(apiURL + serverUrl), body: {
      'wstoken': _userToken,
      'wsfunction': 'core_enrol_get_enrolled_users',
      'courseid': courseId,
      'moodlewsrestformat': 'json',
    });

    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }

    final decodedJson = jsonDecode(response.body);
    if (decodedJson is List) {
      return decodedJson
          .map((i) => Participant.empty().fromMoodleJson(i))
          .toList();
    } else {
      throw StateError('Unexpected response format (expected a List)');
    }
  }

  // ****************************************************************************************
  // Quiz methods
  // ****************************************************************************************

  @override
  Future<void> importQuiz(String courseid, String quizXml) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    final response = await ApiService().httpPost(
      Uri.parse(apiURL + serverUrl),
      body: {
        'wstoken': _userToken,
        'wsfunction': 'local_quizgen_import_questions',
        'moodlewsrestformat': 'json',
        'courseid': courseid,
        'questionxml': quizXml,
      },
    );

    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }
    // Check if Moodle returned an 'error' inside the JSON string
    if (response.body.contains('error')) {
      throw HttpException(response.body);
    }
  }

  @override
  Future<List<Quiz>> getQuizzes(int? courseID, {int? topicId}) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    final response = await ApiService().httpPost(
      Uri.parse(apiURL + serverUrl),
      body: {
        'wstoken': _userToken,
        'wsfunction': 'mod_quiz_get_quizzes_by_courses',
        'moodlewsrestformat': 'json',
      },
    );

    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }

    final quizzesMap = jsonDecode(response.body) as Map<String, dynamic>;
    final decodedJson = quizzesMap['quizzes'] as List<dynamic>?;

    if (decodedJson == null) {
      return [];
    }

    List<Quiz> quizList = [];
    for (var item in decodedJson) {
      // If courseID is null, return all quizzes; otherwise filter by course
      if (courseID == null || item['course'] == courseID) {
        quizList.add(Quiz(
            name: item['name'],
            coursedId: item['course'],
            description: item['intro'],
            id: item['id'],
            timeOpen: item['timeopen'] =
                DateTime.fromMillisecondsSinceEpoch(item['timeopen'] * 1000),
            timeClose: item['timeclose'] =
                DateTime.fromMillisecondsSinceEpoch(item['timeclose'] * 1000)));
      }
    }
    return quizList;
  }

  @override
  Future<int?> createQuiz(String courseid, String quizname, String quizintro,
      String sectionid, String timeopen, String timeclose) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    try {
      final response = await ApiService().httpPost(
        Uri.parse(apiURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'local_learninglens_create_quiz',
          'moodlewsrestformat': 'json',
          'courseid': courseid,
          'name': quizname,
          'intro': quizintro,
          'sectionid': sectionid,
          'timeopen': timeopen,
          'timeclose': timeclose,
        },
      );

      if (response.statusCode != 200) {
        print('Failed to create quiz. Status code: ${response.statusCode}.');
        return null;
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Create Quiz Response: $responseData');

      return responseData['quizid'];
    } catch (e) {
      print('Error creating quiz: $e');
      return null;
    }
  }

  @override
  Future<String> addRandomQuestions(
      String categoryid, String quizid, String numquestions) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    final response = await ApiService().httpPost(
      Uri.parse(apiURL + serverUrl),
      body: {
        'wstoken': _userToken,
        'wsfunction': 'local_learninglens_add_type_randoms_to_quiz',
        'moodlewsrestformat': 'json',
        'categoryid': categoryid,
        'quizid': quizid,
        'numquestions': numquestions,
      },
    );

    if (response.statusCode != 200) {
      return 'Request failed with status: ${response.statusCode}.';
    }

    // The response may be a simple boolean string or a JSON object
    try {
      if (response.body == 'true' || response.body == 'false') {
        final boolString = (response.body == 'true').toString();
        print('Boolean Response: $boolString');
        return boolString;
      } else {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('Response: $responseData');
        return responseData['status'];
      }
    } catch (e) {
      print('Error parsing response in addRandomQuestions: $e');
      return e.toString();
    }
  }

  @override
  Future<int?> importQuizQuestions(String courseid, String quizXml) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    try {
      final response = await ApiService().httpPost(
        Uri.parse(apiURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'local_learninglens_import_questions',
          'moodlewsrestformat': 'json',
          'courseid': courseid,
          'questionxml': quizXml,
        },
      );

      if (response.statusCode != 200) {
        print('Request failed with status: ${response.statusCode}.');
        return null;
      }

      // Some Moodle plugins return extra text before JSON; parse from first '{'
      final int indexOfBrace = response.body.indexOf('{');
      if (indexOfBrace == -1) {
        print('No JSON object found in response for importQuizQuestions.');
        return null;
      }
      final jsonPart = response.body.substring(indexOfBrace);
      final responseData = jsonDecode(jsonPart) as Map<String, dynamic>;
      print('Import Questions Response: $responseData');

      return responseData['categoryid'] as int?;
    } catch (e) {
      print('Error importing quiz questions: $e');
      return null;
    }
  }

  // ****************************************************************************************
  // Assignment methods
  // ****************************************************************************************

  @override
  Future<List<Assignment>> getEssays(int? courseID, {int? topicId}) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    final response = await ApiService().httpPost(
      Uri.parse(apiURL + serverUrl),
      body: {
        'wstoken': _userToken,
        'wsfunction': 'mod_assign_get_assignments',
        'moodlewsrestformat': 'json',
      },
    );

    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }

    final mapJson = jsonDecode(response.body) as Map<String, dynamic>;
    final coursesList = mapJson['courses'] as List<dynamic>?;

    if (coursesList == null) {
      return [];
    }

    final results = <Assignment>[];
    for (var cItem in coursesList) {
      // If courseID is null, get for all courses; if not, filter
      if (courseID == null || cItem['id'] == courseID) {
        final assignmentList = cItem['assignments'] as List<dynamic>;
        for (var a in assignmentList) {
          results.add(Assignment.empty().fromMoodleJson(a));
        }
      }
    }
    return results;
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
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    try {
      final response = await ApiService().httpPost(
        Uri.parse(apiURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'local_learninglens_create_assignment',
          'moodlewsrestformat': 'json',
          'courseid': courseid,
          'sectionid': sectionid,
          'assignmentName': assignmentName,
          'startdate': startdate,
          'enddate': enddate,
          'rubricJson': rubricJson,
          'description': description,
        },
      );

      if (response.statusCode != 200) {
        print('Request failed with status: ${response.statusCode}.');
        return null;
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Create Assignment Response: $responseData');

      return responseData;
    } catch (e) {
      print('Error occurred while creating assignment: $e');
      return null;
    }
  }

  @override
  Future<int?> getContextId(int assignmentId, String courseId) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    try {
      final response = await ApiService().httpPost(
        Uri.parse(apiURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'core_course_get_contents',
          'moodlewsrestformat': 'json',
          'courseid': courseId,
        },
      );

      if (response.statusCode != 200) {
        print(
            'Failed to fetch course contents. Status code: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      for (var section in data) {
        final modules = section['modules'] as List<dynamic>;
        for (var module in modules) {
          // Look for an assignment module with matching instance
          if (module['instance'] == assignmentId &&
              module['modname'] == 'assign') {
            final contextId = module['contextid'];
            print('Context ID for assignment $assignmentId is $contextId');
            return contextId as int?;
          }
        }
      }
      return null;
    } catch (e, st) {
      print('Error fetching context ID: $e');
      print('StackTrace: $st');
      return null;
    }
  }

  // ****************************************************************************************
  // Submissions and grading
  // ****************************************************************************************

  @override
  Future<List<Submission>> getAssignmentSubmissions(int assignmentId) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    try {
      final response = await ApiService().httpPost(
        Uri.parse(apiURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'mod_assign_get_submissions',
          'moodlewsrestformat': 'json',
          'assignmentids[0]': assignmentId.toString(),
          'status': 'submitted',
        },
      );

      if (response.statusCode != 200) {
        print(
            'Failed to load submissions. Status code: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('exception')) {
        throw Exception('Moodle API Error: ${data['message']}');
      }

      // Debugging
      print('Full Response Data (Submissions): ${jsonEncode(data)}');

      final assignmentsArr = data['assignments'] as List<dynamic>? ?? [];
      final submissionsData = <Map<String, dynamic>>[];

      // Extract each "submission" plus the assignmentId
      for (var assign in assignmentsArr) {
        final subs = assign['submissions'] as List<dynamic>? ?? [];
        for (var sub in subs) {
          submissionsData.add({
            'assignmentid': assign['assignmentid'],
            'submission': sub,
          });
        }
      }

      if (submissionsData.isEmpty) {
        print('No submissions found for assignment $assignmentId');
        return [];
      }

      return submissionsData
          .map((jsonMap) => Submission.empty().fromMoodleJson(jsonMap))
          .toList();
    } catch (e, st) {
      print('Error fetching submissions: $e');
      print('StackTrace: $st');
      return [];
    }
  }

  @override
  Future<List<SubmissionWithGrade>> getSubmissionsWithGrades(
      int assignmentId) async {
    // Combine submissions with their associated grade
    final submissions = await getAssignmentSubmissions(assignmentId);
    final grades = await getAssignmentGrades(assignmentId);

    final results = <SubmissionWithGrade>[];
    for (final submission in submissions) {
      final match = findGradeForUser(grades, submission.userid);
      results.add(SubmissionWithGrade(submission: submission, grade: match));
    }
    return results;
  }

  @override
  Future<SubmissionStatus?> getSubmissionStatus(
      int assignmentId, int userId) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    try {
      final response = await ApiService().httpPost(
        Uri.parse(apiURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'mod_assign_get_submission_status',
          'moodlewsrestformat': 'json',
          'assignid': assignmentId.toString(),
          'userid': userId.toString(),
        },
      );

      if (response.statusCode != 200) {
        print(
            'Failed to load submission status. Status code: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('exception')) {
        throw Exception('Moodle API Error: ${data['message']}');
      }

      return SubmissionStatus.empty().fromMoodleJson(data);
    } catch (e, st) {
      print('Error fetching submission status: $e');
      print('StackTrace: $st');
      return null;
    }
  }

  @override
  Future<List<Grade>> getAssignmentGrades(int assignmentId) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    try {
      final response = await ApiService().httpPost(
        Uri.parse(apiURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'mod_assign_get_grades',
          'moodlewsrestformat': 'json',
          'assignmentids[0]': assignmentId.toString(),
        },
      );

      if (response.statusCode != 200) {
        print(
            'Failed to load assignment grades. Status code: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('exception')) {
        throw Exception('Moodle API Error: ${data['message']}');
      }

      print('Grades Response Data: ${jsonEncode(data)}');

      final grades = <Grade>[];
      final assignmentsList = data['assignments'] as List<dynamic>? ?? [];
      for (var assignment in assignmentsList) {
        final gList = assignment['grades'] as List<dynamic>? ?? [];
        for (var g in gList) {
          grades.add(Grade.empty().fromMoodleJson(g));
        }
      }
      return grades;
    } catch (e, st) {
      print('Error fetching assignment grades: $e');
      print('StackTrace: $st');
      return [];
    }
  }

  @override
  Future<bool> setRubricGrades(
      int assignmentId, int userId, String jsonGrades) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    try {
      final response = await ApiService().httpPost(
        Uri.parse(apiURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'local_learninglens_write_rubric_grades',
          'moodlewsrestformat': 'json',
          'assignmentid': assignmentId.toString(),
          'userid': userId.toString(),
          'rubricgrades': jsonGrades,
        },
      );

      if (response.statusCode != 200) {
        print(
            'Failed to set rubric grades. Status code: ${response.statusCode}');
        return false;
      }
      return true;
    } catch (e, st) {
      print('Error setting rubric grades: $e');
      print('StackTrace: $st');
      return false;
    }
  }

  @override
  Future<List<dynamic>> getRubricGrades(int assignmentId, int userid) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');
    try {
      final response = await ApiService().httpPost(
        Uri.parse(apiURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'local_learninglens_get_rubric_grades',
          'moodlewsrestformat': 'json',
          'assignmentid': assignmentId.toString(),
          'userid': userid.toString(),
        },
      );

      if (response.statusCode != 200) {
        print('Failed to load rubric grades. Status: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      if (data.isEmpty || data.first is! Map<String, dynamic>) {
        return [];
      }
      print('Rubric Grades Response: ${jsonEncode(data)}');
      return data;
    } catch (e, st) {
      print('Error fetching rubric grades: $e');
      print('StackTrace: $st');
      return [];
    }
  }

  @override
  Grade? findGradeForUser(List<Grade> grades, int userId) {
    for (final grade in grades) {
      if (grade.userid == userId) {
        return grade;
      }
    }
    return null;
  }

  // ****************************************************************************************
  // Rubric retrieval
  // ****************************************************************************************

  @override
  Future<MoodleRubric?> getRubric(String assignmentid) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    final response = await ApiService().httpPost(
      Uri.parse(apiURL + serverUrl),
      body: {
        'wstoken': _userToken,
        'wsfunction': 'local_learninglens_get_rubric',
        'moodlewsrestformat': 'json',
        'assignmentid': assignmentid,
      },
    );

    if (response.statusCode != 200) {
      print('Request failed with status: ${response.statusCode}.');
      return null;
    }

    final List<dynamic> responseData = jsonDecode(response.body);
    if (responseData.isEmpty || responseData.first is! Map<String, dynamic>) {
      return null;
    }

    print('Rubric JSON Response: $responseData');
    return MoodleRubric.empty().fromMoodleJson(responseData.first);
  }

  // ********************************************************************************************************************
  // Submit lesson plan instance in a course.
  // ********************************************************************************************************************
  Future<bool> sendLessonPlanData(Map<String, dynamic> lessonPlanData) async {
  try {
    print(lessonPlanData);
    print(lessonPlanData['courseid']);
    print(lessonPlanData['lessonPlanName']);
    print(lessonPlanData['content']);
    final response = await ApiService().httpPost(
      Uri.parse(apiURL + serverUrl),
      body: {
        'wstoken': _userToken,
        'wsfunction': 'local_learninglens_create_lesson_plan',
        'moodlewsrestformat': 'json',
        'courseid': lessonPlanData['courseId'],  // Pass courseId directly
        'lessonPlanName': lessonPlanData['lessonPlanName'],  // Pass lessonPlanName directly
        'content': lessonPlanData['content'],  // Pass content directly
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      print('Response: $responseData');

      // If the lesson plan submission was successful, create the Moodle Lesson
      if (responseData.containsKey('lessonPlanId')) {
        return await createLesson(
          courseId: lessonPlanData['courseid'],
          name: lessonPlanData['lessonPlanName'],
        );
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  } catch (e) {
    print('Error occurred while submitting lesson plan: $e');
  }
  return false;
}


  // Method to create the lesson in Moodle
  Future<bool> createLesson({
    required int courseId,
    required String name,
    String intro = "This is an automatically created lesson.",
    int available = 1,
    int deadline = 0,
    int timelimit = 0,
    int retake = 1,
    int maxAttempts = 3,
  }) async {
    final response = await ApiService().httpPost(
      Uri.parse(apiURL + serverUrl),
      body: {
        "wstoken": _userToken,
        "wsfunction": "mod_lesson_add_lesson",
        "moodlewsrestformat": "json",
        "courseid": courseId.toString(),
        "name": name,
        "intro": intro,
        "introformat": "1",
        "available": available.toString(),
        "deadline": deadline.toString(),
        "timelimit": timelimit.toString(),
        "retake": retake.toString(),
        "maxattempts": maxAttempts.toString(),
      },
    );

    final Map<String, dynamic> jsonResponse = json.decode(response.body);

    if (jsonResponse.containsKey("exception")) {
      print("Error creating lesson: ${jsonResponse['message']}");
      return false;
    }

    print("Lesson created successfully: ${jsonResponse}");
    return true;
  }

}

