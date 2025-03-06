import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Lesson {
  final int courseId;
  final String lessonPlanName;
  final String? content; // Content is now explicitly the lesson description

  Lesson({required this.lessonPlanName, required this.courseId, this.content});

  /// Convert lesson plan to JSON for storage or API submission
  Map<String, dynamic> toJson() {
    return {
      'lessonPlanName': lessonPlanName,
      'courseId': courseId,
      'content': content, // Pass content as lesson description
    };
  }

  /// Save lesson plan locally using SharedPreferences
  Future<void> saveLessonLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedPlans = prefs.getStringList('lessonPlans') ?? [];
    savedPlans.add(jsonEncode(toJson()));
    await prefs.setStringList('lessonPlans', savedPlans);
  }

  /// Load lesson plans from SharedPreferences
  static Future<List<Lesson>> loadLessonPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedPlans = prefs.getStringList('lessonPlans') ?? [];

    return savedPlans.map((plan) {
      final Map<String, dynamic> planJson = jsonDecode(plan);
      return Lesson(
        lessonPlanName: planJson['lessonPlanName'],
        courseId: planJson['courseId'],
        content: planJson['content'],
      );
    }).toList();
  }

  /// Submit lesson plan and automatically create a Moodle lesson
  Future<bool> submitLesson() async {
    final lessonPlanJson = toJson();
    print("Submitting lesson plan with data: $lessonPlanJson");
    var courseId = lessonPlanJson['courseId'];
    var lessonPlanName = lessonPlanJson['lessonPlanName'];
    var content = lessonPlanJson['content'];
    return await MoodleLmsService().createLesson(
      courseId: courseId, // Pass courseId as a string
      lessonPlanName: lessonPlanName,
      content: content ?? "No description provided",
    );
  }
}
