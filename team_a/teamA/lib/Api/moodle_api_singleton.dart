import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:learninglens_app/Controller/beans.dart';
import 'package:learninglens_app/services/api_service.dart';

// Singleton class for Moodle API access.
class MoodleApiSingleton {
  // Constants for Moodle API.
  static const serverUrl = '/webservice/rest/server.php';
  static const jsonFormat = '&moodlewsrestformat=json';
  static const errorKey = 'error';

  // The singleton instance.
  static final MoodleApiSingleton _instance = MoodleApiSingleton._internal();

  // User token is stored here.
  String? _userToken;
  // User info
  String moodleURL = '';
  String? moodleUserName;
  String? moodleFirstName;
  String? moodleLastName;
  String? moodleSiteName;
  String? moodleFullName;
  String? moodleProfileImage;
  List<Course>? moodleCourses;

  // Singleton accessor.
  factory MoodleApiSingleton() {
    return _instance;
  }

  // Internal constructor.
  MoodleApiSingleton._internal();

  // Check if user has logged in (if singleton has a token).
  bool isLoggedIn() {
    return _userToken != null;
  }

  // Log in to Moodle and retrieve the user token. Throws HttpException if login failed.
  Future<void> login(String username, String password, String baseURL) async {
    print('Logging in to Moodle...');
    final response = await ApiService().httpGet(Uri.parse(
        '$baseURL/login/token.php?username=$username&password=$password&service=moodle_mobile_app'));
    Map<String, dynamic> data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw HttpException(response.body);
    } else if (data.containsKey(errorKey)) {
      throw HttpException(data[errorKey]);
    }
    _userToken = data['token'];
    moodleURL = baseURL;

