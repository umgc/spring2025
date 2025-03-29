import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:memoryminder/services/scam_detection_service.dart';
import 'package:memoryminder/ui/scam_detail_screen.dart';

import '../src/features/caregiver-dashboard/service/notification_service.dart';

class ScamDetectionScreen extends StatefulWidget {
  @override
  _ScamDetectionScreenState createState() => _ScamDetectionScreenState();
}

class _ScamDetectionScreenState extends State<ScamDetectionScreen> {
  bool _isScanning = true;
  bool _isScamDetected = false;
  int _scamId = 0;
  final ScamDetectionService _scamDetectionService = ScamDetectionService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _performScan();
  }

  Future<void> _performScan() async {
    var result = await _scamDetectionService.checkPhraseInNotes(); // Check for scam in notes
    if (mounted) {
      setState(() {
        _isScanning = false;
        _isScamDetected = result != 0;
      });
      // If a scam is detected, show an alert dialog
      if (result[_scamId] != 0) {
        _scamId = result.keys.first;
        _notificationService.sendNotificationToFirestore(result[_scamId]!); // Send notification to care giver
        _showAlertDialog(); // Show the alert dialog as pop up to the stml user
      }
    }
  }

  void _stopScan() {
    setState(() {
      _isScanning = false;
    });
   // Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black54),
        title: const Text("Back", style: TextStyle(color: Colors.black54)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isScanning
                    ? const CircularProgressIndicator()
                    : _isScamDetected
                        ? const Icon(Icons.warning, color: Colors.red, size: 50)
                        : const Icon(Icons.check_circle, color: Colors.green, size: 50),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isScanning ? _stopScan : null,
                  child: const Text("Stop Scan")
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

void _showAlertDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          "Scam Detected",
          style: TextStyle(color: Colors.red, fontSize: 34),
        ),
        content: const Text(
          "A potential scam detected in your notes. Would you like to view more details?",
          style: TextStyle(color: Colors.red, fontSize: 24),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              "No",
              style: TextStyle(fontSize: 40), // Increased font size
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScamDetailScreen(scamId: _scamId),
                ),
              ).then((_) {
                Navigator.popUntil(context, (route) => route.isFirst);
              });
            },
            child: const Text(
              "Yes",
              style: TextStyle(fontSize: 40), // Increased font size
            ),
          ),
        ],
      );
    },
  );
}
}
