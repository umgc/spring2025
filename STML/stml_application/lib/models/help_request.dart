import 'package:memoryminder/models/caregiver.dart';

enum EmergencyType {
  help,
  medical,
  fall,
}

class HelpRequest {
  final String id;
  final String patientId;
  final EmergencyType type;
  final DateTime timestamp;
  final String location;
  final List<Caregiver> notifiedCaregivers;
  final bool isActive;
  final Map<String, dynamic>? additionalData;

  HelpRequest({
    required this.id,
    required this.patientId,
    required this.type,
    required this.timestamp,
    required this.location,
    this.notifiedCaregivers = const [],
    this.isActive = true,
    this.additionalData,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'type': type.toString().split('.').last,
        'timestamp': timestamp.toIso8601String(),
        'location': location,
        'notifiedCaregivers':
            notifiedCaregivers.map((c) => c.toJson()).toList(),
        'isActive': isActive,
        'additionalData': additionalData,
      };

  factory HelpRequest.fromJson(Map<String, dynamic> json) {
    return HelpRequest(
      id: json['id'],
      patientId: json['patientId'],
      type: EmergencyType.values
          .firstWhere((e) => e.toString().split('.').last == json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'],
      notifiedCaregivers: (json['notifiedCaregivers'] as List)
          .map((c) => Caregiver.fromJson(c))
          .toList(),
      isActive: json['isActive'],
      additionalData: json['additionalData'],
    );
  }
}
