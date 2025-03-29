import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:memoryminder/ui/location_history_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  String? _caregiverToken;
  String? _lastRequestId;

  String? get lastRequestId => _lastRequestId;

  Future<void> initialize() async {
    // Get the FCM token for the current device
    _caregiverToken = await _firebaseMessaging.getToken();
    print("Caregiver Token: $_caregiverToken");

    // Log token generation for analytics
    await _analytics.logEvent(
      name: 'fcm_token_generated',
      parameters: {
        'user_type': 'caregiver',
      },
    );

    // Listen for new tokens (in case the token changes)
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _caregiverToken = newToken;
      print("New Caregiver Token: $_caregiverToken");

      // Log token refresh for analytics
      _analytics.logEvent(
        name: 'fcm_token_refreshed',
        parameters: {
          'user_type': 'caregiver',
        },
      );
    });

    // Configure local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Listen for incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Message received: ${message.notification?.title}");
      _showNotification(message);

      // Log message received for analytics
      _analytics.logEvent(
        name: 'notification_received',
        parameters: {
          'notification_type': message.data['type'] ?? 'unknown',
          'has_notification': message.notification != null,
        },
      );
    });
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // Notification channel ID
      'your_channel_name', // Notification channel name
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      message.notification?.title, // Notification title
      message.notification?.body, // Notification body
      platformChannelSpecifics,
    );

    // Log notification shown for analytics
    await _analytics.logEvent(
      name: 'notification_displayed',
      parameters: {
        'notification_title': message.notification?.title ?? 'No title',
      },
    );
  }

  Future<bool> sendHelpNotification(LocationEntry? currentLocationEntry) async {
    try {
      // Start timer for performance tracking
      final startTime = DateTime.now();

      // Prepare location data
      Map<String, dynamic>? locationData;

      if (currentLocationEntry != null) {
        try {
          // Try to get the current coordinates
          Position currentPosition = await Geolocator.getCurrentPosition();

          // Create the data map with the stored address and current coordinates
          locationData = {
            'address': currentLocationEntry.address,
            'latitude': currentPosition.latitude,
            'longitude': currentPosition.longitude,
            'timestamp': currentLocationEntry.startTime.toIso8601String()
          };

          // Log successful location capture
          await _analytics.logEvent(
            name: 'emergency_location_captured',
            parameters: {
              'method': 'geolocator',
              'has_coordinates': true,
            },
          );
        } catch (e) {
          // Log location error
          await _analytics.logEvent(
            name: 'emergency_location_error',
            parameters: {
              'error_type': 'geolocator_error',
              'error_message': e.toString(),
            },
          );

          // Fallback: try to geocode the address to get coordinates
          try {
            List<Location> locations =
                await locationFromAddress(currentLocationEntry.address);
            if (locations.isNotEmpty) {
              locationData = {
                'address': currentLocationEntry.address,
                'latitude': locations.first.latitude,
                'longitude': locations.first.longitude,
                'timestamp': currentLocationEntry.startTime.toIso8601String()
              };

              // Log successful geocoding
              await _analytics.logEvent(
                name: 'emergency_location_captured',
                parameters: {
                  'method': 'geocoding',
                  'has_coordinates': true,
                },
              );
            } else {
              // If geocoding fails, only send the address
              locationData = {
                'address': currentLocationEntry.address,
                'timestamp': currentLocationEntry.startTime.toIso8601String()
              };

              // Log geocoding with no results
              await _analytics.logEvent(
                name: 'emergency_location_captured',
                parameters: {
                  'method': 'geocoding',
                  'has_coordinates': false,
                },
              );
            }
          } catch (e) {
            // Log geocoding error
            await _analytics.logEvent(
              name: 'emergency_location_error',
              parameters: {
                'error_type': 'geocoding_error',
                'error_message': e.toString(),
              },
            );

            // As a last resort, only send the address
            locationData = {
              'address': currentLocationEntry.address,
              'timestamp': currentLocationEntry.startTime.toIso8601String()
            };
          }
        }
      } else {
        // Log no location available
        await _analytics.logEvent(
          name: 'emergency_location_missing',
        );
      }

      // Call the Cloud Function
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('sendHelpAlert');
      final result = await callable.call({
        'caregiverToken': _caregiverToken,
        'location': locationData,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'userName': FirebaseAuth.instance.currentUser?.displayName
      });

      // Save the request ID for later reference
      _lastRequestId = result.data['requestId'];

      // Calculate time taken
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      // Create parameters map without nullable values
      final Map<String, Object> analyticsParams = {
        'success': result.data['success'] ?? false,
        'has_location': currentLocationEntry != null,
        'processing_time_ms': duration,
      };

      // Add requestId only if it's not null
      if (_lastRequestId != null) {
        analyticsParams['request_id'] = _lastRequestId!;
      }

      // Log complete event with success/failure
      await _analytics.logEvent(
        name: 'emergency_alert_sent',
        parameters: analyticsParams,
      );

      return result.data['success'] ?? false;
    } catch (e) {
      print("Error sending notification: $e");

      // Log error event
      await _analytics.logEvent(
        name: 'emergency_alert_error',
        parameters: {
          'error_message': e.toString(),
        },
      );

      return false;
    }
  }
}
