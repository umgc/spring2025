import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Debugging

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// ✅ Initialize Firebase Cloud Messaging (FCM) and Local Notifications
  Future<void> initialize() async {
    try {
      debugPrint("🚀 Starting NotificationService Initialization...");

      // ✅ Request permission for notifications (iOS & Android)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint("📌 Notification permission: ${settings.authorizationStatus}");

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint("🚨 Notification permission denied!");
        return;
      }

      // ✅ Get FCM token with error handling
      String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken == null) {
        debugPrint("❌ Failed to retrieve FCM Token!");
      } else {
        debugPrint("✅ FCM Token: $fcmToken");
      }

      // ✅ Handle foreground notifications safely
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("🔔 Foreground Notification: ${message.notification?.title}");
        _showLocalNotification(message);
      });

      // ✅ Ensure background handler is set up correctly
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint("✅ Background message handler registered.");

      // ✅ Initialize Local Notifications (Updated)
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      bool? initSuccess = await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          debugPrint("📲 User tapped on notification: ${response.payload}");
        },
      );

      debugPrint("📲 Local Notifications initialized: $initSuccess");
      debugPrint("✅ NotificationService Initialized Successfully");

    } catch (e, stackTrace) {
      debugPrint("❌ Error initializing NotificationService: $e");
      debugPrint(stackTrace.toString());
    }
  }

  /// 🔔 Show local notification when FCM message is received
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'high_importance_channel', // Channel ID
        'High Importance Notifications', // Channel Name
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotificationsPlugin.show(
        0, // Notification ID
        message.notification?.title ?? "New Notification",
        message.notification?.body ?? "No message body",
        platformChannelSpecifics,
      );

      debugPrint("✅ Local Notification Shown");
    } catch (e) {
      debugPrint("❌ Error showing local notification: $e");
    }
  }

  /// ✅ Send a notification to the caregiver
  Future<void> sendNotificationToCaregiver(String caregiverFcmToken, String title, String body) async {
    try {
      await FirebaseMessaging.instance.sendMessage(
        to: caregiverFcmToken,
        data: {
          "title": title,
          "body": body,
        },
      );
      debugPrint("✅ Notification sent to caregiver.");
    } catch (e) {
      debugPrint("❌ Error sending notification: $e");
    }
  }
}

/// ✅ Background message handler function (Ensure this is outside the class)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("🔕 Background Notification: ${message.notification?.title}");
}
