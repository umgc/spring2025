// ignore_for_file: avoid_print, prefer_const_constructors
// Imported libraries and packages

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/model/CareRecipient.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/service/notification_stream_service.dart';


class ManageCareRecipientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
  }

  Future<void> createCareRecipient(CareRecipient careRecipient) async {
    await _firestore.collection('careRecipients').add({
      'firstName': careRecipient.firstName,
      'lastName': careRecipient.lastName,
      'location': careRecipient.location,
      'age': careRecipient.age,
    });
    print('Care Recipient added successfully.');
  }

  Future<void> markNotificationAsRead(String messageId) async {
    try {
      DocumentReference notificationRef = _firestore.collection('notifications').doc(messageId);
      await notificationRef.update({'read':true});
      print('Notification updated as read');

    } catch(e) {
      print('Error updating notification data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllCareRecipients() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('careRecipients')
          .orderBy('firstName')
          .get();
      List<Map<String, dynamic>> careRecipients = snapshot.docs.map((doc) {
        return {'id': doc.id,
          'firstName': doc['firstName'],
          'lastName': doc['lastName'],
          'location': doc['location'],
          'age': doc['age'],
        };
      }).toList();
      print('-------${careRecipients.length}');
      return careRecipients;
    } catch(e) {
      print('Error fetching careRecipients $e');
    }
    return [];
  }
}
