// ignore_for_file: avoid_print, prefer_const_constructors
// Imported libraries and packages

import 'package:memoryminder/src/features/account_creation_and_login/presentation/login_screen.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/app_bar.dart';
import 'package:memoryminder/src/features/help/presentation/help_screen.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/presentation/audio_screen.dart';
import 'package:memoryminder/src/features/gallery/presentation/gallery_screen.dart';
import 'package:memoryminder/src/features/scam_detection/presentation/scam_detection_screen.dart';
import 'package:memoryminder/src/camera_manager.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'package:flutter/material.dart';


// Main HomeScreen widget which is a stateless widget.
class STMLUserDashboardScreen extends StatefulWidget {
  @override
  _STMLUserDashboardScreenState createState() => _STMLUserDashboardScreenState();
}

class _STMLUserDashboardScreenState extends State<STMLUserDashboardScreen> {
  bool hasBeenInitialized = false;
  double iconSize = 65;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  _initializeCamera() {
    if (!hasBeenInitialized) {
      CameraManager cm = CameraManager();
      cm.startAutoRecording();
      hasBeenInitialized = true;
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
          title: 'My Dashboard',
        ),
        // Main content of the screen
        body: Container(

          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16.0, 140, 16.0, 25),
                child: Text(
                  'Helping you remember the important things.\n Choose a feature to get started!',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Grid view to display multiple options/buttons

              Expanded(
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 1.30,
                  padding: const EdgeInsets.all(26.0),
                  children: [
                    // Using the helper function to build each button in the grid
                    _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.home_filled,
                            size: iconSize, color: Colors.black54),
                        text: 'Take Me Home',
                        screen: LoginScreen(),
                        keyName: "TakeMeHomeButtonKey",
                        backgroundColor:
                            const Color(0xFF000000).withOpacity(0.30)),
                    _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.sos_sharp,
                            size: iconSize, color: Colors.black54),
                        text: 'HELP',
                        screen: HelpScreen(),
                        keyName: "HelpButtonKey",
                        backgroundColor: const Color(0xFFFFFFFF).withOpacity(0.30),
                    ),
                    _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.photo,
                            size: iconSize, color: Colors.black54),
                        text: 'Gallery',
                        screen: GalleryScreen(),
                        keyName: "GalleryButtonKey",
                        backgroundColor:
                            const Color(0xFFFFFFFF).withOpacity(0.30)),
                    _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.search,
                            size: iconSize, color: Colors.black54),
                        text: 'My Tasks',
                        screen: LoginScreen(),
                        keyName: "MyTasksButtonKey",
                        backgroundColor:
                            const Color(0xFFFFFFFF).withOpacity(0.30)),
                    _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.mic_rounded,
                            size: iconSize, color: Colors.black54),
                        text: 'Record Notes / Audio',
                        screen: AudioScreen(),
                        keyName: "AudioRecordingButtonKey",
                        backgroundColor:
                            const Color(0xFFFFFFFF).withOpacity(0.30)),
                    _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.warning_amber_rounded,
                            size: iconSize, color: Colors.black54),
                        text: 'Scam Detection',
                        screen: ScamDetectionScreen(),
                        keyName: "potentialScamScanner",
                        backgroundColor:
                            const Color(0xFFFFFFFF).withOpacity(0.30)),
                    _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.health_and_safety_outlined,
                            size: iconSize, color: Colors.black54),
                        text: 'My Health',
                        routeName: '/healthMetrics',
                        keyName: "healthMetrics",
                        backgroundColor:
                            const Color(0xFFFFFFFF).withOpacity(0.30)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom navigation bar with multiple options for quick navigation
        bottomNavigationBar: UiUtils.createBottomNavigationBar(context));
  }


  // Helper function to create each button for the GridView
  Widget _buildElevatedButton({
    required BuildContext context,
    required Icon icon,
    required String text,
    Widget? screen,
    String? routeName,
    required String keyName,
    required Color backgroundColor,
  }) {
    return ElevatedButton(
      key: Key(keyName),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.lightBlue[100],
        padding: const EdgeInsets.all(16.0),
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      onPressed: () {
        if (routeName != null) {
          Navigator.pushNamed(context, routeName); // Use named route if provided
        }
        else if (screen != null)
        {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen), // Default behavior
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 10.0),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
