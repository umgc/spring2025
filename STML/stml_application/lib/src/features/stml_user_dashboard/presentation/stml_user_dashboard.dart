// ignore_for_file: avoid_print, prefer_const_constructors
// Imported libraries and packages

import 'package:memoryminder/services/notification_service.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/app_bar.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/caregiver-dashboard.dart';
import 'package:memoryminder/ui/dementia_resources.dart';
import 'package:memoryminder/ui/help_screen.dart';
import 'package:memoryminder/ui/response_screen.dart';
import 'package:memoryminder/ui/assistant_screen.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/presentation/audio_screen.dart';
import 'package:memoryminder/ui/gallery_screen.dart';
import 'package:memoryminder/ui/profile_screen.dart';
import 'package:memoryminder/ui/scam_detection_screen.dart';
import 'package:memoryminder/ui/tour_screen.dart';
import 'package:memoryminder/ui/location_history_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memoryminder/src/camera_manager.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:memoryminder/features/caregiver_task_management/caregiver_task_screen.dart';

// Main HomeScreen widget which is a stateless widget.
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool hasBeenInitialized = false;
  double iconSize = 65;

  // To keep track of the current location
  LocationEntry? currentLocationEntry;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _listenToLocationChanges();
  }

  _initializeCamera() {
    if (!hasBeenInitialized) {
      CameraManager cm = CameraManager();
      cm.startAutoRecording();
      hasBeenInitialized = true;
    }
  }

  _listenToLocationChanges() {
    final locationStream = Geolocator.getPositionStream();
    locationStream.listen((Position position) async {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final Placemark placemark = placemarks.first;
          final address =
              "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.isoCountryCode}";

          if (currentLocationEntry == null ||
              currentLocationEntry!.address != address) {
            if (currentLocationEntry != null) {
              if (currentLocationEntry!.endTime == null) {
                currentLocationEntry!.endTime = DateTime.now();
                await LocationDatabase.instance.update(currentLocationEntry!);
              }
            }

            final newEntry =
                LocationEntry(address: address, startTime: DateTime.now());
            final id = await LocationDatabase.instance.create(newEntry);
            newEntry.id = id;
            currentLocationEntry = newEntry;
          }
        }
      } catch (e) {
        print(e);
      }
    });
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
                        screen: ProfileScreen(),
                        keyName: "TakeMeHomeButtonKey",
                        backgroundColor:
                            const Color(0xFF000000).withOpacity(0.30)),
                    _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.help_outline,
                            size: iconSize, color: Colors.white),
                        text: 'HELP',
                        screen: HelpScreen(),
                        keyName: "HelpButtonKey",
                        backgroundColor: Colors.red.withOpacity(0.80)),
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
                        screen: ResponseScreen(),
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
                        screen: TourScreen(),
                        keyName: "TourGuideButtonKey",
                        backgroundColor:
                            const Color(0xFFFFFFFF).withOpacity(0.30)),
                    _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.task_alt,
                            size: iconSize, color: Colors.black54),
                        text: 'Caregiver Tasks',
                        screen: CaregiverTaskScreen(),
                        keyName: "CaregiverTaskButtonKey",
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
    required Widget screen,
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
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
