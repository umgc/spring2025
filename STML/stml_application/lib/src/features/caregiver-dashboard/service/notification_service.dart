// ignore_for_file: avoid_print, prefer_const_constructors
// Imported libraries and packages

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/service/notification_stream_service.dart';


class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    await _messaging.subscribeToTopic("STML_USER_PRESSED_HELP");

    _messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('---------------------------------------------------------------------');
      print('---Received a notification message: ${message.notification?.title}---');
      print('---------------------------------------------------------------------');

      _storeMessage(message);
      await Future.delayed(Duration(seconds: 5));
      getRecentNotifications();
    });

    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  }

  Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    print('---------------------------------------------------------------------');
    print('---Received a background data message-------------------------------');
    print('---------------------------------------------------------------------');
  }

  Future<void> _storeMessage(RemoteMessage message) async {
    print(message.data);
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
}