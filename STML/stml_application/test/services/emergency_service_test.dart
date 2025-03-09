import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoryminder/models/emergency_request.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:memoryminder/services/emergency_service.dart';
import 'package:mockito/annotations.dart';
import 'emergency_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('EmergencyService', () {
    late EmergencyService emergencyService;
    late MockClient mockClient;
    const baseUrl = 'http://test-api.com';

    setUp(() {
      mockClient = MockClient();
      emergencyService = EmergencyService(
        baseUrl: baseUrl,
        client: mockClient,
      );
    });

    test('createEmergencyRequest creates request successfully', () async {
      final uri = Uri.parse('$baseUrl/api/emergency');

      when(mockClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'id': '123',
              'type': 'help',
              'location': 'test',
              'timestamp': DateTime.now().toIso8601String(),
              'userId': 'user123',
              'additionalData': null
            }),
            201,
          ));

      final result = await emergencyService.createEmergencyRequest(
        type: EmergencyType.help,
        location: 'test',
        userId: 'user123',
      );

      verify(mockClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: anyNamed('body'),
      )).called(1);

      expect(result.id, '123');
      expect(result.type, EmergencyType.help);
      expect(result.location, 'test');
      expect(result.userId, 'user123');
    });

    test('createEmergencyRequest handles errors', () async {
      final uri = Uri.parse('$baseUrl/api/emergency');

      when(mockClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Server Error', 500));

      expect(
        () => emergencyService.createEmergencyRequest(
          type: EmergencyType.help,
          location: 'test',
          userId: 'user123',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
