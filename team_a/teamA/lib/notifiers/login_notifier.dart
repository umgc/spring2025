// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/moodle_api_singleton.dart'; // Import your Moodle API
import 'package:learninglens_app/services/local_storage_service.dart';

enum LLMKey { openAI, perplexity, claude }

class LoginNotifier with ChangeNotifier {
  bool _isLoggedIn = false;
  bool _hasLLMKey = false;
  String? _username;
  String? _password;
  String? _moodleUrl;
  final LocalStorageService _localStorageService = LocalStorageService();
  final MoodleApiSingleton _moodleApi =
      MoodleApiSingleton(); // Moodle API instance

  bool get hasLLMKey => _hasLLMKey;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get password => _password;
  String? get moodleUrl => _moodleUrl;

  LoginNotifier() {
    _loadLoginState(); // Load saved login state when the notifier is created
  }

  Future<void> _loadLoginState() async {
    _isLoggedIn = LocalStorageService.getIsLoggedIn();
    _username = LocalStorageService.getUsername();
    _password = LocalStorageService.getPassword();
    _moodleUrl = LocalStorageService.getMoodleUrl();


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
        LocalStorageService.saveLoginState(_isLoggedIn);
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

    LocalStorageService.clearLoginState();
    LocalStorageService.clearCredentials();
    LocalStorageService.clearMoodleUrl();

    notifyListeners();
  }

  // save the llm key to local storage
  Future<void> saveLLMKey(LLMKey key, String value) async {
    if(key == LLMKey.openAI){
      LocalStorageService.saveOpenAIKey(value);
    } else if(key == LLMKey.perplexity){
      LocalStorageService.savePerplexityKey(value);
    } else if(key == LLMKey.claude){
      LocalStorageService.saveClaudeKey(value);
    }
    _hasLLMKey = await _checkHasLLMKey();
    notifyListeners();
  }
}
