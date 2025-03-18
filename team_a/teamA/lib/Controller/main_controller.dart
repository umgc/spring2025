import 'package:flutter/foundation.dart';
import 'package:learninglens_app/beans/course.dart';

class MainController {
  // Singleton instance
  static final MainController _instance = MainController._internal();
  // Singleton accessor
  factory MainController() {
    return _instance;
  }
  // Internal constructor
  MainController._internal();
  static bool isLoggedIn = false;
  // final llm = LlmApi(dotenv.env['PERPLEXITY_API_KEY']!);
  final ValueNotifier<bool> isUserLoggedInNotifier = ValueNotifier(false);
  Course? selectedCourse;
  String? username;
}
