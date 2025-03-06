// lib/models/caregiver.dart

class Caregiver {
  final String id;
  final String name;
  final String fcmToken;

  Caregiver({
    required this.id,
    required this.name,
    required this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fcmToken': fcmToken,
    };
  }

  factory Caregiver.fromMap(Map<String, dynamic> map) {
    return Caregiver(
      id: map['id'],
      name: map['name'],
      fcmToken: map['fcmToken'],
    );
  }
}
