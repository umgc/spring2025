import 'package:flutter/material.dart';
import 'package:memoryminder/services/notification_service.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Help is on the way!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await notificationService.sendHelpNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Help request sent to caregiver.')),
                );
              },
              child: const Text('Send Help Request'),
            ),
          ],
        ),
      ),
    );
  }
}
