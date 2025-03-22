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
    List<Map<String,dynamic>>? emergencyContactsMap = careRecipient.emergencyContacts?.map((obj)=> obj.toMap()).toList();

    await _firestore.collection('careRecipients').add({
      'firstName': careRecipient.firstName,
      'lastName': careRecipient.lastName,
      'address': careRecipient.address,
      'city': careRecipient.city,
      'state': careRecipient.state,
      'county': careRecipient.county,
      'email': careRecipient.email,
      'phone': careRecipient.phone,
      'age': careRecipient.age,
      'emergencyContacts': emergencyContactsMap
    });
    print('Care Recipient added successfully.');
  }

  Future<void> updateCareRecipient(String? careRecipientId, CareRecipient careRecipient) async {
    List<Map<String,dynamic>>? emergencyContactsMap = careRecipient.emergencyContacts?.map((obj)=> obj.toMap()).toList();

    try {
      DocumentReference notificationRef = _firestore.collection('careRecipients').doc(careRecipientId);
      await notificationRef.update({'firstName': careRecipient.firstName,
        'lastName': careRecipient.lastName,
        'address': careRecipient.address,
        'city': careRecipient.city,
        'state': careRecipient.state,
        'county': careRecipient.county,
        'email': careRecipient.email,
        'phone': careRecipient.phone,
        'age': careRecipient.age,
        'emergencyContacts': emergencyContactsMap});
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
          'address': doc['address'],
          'city': doc['city'],
          'state': doc['state'],
          'county': doc['county'],
          'email': doc['email'],
          'phone': doc['phone'],
          'age': doc['age'],
          'emergencyContacts': doc['emergencyContacts'],
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