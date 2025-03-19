// lib/services/caregiver_notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:memoryminder/models/caregiver.dart';
import 'package:memoryminder/services/navigation_service.dart';
import 'package:memoryminder/models/emergency_type.dart';
import 'package:memoryminder/config/config.dart';
import 'package:memoryminder/services/esri_client.dart';

class CaregiverNotificationService {
  final FirebaseMessaging _firebaseMessaging;
  final Logger _logger = Logger('CaregiverNotificationService');
  final FlutterLocalNotificationsPlugin _localNotifications;
  final NavigationService _navigationService;
  final EsriClient _esriClient;

  final Map<EmergencyType, DateTime> _lastAlertTimestamps = {};
  static const Duration _alertThrottleDuration = Duration(minutes: 5);

  static final AndroidNotificationChannel _emergencyChannel =
      AndroidNotificationChannel(
    'emergency_alerts',
    'Emergency Alerts',
    description: 'High priority alerts for emergency situations',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    sound: const RawResourceAndroidNotificationSound('emergency_alert'),
  );

  CaregiverNotificationService({
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    NavigationService? navigationService,
    EsriClient? esriClient,
  })  : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _localNotifications =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
        _navigationService = navigationService ?? NavigationService(),
        _esriClient = esriClient ?? EsriClient(apiKey: Config.esriApiKey) {
    _setupLogging();
  }

