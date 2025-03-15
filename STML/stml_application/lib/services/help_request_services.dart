// By Sandrine

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:logging/logging.dart';
import '../models/caregiver.dart';
import 'caregiver_notification_service.dart';
import 'package:memoryminder/models/emergency_type.dart';

enum HelpRequestStatus { pending, inProgress, completed, cancelled }

class HelpRequest {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String location;
  final EmergencyType emergencyType;
  final HelpRequestStatus status;
  final List<String> notifiedCaregiverIds;

  HelpRequest({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.location,
    required this.emergencyType,
    this.status = HelpRequestStatus.pending,
    this.notifiedCaregiverIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'location': location,
        'emergencyType': emergencyType.toString().split('.').last,
        'status': status.toString().split('.').last,
        'notifiedCaregiverIds': notifiedCaregiverIds,
      };

  factory HelpRequest.fromJson(Map<String, dynamic> json) {
    return HelpRequest(
      id: json['id'],
      userId: json['userId'],
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'],
      emergencyType: EmergencyType.values.firstWhere(
          (e) => e.toString().split('.').last == json['emergencyType']),
      status: HelpRequestStatus.values
          .firstWhere((s) => s.toString().split('.').last == json['status']),
      notifiedCaregiverIds: List<String>.from(json['notifiedCaregiverIds']),
    );
  }
}

class HelpRequestService {
  // Logger instance for this class
  final Logger _logger = Logger('HelpRequestService');

  final String baseUrl;
  final http.Client _client;
  final CaregiverNotificationService _notificationService;

  HelpRequestService({
    required this.baseUrl,
    http.Client? client,
    CaregiverNotificationService? notificationService,
  })  : _client = client ?? http.Client(),
        _notificationService =
            notificationService ?? CaregiverNotificationService() {
    // Initialize logging configuration
    _initializeLogging();
  }

  // Initialize logging with custom configuration
  void _initializeLogging() {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      // Custom log format with timestamp and level
      final timestamp = record.time.toIso8601String();
      final message = '[$timestamp] ${record.level.name}: ${record.message}';

      // Use developer.log instead of print
      developer.log(
        message,
        time: record.time,
        level: record.level.value,
        name: record.loggerName,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    });
  }

  // Create a new help request
  Future<HelpRequest> createHelpRequest({
    required String userId,
    required String location,
    required EmergencyType emergencyType,
  }) async {
    try {
      _logger.info('Creating help request for user: $userId');

      final response = await _client.post(
        Uri.parse('$baseUrl/api/help-requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode({
          'userId': userId,
          'location': location,
          'emergencyType': emergencyType.toString().split('.').last,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        final helpRequest = HelpRequest.fromJson(jsonDecode(response.body));
        _logger.info(
            'Help request created successfully with ID: ${helpRequest.id}');
        await _notifyCaregivers(helpRequest);
        return helpRequest;
      } else {
        _logger.severe(
            'Failed to create help request. Status code: ${response.statusCode}');
        throw HelpRequestException(
            'Failed to create help request: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error creating help request', e, stackTrace);
      throw HelpRequestException('Error creating help request: $e');
    }
  }

  // Update the status of an existing help request
  Future<void> updateRequestStatus(
    String requestId,
    HelpRequestStatus status,
  ) async {
    try {
      _logger
          .info('Updating request status: $requestId to ${status.toString()}');

      final response = await _client.patch(
        Uri.parse('$baseUrl/api/help-requests/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode({
          'status': status.toString().split('.').last,
        }),
      );

      if (response.statusCode != 200) {
        _logger.severe(
            'Failed to update request status. Status code: ${response.statusCode}');
        throw HelpRequestException(
            'Failed to update request status: ${response.statusCode}');
      }

      _logger.info('Request status updated successfully');
    } catch (e, stackTrace) {
      _logger.severe('Error updating request status', e, stackTrace);
      throw HelpRequestException('Error updating request status: $e');
    }
  }

  // Notify all assigned caregivers about the help request
  Future<void> _notifyCaregivers(HelpRequest request) async {
    final caregivers = await _fetchAssignedCaregivers(request.userId);
    _logger.info(
        'Notifying ${caregivers.length} caregivers for request: ${request.id}');

    for (final caregiver in caregivers) {
      try {
        await _notificationService.sendEmergencyAlert(
          caregiver: caregiver,
          patientLocation: request.location,
          emergencyType: request.emergencyType,
        );
        _logger.info('Successfully notified caregiver: ${caregiver.userId}');
      } catch (e, stackTrace) {
        _logger.warning(
            'Failed to notify caregiver ${caregiver.userId}', e, stackTrace);
        // Continue notifying other caregivers even if one fails
      }
    }
  }

  // Fetch list of assigned caregivers for a user
  Future<List<Caregiver>> _fetchAssignedCaregivers(String userId) async {
    try {
      _logger.info('Fetching assigned caregivers for user: $userId');

      final response = await _client.get(
        Uri.parse('$baseUrl/api/users/$userId/caregivers'),
        headers: {
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final caregivers =
            data.map((json) => Caregiver.fromJson(json)).toList();
        _logger.info('Successfully fetched ${caregivers.length} caregivers');
        return caregivers;
      } else {
        _logger.severe(
            'Failed to fetch caregivers. Status code: ${response.statusCode}');
        throw HelpRequestException(
            'Failed to fetch caregivers: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error fetching caregivers', e, stackTrace);
      throw HelpRequestException('Error fetching caregivers: $e');
    }
  }

  // Get authentication token - Implementation placeholder
  Future<String> _getAuthToken() async {
    // Implement proper authentication token retrieval here!
    return 'auth-token';
  }
}

class HelpRequestException implements Exception {
  final String message;
  HelpRequestException(this.message);

  @override
  String toString() => message;
}
