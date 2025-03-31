import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

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

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/user_data.txt');
  }

  Future<String> readUserData() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      return contents;
    } catch (e) {
      return '';
    }
  }


  // Function to call emergency services
  Future<void> callEmergencyServices() async {
    // Replace with your country's emergency number, e.g., "112" or "911"
    final status = await Permission.phone.request();
    print(status);
    final Uri launchUri = Uri(scheme: 'tel', path: '411');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print('Could not launch $launchUri'); // This is where your log likely comes from
    }
  }
  Future<void> sendNotificationToCaregiver() async {
    print("------------Sending notification");
    String title = '';
    String data = await readUserData();
    List<String> details = data.split(', ');
    if (details.length >= 3) {
      title = '${details[0]} called for HELP!';
    }

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
        'title': title,
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