  void _setupLogging() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      _logger.info('${record.level.name}: ${record.time}: ${record.message}');
      if (record.level >= Level.SEVERE) {
        _sendErrorToMonitoring(record);
      }
    });
  }

  Future<bool> initialize() async {
    try {
      await _initializeLocalNotifications();
      await _setupFCM();
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Initialization failed', e, stackTrace);
      return false;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_emergencyChannel);
  }

  Future<void> _setupFCM() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      throw Exception('FCM permission denied');
    }

    final token = await _firebaseMessaging.getToken();
    _logger.info('FCM Token: $token');

    _firebaseMessaging.onTokenRefresh.listen(_handleTokenRefresh);
    configureMessageHandling();
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.fcmServerUrl}/update-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Config.serverKey}',
          'X-HIPAA-Compliance': 'true',
        },
        body: jsonEncode({
          'token': newToken,
          'timestamp': DateTime.now().toIso8601String(),
          'device_id': await _firebaseMessaging.getToken(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Token update failed: ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.severe('Token refresh error', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> sendEmergencyAlert({
    required Caregiver caregiver,
    required String patientLocation,
    required EmergencyType emergencyType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (!_isHIPAACompliant(patientLocation)) {
        _logger.warning('HIPAA compliance check failed for location data');
        return false;
      }

      if (_isThrottled(emergencyType, patientLocation)) {
        _logger.info('Alert throttled for $emergencyType at $patientLocation');
        return false;
      }

      final message = _buildFCMMessage(
          caregiver, patientLocation, emergencyType, additionalData);
      final response = await _sendFCMRequest(message);

      if (response.statusCode == 200) {
        _handleSuccessfulAlert(caregiver, emergencyType, patientLocation);
        return true;
      }

      _handleFailedAlert(response);
      return false;
    } catch (e, stackTrace) {
      _logger.severe('Emergency alert failed', e, stackTrace);
      return false;
    }
  }

  Map<String, dynamic> _buildFCMMessage(
    Caregiver caregiver,
    String location,
    EmergencyType type,
    Map<String, dynamic>? data,
  ) {
    final translatedTitle =
        _getTranslatedTitle(caregiver.preferredLanguage, type);
    final translatedBody =
        _getTranslatedBody(caregiver.preferredLanguage, type, location);

    return {
      'to': caregiver.fcmToken,
      'priority': 'high',
      'data': {
        'type': 'emergency',
        'emergencyType': type.name,
        'location': location,
        'timestamp': DateTime.now().toIso8601String(),
        'hipaa_compliant': true,
        if (data != null) ...data,
      },
      'notification':
          _buildPlatformNotifications(translatedTitle, translatedBody),
    };
  }

  Map<String, dynamic> _buildPlatformNotifications(String title, String body) {
    return {
      'title': title,
      'body': body,
      'sound': 'emergency_alert.wav',
      'badge': '1',
      'android': {
        'channelId': _emergencyChannel.id,
        'priority': 'high',
        'vibrateTimingsMillis': [0, 500, 500, 500],
      },
      'apns': {
        'payload': {
          'aps': {
            'sound': 'emergency_alert.wav',
            'interruption-level': 'time-sensitive',
          },
        },
      },
    };
  }

  Future<http.Response> _sendFCMRequest(Map<String, dynamic> message) async {
    return await http.post(
      Uri.parse(Config.fcmServerUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=${Config.serverKey}',
        'X-Platform': 'Flutter/${Config.appVersion}',
      },
      body: jsonEncode(message),
    );
  }

  void _handleSuccessfulAlert(
      Caregiver caregiver, EmergencyType type, String location) {
    _lastAlertTimestamps[type] = DateTime.now();
    _logger.info('Alert sent to ${caregiver.userId} for $type at $location');
    _triggerEmergencyProtocol(type, location);
  }

  void _handleFailedAlert(http.Response response) {
    _logger.warning('''
      FCM Error: ${response.statusCode}
      Headers: ${response.headers}
      Body: ${response.body}
    ''');
  }

  bool _isThrottled(EmergencyType type, String location) {
    final lastTimestamp = _lastAlertTimestamps[type];
    return lastTimestamp != null &&
        DateTime.now().difference(lastTimestamp) < _alertThrottleDuration;
  }

  bool _isHIPAACompliant(String locationData) {
    return !locationData.contains(
        RegExp(r'\b(?:street|address|zipcode)\b', caseSensitive: false));
  }

  String _getTranslatedTitle(String language, EmergencyType type) {
    final translations = {
      'en': {
        EmergencyType.urgent: 'Urgent Assistance Needed',
        EmergencyType.fall: 'Fall Detected',
        EmergencyType.medical: 'Medical Emergency',
        EmergencyType.confusion: 'Disorientation Alert',
        EmergencyType.general: 'General Assistance',
      },
      'es': {
        EmergencyType.urgent: 'Asistencia Urgente Necesaria',
        EmergencyType.fall: 'Caída Detectada',
        EmergencyType.medical: 'Emergencia Médica',
        EmergencyType.confusion: 'Alerta de Desorientación',
        EmergencyType.general: 'Asistencia General',
      },
    };
    return translations[language]?[type] ?? _getEmergencyTitle(type);
  }

  String _getTranslatedBody(
      String language, EmergencyType type, String location) {
    final translations = {
      'en': {
        EmergencyType.urgent: 'Patient needs immediate help at: %location%',
        EmergencyType.fall: 'Fall detected at: %location%',
        EmergencyType.medical: 'Medical emergency at: %location%',
        EmergencyType.confusion: 'Patient disoriented at: %location%',
        EmergencyType.general: 'Assistance needed at: %location%',
      },
      'es': {
        EmergencyType.urgent:
            'Paciente necesita ayuda inmediata en: %location%',
        EmergencyType.fall: 'Caída detectada en: %location%',
        EmergencyType.medical: 'Emergencia médica en: %location%',
        EmergencyType.confusion: 'Paciente desorientado en: %location%',
        EmergencyType.general: 'Asistencia necesaria en: %location%',
      },
    };
    return (translations[language]?[type] ?? _getEmergencyBody(type, location))
        .replaceAll('%location%', location);
  }

  String _getEmergencyTitle(EmergencyType type) {
    switch (type) {
      case EmergencyType.urgent:
        return 'Urgent Help Needed';
      case EmergencyType.fall:
        return 'Fall Detected';
      case EmergencyType.medical:
        return 'Medical Emergency';
      case EmergencyType.confusion:
        return 'Disorientation Alert';
      case EmergencyType.general:
        return 'General Assistance';
    }
  }

  String _getEmergencyBody(EmergencyType type, String location) {
    switch (type) {
      case EmergencyType.urgent:
        return 'Your patient needs immediate assistance at $location';
      case EmergencyType.fall:
        return 'A fall has been detected at $location. Immediate attention required.';
      case EmergencyType.medical:
        return 'Medical emergency reported at $location. Urgent response needed.';
      case EmergencyType.confusion:
        return 'Patient showing signs of disorientation at $location. Assistance needed.';
      case EmergencyType.general:
        return 'General assistance needed at $location';
    }
  }

  Future<void> _triggerEmergencyProtocol(
      EmergencyType type, String location) async {
    switch (type) {
      case EmergencyType.urgent:
        await _triggerUrgentProtocol(location);
        break;
      case EmergencyType.fall:
        await _triggerFallProtocol(location);
        break;
      case EmergencyType.medical:
        await _triggerMedicalProtocol(location);
        break;
      case EmergencyType.confusion:
        await _triggerConfusionProtocol(location);
        break;
      case EmergencyType.general:
        await _triggerGeneralProtocol(location);
        break;
    }
  }

  Future<void> _triggerUrgentProtocol(String location) async {
    try {
      final route = await _esriClient.getRouteToHome(location);
      await _esriClient.sendDirectionsToCaregiver(route);
      await _localNotifications.show(
        0,
        'Emergency Protocol Activated',
        'Safety measures initiated for location: $location',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'emergency_protocols',
            'Emergency Protocols',
            importance: Importance.max,
          ),
        ),
      );
    } catch (e, stackTrace) {
      _logger.severe('Urgent protocol failed', e, stackTrace);
    }
  }

  Future<void> _triggerFallProtocol(String location) async {
    _logger.info('Fall protocol triggered for $location');
    // Implement fall-specific logic
  }

  Future<void> _triggerMedicalProtocol(String location) async {
    _logger.info('Medical protocol triggered for $location');
    // Implement medical-specific logic
  }

  Future<void> _triggerConfusionProtocol(String location) async {
    _logger.info('Confusion protocol triggered for $location');
    // Implement confusion-specific logic
  }

  Future<void> _triggerGeneralProtocol(String location) async {
    _logger.info('General protocol triggered for $location');
    // Implement general assistance logic
  }

  Future<void> _storeEmergencyEvent(EmergencyType type, String location) async {
    try {
      await FirebaseFirestore.instance.collection('emergency_events').add({
        'type': type.name,
        'location': location,
        'timestamp': FieldValue.serverTimestamp(),
        'handled': false,
      });
    } catch (e, stackTrace) {
      _logger.severe('Failed to store emergency event', e, stackTrace);
    }
  }

  void configureMessageHandling() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.info('Received foreground message: ${message.messageId}');
    await _processEmergencyData(message.data);
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    _logger.info('Message opened app: ${message.messageId}');
    await _processEmergencyData(message.data);
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _processEmergencyData(data);
    }
  }

  Future<void> _processEmergencyData(Map<String, dynamic> data) async {
    try {
      final type = _parseEmergencyType(data['emergencyType']);
      final location = data['location'];
      final timestamp = DateTime.parse(data['timestamp']);

      await _storeEmergencyEvent(type, location);

      // Utilisation des méthodes existantes avec le switch case
      switch (type) {
        case EmergencyType.urgent:
          await _navigationService.navigateToEmergencyHelp(location, timestamp);
          break;
        case EmergencyType.fall:
          await _navigationService.navigateToFallAlert(location, timestamp);
          break;
        case EmergencyType.medical:
          await _navigationService.navigateToMedicalEmergency(
              location, timestamp);
          break;
        case EmergencyType.confusion:
          await _navigationService.navigateToConfusionAlert(
              location, timestamp);
          break;
        case EmergencyType.general:
          await _navigationService.navigateToGeneralAssistance(
              location, timestamp);
          break;
      }
    } catch (e, stackTrace) {
      _logger.severe('Error processing emergency data', e, stackTrace);
    }
  }

  EmergencyType _parseEmergencyType(String typeString) {
    return EmergencyType.values.firstWhere(
      (type) => type.name == typeString.toLowerCase(),
      orElse: () => EmergencyType.urgent,
    );
  }

  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    final service = CaregiverNotificationService();
    await service.initialize();
    await service._processEmergencyData(message.data);
  }

  void _sendErrorToMonitoring(LogRecord record) {
    // Implement error reporting integration (Sentry, Crashlytics, etc.)
  }
}
