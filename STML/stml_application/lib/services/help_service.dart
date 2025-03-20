import 'package:firebase_messaging/firebase_messaging.dart';

class HelpService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> sendHelpNotification() async {
    // Remplacez 'caregiver_device_token' par le token du soignant
    await _firebaseMessaging.sendMessage(
      to: 'caregiver_device_token',
      data: {
        'type': 'help_request',
        'message': 'The STML user has requested help.',
      },
    );
  }
}
