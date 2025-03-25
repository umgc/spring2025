import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/lesson_plan.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/quiz_type.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/submission_status.dart';
import 'package:learninglens_app/beans/grade.dart';
import 'package:learninglens_app/beans/submission.dart';
import 'package:learninglens_app/beans/submission_with_grade.dart';
import 'package:learninglens_app/beans/moodle_rubric.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';


class ApiSingleton implements LmsInterface {
  static final ApiSingleton _instance = ApiSingleton._internal();

  ApiSingleton._internal();

  factory ApiSingleton() {
    return _instance;
  }

  String? _userToken = '';

  @override
  String serverUrl = '';
  
  @override
  String apiURL = '';

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
  

  // Authentication/Login methods
  @override
  Future<void> login(String username, String password, String baseURL) {
    // TODO: implement login
    throw UnimplementedError();
  }

  @override
  bool isLoggedIn() {
    return _userToken != null;
  }
  
  @override
  Future<bool> isUserTeacher(List<Course> moodleCourses) {
    // TODO: implement isUserTeacher
    throw UnimplementedError();
  }
  
  @override
  void logout() {
    print('Logging out of LMS...');
    resetLMSUserInfo();
  }
  
  @override
  void resetLMSUserInfo() {
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
  
  // Course methods
  @override
  Future<List<Course>> getCourses() {
    // TODO: implement getCourses
    throw UnimplementedError();
  }

  @override
  Future<List<Course>> getUserCourses() {
    // TODO: implement getUserCourses
    throw UnimplementedError();
  }

  @override
  Future<List<Participant>> getCourseParticipants(String courseId) {
    // TODO: implement getCourseParticipants
    throw UnimplementedError();
  }
  
  
  // Quiz methods
  @override
  Future<void> importQuiz(String courseid, String quizXml) {
    // TODO: implement importQuiz
    throw UnimplementedError();
  }

  @override
  Future<List<Quiz>> getQuizzes(int? courseID, {int? topicId}) {
    // TODO: implement getQuizzes
    throw UnimplementedError();
  }

  @override
  Future<int?> createQuiz(String courseid, String quizname, String quizintro, String sectionid, String timeopen, String timeclose) {
    // TODO: implement createQuiz
    throw UnimplementedError();
  }

  @override
  Future<int?> importQuizQuestions(String courseid, String quizXml) {
    // TODO: implement importQuizQuestions
    throw UnimplementedError();
  }

  @override
  Future<String> addRandomQuestions(String categoryid, String quizid, String numquestions) {
    // TODO: implement addRandomQuestions
    throw UnimplementedError();
  }

  @override
  Future<List<QuestionType>> getQuestionsFromQuiz(int quizId) async {
    // TODO: implement google api code
    throw UnimplementedError();
  }
  
  
  // Assignment methods
  @override
  Future<List<Assignment>> getEssays(int? courseID, {int? topicId}) {
    // TODO: implement getEssays
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> createAssignment(String courseid, String sectionid, String assignmentName, String startdate, String enddate, String rubricJson, String description) {
    // TODO: implement createAssignment
    throw UnimplementedError();
  }

  @override
  Future<int?> getContextId(int assignmentId, String courseId) {
    // TODO: implement getContextId
    throw UnimplementedError();
  }
  
  // Submission and grading methods
  @override
  Future<List<Submission>> getAssignmentSubmissions(int assignmentId) {
    // TODO: implement getAssignmentSubmissions
    throw UnimplementedError();
  }

  @override
  Future<List<SubmissionWithGrade>> getSubmissionsWithGrades(int assignmentId) {
    // TODO: implement getSubmissionsWithGrades
    throw UnimplementedError();
  }

  @override
  Future<SubmissionStatus?> getSubmissionStatus(int assignmentId, int userId) {
    // TODO: implement getSubmissionStatus
    throw UnimplementedError();
  }
  
  @override
  Future<List<Grade>> getAssignmentGrades(int assignmentId) {
    // TODO: implement getAssignmentGrades
    throw UnimplementedError();
  }

  @override
  Future<bool> setRubricGrades(int assignmentId, int userId, String jsonGrades) {
    // TODO: implement setRubricGrades
    throw UnimplementedError();
  }

  @override
  Future<List> getRubricGrades(int assignmentId, int userid) {
    // TODO: implement getRubricGrades
    throw UnimplementedError();
  }
  
  @override
  Grade? findGradeForUser(List<Grade> grades, int userId) {
    // TODO: implement findGradeForUser
    throw UnimplementedError();
  }
  
  // Rubric methods
  @override
  Future<MoodleRubric?> getRubric(String assignmentid) {
    // TODO: implement getRubric
    throw UnimplementedError();
  }

  //Get Lesson Plan
  Future<LessonPlan>getLessonPlan(String courseId){
    //\TODO: implement getLessonPlan
    throw UnimplementedError();
  }

       @override
  Future<List<QuestionType>> getQuestionsFromQuizGoogle(String courseId, String courseWorkId) async {
    // TODO: implement google api code
    throw UnimplementedError();
  }
  
  @override
  Future<List<Participant>> getQuizGradesForParticipants(String courseId, int quizId) {
    // TODO: implement getQuizGradesForParticipants
    throw UnimplementedError();
  }

}