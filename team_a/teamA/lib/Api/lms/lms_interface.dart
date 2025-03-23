import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/quiz_type.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/submission_status.dart';
import 'package:learninglens_app/beans/grade.dart';
import 'package:learninglens_app/beans/submission.dart';
import 'package:learninglens_app/beans/submission_with_grade.dart';
import 'package:learninglens_app/beans/moodle_rubric.dart';

// Singleton interface class for API access.
abstract class LmsInterface {
  late String serverUrl;

  // User info
  late String apiURL;
  String? userName;
  String? firstName;
  String? lastName;
  String? siteName;
  String? fullName;
  String? profileImage;
  List<Course>? courses;

  // Authentication/Login methods
  Future<void> login(String username, String password, String baseURL);
  bool isLoggedIn();
  Future<bool> isUserTeacher(List<Course> moodleCourses);
  void logout();
  void resetLMSUserInfo();

  // Course methods
  Future<List<Course>> getCourses();
  Future<List<Course>> getUserCourses();
  Future<List<Participant>> getCourseParticipants(String courseId);

  // Quiz methods
  Future<void> importQuiz(String courseid, String quizXml);
  Future<List<Quiz>> getQuizzes(int? courseID, {int? topicId});
  Future<int?> createQuiz(String courseid, String quizname, String quizintro,
      String sectionid, String timeopen, String timeclose);
  Future<String> addRandomQuestions(
      String categoryid, String quizid, String numquestions);
  Future<int?> importQuizQuestions(String courseid, String quizXml);
  Future<List<QuestionType>> getQuestionsFromQuiz(int quizId);

  // Assignment methods
  Future<List<Assignment>> getEssays(int? courseID, {int? topicId});
  Future<Map<String, dynamic>?> createAssignment(String courseid, String sectionid, String assignmentName, 
                                                  String startdate, String enddate, String rubricJson, String description);
  Future<int?> getContextId(int assignmentId, String courseId);

  // Submission and grading methods
  Future<List<Submission>> getAssignmentSubmissions(int assignmentId);
  Future<List<SubmissionWithGrade>> getSubmissionsWithGrades(int assignmentId);
  Future<SubmissionStatus?> getSubmissionStatus(int assignmentId, int userId);
  Future<List<Grade>> getAssignmentGrades(int assignmentId);
  Future<bool> setRubricGrades(int assignmentId, int userId, String jsonGrades);
  Future<List<dynamic>> getRubricGrades(int assignmentId, int userid);
  Grade? findGradeForUser(List<Grade> grades, int userId);

  // Rubric methods
  Future<MoodleRubric?> getRubric(String assignmentid);
  Future<List<Participant>> getQuizGradesForParticipants(String courseId, int quizId);
}
