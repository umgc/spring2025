import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/**
 * This class is responsible for handling all the local storage operations that utilizes the Shared Preferences package and the dotenv package.
 * through the use of the shared_preferences package, the class is able to store and retrieve data from the local storage of the device.
 * The class also uses the dotenv package to access the .env file that contains the environment variables that are used in the application and during development.
 * 
 * TODO: 
 * Encrypt the data stored in the local storage to ensure the security of the user's data.
 * During the save sets we could send a pulse request to the server(moodle, openai, claude,preplexity etc.) to ensure the application can reach the server.
 */
class LocalStorageService {
  static const String _kCredentialsKey = 'credentials';
  static const String _kThemeKey = 'theme';
  static const String _openAIKey = 'openAIKey';
  static const String _claudeKey = 'claudeKey';
  static const String _perplexityKey = 'perplexityKey'; 
  static const String _moodleUrlKey = 'moodleUrl'; 
  static const String _primaryColorKey = 'primaryColor';
  static const String _isLoggedInKey = 'isLoggedIn'; 

  // TODO: encrypt me please
  Future<void> saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kCredentialsKey, [username, password]);
  }

  Future<List<String>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kCredentialsKey);
  }

  Future<void> saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, themeName);
  }

  Future<String?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kThemeKey);
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCredentialsKey);
  }

  Future<void> clearTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kThemeKey);
  }

  Future<void> saveLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  Future<bool?> getIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey);
  }

  Future<void> saveMoodleUrl(String moodleUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_moodleUrlKey, moodleUrl);
  }

  Future<String?> getMoodleUrl() async {
    final prefs = await SharedPreferences.getInstance();
    if(prefs.getString(_moodleUrlKey) != null){
      //print('returning moodle url from shared preferences');
      return prefs.getString(_moodleUrlKey);
    } else if(dotenv.env['MOODLE_URL'] != null){
      //print('returning moodle url from dotenv');
      return dotenv.env['MOODLE_URL'];
    }
    return '';
  }

  Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
  }

  Future<void> clearMoodleUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_moodleUrlKey);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final credentials = prefs.getStringList(_kCredentialsKey);
    if(credentials?[0] != null){
      //print('returning username from shared preferences');
      return credentials?[0];
    } else if(dotenv.env['MOODLE_USERNAME'] != null){
      //print('returning username from dotenv');
      return dotenv.env['MOODLE_USERNAME'];
    } else {
      return '';
    }
  }

  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final credentials = prefs.getStringList(_kCredentialsKey);
     if(credentials?[1] != null){
      //print('returning password from shared preferences');
      return credentials?[1];
    } else if(dotenv.env['MOODLE_PASSWORD'] != null){
      //print('returning password from dotenv');
      return dotenv.env['MOODLE_PASSWORD'];
    } else {
      return '';
    }
  }

  Future<void> savePrimaryColor(String colorHex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_primaryColorKey, colorHex);
  }

  Future<String?> getPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_primaryColorKey);
  }

  Future<void> saveOpenAIKey(String openAIKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openAIKey, openAIKey);
  }

  Future<String?> getOpenAIKey() async {
    final prefs = await SharedPreferences.getInstance();
    if(prefs.getString(_openAIKey) != null){
      //print('returning openai key from shared preferences');
      return prefs.getString(_openAIKey);
    } else if(dotenv.env['openai_apikey'] != null){
      //print('returning openai key from dotenv');
      return dotenv.env['openai_apikey'];
    }
    return '';
  }

  Future<void> saveClaudeKey(String claudeKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claudeKey, claudeKey);
  }

  Future<String?> getClaudeKey() async {
    final prefs = await SharedPreferences.getInstance();
    if(prefs.getString(_claudeKey) != null){
      //print('returning claude key from shared preferences');
      return prefs.getString(_claudeKey);
    } else if(dotenv.env['claudeApiKey'] != null){
      //print('returning claude key from dotenv');
      return dotenv.env['claudeApiKey'];
    }
    return '';
  }

  Future<void> savePreplexityKey(String perplexity) async {  // Corrected method name
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_perplexityKey, perplexity); // Corrected key name
  }

  Future<String?> getPreplexityKey() async { // Corrected method name
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_perplexityKey) != null) {
      //print('returning preplexity from shared preferences');
      return prefs.getString(_perplexityKey); // Corrected key name
    } else if (dotenv.env['perplexity_apikey'] != null) {
      //print('returning preplexity from dotenv');
      return dotenv.env['perplexity_apikey']; // Corrected key name
    }
    return '';
  }

  Future<void> clearPreplexityKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_perplexityKey);
  }

  Future<void> clearOpenAIKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_openAIKey);
  }

  Future<void> clearClaudeKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claudeKey);
  }
}