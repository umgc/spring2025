import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memoryminder/services/emergency_services.dart';
import 'package:memoryminder/models/emergency_type.dart';

void main() {
  group('EmergencyService', () {
    late EmergencyService emergencyService;
    late http.Client mockClient;

    setUp(() {
      mockClient = MockClient((request) async {
        if (request.url.toString().contains('/api/emergency')) {
          return http.Response(
            jsonEncode({
              'id': '123',
              'type': 'urgent',
              'location': '123 Main St',
              'timestamp': '2025-03-01T12:00:00Z',
              'userId': 'user123',
              'additionalData': null,
            }),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });
      emergencyService = EmergencyService(
          baseUrl: 'https://api.example.com', client: mockClient);
    });

    test('createEmergencyRequest should return EmergencyRequest on success',
        () async {
      final request = await emergencyService.createEmergencyRequest(
        type: EmergencyType.urgent,
        location: '123 Main St',
        userId: 'user123',
      );

      expect(request.id, '123');
      expect(request.type, EmergencyType.urgent);
      expect(request.location, '123 Main St');
      expect(request.userId, 'user123');
    });

    test('createEmergencyRequest should throw on failure', () async {
      mockClient = MockClient((request) async {
        return http.Response('Error', 500);
      });
      emergencyService = EmergencyService(
          baseUrl: 'https://api.example.com', client: mockClient);

      expect(
        () => emergencyService.createEmergencyRequest(
          type: EmergencyType.urgent,
          location: '123 Main St',
          userId: 'user123',
        ),
        throwsA(isA<EmergencyServiceException>()),
      );
    });
  });
}

class MockClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest) handler;

  MockClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes), // Correction ici
      response.statusCode,
      contentLength: response.contentLength,
      request: request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
