// lib/models/caregiver.dart
import 'package:memoryminder/models/user.dart';

class Caregiver extends User {
  final String relationship;
  final List<String> assignedSTMLUsers;
  final Map<String, bool> alertPreferences;
  final bool cameraAccess;
  final bool enableEmergencyNotifications;
  final bool enableLocationSharing;
  final bool enableCameraAccess;
  final String preferredLanguage;

  Caregiver({
    required super.userId,
    required super.firstName,
    required super.lastName,
    required super.email,
    super.phoneNumber,
    required this.relationship,
    this.assignedSTMLUsers = const [],
    this.alertPreferences = const {},
    this.cameraAccess = false,
    required super.fcmToken,
    this.enableEmergencyNotifications = true,
    this.enableLocationSharing = true,
    this.enableCameraAccess = false,
    required this.preferredLanguage,
  }) : super(userType: 'Caregiver');

  factory Caregiver.fromJson(Map<String, dynamic> json) => Caregiver(
        userId: json['userId'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        phoneNumber: json['phoneNumber'],
        relationship: json['relationship'],
        assignedSTMLUsers: List<String>.from(json['assignedSTMLUsers'] ?? []),
        alertPreferences:
            Map<String, bool>.from(json['alertPreferences'] ?? {}),
        cameraAccess: json['cameraAccess'] ?? false,
        fcmToken: json['fcmToken'],
        enableEmergencyNotifications:
            json['enableEmergencyNotifications'] ?? true,
        enableLocationSharing: json['enableLocationSharing'] ?? true,
        enableCameraAccess: json['enableCameraAccess'] ?? false,
        preferredLanguage: json['preferredLanguage'] ?? 'en',
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'relationship': relationship,
        'assignedSTMLUsers': assignedSTMLUsers,
        'alertPreferences': alertPreferences,
        'cameraAccess': cameraAccess,
        'enableEmergencyNotifications': enableEmergencyNotifications,
        'enableLocationSharing': enableLocationSharing,
        'enableCameraAccess': enableCameraAccess,
        'preferredLanguage': preferredLanguage,
      };
}
