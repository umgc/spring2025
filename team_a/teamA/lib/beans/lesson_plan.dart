import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LessonPlan {
  final String lessonPlanName;
  final String courseId;
  final String? manualEntry;
  final String? filePath;

  LessonPlan({required this.lessonPlanName, required this.courseId, this.manualEntry, this.filePath});

  Map<String, dynamic> toJson() {
    return {
      'lessonPlanName': lessonPlanName,
      'courseId': courseId,
      'content': manualEntry,
      'filePath': filePath,
    };
  }

  //pretty sure this works
  Future<void> saveLessonPlanLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedPlans = prefs.getStringList('lessonPlans') ?? [];
    savedPlans.add(jsonEncode(this.toJson()));
    await prefs.setStringList('lessonPlans', savedPlans);
  }

  //unsure about this logic
  static Future<List<LessonPlan>> loadLessonPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedPlans = prefs.getStringList('lessonPlans') ?? [];

    return savedPlans.map((plan) {
      final Map<String, dynamic> planJson = jsonDecode(plan);
      return LessonPlan(
        lessonPlanName: planJson['lessonPlanName'],
        courseId: planJson['courseId'],
        manualEntry: planJson['content'],
        filePath: planJson['filePath'],
      );
    }).toList();
  }

}