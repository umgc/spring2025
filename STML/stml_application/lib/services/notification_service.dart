import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _caregiverToken;

  Future<void> initialize() async {
    // Récupérer le token FCM de l'appareil actuel
    _caregiverToken = await _firebaseMessaging.getToken();
    print("Caregiver Token: $_caregiverToken");

    // Écouter les nouveaux tokens (au cas où le token change)
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _caregiverToken = newToken;
      print("New Caregiver Token: $_caregiverToken");
    });

    // Configurer les notifications locales
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Écouter les messages entrants
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Message reçu: ${message.notification?.title}");
      _showNotification(message);
    });
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // ID du canal de notification
      'your_channel_name', // Nom du canal de notification
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0, // ID de la notification
      message.notification?.title, // Titre de la notification
      message.notification?.body, // Corps de la notification
      platformChannelSpecifics,
    );
  }

  Future<void> sendHelpNotification() async {
    if (_caregiverToken == null) {
      print("Caregiver token is not available.");
      return;
    }

    // Envoyer une notification au soignant
    await _firebaseMessaging.sendMessage(
      to: _caregiverToken!,
      data: {
        'type': 'help_request',
        'message': 'The STML user has requested help.',
      },
    );
  }
}
