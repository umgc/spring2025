// lib/services/emergency_services.dart
// Author: Sandrine

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // To handle phone calls
import '../models/emergency_request.dart';
import 'package:memoryminder/models/emergency_type.dart';

class EmergencyService {
  final String baseUrl;
  final http.Client client;

  EmergencyService({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  /// Creates an emergency request and sends the data to the backend
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

  /// Updates the status of an emergency request
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

  /// Triggers an emergency call to 911
  Future<void> call911({required String location}) async {
    try {
      // Phone number format for the emergency call
      const phoneNumber = '911';
      final url = 'tel:$phoneNumber';

      // Checks if the application can launch the call
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw EmergencyServiceException(
            'Could not launch call to $phoneNumber');
      }

      // Sends emergency data to the backend (optional)
      await createEmergencyRequest(
        type: EmergencyType.urgent,
        location: location,
        userId: 'currentUserId', // Replace with the current user's ID
        additionalData: {
          'callInitiated': true,
          'location': location,
        },
      );
    } catch (e) {
      throw EmergencyServiceException('Error calling 911: $e');
    }
  }
}

class EmergencyServiceException implements Exception {
  final String message;
  EmergencyServiceException(this.message);

  @override
  String toString() => message;
}
