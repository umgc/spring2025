// test/services/caregiver_notification_service_test.dart

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:memoryminder/services/caregiver_notification_service.dart';
import 'package:memoryminder/models/caregiver.dart';

import 'caregiver_notification_service_test.mocks.dart';

@GenerateMocks([
  http.Client,
  NotificationSettings,
  RemoteMessage,
])
class MockFirebaseMessaging with Mock implements FirebaseMessaging {
  final _messageController = StreamController<RemoteMessage>.broadcast();

  @override
  Future<String?> getToken({String? vapidKey}) async => 'mock_token';

  Stream<RemoteMessage> get onMessage => _messageController.stream;

  void simulateMessage(RemoteMessage message) {
    _messageController.add(message);
  }

  void dispose() {
    _messageController.close();
  }
}

void main() {
  late CaregiverNotificationService notificationService;
  late MockFirebaseMessaging mockFirebaseMessaging;
  late MockClient mockHttpClient;
  late MockNotificationSettings mockSettings;
  late MockRemoteMessage mockMessage;

  const fcmServerUrl = 'YOUR_FIREBASE_CLOUD_FUNCTION_URL';

  setUp(() {
    mockFirebaseMessaging = MockFirebaseMessaging();
    mockHttpClient = MockClient();
    mockSettings = MockNotificationSettings();
    mockMessage = MockRemoteMessage();
    notificationService = CaregiverNotificationService(
      firebaseMessaging: mockFirebaseMessaging,
    );
  });

  group('CaregiverNotificationService', () {
    test('should initialize FCM and request permissions', () async {
      // Arrange
      when(mockFirebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
        provisional: false,
      )).thenAnswer((_) async => mockSettings);

      when(mockSettings.authorizationStatus)
          .thenReturn(AuthorizationStatus.authorized);
      when(mockFirebaseMessaging.getToken())
          .thenAnswer((_) async => 'fake-token');

      // Act
      final result = await notificationService.initialize();

      // Assert
      expect(result, true);
      verify(mockFirebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
        provisional: false,
      )).called(1);
    });

    test('should send emergency notification to caregiver', () async {
      // Arrange
      final caregiver = Caregiver(
        id: 'caregiver123',
        name: 'John Doe',
        fcmToken: 'fake-fcm-token',
      );

      when(mockHttpClient.post(
        argThat(equals(Uri.parse(fcmServerUrl))),
        headers: argThat(isA<Map<String, String>>()),
        body: argThat(isA<String>()),
      )).thenAnswer((_) async => http.Response('{"success": true}', 200));

      // Act
      final result = await notificationService.sendEmergencyAlert(
        caregiver: caregiver,
        patientLocation: 'Home',
        emergencyType: EmergencyType.help,
      );

      // Assert
      expect(result, true);
      verify(mockHttpClient.post(
        Uri.parse(fcmServerUrl),
        headers: argThat(
          predicate<Map<String, String>>((headers) =>
              headers['Content-Type'] == 'application/json' &&
              headers['Authorization'] != null),
        ),
        body: argThat(contains('"type":"emergency"')),
      )).called(1);
    });

    test('should handle FCM token refresh', () async {
      // Arrange
      const newToken = 'new-fcm-token';
      when(mockFirebaseMessaging.getToken()).thenAnswer((_) async => newToken);

      // Act
      final token = await notificationService.refreshToken();

      // Assert
      expect(token, newToken);
      verify(mockFirebaseMessaging.getToken()).called(1);
    });

    test('should handle notification permission denial', () async {
      // Arrange
      when(mockFirebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
        provisional: false,
      )).thenAnswer((_) async => mockSettings);

      when(mockSettings.authorizationStatus)
          .thenReturn(AuthorizationStatus.denied);

      // Act
      final result = await notificationService.initialize();

      // Assert
      expect(result, false);
    });

    test('should handle message configuration', () async {
      // Arrange
      when(mockMessage.messageId).thenReturn('test-message');
      when(mockMessage.data).thenReturn({'type': 'emergency'});

      final messageStream = Stream<RemoteMessage>.fromIterable([mockMessage]);
      when(mockFirebaseMessaging.onMessage).thenAnswer((_) => messageStream);

      // Act
      notificationService.configureMessageHandling();

      // Assert
      verify(mockFirebaseMessaging.onMessage);
    });

    test('should handle failed emergency alert sending', () async {
      // Arrange
      final caregiver = Caregiver(
        id: 'caregiver123',
        name: 'John Doe',
        fcmToken: 'fake-fcm-token',
      );

      when(mockHttpClient.post(
        argThat(equals(Uri.parse(fcmServerUrl))),
        headers: argThat(isA<Map<String, String>>()),
        body: argThat(isA<String>()),
      )).thenAnswer((_) async => http.Response('{"error": "Failed"}', 400));

      // Act
      final result = await notificationService.sendEmergencyAlert(
        caregiver: caregiver,
        patientLocation: 'Home',
        emergencyType: EmergencyType.help,
      );

      // Assert
      expect(result, false);
    });

    test('should handle token refresh failure', () async {
      // Arrange
      when(mockFirebaseMessaging.getToken()).thenAnswer((_) async => null);

      // Act
      final token = await notificationService.refreshToken();

      // Assert
      expect(token, null);
      verify(mockFirebaseMessaging.getToken()).called(1);
    });
  });
}
