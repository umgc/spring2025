// lib/config/config.dart
class Config {
  static const String fcmServerUrl = String.fromEnvironment('FCM_SERVER_URL');
  static const String serverKey = String.fromEnvironment('FCM_SERVER_KEY');
  static const String esriApiKey = String.fromEnvironment('ESRI_API_KEY');
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = 'YOUR_API_BASE_URL';
}
