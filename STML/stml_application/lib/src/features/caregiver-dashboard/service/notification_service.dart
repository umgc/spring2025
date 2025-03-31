// ignore_for_file: avoid_print, prefer_const_constructors
// Imported libraries and packages

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/service/notification_stream_service.dart';



class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _messaging.subscribeToTopic("STML_USER_PRESSED_HELP");

    _messaging.requestPermission(alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('---------------------------------------------------------------------');
      print('---Received a notification message: ${message.notification?.title}---');
      print('---------------------------------------------------------------------');

      _storeMessage(message);
      await Future.delayed(Duration(seconds: 5));
      getRecentNotifications();
      _showLocalNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSinitializationSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(android: androidInitializationSettings, iOS: iOSinitializationSettings);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);


    // Handle initial message when the app is opened from a terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Handle when the app is opened from background state.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

  }

  static void _handleMessage(RemoteMessage message) {
    // Navigate to a specific screen or perform an action based on the notification data.
    print('Handling message: ${message.data}');
    // Example: Navigator.of(navigatorKey.currentContext!).pushNamed('/details', arguments: message.data);
  }



  Future<void> _showLocalNotification(RemoteMessage message) async{
    const AndroidNotificationDetails androidChannelSpecifics = AndroidNotificationDetails('Help', 'Help', channelDescription: 'User pressed Help button', importance: Importance.max, priority: Priority.high, ticker: 'ticker');
    const NotificationDetails channelSpecifics = NotificationDetails(android: androidChannelSpecifics, iOS: const DarwinNotificationDetails());
    await flutterLocalNotificationsPlugin.show(0, message.notification?.title, message.notification?.title, channelSpecifics);

  }

  Future<void> _storeMessage(RemoteMessage message) async {
    await _firestore.collection('notifications').add({
      'title': message.notification?.title,
      'read': false, //Flag to indicate if the message is read or not.
      'createdDate': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markNotificationAsRead(String messageId) async {
    try {
      DocumentReference notificationRef = _firestore.collection('notifications').doc(messageId);
      await notificationRef.update({'read':true});
      print('Notification updated as read');
      getRecentNotifications();

    } catch(e) {
      print('Error updating notification data: $e');
    }
  }

  Future<void> getRecentNotifications() async {
    try {
      NotificationStreamService().dispose();
      QuerySnapshot snapshot = await _firestore.collection('notifications')
          .orderBy('createdDate', descending: true)
          .limit(10)
          .get();
      List<Map<String, dynamic>> notifications = snapshot.docs.map((doc) {
        return {'id': doc.id,
          'title': doc['title'],
          'read': doc['read'],
          'createDate': doc['createdDate'],
        };
      }).toList();
      NotificationStreamService().addData(notifications);
    } catch(e) {
      print('Error fetching notifications $e');
    }
  }

Future<void> sendNotificationToFirestore(String title) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'title': title,
    'read': false, // Mark as unread by default
    'createdDate': FieldValue.serverTimestamp(),
  });

}
}

Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  print('---------------------------------------------------------------------');
  print('---Received a background data message----${message.notification?.title}---------------------------');
  print('---------------------------------------------------------------------');
  await Firebase.initializeApp();

  NotificationService()._storeMessage(message);
  await Future.delayed(Duration(seconds: 5));
  NotificationService().getRecentNotifications();
  NotificationService()._showLocalNotification(message);
}