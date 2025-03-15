//lib/models/emergency_request.dart
//by Sandrine
import 'package:memoryminder/models/emergency_type.dart';

class EmergencyRequest {
  final String id;
  final EmergencyType type;
  final String location;
  final DateTime timestamp;
  final String userId;
  final Map<String, dynamic>? additionalData;

  EmergencyRequest({
    required this.id,
    required this.type,
    required this.location,
    required this.timestamp,
    required this.userId,
    this.additionalData,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString().split('.').last,
        'location': location,
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
        'additionalData': additionalData,
      };

  factory EmergencyRequest.fromJson(Map<String, dynamic> json) {
    return EmergencyRequest(
      id: json['id'],
      type: EmergencyType.values
          .firstWhere((e) => e.toString().split('.').last == json['type']),
      location: json['location'],
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      additionalData: json['additionalData'],
    );
  }
}
