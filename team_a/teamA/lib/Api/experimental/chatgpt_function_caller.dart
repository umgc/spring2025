import 'dart:convert';
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/lesson_plan.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/quiz.dart';

class ChatGPTFunctionCaller {
  final MoodleLmsService moodleService;

  ChatGPTFunctionCaller(this.moodleService);

  /// Handles function calls based on user input
  Future<String> handleFunctionCall(String functionName, Map<String, dynamic>? args) async {
    switch (functionName) {
      case "getCourses":
        final courses = await moodleService.getCourses();
        return _formatCoursesResponse(courses);
      
      case "getUserCourses":
        final userCourses = await moodleService.getUserCourses();
        return _formatCoursesResponse(userCourses);

      case "getCourseParticipants":
        if (args == null || !args.containsKey("courseId")) {
          return "Error: Missing required parameter 'courseId'.";
        }
        final participants = await moodleService.getCourseParticipants(args["courseId"]);
        return _formatParticipantsResponse(participants);

      case "getQuizzes":
        if (args == null || !args.containsKey("courseID")) {
          return "Error: Missing required parameter 'courseID'.";
        }
        final quizzes = await moodleService.getQuizzes(args["courseID"]);
        return _formatQuizzesResponse(quizzes);

      case "getLessonPlans":
        if (args == null || !args.containsKey("courseId")) {
          return "Error: Missing required parameter 'courseId'.";
        }
        final lessons = await moodleService.getLessonPlans(args["courseId"]);
        return _formatLessonsResponse(lessons);

      default:
        return "Error: Unknown function '$functionName'.";
    }
  }

  /// Helper functions to format responses
  String _formatCoursesResponse(List<Course> courses) {
    if (courses.isEmpty) return "No courses found.";
    return courses.map((c) => "Course: ${c.fullName} (ID: ${c.id})").join("\n");
  }

  String _formatParticipantsResponse(List<Participant> participants) {
    if (participants.isEmpty) return "No participants found.";
    return participants.map((p) => "Participant: ${p.fullname} (ID: ${p.id})").join("\n");
  }

  String _formatQuizzesResponse(List<Quiz> quizzes) {
    if (quizzes.isEmpty) return "No quizzes found.";
    return quizzes.map((q) => "Quiz: ${q.name} (ID: ${q.id})").join("\n");
  }

  String _formatLessonsResponse(List<LessonPlan> lessons) {
    if (lessons.isEmpty) return "No lesson plans found.";
    return lessons.map((l) => "Lesson: ${l.intro} (ID: ${l.id})").join("\n");
  }
}
