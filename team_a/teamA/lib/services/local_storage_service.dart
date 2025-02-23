import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// This class manages local storage operations using SharedPreferences and dotenv.
/// TODO:
/// - Encrypt sensitive data stored in SharedPreferences.
/// - Implement periodic server checks for API availability (Moodle, OpenAI, Claude, Perplexity).
class LocalStorageService {
  static late SharedPreferences _prefs;

  /// Initializes SharedPreferences. MUST be called once at app startup.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Saves user credentials.
  static void saveCredentials(String username, String password) {
    _prefs.setStringList('credentials', [username, password]);
  }

  /// Retrieves stored username, falling back to dotenv.
  static String getUsername() {
    final credentials = _prefs.getStringList('credentials');
    return credentials != null && credentials.isNotEmpty
        ? credentials[0]
        : dotenv.env['MOODLE_USERNAME'] ?? '';
  }

  /// Retrieves stored password, falling back to dotenv.
  static String getPassword() {
    final credentials = _prefs.getStringList('credentials');
    return credentials != null && credentials.length > 1
        ? credentials[1]
        : dotenv.env['MOODLE_PASSWORD'] ?? '';
  }

  /// Clears stored credentials.
  static void clearCredentials() {
    _prefs.remove('credentials');
  }

  /// Saves theme preference.
  static void saveTheme(String themeName) {
    _prefs.setString('theme', themeName);
  }

  /// Retrieves stored theme preference.
  static String getTheme() {
    return _prefs.getString('theme') ?? 'light'; // Default to 'light' theme
  }

  /// Clears theme preference.
  static void clearTheme() {
    _prefs.remove('theme');
  }

  /// Saves login state.
  static void saveMoodleLoginState(bool isLoggedIn) {
    _prefs.setBool('isLoggedIntoMoodle', isLoggedIn);
  }

  /// Retrieves login state.
  static bool isLoggedIntoMoodle() {
    return _prefs.getBool('isLoggedIntoMoodle') ?? false;
  }

  /// Clears login state.
  static void clearMoodleLoginState() {
    _prefs.remove('isLoggedIntoMoodle');
  }


    /// Saves login state.
  static void saveGoogleLoginState(bool isLoggedIn) {
    _prefs.setBool('isLoggedIntoGoogle', isLoggedIn);
  }

  /// Retrieves login state.
  static bool isLoggedIntoGoogle() {
    return _prefs.getBool('isLoggedIntoGoogle') ?? false;
  }

  /// Clears login state.
  static void clearGoogleLoginState() {
    _prefs.remove('isLoggedIntoGoogle');
  }

  /// Saves Moodle URL.
  static void saveMoodleUrl(String moodleUrl) {
    _prefs.setString('moodleUrl', moodleUrl);
  }

  /// Retrieves Moodle URL from storage or dotenv.
  static String getMoodleUrl() {
    return _prefs.getString('moodleUrl') ?? dotenv.env['MOODLE_URL'] ?? '';
  }

  /// Clears Moodle URL.
  static void clearMoodleUrl() {
    _prefs.remove('moodleUrl');
  }

  /// Saves primary color.
  static void savePrimaryColor(String colorHex) {
    _prefs.setString('primaryColor', colorHex);
  }

  /// Retrieves primary color.
  static String getPrimaryColor() {
    return _prefs.getString('primaryColor') ?? '#FFFFFF'; // Default to white
  }

  /// Saves OpenAI API key.
  static void saveOpenAIKey(String openAIKey) {
    _prefs.setString('openAIKey', openAIKey);
  }

  /// Retrieves OpenAI API key from storage or dotenv.
  static String getOpenAIKey() {
    return _prefs.getString('openAIKey') ?? dotenv.env['openai_apikey'] ?? '';
  }

  /// Clears OpenAI API key.
  static void clearOpenAIKey() {
    _prefs.remove('openAIKey');
  }

  /// Saves Claude API key.
  static void saveClaudeKey(String claudeKey) {
    _prefs.setString('claudeKey', claudeKey);
  }

  /// Retrieves Claude API key from storage or dotenv.
  static String getClaudeKey() {
    return _prefs.getString('claudeKey') ?? dotenv.env['claudeApiKey'] ?? '';
  }

  /// Clears Claude API key.
  static void clearClaudeKey() {
    _prefs.remove('claudeKey');
  }

  /// Saves Perplexity API key.
  static void savePerplexityKey(String perplexityKey) {
    _prefs.setString('perplexityKey', perplexityKey);
  }

  /// Retrieves Perplexity API key from storage or dotenv.
  static String getPerplexityKey() {
    return _prefs.getString('perplexityKey') ?? dotenv.env['perplexity_apikey'] ?? '';
  }

  /// Clears Perplexity API key.
  static void clearPerplexityKey() {
    _prefs.remove('perplexityKey');
  }

  static String? getGoogleClientId() {
    return _prefs.getString('GOOGLE_CLIENT_ID') ?? dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  }

  static void saveGoogleClientId(String clientId) {
    _prefs.setString('GOOGLE_CLIENT_ID', clientId);
  }

  static void clearGoogleClientId() {
    _prefs.remove('GOOGLE_CLIENT_ID');
  }

  static saveGoogleAccessToken(String accessToken) {
    _prefs.setString('GOOGLE_ACCESS_TOKEN', accessToken);
  }

  static String? getGoogleAccessToken() {
    return _prefs.getString('GOOGLE_ACCESS_TOKEN');
  }

  static clearGoogleAccessToken() {
    _prefs.remove('GOOGLE_ACCESS_TOKEN');
  }  
  // Save LmsType as an INTEGER
  static void saveSelectedClassroom(LmsType type) {
    _prefs.setInt('selectedClassroom', type.index);
  }

  // Get LmsType from stored INTEGER
  static LmsType getSelectedClassroom() {
    int? storedValue = _prefs.getInt('selectedClassroom');
    return storedValue != null ? LmsType.values[storedValue] : LmsType.MOODLE;
  }

  // Clear stored selection
  static void clearSelectedClassroom() {
    _prefs.remove('selectedClassroom');
  }

  static hasLLMKey() {
    return getOpenAIKey().isNotEmpty || getClaudeKey().isNotEmpty || getPerplexityKey().isNotEmpty;
  }
}
