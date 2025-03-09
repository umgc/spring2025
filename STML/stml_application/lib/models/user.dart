// lib/models/user.dart

/// Base class for all user types in the MemoryMinder application
abstract class User {
  /// Unique identifier for the user
  final String userId;

  /// User's first name
  final String firstName;

  /// User's last name
  final String lastName;

  /// User's email address
  final String email;

  /// User's phone number (optional)
  final String? phoneNumber;

  /// Type of user (e.g., 'Caregiver', 'STMLUser', 'Administrator')
  final String userType;

  /// FCM token for push notifications
  final String fcmToken;

  User({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    required this.userType,
    required this.fcmToken,
  });

  /// Convert user data to JSON format
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'userType': userType,
      'fcmToken': fcmToken,
    };
  }

  /// Full name getter
  String get fullName => '$firstName $lastName';
}
