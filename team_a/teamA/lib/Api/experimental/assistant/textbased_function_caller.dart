import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/quiz.dart';

class TextBasedFunctionCaller {
  final LmsInterface lmsService;

  TextBasedFunctionCaller(this.lmsService);

  /// Dispatch the function call based on [functionName] and [args].
  Future<String> callFunctionByName(
      String functionName, Map<String, dynamic> args) async {
    print('${functionName}, ${args}');
    try {
      switch (functionName) {
        case "getUserCourses":
          final courses = await lmsService.getUserCourses();
          return _formatCourses(courses);

        case "getQuizzes":
          if (!args.containsKey("courseID")) {
            return "Error: Missing 'courseID'.";
          }
          // Try parse courseID
          final courseID = int.tryParse(args["courseID"]);
          if (courseID == null) {
            return "Error: 'courseID' must be an integer.";
          }

          // Check if quizTopicId was provided
          if (!args.containsKey("quizTopicId") ||
              args["quizTopicId"] == null ||
              args["quizTopicId"].isEmpty) {
            // Not provided => pass null to getQuizzes
            final quizzes = await lmsService.getQuizzes(courseID, topicId: null);
            return _formatQuizzes(quizzes);
          } else {
            // Provided => parse it
            final int? quizTopicId = int.tryParse(args["quizTopicId"]);
            if (quizTopicId == null) {
              return "Error: 'quizTopicId' must be an integer if provided.";
            }
            final quizzes =
                await lmsService.getQuizzes(courseID, topicId: quizTopicId);
            return _formatQuizzes(quizzes);
          }

        case "getQuizGradesForParticipants":
          if (!args.containsKey("courseId") || !args.containsKey("quizId")) {
            return "Error: Missing courseId or quizId.";
          }
          final courseId = args["courseId"];
          final quizId = int.parse(args["quizId"]);
          final participants =
              await lmsService.getQuizGradesForParticipants(courseId, quizId);
          return _formatGrades(participants);

        case "getCourseParticipants":
          if (!args.containsKey("courseId")) {
            return "Error: Missing courseId.";
          }
          final courseId = args["courseId"];
          final participants = await lmsService.getCourseParticipants(courseId);
          return _formatParticipants(participants);

        default:
          return "Error: Unknown function '$functionName'.";
      }
    } catch (e) {
      // For your real app, handle or log the exception in detail
      return "Error: Exception occurred calling '$functionName': $e";
    }
  }

  // Helper: format a list of courses
  String _formatCourses(List<Course> courses) {
    if (courses.isEmpty) return "No enrolled courses found.";
    return courses
        .map((c) =>
            "Course: ${c.fullName} (ID: ${c.id}, quizTopicId: ${c.quizTopicId})")
        .join("\n");
  }

  // Helper: format a list of quizzes
  String _formatQuizzes(List<Quiz> quizzes) {
    if (quizzes.isEmpty) return "No quizzes found.";
    return quizzes.map((q) => "Quiz: ${q.name} (ID: ${q.id})").join("\n");
  }

  // Helper: format quiz grades for participants
  String _formatGrades(List<Participant> participants) {
    if (participants.isEmpty) return "No participants or grades found.";
    return participants.map((p) {
      final gradeStr =
          (p.avgGrade != null) ? p.avgGrade.toString() : "No grade";
      return "Student: ${p.fullname} (ID: ${p.id}), Grade: $gradeStr";
    }).join("\n");
  }

  // Helper: format participants list
  String _formatParticipants(List<Participant> participants) {
    if (participants.isEmpty) return "No participants found.";
    return participants
        .map((p) =>
            "Student: ${p.fullname} (ID: ${p.id}) Roles: ${p.roles.join(', ')}")
        .join("\n");
  }
}