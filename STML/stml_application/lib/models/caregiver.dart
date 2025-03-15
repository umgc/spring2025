// lib/models/caregiver.dart
//By Sandrine

import 'user.dart';

/// Represents a caregiver user in the MemoryMinder application
/// Inherits from the base User class as specified in the class diagram
class Caregiver extends User {
  /// Relationship to the STML user (e.g., spouse, child, friend)
  final String relationship;

  /// List of STML users assigned to this caregiver
  final List<String> assignedSTMLUsers;

  /// Alert preferences for patient events
  final Map<String, dynamic> alertPreferences;

  /// Whether the caregiver has camera access permission
  final bool? cameraAccess;

  Caregiver({
    required super.userId,
    required super.firstName,
    required super.lastName,
    required super.email,
    super.phoneNumber,
    required this.relationship,
    this.assignedSTMLUsers = const [],
    this.alertPreferences = const {},
    this.cameraAccess,
    required super.fcmToken,
  }) : super(
          userType: 'Caregiver',
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'relationship': relationship,
      'assignedSTMLUsers': assignedSTMLUsers,
      'alertPreferences': alertPreferences,
      'cameraAccess': cameraAccess,
    };
  }

  factory Caregiver.fromJson(Map<String, dynamic> json) {
    return Caregiver(
      userId: json['userId'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      relationship: json['relationship'],
      assignedSTMLUsers: List<String>.from(json['assignedSTMLUsers'] ?? []),
      alertPreferences:
          Map<String, dynamic>.from(json['alertPreferences'] ?? {}),
      cameraAccess: json['cameraAccess'],
      fcmToken: json['fcmToken'],
    );
  }

  /// Receives alerts for assigned STML users
  Future<void> receiveAlert(String alertType, String stmlUserId) async {
    // Implementation for receiving alerts
  }

  /// Views the current location of an assigned STML user
  Future<void> viewSTMLUserLocation(String stmlUserId) async {
    // Implementation for viewing STML user location
  }
}
