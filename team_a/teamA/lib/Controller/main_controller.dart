import 'package:flutter/foundation.dart';
import '../Api/moodle_api_singleton.dart';
import 'package:learninglens_app/Controller/beans.dart';

class MainController 
{
  // Singleton instance
  static final MainController _instance = MainController._internal();
  // Singleton accessor
  factory MainController() 
  {
    return _instance;
  }
  // Internal constructor
  MainController._internal();
  static bool isLoggedIn = false;
  // final llm = LlmApi(dotenv.env['PERPLEXITY_API_KEY']!);
  final ValueNotifier<bool> isUserLoggedInNotifier = ValueNotifier(false);
  Course? selectedCourse;


  Future<bool> loginToMoodle(String username, String password, String moodleURL) async 
  {
    var moodleApi = MoodleApiSingleton();
    try 
    {
      await moodleApi.login(username, password, moodleURL);
      isLoggedIn = true;

      return checkIfTeacher();
    } catch (e) 
    {
      if (kDebugMode) 
      {
        print(e);
      }
      isLoggedIn = false;
      return false;
    }
  }

  Future<bool> checkIfTeacher() async {
  Future<bool> isTeacher = MoodleApiSingleton().isUserTeacher(MoodleApiSingleton().moodleCourses ?? []);
  if (await isTeacher) {
    print('The user is a teacher in at least one course.');
    return true;
  } else {
    print('The user is not a teacher in any course.');
    return false;
  }
}


  void logoutFromMoodle() 
  {
    var moodleApi = MoodleApiSingleton();
    moodleApi.logout();
    isLoggedIn = false;
  }

  Future<bool> isUserLoggedIn() async 
  {
    return isLoggedIn;
  }

  void selectCourse(int index) {
    var api = MoodleApiSingleton();
    if (index < (api.moodleCourses?.length ?? 0)){
      selectedCourse = api.moodleCourses?[index];
    }
  }
}
