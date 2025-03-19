import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/participant.dart';

class ChatGPTFunctionCaller {
  final LmsInterface lmsService;
  ChatGPTFunctionCaller(this.lmsService);

  /// The central dispatcher
  Future<String> handleFunctionCall(String functionName, Map<String, dynamic>? args) async {

    try{
      switch (functionName) {
        case "getUserCourses":
          final userCourses = await lmsService.getUserCourses();
          return _formatCourses(userCourses);

        case "getQuizzes":
          if (args == null || !args.containsKey("courseID")) {
            return "Error: Missing required parameter 'courseID'.";
          }
          print(args);
          final quizzes = await lmsService.getQuizzes(args["courseID"], topicId: args["quizTopicId"]);
          return _formatQuizzes(quizzes);

        case "getQuizGradesForParticipants":
          if (args == null || !args.containsKey("courseId") || !args.containsKey("quizId")) {
            return "Error: Missing 'courseId' or 'quizId' argument.";
          }
          final participants = await lmsService.getQuizGradesForParticipants(
            args["courseId"].toString(),
            args["quizId"],
          );
          return _formatGrades(participants);

        // NEW: getCourseParticipants
        case "getCourseParticipants":
          if (args == null || !args.containsKey("courseId")) {
            return "Error: Missing required parameter 'courseId'.";
          }
          final participants = await lmsService.getCourseParticipants(args["courseId"]);
          return _formatParticipants(participants);

        default:
          return "Error: Unknown function '$functionName'.";
      }
    } catch (e){
      return "Method has not yet been implmeneted.";
    }
  }

  String _formatCourses(List<Course> courses) {
    if (courses.isEmpty) return "No enrolled courses found.";
    return courses.map((c) => "Course: ${c.fullName} (ID: ${c.id}) (quizTopicId: ${c.quizTopicId})").join("\n");
  }

  String _formatQuizzes(List<Quiz> quizzes) {
    if (quizzes.isEmpty) return "No quizzes found in that course.";
    return quizzes.map((q) => "Quiz: ${q.name} (ID: ${q.id})").join("\n");
  }

  String _formatGrades(List<Participant> participants) {
    if (participants.isEmpty) return "No participants or grades found.";
    // Show each participant with .avgGrade if available
    return participants.map((p) {
      final gradeStr = (p.avgGrade != null) ? p.avgGrade.toString() : "No grade";
      return "Student: ${p.fullname} (ID: ${p.id}), Grade: $gradeStr";
    }).join("\n");
  }

  /// Format participants (no quiz grade needed here, just their names/IDs)
  String _formatParticipants(List<Participant> participants) {
    if (participants.isEmpty) return "No participants found.";
    return participants.map((p) {
      return "Student: ${p.fullname} (ID: ${p.id}) Roles: ${p.roles.join(', ')}";
    }).join("\n");
  }
}
