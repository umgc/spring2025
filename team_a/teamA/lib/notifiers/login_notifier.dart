// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/Api/lms/google_classroom/google_lms_service.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

enum LLMKey { openAI, perplexity, claude }

class LoginNotifier with ChangeNotifier {
  bool _isLoggedIn = false;
  bool _hasLLMKey = false;
  String? _username;
  String? _password;
  String? _moodleUrl;
  // Google variables
  String? _clientID;

  final LocalStorageService _localStorageService = LocalStorageService();
  final LmsInterface _api = LmsFactory.getLmsService(); // Moodle API instance

  bool get hasLLMKey => _hasLLMKey;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get password => _password;
  String? get moodleUrl => _moodleUrl;

  late GoogleSignIn _googleSignIn;

  LoginNotifier() {
    _loadLoginState(); // Load saved login state when the notifier is created
  }

  Future<void> _loadLoginState() async {
    _isLoggedIn = LocalStorageService.isLoggedIntoMoodle();
    _username = LocalStorageService.getUsername();
    _password = LocalStorageService.getPassword();
    _moodleUrl = LocalStorageService.getMoodleUrl();
    _clientID = LocalStorageService.getGoogleClientId();

    _hasLLMKey = await _checkHasLLMKey();

    _autoLogin();
    notifyListeners();
  }

  Future<bool> _checkHasLLMKey() async {
    String? openAIKey = LocalStorageService.getOpenAIKey();
    String? perplexityKey = LocalStorageService.getPerplexityKey();
    String? claudeKey = LocalStorageService.getClaudeKey();

    return openAIKey != null && openAIKey.isNotEmpty ||
        perplexityKey != null && perplexityKey.isNotEmpty ||
        claudeKey != null && claudeKey.isNotEmpty;
  }

  Future<void> _autoLogin() async {
  if (_username != null && _username!.isNotEmpty &&
      _password != null && _password!.isNotEmpty &&
      _moodleUrl != null && _moodleUrl!.isNotEmpty) {
    try {
      // Attempt to auto-login with saved credentials
      await login(_username!, _password!, _moodleUrl!);
    } catch (e) {
      // Handle any exceptions during auto-login
      print('Auto-login Error: $e');
    }
  } else {
    print('Auto-login skipped: Missing or empty credentials.');
  }
}

  Future<void> login(String username, String password, String moodleUrl) async {
    try {
      // 1. Authenticate with Moodle API:
      await _api.login(username, password, moodleUrl);

      if (_api.isLoggedIn()) {
        _isLoggedIn = true;
        _username = username;
        _password = password;
        _moodleUrl = moodleUrl;

        // 2. Save login state and credentials to local storage:
        LocalStorageService.saveMoodleLoginState(_isLoggedIn);
        LocalStorageService.saveCredentials(username, password);
        LocalStorageService.saveMoodleUrl(moodleUrl); // Save Moodle URL

        // check the hasLLMKey state
        notifyListeners(); // Notify listeners (widgets) about the login
      } else {
        // Handle login failure (e.g., show an error message)
        throw Exception('Moodle login failed. Check credentials and URL.');
      }
    } catch (e) {
      // Handle any exceptions during login
      print('Login Error: $e');
      rethrow; // Re-throw the exception to be handled by the caller
    }
  }

  void logout() async {
    _isLoggedIn = false;
    _username = null;
    _password = null;
    _moodleUrl = null;

    LocalStorageService.clearMoodleLoginState();
    LocalStorageService.clearCredentials();
    LocalStorageService.clearMoodleUrl();
    LmsFactory.getLmsService().resetLMSUserInfo();

    notifyListeners();
  }

  // save the llm key to local storage
  Future<void> saveLLMKey(LLMKey key, String value) async {
    if (key == LLMKey.openAI) {
      LocalStorageService.saveOpenAIKey(value);
    } else if (key == LLMKey.perplexity) {
      LocalStorageService.savePerplexityKey(value);
    } else if (key == LLMKey.claude) {
      LocalStorageService.saveClaudeKey(value);
    }
    _hasLLMKey = await _checkHasLLMKey();
    notifyListeners();
  }

  ///
  /// Google classroom login steps 
  ///
  Future<void> signInWithGoogle() async {
    if (_clientID == null) {
      throw Exception("GOOGLE_CLIENT_ID not found in .env file.");
    }

    try {
      // 1. Authenticate with Google OATH:
      await LmsFactory.getLmsServiceGoogle().loginOath(_clientID!);

      if (_api.isLoggedIn()) {
        _isLoggedIn = true;

        // 2. Save login state and credentials to local storage:
        LocalStorageService.saveGoogleLoginState(_isLoggedIn);
        LocalStorageService.saveGoogleAccessToken(
                  LmsFactory.getLmsServiceGoogle().getGoogleAccessToken());
        
        // testing getCourses method
        LmsFactory.getLmsServiceGoogle().getCourses();

        // check the hasLLMKey state
        notifyListeners(); // Notify listeners (widgets) about the login
      } else {
        // Handle login failure (e.g., show an error message)
        throw Exception('Google login failed.');
      }
    } catch (e) {
      // Handle any exceptions during login
      print('Login Error: $e');
      rethrow; // Re-throw the exception to be handled by the caller
    }
  }

  Future<void> signOutFromGoogle() async {
    try {
      LmsFactory.getLmsServiceGoogle().logout();
      LocalStorageService.clearGoogleLoginState();
      _isLoggedIn = false;
      LocalStorageService.clearGoogleAccessToken();
    } catch (error) {
      print("Google Sign-Out Error: $error");
      throw Exception("Google Sign-Out failed: $error");
    }

    Future<void> makeClassroomApiRequest(
        String apiEndpoint, dynamic http) async {
      String? accessToken = LocalStorageService.getGoogleAccessToken();

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
  }
}
