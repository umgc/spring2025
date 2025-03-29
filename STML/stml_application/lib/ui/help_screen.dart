import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:memoryminder/services/notification_service.dart';
import 'package:memoryminder/ui/location_history_screen.dart';
import 'package:memoryminder/src/utils/permission_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:async'; // For StreamSubscription

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  bool _helpSent = false;
  String? _requestId;
  String _statusMessage = '';
  StreamSubscription<DocumentSnapshot>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
    _checkPermissions();

    // Log screen view for analytics
    FirebaseAnalytics.instance.logScreenView(
      screenName: 'help_screen',
    );
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    // Check general permissions using the existing PermissionManager
    await PermissionManager.requestInitialPermissions();

    // Additionally check location service
    await PermissionManager.checkIfLocationServiceIsActive(context);

    // Also request notification permission (not covered in PermissionManager)
    await _requestNotificationPermission();
  }

  Future<bool> _requestNotificationPermission() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Notifications Required"),
            content: const Text(
                "Notifications are essential for caregiver alerts. Please enable them in your device settings."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return false;
    }

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  void _subscribeToHelpRequestUpdates(String requestId) {
    _statusSubscription?.cancel();

    _statusSubscription = FirebaseFirestore.instance
        .collection('helpRequests')
        .doc(requestId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      if (snapshot.exists) {
        final status = snapshot.data()?['status'];

        setState(() {
          if (status == 'responded') {
            _statusMessage = 'Your caregiver has confirmed and is on the way!';

            // Log status update received
            FirebaseAnalytics.instance.logEvent(
              name: 'help_request_status_updated',
              parameters: {
                'request_id': requestId,
                'status': status,
              },
            );

            // Show a prominent notification
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your caregiver is on the way!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 10),
              ),
            );
          } else {
            _statusMessage =
                'Help request sent. Waiting for caregiver to respond...';
          }
        });
      }
    });
  }

  Future<void> _sendHelpRequest() async {
    // Check permissions before sending alert
    bool hasGeneralPermissions =
        await PermissionManager.requestInitialPermissions();
    bool hasLocationService =
        await PermissionManager.checkIfLocationServiceIsActive(context);
    bool hasNotificationPermission = await _requestNotificationPermission();

    if (!hasGeneralPermissions ||
        !hasLocationService ||
        !hasNotificationPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Required permissions are missing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _helpSent = false;
      _statusMessage = '';
    });

    try {
      // Get the most recent location entry
      final locations = await LocationDatabase.instance.readAllLocations();
      final currentLocation = locations.isNotEmpty ? locations.first : null;

      // Send the help notification with location data
      final success =
          await _notificationService.sendHelpNotification(currentLocation);

      // Get the request ID from the notification service
      _requestId = _notificationService.lastRequestId;

      if (!mounted) return;

      if (success && _requestId != null) {
        setState(() {
          _helpSent = true;
          _statusMessage =
              'Help request sent. Waiting for caregiver to respond...';
        });

        // Subscribe to updates on this request
        _subscribeToHelpRequestUpdates(_requestId!);

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Help request sent successfully to caregiver.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show failure message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send help request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStatusIndicator() {
    if (!_helpSent) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emergency,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                'Need assistance?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Status indicator (shows when help is sent)
              _buildStatusIndicator(),

              const SizedBox(height: 20),
              _isLoading
                  ? const Column(
                      children: [
                        CircularProgressIndicator(color: Colors.red),
                        SizedBox(height: 10),
                        Text(
                          'Sending emergency alert...',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    )
                  : _helpSent
                      ? ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('SEND ANOTHER ALERT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                          ),
                          onPressed: _sendHelpRequest,
                        )
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.warning_amber_rounded),
                          label: const Text('SEND EMERGENCY ALERT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                          ),
                          onPressed: _sendHelpRequest,
                        ),
              const SizedBox(height: 20),
              const Text(
                'This will send your current location to your caregiver',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),

              if (_helpSent) const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
