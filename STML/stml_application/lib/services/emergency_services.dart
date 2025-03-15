//lib/services/emergency_services.dart
//Autor: Sandrine

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/emergency_request.dart';
import 'package:memoryminder/models/emergency_type.dart';

class EmergencyService {
  final String baseUrl;
  final http.Client client;

  EmergencyService({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<EmergencyRequest> createEmergencyRequest({
    required EmergencyType type,
    required String location,
    required String userId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/emergency'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'type': type.toString().split('.').last,
          'location': location,
          'timestamp': DateTime.now().toIso8601String(),
          'userId': userId,
          'additionalData': additionalData,
        }),
      );

      if (response.statusCode == 201) {
        return EmergencyRequest.fromJson(jsonDecode(response.body));
      } else {
        throw EmergencyServiceException(
            'Failed to create emergency request: ${response.statusCode}');
      }
    } catch (e) {
      throw EmergencyServiceException('Error creating emergency request: $e');
    }
  }

  Future<void> updateEmergencyStatus({
    required String requestId,
    required String status,
  }) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/api/emergency/$requestId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      if (response.statusCode != 200) {
        throw EmergencyServiceException(
            'Failed to update emergency status: ${response.statusCode}');
      }
    } catch (e) {
      throw EmergencyServiceException('Error updating emergency status: $e');
    }
  }
}

class EmergencyServiceException implements Exception {
  final String message;
  EmergencyServiceException(this.message);

  @override
  String toString() => message;
}