    //get user info
    final userinforesponse =
        await ApiService().httpPost(Uri.parse(baseURL + serverUrl), body: {
      'wstoken': _userToken,
      'wsfunction': 'core_webservice_get_site_info',
      'moodlewsrestformat': 'json',
    });
    if (userinforesponse.statusCode != 200) {
      throw HttpException(userinforesponse.body);
    }
    moodleCourses = await getUserCourses();
    Map<String, dynamic> userData = jsonDecode(userinforesponse.body);
    moodleUserName = userData['username'];
    moodleFirstName = userData['firstname'];
    moodleLastName = userData['lastname'];
    moodleSiteName = userData['sitename'];
    moodleFullName = userData['fullname'];
    moodleProfileImage = userData['userpictureurl'];
  }

  Future<bool> isUserTeacher(List<Course> moodleCourses) async {
    // Step 1: Iterate over each course in moodleCourses
    for (var course in moodleCourses) {
      final courseId = course.id;

      // Step 2: Check the user's roles in each course
      // final getRolesUrl = Uri.parse('$moodleURL/?wsfunction=core_role_get_roles_in_context&moodlewsrestformat=json');
      final rolesResponse =
          await ApiService().httpPost(Uri.parse(moodleURL + serverUrl), body: {
        'wstoken': _userToken,
        'wsfunction': 'core_enrol_get_enrolled_users',
        'courseid': courseId.toString(),
        'moodlewsrestformat': 'json',
      });

      if (rolesResponse.statusCode == 200) {
        List<dynamic> users = json.decode(rolesResponse.body);

        // Check if the specified user is in the list and has teacher roles
        for (var user in users) {
          if (user['username'].toString() == moodleUserName) {
            for (var role in user['roles']) {
              if (role['roleid'] == 3 || role['roleid'] == 4) {
                return true; // User is a teacher in this course
              }
            }
          }
        }
      } else {
        throw Exception('Failed to load roles for course $courseId');
      }
    }

    return false; // User is not a teacher in any course
  }

  // Log out of Moodle by deleting the stored user token.
  void logout() {
    print('Logging out of Moodle...');
    resetMoodle();
  }

  void resetMoodle() {
    _userToken = null;
    moodleURL = '';
    moodleUserName = '';
    moodleFirstName = null;
    moodleLastName = null;
    moodleSiteName = null;
    moodleFullName = null;
    moodleProfileImage = null;
    moodleCourses = [];
  }

  // Get list of courses.
  Future<List<Course>> getCourses() async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    final response =
        await ApiService().httpPost(Uri.parse(moodleURL + serverUrl), body: {
      'wstoken': _userToken,
      'wsfunction': 'core_course_get_courses',
      'moodlewsrestformat': 'json',
    });

    // '$moodleURL$serverUrl&wstoken=$_userToken$jsonFormat&wsfunction=core_course_get_courses'
    // ));
    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }
    List<Course> courses = (jsonDecode(response.body) as List)
        .map((i) => Course.fromJson(i))
        .toList();
    return courses;
  }

  // Import XML quiz into the specified course. Returns a list of IDs for newly imported questions.
  Future<void> importQuiz(String courseid, String quizXml) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    final http.Response response = await ApiService().httpPost(Uri.parse(
        '$serverUrl$_userToken$jsonFormat&wsfunction=local_quizgen_import_questions&courseid=$courseid&questionxml=$quizXml'));
    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }
    if (response.body.contains('error')) {
      throw HttpException(response.body);
    }
  }

  Future<List<Quiz>> getQuizzes(int? courseID) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    // URL of the Moodle server
    final response =
        await ApiService().httpPost(Uri.parse(moodleURL + serverUrl), body: {
      'wstoken': _userToken,
      'wsfunction': 'mod_quiz_get_quizzes_by_courses',
      'moodlewsrestformat': 'json',
    });

    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }

    List<dynamic>? decodedJson =
        (jsonDecode(response.body) as Map<String, dynamic>)['quizzes'];
    if (decodedJson == null) {
      return [];
    }

    List<Quiz> results = [];
    for (int i = 0; i < decodedJson.length; i++) {
      if (courseID == null || decodedJson[i]['course'] == courseID) {
        results.insert(
            results.length,
            Quiz(
                name: decodedJson[i]['name'],
                coursedId: decodedJson[i]['course'],
                description: decodedJson[i]['intro'],
                id: decodedJson[i]['id']));
      }
    }
    return results;
  }

  Future<List<Assignment>> getEssays(int? courseID) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    // URL of the Moodle server
    final response =
        await ApiService().httpPost(Uri.parse(moodleURL + serverUrl), body: {
      'wstoken': _userToken,
      'wsfunction': 'mod_assign_get_assignments',
      'moodlewsrestformat': 'json',
    });

    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }

    List<dynamic>? decodedJson =
        (jsonDecode(response.body) as Map<String, dynamic>)['courses'];
    if (decodedJson == null) {
      return [];
    }

    List<Assignment> results = [];
    for (int i = 0; i < decodedJson.length; i++) {
      if (courseID == null || decodedJson[i]['id'] == courseID) {
        for (Map<String, dynamic> a in decodedJson[i]['assignments']) {
          results.insert(results.length, Assignment.fromJson(a));
        }
      }
    }
    return results;
  }

  // ********************************************************************************************************************
  // Get participants in a course
  // ********************************************************************************************************************

  Future<List<Participant>> getCourseParticipants(String courseId) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');

    // URL of the Moodle server
    final response =
        await ApiService().httpPost(Uri.parse(moodleURL + serverUrl), body: {
      'wstoken': _userToken,
      'wsfunction': 'core_enrol_get_enrolled_users',
      'courseid': courseId,
      'moodlewsrestformat': 'json',
    });

    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }

    var decodedJson = jsonDecode(response.body);

    // Assuming the response is directly a list of participants
    List<Participant> participants;
    if (decodedJson is List) {
      participants = decodedJson.map((i) => Participant.fromJson(i)).toList();
    } else {
      throw StateError('Unexpected response format');
    }
    return participants;
  }

  // ********************************************************************************************************************
  // Get list of courses the user is enrolled in.
  // ********************************************************************************************************************

  Future<List<Course>> getUserCourses() async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');
    // var moodleURL = MoodleApiSingleton().moodleURL;
    final response =
        await ApiService().httpPost(Uri.parse(moodleURL + serverUrl), body: {
      'wstoken': _userToken,
      'wsfunction':
          'core_course_get_enrolled_courses_by_timeline_classification',
      'classification': 'inprogress',
      'moodlewsrestformat': 'json',
    });
    if (response.statusCode != 200) {
      throw HttpException(response.body);
    }

    var decodedJson = jsonDecode(response.body);
    // Check if the response is a list or a map containing a list
    List<Course> courses;
    if (decodedJson is List) {
      // If the response is directly a list
      courses = decodedJson.map((i) => Course.fromJson(i)).toList();
    } else if (decodedJson is Map<String, dynamic>) {
      // If the response is a map containing a list of courses
      var courseList = decodedJson['courses'] as List<dynamic>;
      courses = courseList.map((i) => Course.fromJson(i)).toList();
    } else {
      throw StateError('Unexpected response format');
    }
    //obtain the contents of each course
    for (Course course in courses) {
      course.quizzes = await getQuizzes(course.id);
      course.essays = await getEssays(course.id);
    }
    return courses;
  }

  Future<SubmissionStatus?> getSubmissionStatus(
      int assignmentId, int userId) async {
    try {
      final response = await ApiService().httpPost(
        Uri.parse(moodleURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'mod_assign_get_submission_status',
          'moodlewsrestformat': 'json',
          'assignid': assignmentId.toString(),
          'userid': userId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('exception')) {
          throw Exception('Moodle API Error: ${data['message']}');
        }

        // Parse the response and return a SubmissionStatus object
        return SubmissionStatus.fromJson(data);
      } else {
        print(
            'Failed to load submission status. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error fetching submission status: $e');
      print('StackTrace: $stackTrace');
      return null;
    }
  }

  // ********************************************************************************************************************
  // Get rubric grades for an assignment.
  // ********************************************************************************************************************

  Future<List<dynamic>> getRubricGrades(int assignmentId, int userid) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');
    try {
      final response = await ApiService().httpPost(
        Uri.parse(moodleURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'local_learninglens_get_rubric_grades',
          'moodlewsrestformat': 'json',
          'assignmentid': assignmentId.toString(),
          'userid': userid.toString(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Debug: Print the entire grades JSON response
        print('Grades Response Data: ${json.encode(data)}');

        final List<dynamic> responseData = json.decode(response.body);
        if (responseData.isNotEmpty &&
            responseData.first is Map<String, dynamic>) {
          // Map<String, dynamic> rubricData = responseData.first;
          print('Response: $responseData');
          return responseData;
        } else {
          print('Failed to load grades. Status code: ${response.statusCode}');
          return [];
        }
      } else {
        print('Failed to load grades. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('Error fetching grades: $e');
      print('StackTrace: $stackTrace');
      return [];
    }
  }

  // ********************************************************************************************************************
  // Set rubric grades for an assignment.
  // ********************************************************************************************************************

  Future<bool> setRubricGrades(
      int assignmentId, int userId, String jsonGrades) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');
    try {
      final response = await ApiService().httpPost(
        Uri.parse(moodleURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'local_learninglens_write_rubric_grades',
          'moodlewsrestformat': 'json',
          'assignmentid': assignmentId.toString(),
          'userid': userId.toString(),
          'rubricgrades': jsonGrades,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to load grades. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      print('Error fetching grades: $e');
      print('StackTrace: $stackTrace');
      return false;
    }
  }

  // ********************************************************************************************************************
  // Get grades for an assignment.
  // ********************************************************************************************************************

  Future<List<Grade>> getAssignmentGrades(int assignmentId) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');
    try {
      final response = await ApiService().httpPost(
        Uri.parse(moodleURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'mod_assign_get_grades',
          'moodlewsrestformat': 'json',
          'assignmentids[0]': assignmentId.toString(), // The assignment ID
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('exception')) {
          throw Exception('Moodle API Error: ${data['message']}');
        }

        // Debug: Print the entire grades JSON response
        print('Grades Response Data: ${json.encode(data)}');

        // Initialize an empty list for grades
        List<Grade> grades = [];

        // Access the 'grades' list within the assignments
        if (data['assignments'] != null && data['assignments'] is List) {
          List assignments = data['assignments'];
          for (var assignment in assignments) {
            if (assignment['grades'] != null && assignment['grades'] is List) {
              for (var gradeData in assignment['grades']) {
                // Parse each grade and add it to the list
                grades.add(Grade.fromJson(gradeData));
              }
            }
          }
        }

        return grades;
      } else {
        print('Failed to load grades. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('Error fetching grades: $e');
      print('StackTrace: $stackTrace');
      return [];
    }
  }

  // ********************************************************************************************************************
  // Get submissions for an assignment.
  // ********************************************************************************************************************

  Future<List<Submission>> getAssignmentSubmissions(int assignmentId) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');
    try {
      final response = await ApiService().httpPost(
        Uri.parse(moodleURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'mod_assign_get_submissions',
          'moodlewsrestformat': 'json',
          'assignmentids[0]': assignmentId.toString(),
          'status': 'submitted',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('exception')) {
          throw Exception('Moodle API Error: ${data['message']}');
        }

        // **Debugging: Print the entire JSON response**
        print('Full Response Data: ${json.encode(data)}');

        // **Initialize an empty list for submissions**
        List<dynamic> submissionsData = [];

        // **Access the 'assignments' list**
        if (data['assignments'] != null && data['assignments'] is List) {
          List assignments = data['assignments'];
          for (var assignment in assignments) {
            if (assignment['submissions'] != null &&
                assignment['submissions'] is List) {
              for (var submission in assignment['submissions']) {
                // Create a map that includes the assignmentid along with the submission data
                submissionsData.add({
                  'assignmentid':
                      assignment['assignmentid'], // Store assignmentid
                  'submission': submission // Store the actual submission
                });
              }
            }
          }
        }

        // **Debugging: Print the number of submissions found**
        print('Number of submissions found: ${submissionsData.length}');

        if (submissionsData.isEmpty) {
          print('No submissions found.');
          return []; // Return empty list if no submissions are found
        }

        // **Map the submissions to Submission objects**
        List<Submission> submissions = submissionsData
            .map((submissionJson) => Submission.fromJson(submissionJson))
            .toList();

        return submissions;
      } else {
        // Log the unexpected status code
        print(
            'Failed to load submissions. Status code: ${response.statusCode}');
        return []; // Return empty list on non-200 status codes
      }
    } catch (e, stackTrace) {
      // Log the error details
      print('Error fetching submissions: $e');
      print('StackTrace: $stackTrace');
      return []; // Return empty list in case of any exceptions
    }
  }

  // helper function to find grade for a user
  Grade? findGradeForUser(List<Grade> grades, int userId) {
    for (Grade grade in grades) {
      if (grade.userid == userId) {
        return grade;
      }
    }
    return null; // Return null if no grade is found for this user
  }

  // ********************************************************************************************************************
  // Get submissions with grades for an assignment.
  // ********************************************************************************************************************

  Future<List<SubmissionWithGrade>> getSubmissionsWithGrades(
      int assignmentId) async {
    List<Submission> submissions = await getAssignmentSubmissions(assignmentId);
    List<Grade> grades = await getAssignmentGrades(assignmentId);

    // Combine submissions and grades
    List<SubmissionWithGrade> submissionsWithGrades = [];

    for (Submission submission in submissions) {
      Grade? grade = findGradeForUser(grades, submission.userid);

      submissionsWithGrades.add(SubmissionWithGrade(
        submission: submission,
        grade: grade, // May be null if no grade found
      ));
    }

    return submissionsWithGrades;
  }

  // ********************************************************************************************************************
  // Get rubric for an assignment.
  // ********************************************************************************************************************

  Future<MoodleRubric?> getRubric(String assignmentid) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');
    final response = await ApiService().httpPost(
      Uri.parse(moodleURL + serverUrl),
      body: {
        'wstoken': _userToken,
        'wsfunction': 'local_learninglens_get_rubric',
        'moodlewsrestformat': 'json',
        'assignmentid': assignmentid,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      if (responseData.isNotEmpty &&
          responseData.first is Map<String, dynamic>) {
        Map<String, dynamic> rubricData = responseData.first;
        print('Response: $responseData');
        return MoodleRubric.fromJson(rubricData);
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return null;
    }
    return null;
  }

  // ********************************************************************************************************************
  // Add random questions to the specified quiz using learninglens plugin.
  // ********************************************************************************************************************

  Future<String> addRandomQuestions(
      String categoryid, String quizid, String numquestions) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');
    final response = await ApiService().httpPost(
      Uri.parse(moodleURL + serverUrl),
      body: {
        'wstoken': _userToken,
        'wsfunction': 'local_learninglens_add_type_randoms_to_quiz',
        'moodlewsrestformat': 'json',
        'categoryid': categoryid,
        'quizid': quizid,
        'numquestions': numquestions,
      },
    );
    if (response.statusCode == 200) {
      try {
        if (response.body == 'true' || response.body == 'false') {
          final String responseData = (response.body == 'true').toString();
          print('Boolean Response: $responseData');
          return responseData;
        } else {
          // If it's not a boolean, assume it's JSON
          final Map<String, dynamic> responseData = json.decode(response.body);
          print('Response: $responseData');
          return responseData['status'];
        }
      } catch (e) {
        print('Error parsing response: $e');
        return e.toString();
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return 'Request failed with status: ${response.statusCode}.';
    }
  }

  // ********************************************************************************************************************
  // Import XML quiz questions into the specified course using learninglens plugin.
  // ********************************************************************************************************************

  Future<int?> importQuizQuestions(String courseid, String quizXml) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');
    try {
      final response = await ApiService().httpPost(
        Uri.parse(moodleURL + serverUrl),
        body: {
          'wstoken': _userToken,
          'wsfunction': 'local_learninglens_import_questions',
          'moodlewsrestformat': 'json',
          'courseid': courseid,
          'questionxml': quizXml,
        },
      );
      if (response.statusCode == 200) {
        String jsonPart = response.body.substring(response.body.indexOf('{'));
        final Map<String, dynamic> responseData = json.decode(jsonPart);
        print('Response: $responseData');
        return responseData['categoryid'];
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ********************************************************************************************************************
  // Create a new quiz in the specified course using learninglens plugin.
  // ********************************************************************************************************************

  Future<int?> createQuiz(String courseid, String quizname, String quizintro,
      String sectionid, String timeopen, String timeclose) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');
    // const String url = 'webservice/rest/server.php';
    try {
      final response = await ApiService().httpPost(
        Uri.parse(moodleURL + serverUrl),
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('Response: $responseData');
        return responseData['quizid'];
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return null;
      }
    } catch (e) {
      print('Error occurred: $e');
      return null;
    }
  }

  // ********************************************************************************************************************
  // Create a new assignment with optional rubric JSON in the specified course using learninglens plugin.
  // ********************************************************************************************************************

  Future<Map<String, dynamic>?> createAssignment(
      String courseid,
      String sectionid,
      String assignmentName,
      String startdate,
      String enddate,
      String rubricJson,
      String description) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');
    try {
      final response = await ApiService().httpPost(
        Uri.parse(moodleURL + serverUrl),
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('Response: $responseData');
        return responseData;
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return null;
      }
    } catch (e) {
      print('Error occurred');
      return null;
    }
  }

  // ********************************************************************************************************************
  // Gets context ID for an assignment instance in a course.
  // ********************************************************************************************************************

  Future<int?> getContextId(int assignmentId, String courseId) async {
    if (_userToken == null) throw StateError('User not logged in to Moodle');
    try {
      final response =
          await ApiService().httpPost(Uri.parse(moodleURL + serverUrl), body: {
        'wstoken': _userToken,
        'wsfunction': 'core_course_get_contents',
        'moodlewsrestformat': 'json',
        'courseid': courseId, // Replace with actual course ID
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        for (var section in data) {
          for (var module in section['modules']) {
            if (module['instance'] == assignmentId &&
                module['modname'] == 'assign') {
              // Get the contextid of the assignment instance 13
              int contextId = module['contextid'];
              print('Context ID for assignment instance 13: $contextId');
              return contextId; // Exit once found
            }
          }
        }
        return null; // Context ID not found
      } else {
        print(
            'Failed to fetch course contents. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error fetching context ID: $e');
      print('StackTrace: $stackTrace');
      return null;
    }
  }
}
