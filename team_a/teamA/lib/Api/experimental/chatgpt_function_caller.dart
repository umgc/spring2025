import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/participant.dart';

class ChatGPTFunctionCaller {
  final MoodleLmsService moodleService;
  ChatGPTFunctionCaller(this.moodleService);

  /// The central dispatcher
  Future<String> handleFunctionCall(String functionName, Map<String, dynamic>? args) async {
    switch (functionName) {
      case "getUserCourses":
        final userCourses = await moodleService.getUserCourses();
        return _formatCourses(userCourses);

      case "getQuizzes":
        if (args == null || !args.containsKey("courseID")) {
          return "Error: Missing required parameter 'courseID'.";
        }
        final quizzes = await moodleService.getQuizzes(args["courseID"]);
        return _formatQuizzes(quizzes);

      case "getQuizGradesForParticipants":
        if (args == null || !args.containsKey("courseId") || !args.containsKey("quizId")) {
          return "Error: Missing 'courseId' or 'quizId' argument.";
        }
        final participants = await moodleService.getQuizGradesForParticipants(
          args["courseId"].toString(),
          args["quizId"],
        );
        return _formatGrades(participants);

      default:
        return "Error: Unknown function '$functionName'.";
    }
  }

  String _formatCourses(List<Course> courses) {
    if (courses.isEmpty) return "No enrolled courses found.";
    return courses.map((c) => "Course: ${c.fullName} (ID: ${c.id})").join("\n");
  }

  String _formatQuizzes(List<Quiz> quizzes) {
    if (quizzes.isEmpty) return "No quizzes found in that course.";
    return quizzes.map((q) => "Quiz: ${q.name} (ID: ${q.id})").join("\n");
  }

  String _formatGrades(List<Participant> participants) {
    if (participants.isEmpty) return "No participants or grades found.";
    // if the participant has .avgGrade, show it
    return participants.map((p) {
      final gradeStr = (p.avgGrade != null) ? p.avgGrade.toString() : "No grade";
      return "Student: ${p.fullname} (ID: ${p.id}), Grade: $gradeStr";
    }).join("\n");
  }
}
