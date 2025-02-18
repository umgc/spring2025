import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../Api/moodle_api_singleton.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js; // Import the dart:js library

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

  //Added for the purpose of the Google Login

  late GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> initializeGoogleSignIn() async {
    await dotenv.load(fileName: ".env");

    String? clientId = dotenv.env['GOOGLE_CLIENT_ID'];
    print('clientId: $clientId');

    if (clientId == null) {
      throw Exception("GOOGLE_CLIENT_ID not found in .env file.");
    }

    _googleSignIn = GoogleSignIn(
      clientId: clientId,
      scopes: <String>[
        'email',
        'profile',
        'https://www.googleapis.com/auth/classroom.courses',
        'https://www.googleapis.com/auth/classroom.rosters',
        'https://www.googleapis.com/auth/classroom.coursework.students',
        'https://www.googleapis.com/auth/classroom.coursework.me',
        'https://www.googleapis.com/auth/classroom.courses.readonly',
        'https://www.googleapis.com/auth/forms.body',
        'https://www.googleapis.com/auth/forms.responses.readonly'
      ],
    );
  }

  Future<void> signInWithGoogle(context) async {
    await initializeGoogleSignIn();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception("Google Sign-In was cancelled by the user.");
      }
      // Get the user's name
      username = googleUser.displayName;

      MoodleApiSingleton().moodleFirstName ??= username;
      // MoodleApiSingleton().setLoggedIn(true);

      print('Welcome, ${MoodleApiSingleton().moodleFirstName ?? 'User'}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      isLoggedIn = true;

      if (accessToken == null) {
        throw Exception("Failed to obtain access token.");
      }

      await setAccessToken(accessToken);
      isUserLoggedInNotifier.value = true;
    } catch (error) {
      print("Google Sign-In Error: $error");
      throw Exception("Google Sign-In failed: $error");
    }
  }

  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      await clearAccessToken();
      isUserLoggedInNotifier.value = false;
    } catch (error) {
      print("Google Sign-Out Error: $error");
      throw Exception("Google Sign-Out failed: $error");
    }
  }

  Future<void> setAccessToken(String accessToken) async {
    try {
      if (kIsWeb) {
        js.context.callMethod('eval', [
          "window.localStorage.setItem('google_access_token', '$accessToken');"
        ]);
      } else {
        await _storage.write(key: 'google_access_token', value: accessToken);
      }
      print('Google access token stored securely.');
    } catch (e) {
      print('Error storing Google access token: $e');
      throw Exception("Failed to store access token: $e");
    }
  }

  Future<String?> getAccessToken({required List<String> scopes}) async {
    try {
      if (kIsWeb) {
        return js.context.callMethod(
                'eval', ["window.localStorage.getItem('google_access_token');"])
            as String?;
      } else {
        return await _storage.read(key: 'google_access_token');
      }
    } catch (e) {
      print('Error retrieving Google access token: $e');
      return null;
    }
  }

  Future<void> clearAccessToken() async {
    try {
      if (kIsWeb) {
        js.context.callMethod(
            'eval', ["window.localStorage.removeItem('google_access_token');"]);
      } else {
        await _storage.delete(key: 'google_access_token');
      }
      print('Google access token cleared.');
    } catch (e) {
      print('Error clearing Google access token: $e');
      throw Exception("Failed to clear access token: $e");
    }
  }

  Future<void> makeClassroomApiRequest(String apiEndpoint, dynamic http) async {
    String? accessToken = await getAccessToken(scopes: [
      // 'https://www.googleapis.com/auth/classroom.courses.readonly',
      // 'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
      // 'https://www.googleapis.com/auth/classroom.rosters.readonly'
      // 'https://www.googleapis.com/auth/classroom.courses.readonly',
      // 'https://www.googleapis.com/auth/classroom.coursework.me',
      // 'https://www.googleapis.com/auth/classroom.coursework.students'
      'https://www.googleapis.com/auth/classroom.courses.readonly',
      'https://www.googleapis.com/auth/classroom.coursework.me',
      'https://www.googleapis.com/auth/classroom.coursework.students',
      'https://www.googleapis.com/auth/forms.body',
      'https://www.googleapis.com/auth/forms.responses.readonly'
    ]);

    if (accessToken != null) {
      try {
        final response = await http.get(
          Uri.parse(apiEndpoint),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (response.statusCode == 200) {
          print('Classroom API Response: ${response.body}');
        } else {
          print(
              'Classroom API Error: ${response.statusCode} - ${response.body}');
          throw Exception(
              "Classroom API request failed: ${response.statusCode}");
        }
      } catch (e) {
        print('Error making Classroom API request: $e');
        throw Exception("Failed to make Classroom API request: $e");
      }
    } else {
      print('No Google access token available. User needs to sign in.');
      throw Exception("No access token available. Please sign in again.");
    }
  }

  Future<bool> loginToMoodle(
      String username, String password, String moodleURL) async {
    var moodleApi = MoodleApiSingleton();
    try {
      await moodleApi.login(username, password, moodleURL);
      isLoggedIn = true;

      return checkIfTeacher();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      isLoggedIn = false;
      return false;
    }
  }

  Future<bool> checkIfTeacher() async {
    Future<bool> isTeacher = MoodleApiSingleton()
        .isUserTeacher(MoodleApiSingleton().moodleCourses ?? []);
    if (await isTeacher) {
      print('The user is a teacher in at least one course.');
      return true;
    } else {
      print('The user is not a teacher in any course.');
      return false;
    }
  }

  void logoutFromMoodle() {
    var moodleApi = MoodleApiSingleton();
    moodleApi.logout();

    isLoggedIn = false;
  }

  Future<bool> isUserLoggedIn() async {
    return isLoggedIn;
  }

  void selectCourse(int index) {
    var api = MoodleApiSingleton();
    if (index < (api.moodleCourses?.length ?? 0)) {
      selectedCourse = api.moodleCourses?[index];
    }
  }
}
