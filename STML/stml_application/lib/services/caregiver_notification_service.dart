import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:memoryminder/models/caregiver.dart';
import 'package:memoryminder/services/navigation_service.dart';
import 'dart:convert';

enum EmergencyType {
  help,
  fall,
  medical,
}

class CaregiverNotificationService {
  final FirebaseMessaging _firebaseMessaging;
  final _logger = Logger('CaregiverNotificationService');
  final String _fcmServerUrl = 'YOUR_FIREBASE_CLOUD_FUNCTION_URL';
  final String _serverKey = 'YOUR_SERVER_KEY';
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NavigationService _navigationService = NavigationService();

  static const AndroidNotificationChannel _emergencyChannel =
      AndroidNotificationChannel(
    'emergency_alerts',
    'Emergency Alerts',
    description: 'High priority alerts for emergency situations',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    sound: RawResourceAndroidNotificationSound('emergency_alert'),
  );

  CaregiverNotificationService({
    FirebaseMessaging? firebaseMessaging,
  }) : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance {
    _setupLogging();
  }

  void _setupLogging() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      _logger.info('${record.level.name}: ${record.time}: ${record.message}');
      if (record.level >= Level.SEVERE) {
        // Implement crash reporting service here (e.g., Crashlytics)
        // FirebaseCrashlytics.instance.recordError(record.error, record.stackTrace);
      }
    });
  }

  Future<bool> initialize() async {
    try {
      await _initializeLocalNotifications();
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
        provisional: false,
        announcement: true,
      );

      String? token = await _firebaseMessaging.getToken();
      _logger.info('FCM Token: $token');

      _firebaseMessaging.onTokenRefresh.listen(_handleTokenRefresh);
      configureMessageHandling();

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e, stackTrace) {
      _logger.severe('Error initializing FCM', e, stackTrace);
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
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
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

  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      await http.post(
        Uri.parse('$_fcmServerUrl/update-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_serverKey',
        },
        body: jsonEncode({
          'token': newToken,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      _logger.info('Token updated successfully in backend');
    } catch (e, stackTrace) {
      _logger.severe('Failed to update token in backend', e, stackTrace);
    }
  }

  EmergencyType _parseEmergencyType(String? type) {
    switch (type?.toLowerCase()) {
      case 'help':
        return EmergencyType.help;
      case 'fall':
        return EmergencyType.fall;
      case 'medical':
        return EmergencyType.medical;
      default:
        _logger.warning('Unknown emergency type: $type, defaulting to help');
        return EmergencyType.help;
    }
  }

  Future<bool> sendEmergencyAlert({
    required Caregiver caregiver,
    required String patientLocation,
    required EmergencyType emergencyType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final alertData = {
        'to': caregiver.fcmToken,
        'priority': 'high',
        'data': {
          'type': 'emergency',
          'emergencyType': emergencyType.toString().split('.').last,
          'location': patientLocation,
          'timestamp': DateTime.now().toIso8601String(),
          if (additionalData != null) ...additionalData,
        },
        'notification': {
          'title': _getEmergencyTitle(emergencyType),
          'body': _getEmergencyBody(emergencyType, patientLocation),
          'sound': 'emergency_alert.wav',
          'badge': 1,
          'priority': 'high',
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': _emergencyChannel.id,
            'priority': 'high',
            'default_sound': false,
            'sound': 'emergency_alert',
            'default_vibrate_timings': false,
            'vibrate_timings': ['0s', '0.5s', '0.5s', '0.5s'],
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'sound': 'emergency_alert.wav',
              'badge': 1,
              'content-available': 1,
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(_fcmServerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(alertData),
      );

      if (response.statusCode == 200) {
        _logger.info('Emergency alert sent successfully to ${caregiver.name}');
        return true;
      } else {
        _logger.warning(
            'Failed to send emergency alert. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.severe('Error sending emergency alert', e, stackTrace);
      return false;
    }
  }

  String _getEmergencyTitle(EmergencyType type) {
    switch (type) {
      case EmergencyType.help:
        return 'Urgent Help Needed';
      case EmergencyType.fall:
        return 'Fall Detected';
      case EmergencyType.medical:
        return 'Medical Emergency';
    }
  }

  String _getEmergencyBody(EmergencyType type, String location) {
    switch (type) {
      case EmergencyType.help:
        return 'Your patient needs immediate assistance at $location';
      case EmergencyType.fall:
        return 'A fall has been detected at $location. Immediate attention required.';
      case EmergencyType.medical:
        return 'Medical emergency reported at $location. Urgent response needed.';
    }
  }

  Future<String?> refreshToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _handleTokenRefresh(token);
      }
      return token;
    } catch (e, stackTrace) {
      _logger.severe('Error refreshing FCM token', e, stackTrace);
      return null;
    }
  }

  void configureMessageHandling() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.info('Received foreground message: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _emergencyChannel.id,
            _emergencyChannel.name,
            channelDescription: _emergencyChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            sound: const RawResourceAndroidNotificationSound('emergency_alert'),
            playSound: true,
            enableLights: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'emergency_alert.wav',
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: jsonEncode(data),
      );

      _processEmergencyData(data);
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    _logger.info('Message opened app: ${message.messageId}');
    await _navigateBasedOnMessage(message.data);
  }

  void _onLocalNotificationTapped(NotificationResponse response) async {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      await _navigateBasedOnMessage(data);
    }
  }

  Future<void> _navigateBasedOnMessage(Map<String, dynamic> data) async {
    final type = _parseEmergencyType(data['emergencyType']);
    final location = data['location'];
    final timestamp = DateTime.parse(data['timestamp']);

    switch (type) {
      case EmergencyType.help:
        await _navigationService.navigateToEmergencyHelp(location, timestamp);
        break;
      case EmergencyType.fall:
        await _navigationService.navigateToFallAlert(location, timestamp);
        break;
      case EmergencyType.medical:
        await _navigationService.navigateToMedicalEmergency(
            location, timestamp);
        break;
    }
  }

  Future<void> _processEmergencyData(Map<String, dynamic> data) async {
    final type = _parseEmergencyType(data['emergencyType']);
    final location = data['location'];
    final timestamp = DateTime.parse(data['timestamp']);

    await _storeEmergencyEvent(type, location, timestamp);
    await _updateEmergencyStatus(type, true);

    switch (type) {
      case EmergencyType.help:
        await _triggerHelpProtocol(location);
        break;
      case EmergencyType.fall:
        await _triggerFallProtocol(location);
        break;
      case EmergencyType.medical:
        await _triggerMedicalProtocol(location);
        break;
    }
  }

  Future<void> _storeEmergencyEvent(
    EmergencyType type,
    String location,
    DateTime timestamp,
  ) async {
    final logger = Logger('EmergencyStorage');
    try {
      // Implement your storage logic here
      logger.info('Emergency event stored successfully');
    } catch (e, stackTrace) {
      logger.severe('Failed to store emergency event', e, stackTrace);
    }
  }

  Future<void> _updateEmergencyStatus(EmergencyType type, bool isActive) async {
    final logger = Logger('EmergencyStatus');
    try {
      // Implement your status update logic here
      logger.info('Emergency status updated successfully');
    } catch (e, stackTrace) {
      logger.severe('Failed to update emergency status', e, stackTrace);
    }
  }

  Future<void> _triggerHelpProtocol(String location) async {
    final logger = Logger('HelpProtocol');
    try {
      // Implement help protocol logic here
      logger.info('Help protocol triggered for location: $location');
    } catch (e, stackTrace) {
      logger.severe('Failed to trigger help protocol', e, stackTrace);
    }
  }

  Future<void> _triggerFallProtocol(String location) async {
    final logger = Logger('FallProtocol');
    try {
      // Implement fall protocol logic here
      logger.info('Fall protocol triggered for location: $location');
    } catch (e, stackTrace) {
      logger.severe('Failed to trigger fall protocol', e, stackTrace);
    }
  }

  Future<void> _triggerMedicalProtocol(String location) async {
    final logger = Logger('MedicalProtocol');
    try {
      // Implement medical protocol logic here
      logger.info('Medical protocol triggered for location: $location');
    } catch (e, stackTrace) {
      logger.severe('Failed to trigger medical protocol', e, stackTrace);
    }
  }

  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    final logger = Logger('BackgroundHandler');
    final data = message.data;
    final notification = message.notification;

    if (notification != null) {
      logger.info('Background message received');
      logger.info('Title: ${notification.title}');
      logger.info('Body: ${notification.body}');
      logger.info('Data: $data');

      await _storeBackgroundEmergency(data);
      await _showBackgroundNotification(notification, data);
    }
  }

  static Future<void> _storeBackgroundEmergency(
      Map<String, dynamic> data) async {
    final logger = Logger('BackgroundStorage');
    try {
      // Implement your background storage logic here
      logger.info('Background emergency data stored successfully');
    } catch (e, stackTrace) {
      logger.severe('Failed to store background emergency data', e, stackTrace);
    }
  }

  static Future<void> _showBackgroundNotification(
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) async {
    final logger = Logger('BackgroundNotification');
    try {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      const androidChannel = AndroidNotificationChannel(
        'emergency_alerts',
        'Emergency Alerts',
        description: 'High priority alerts for emergency situations',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        sound: RawResourceAndroidNotificationSound('emergency_alert'),
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      const androidDetails = AndroidNotificationDetails(
        'emergency_alerts',
        'Emergency Alerts',
        channelDescription: 'High priority alerts for emergency situations',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        sound: RawResourceAndroidNotificationSound('emergency_alert'),
        playSound: true,
        enableLights: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        ticker: 'Emergency Alert',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'emergency_alert.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
        threadIdentifier: 'emergency_alerts',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: jsonEncode(data),
      );

      logger.info('Background notification shown successfully');
    } catch (e, stackTrace) {
      logger.severe('Failed to show background notification', e, stackTrace);
    }
  }
}
