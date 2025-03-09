import 'dart:convert' show jsonEncode;
import 'package:flutter_test/flutter_test.dart';
import 'package:memoryminder/models/help_request.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:memoryminder/services/help_request_service.dart';
import 'package:memoryminder/services/caregiver_notification_service.dart';
import 'help_request_service_test.mocks.dart' as mocks;
import 'package:memoryminder/models/emergency_type.dart';

// Generate mock classes for testing
@GenerateMocks([http.Client, CaregiverNotificationService])
void main() {
  // Test service instances
  late HelpRequestService helpRequestService;
  late mocks.MockClient mockClient;
  late mocks.MockCaregiverNotificationService mockNotificationService;

  // Base URL for API calls
  const baseUrl = 'http://test-api.com';

  // Setup method runs before each test
  setUp(() {
    mockClient = mocks.MockClient();
    mockNotificationService = mocks.MockCaregiverNotificationService();
    helpRequestService = HelpRequestService(
      baseUrl: baseUrl,
      client: mockClient,
      notificationService: mockNotificationService,
    );
  });

  group('HelpRequestService Tests', () {
    test(
        'createHelpRequest should successfully create request and notify caregivers',
        () async {
      // Test data setup
      const userId = 'user123';
      const location = 'Home';
      final emergencyType = EmergencyType.help;

      // Mock HTTP POST response for help request creation
      when(mockClient.post(
        Uri.parse('$baseUrl/api/help-requests'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'id': 'request123',
              'userId': userId,
              'location': location,
              'emergencyType': 'help',
              'timestamp': DateTime.now().toIso8601String(),
              'status': 'pending',
              'notifiedCaregiverIds': [],
            }),
            201,
          ));

      // Mock HTTP GET response for fetching caregivers
      when(mockClient.get(
        Uri.parse('$baseUrl/api/users/$userId/caregivers'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode([
              {
                'id': 'caregiver123',
                'firstName': 'John',
                'lastName': 'Doe',
                'userId': 'cg123',
                'fcmToken': 'fake-token',
                'phoneNumber': '+1234567890',
                'email': 'john.doe@example.com'
              }
            ]),
            200,
          ));

      // Mock notification service response
      when(mockNotificationService.sendEmergencyAlert(
        caregiver: anyNamed('caregiver'),
        patientLocation: anyNamed('patientLocation'),
        emergencyType: anyNamed('emergencyType'),
      )).thenAnswer((_) async => true);

      // Execute the method being tested
      final result = await helpRequestService.createHelpRequest(
        userId: userId,
        location: location,
        emergencyType: emergencyType,
      );

      // Verify the results
      expect(result.id, 'request123');
      expect(result.userId, userId);
      expect(result.location, location);
      expect(result.emergencyType, emergencyType);
      expect(result.status, HelpRequestStatus.pending);

      // Verify notification was sent
      verify(mockNotificationService.sendEmergencyAlert(
        caregiver: anyNamed('caregiver'),
        patientLocation: location,
        emergencyType: emergencyType,
      )).called(1);
    });

    test('createHelpRequest should handle API errors appropriately', () async {
      // Test data
      const userId = 'user123';
      const location = 'Home';
      final emergencyType = EmergencyType.help;

      // Mock failed API response
      when(mockClient.post(
        Uri.parse('$baseUrl/api/help-requests'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Server Error', 500));

      // Verify error handling
      expect(
        () => helpRequestService.createHelpRequest(
          userId: userId,
          location: location,
          emergencyType: emergencyType,
        ),
        throwsA(isA<HelpRequestException>()),
      );
    });

    test('updateRequestStatus should successfully update status', () async {
      // Test data
      const requestId = 'request123';
      const newStatus = HelpRequestStatus.inProgress;

      // Mock successful status update
      when(mockClient.patch(
        Uri.parse('$baseUrl/api/help-requests/$requestId'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('', 200));

      // Execute and verify no exceptions
      await expectLater(
        helpRequestService.updateRequestStatus(requestId, newStatus),
        completes,
      );
    });

    test('updateRequestStatus should handle errors', () async {
      // Test data
      const requestId = 'request123';
      const newStatus = HelpRequestStatus.inProgress;

      // Mock failed status update
      when(mockClient.patch(
        Uri.parse('$baseUrl/api/help-requests/$requestId'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Error', 400));

      // Verify error handling
      expect(
        () => helpRequestService.updateRequestStatus(requestId, newStatus),
        throwsA(isA<HelpRequestException>()),
      );
    });
  });
}
