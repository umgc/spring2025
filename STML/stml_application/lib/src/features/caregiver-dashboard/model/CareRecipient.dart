import 'package:memoryminder/src/features/caregiver-dashboard/presentation/add_care_recipient.dart';

class CareRecipient {
  final String firstName;
  final String lastName;
  final String? location;
  final int? age;
  final List<EmergencyContact> emergencyContacts;

  CareRecipient({
    required this.firstName,
    required this.lastName,
    this.location,
    this.age,
    required this.emergencyContacts,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'location': location,
      'age': age,
      'emergencyContacts': emergencyContacts
    };
  }

  // Convert a Map into a LocationDataModel
  static CareRecipient fromMap(Map<String, dynamic> map) {
    return CareRecipient(
      firstName: map['firstName'],
      lastName: map['lastName'],
      location: map['location'],
      age: map['age'],
      emergencyContacts: map['emergencyContacts'],
    );
  }
}