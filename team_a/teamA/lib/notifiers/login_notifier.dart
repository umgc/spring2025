import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/notifiers/login_state.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

enum LLMKey { openAI, perplexity, claude, grok }

class LoginNotifier with ChangeNotifier {
  // ---------------------------------------
  // New: use these model objects
  // ---------------------------------------
  final LoginState _moodleState = LoginState();
  final LoginState _googleState = LoginState();

  // If you want external access to them, you can provide getters:
  LoginState get moodleState => _moodleState;
  LoginState get googleState => _googleState;

  // You can still store other fields here as needed
  bool _hasLLMKey = false;
  String? _username;
  String? _password;
  String? _moodleUrl;
  String? _clientID;  // for Google
  String? _otherError;  // If you want any global error, or remove if not needed

  final LmsInterface _api = LmsFactory.getLmsService(); // Moodle API instance

  bool get hasLLMKey => _hasLLMKey;
  String? get username => _username;
  String? get password => _password;
  String? get moodleUrl => _moodleUrl;

  // Constructor
  LoginNotifier() {
    _loadLoginState(); // Load any saved login state on creation
  }

  // ---------------------------------------
  // Load from local storage
  // ---------------------------------------
  Future<void> _loadLoginState() async {
    // Moodle
    _moodleState.isLoggedIn = LocalStorageService.isLoggedIntoMoodle();
    _username = LocalStorageService.getUsername();
    _password = LocalStorageService.getPassword();
    _moodleUrl = LocalStorageService.getMoodleUrl();

    // Google
    _googleState.isLoggedIn = LocalStorageService.isLoggedIntoGoogle();
    _clientID = LocalStorageService.getGoogleClientId();

    // LLM Key
    _hasLLMKey = await _checkHasLLMKey();

    // Attempt auto-login if we had credentials
    _autoLogin();
    notifyListeners();
  }

  // ---------------------------------------
  // Check existence of any LLM keys
  // ---------------------------------------
  Future<bool> _checkHasLLMKey() async {
    final openAIKey = LocalStorageService.getOpenAIKey();
    final perplexityKey = LocalStorageService.getPerplexityKey();
    final grokKey = LocalStorageService.getGrokKey();

    return (openAIKey != null && openAIKey.isNotEmpty) ||
           (perplexityKey != null && perplexityKey.isNotEmpty) ||
           (grokKey != null && grokKey.isNotEmpty);
  }

  // ---------------------------------------
  // Auto-login if we have saved credentials
  // ---------------------------------------
  Future<void> _autoLogin() async {
    if ((_username != null && _username!.isNotEmpty) &&
        (_password != null && _password!.isNotEmpty) &&
        (_moodleUrl != null && _moodleUrl!.isNotEmpty)) {
      try {
        await signInWithMoodle(_username!, _password!, _moodleUrl!);
      } catch (e) {
        print('Auto-login Error: $e');
      }
    } else {
      print('Auto-login skipped: Missing or empty credentials.');
    }
  }

  // ---------------------------------------
  // Moodle: Sign-in
  // ---------------------------------------
  Future<void> signInWithMoodle(String username, String password, String moodleUrl) async {
    try {
      await _api.login(username, password, moodleUrl);

      if (_api.isLoggedIn()) {
        // Make sure moodle user is a teacher. 
        if (await _api.isUserTeacher(_api.courses!)) {
          // User is a teacher
          _moodleState.isLoggedIn = true;
          _moodleState.errorMessage = null;   // Clear any old error
          _username = username;
          _password = password;
          _moodleUrl = moodleUrl;

          // Save to local storage
          LocalStorageService.saveMoodleLoginState(_moodleState.isLoggedIn);
          LocalStorageService.saveCredentials(username, password);
          LocalStorageService.saveMoodleUrl(moodleUrl);
        } else {
          // user is not a teacher
          _api.logout();
          _moodleState.isLoggedIn = false;
          _moodleState.errorMessage = "User is not a teacher";
        }
      } else {
        // Logged in is false; set a custom error
        _moodleState.isLoggedIn = false;
        _moodleState.errorMessage = "Invalid username or password.";
      }

      notifyListeners();
    } catch (e) {
      // Catch the exception, set isLoggedIn = false, set error
      _moodleState.isLoggedIn = false;
      _moodleState.errorMessage = "Moodle login failed: ${e.toString()}";
      notifyListeners();
    }
  }

