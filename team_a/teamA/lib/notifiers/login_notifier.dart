import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/moodle_api_singleton.dart'; // Import your Moodle API
import 'package:learninglens_app/services/local_storage_service.dart';

class LoginNotifier with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _username;
  String? _password;
  String? _moodleUrl;
  final LocalStorageService _localStorageService = LocalStorageService();
  final MoodleApiSingleton _moodleApi =
      MoodleApiSingleton(); // Moodle API instance

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get password => _password;
  String? get moodleUrl => _moodleUrl;

  LoginNotifier() {
    _loadLoginState(); // Load saved login state when the notifier is created
  }

  Future<void> _loadLoginState() async {
    _isLoggedIn = await _localStorageService.getIsLoggedIn() ?? false;
    _username = await _localStorageService.getUsername();
    _password = await _localStorageService.getPassword();
    _moodleUrl = await _localStorageService.getMoodleUrl();
    _autoLogin(); // Attempt to auto-login when the notifier is created
    notifyListeners();
  }

  Future<void> _autoLogin() async {
    if (_username != null && _password != null && _moodleUrl != null) {
      try {
        // Attempt to auto-login with saved credentials
        await login(_username!, _password!, _moodleUrl!);
      } catch (e) {
        // Handle any exceptions during auto-login
        print('Auto-login Error: $e');
      }
    }
  }

  Future<void> login(String username, String password, String moodleUrl) async {
    try {
      // 1. Authenticate with Moodle API:
      await _moodleApi.login(username, password, moodleUrl);

      if (_moodleApi.isLoggedIn()) {
        _isLoggedIn = true;
        _username = username;
        _password = password;
        _moodleUrl = moodleUrl;

        // 2. Save login state and credentials to local storage:
        await _localStorageService.saveLoginState(_isLoggedIn);
        await _localStorageService.saveCredentials(username, password);
        await _localStorageService.saveMoodleUrl(moodleUrl); // Save Moodle URL

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

    await _localStorageService.clearLoginState();
    await _localStorageService.clearCredentials();
    await _localStorageService.clearMoodleUrl();

    notifyListeners();
  }
}
