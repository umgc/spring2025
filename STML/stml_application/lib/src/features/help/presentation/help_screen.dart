import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class HelpScreen extends StatefulWidget {
  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  void initState() {
    super.initState();
    // Call the emergency service when the screen is loaded
    callEmergencyServices();
    sendNotificationToCaregiver();
  }

  // Function to call emergency services
  Future<void> callEmergencyServices() async {
    // Replace with your country's emergency number, e.g., "112" or "911"
    const emergencyNumber = 'tel:2023861943'; // Example emergency number

    // Check if the URL can be launched (i.e., the phone dialer is available)
    if (await canLaunch(emergencyNumber)) {
      await launch(emergencyNumber);
    } else {
      // Show an error message if the dialer cannot be launched
      print("Cannot place a call.");
    }
  }
  Future<void> sendNotificationToCaregiver() async {
    print("------------Sending notification");
    // The URL for the Firebase Function
    var url = Uri.parse(
        'https://us-central1-spring2025-81f5b.cloudfunctions.net/sendNotification');

    // Send the notification request to Firebase Function
    var response = await http.post(
      url,
      body: {
        'topic': 'STML_USER_PRESSED_HELP',
        // The topic you want to send the notification to
        'message': 'USER called for HELP!',
        'title': 'USER called for HELP!',
        // The message you want to send
      },
    );

    if (response.statusCode == 200) {
      print("Notification sent successfully!");
    } else {
      print("Failed to send notification.");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the background color for the entire screen
        extendBodyBehindAppBar: true,
        extendBody: true,
        // Setting up the app bar at the top of the screen
        appBar: const CustomAppBar(
          title: 'HELP',
        ),
        // Main content of the screen
        body: Container(

          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(50.0, 250, 16.0, 25),
                child: Text('HELP is on the way!!!',
                  style: TextStyle(
                    fontSize: 30.0,
                    color: Colors.red,
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Grid view to display multiple options/buttons


            ],
          ),
        ),
    bottomNavigationBar: UiUtils.createBottomNavigationBar(context));
  }

}