  // ---------------------------------------
  // Moodle: Sign-out
  // ---------------------------------------
  Future<void> signOutFromMoodle() async {
    _moodleState.isLoggedIn = false;
    _moodleState.errorMessage = null;
    _username = null;
    _password = null;
    _moodleUrl = null;

    // Clear from local storage
    LocalStorageService.clearMoodleLoginState();
    LocalStorageService.clearCredentials();
    LocalStorageService.clearMoodleUrl();

    // Reset LMS
    LmsFactory.getLmsService().resetLMSUserInfo();

    notifyListeners();
  }

  // ---------------------------------------
  // Google: Sign-in
  // ---------------------------------------
  Future<void> signInWithGoogle() async {
    if (_clientID == null) {
      throw Exception("GOOGLE_CLIENT_ID not found in .env file.");
    }

    try {
      await LmsFactory.getLmsServiceGoogle().loginOath(_clientID!);

      // if (_api.isLoggedIn()) {
      if (LmsFactory.getLmsServiceGoogle().isLoggedIn()) {
        _googleState.isLoggedIn = true;
        _googleState.errorMessage = null;

        // Save to local storage
        LocalStorageService.saveGoogleLoginState(_googleState.isLoggedIn);
        LocalStorageService.saveGoogleAccessToken(
          LmsFactory.getLmsServiceGoogle().getGoogleAccessToken()
        );

        notifyListeners();
      } else {
        _googleState.isLoggedIn = false;
        _googleState.errorMessage = 'Google login failed.';
        notifyListeners();
        throw Exception('Google login failed.');
      }
    } catch (e) {
      _googleState.isLoggedIn = false;
      _googleState.errorMessage = "Google login failed: ${e.toString()}";
      notifyListeners();
      rethrow;  // Or remove if you don't want to rethrow
    }
  }

  // ---------------------------------------
  // Google: Sign-out
  // ---------------------------------------
  Future<void> signOutFromGoogle() async {
    try {
      LmsFactory.getLmsServiceGoogle().logout();
      _googleState.isLoggedIn = false;
      _googleState.errorMessage = null;

      LocalStorageService.clearGoogleLoginState();
      LocalStorageService.clearGoogleAccessToken();

      notifyListeners();
    } catch (error) {
      print("Google Sign-Out Error: $error");
      // Optionally set _googleState.errorMessage
      throw Exception("Google Sign-Out failed: $error");
    }
  }

  // ---------------------------------------
  // Example Classroom API request for Google
  // ---------------------------------------
  Future<void> makeClassroomApiRequest(String apiEndpoint, dynamic http) async {
    final accessToken = LocalStorageService.getGoogleAccessToken();

    if (accessToken != null) {
      try {
        final response = await http.get(
          Uri.parse(apiEndpoint),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (response.statusCode == 200) {
          print('Classroom API Response: ${response.body}');
        } else {
          print('Classroom API Error: ${response.statusCode} - ${response.body}');
          throw Exception("Classroom API request failed: ${response.statusCode}");
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

  // ---------------------------------------
  // Save the LLM key to local storage
  // ---------------------------------------
  Future<void> saveLLMKey(LLMKey key, String value) async {
    switch (key) {
      case LLMKey.openAI:
        LocalStorageService.saveOpenAIKey(value);
        break;
      case LLMKey.perplexity:
        LocalStorageService.savePerplexityKey(value);
        break;
      case LLMKey.grok:
        LocalStorageService.saveGrokKey(value);
        break;
      case LLMKey.claude:
        // If you had a Claude key, you could handle it here
        break;
    }

    _hasLLMKey = await _checkHasLLMKey();
    notifyListeners();
  }
}
