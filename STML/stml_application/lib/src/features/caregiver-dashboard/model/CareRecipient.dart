import 'package:memoryminder/src/features/caregiver-dashboard/model/emergency_contact.dart';

class CareRecipient {
  final String firstName;
  final String lastName;
  final String? address;
  final String? city;
  final String? state;
  final String? county;
  final String? email;
  final String? phone;
  final int? age;
  final List<EmergencyContact>? emergencyContacts;

  CareRecipient({
    required this.firstName,
    required this.lastName,
    this.address,
    this.city,
    this.state,
    this.county,
    this.email,
    this.phone,
    this.age,
    required this.emergencyContacts,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'address': address,
      'city': city,
      'state': state,
      'county': county,
      'email': email,
      'phone': phone,
      'age': age,
      'emergencyContacts': emergencyContacts
    };
  }

  // Convert a Map into a LocationDataModel
  static CareRecipient fromMap(Map<String, dynamic> map) {
    return CareRecipient(
      firstName: map['firstName'],
      lastName: map['lastName'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      county: map['county'],
      email: map['email'],
      phone: map['phone'],
      age: map['age'],
      emergencyContacts: (map['emergencyContacts'] as List<dynamic>?)
          ?.map((item) => EmergencyContact.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

