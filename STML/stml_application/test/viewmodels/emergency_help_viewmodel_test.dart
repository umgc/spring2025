import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memoryminder/viewmodels/emergency_help_viewmodel.dart';
import 'package:memoryminder/services/emergency_services.dart';
import 'package:memoryminder/models/emergency_type.dart';
import 'package:memoryminder/models/emergency_request.dart';

void main() {
  group('EmergencyHelpViewModel', () {
    late EmergencyHelpViewModel viewModel;
    late MockEmergencyService mockEmergencyService;

    setUp(() {
      mockEmergencyService = MockEmergencyService();
      viewModel = EmergencyHelpViewModel(mockEmergencyService);
    });

    test('sendEmergencyRequest should call createEmergencyRequest', () async {
      await viewModel.sendEmergencyRequest(
        location: '123 Main St',
        userId: 'user123',
      );

      expect(mockEmergencyService.createEmergencyRequestCalled, true);
    });

    test('sendEmergencyRequest should throw on failure', () async {
      mockEmergencyService = MockEmergencyService(shouldThrow: true);
      viewModel = EmergencyHelpViewModel(mockEmergencyService);

      expect(
        () => viewModel.sendEmergencyRequest(
          location: '123 Main St',
          userId: 'user123',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}

class MockEmergencyService implements EmergencyService {
  bool createEmergencyRequestCalled = false;
  final bool shouldThrow;

  MockEmergencyService({this.shouldThrow = false});

  @override
  final String baseUrl = 'https://api.example.com';

  @override
  final http.Client client = http.Client();

  @override
  Future<EmergencyRequest> createEmergencyRequest({
    required EmergencyType type,
    required String location,
    required String userId,
    Map<String, dynamic>? additionalData,
  }) async {
    createEmergencyRequestCalled = true;
    if (shouldThrow) {
      throw Exception('Failed to create emergency request');
    }
    return EmergencyRequest(
      id: '123',
      type: type,
      location: location,
      timestamp: DateTime.now(),
      userId: userId,
    );
  }

  @override
  Future<void> updateEmergencyStatus({
    required String requestId,
    required String status,
  }) async {
    // Mock implementation
  }

  @override
  Future<void> call911({required String location}) {
    // TODO: implement call911
    throw UnimplementedError();
  }
}
