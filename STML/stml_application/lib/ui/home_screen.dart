// ignore_for_file: avoid_print, prefer_const_constructors
// Imported libraries and packages

import 'package:memoryminder/ui/response_screen.dart';
import 'package:memoryminder/ui/assistant_screen.dart';
import 'package:memoryminder/ui/audio_screen.dart';
import 'package:memoryminder/ui/gallery_screen.dart';
import 'package:memoryminder/ui/profile_screen.dart';
import 'package:memoryminder/ui/tour_screen.dart';
import 'package:memoryminder/ui/location_history_screen.dart';
import 'package:memoryminder/ui/dementia_resources.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memoryminder/src/camera_manager.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'package:flutter/material.dart';


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
        appBar: AppBar(
          backgroundColor: const Color(0x440000), // Set appbar background color
          elevation: 0.0,
          centerTitle: true, // This centers the title
          automaticallyImplyLeading: false,

          title: Row(
            mainAxisSize: MainAxisSize
                .min, // This ensures the Row takes the least amount of space
            children: [
              Image.asset(
                'assets/icons/app_icon.png', // Replace this with your icon's path
                fit: BoxFit.contain,
                height: 32, // Adjust the size as needed
              ),
              const SizedBox(width: 10), // Spacing between the icon and title
              const Text('CogniOpen',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54)),
            ],
          ),

          // Widgets on the right side of the AppBar
          actions: [
            // First page icon to navigate back
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: Colors.black54,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),

            // First page icon to navigate back
            IconButton(
              icon: const Icon(
                Icons.first_page,
                color: Colors.black54,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        // Main content of the screen
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/background.jpg"),
              fit: BoxFit.cover,
            ),
          ),
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
                      icon: Icon(Icons.handshake_outlined,
                          size: iconSize, color: Colors.black54),
                      text: 'Virtual Assistant',
                      screen: AssistantScreen(),
                      keyName: "VirtualAssistantButtonKey",
                    ),
                    _buildElevatedButton(
                      context: context,
                      icon: Icon(Icons.photo,
                          size: iconSize, color: Colors.black54),
                      text: 'Gallery',
                      screen: GalleryScreen(),
                      keyName: "GalleryButtonKey",
                    ),
                    _buildElevatedButton(
                      context: context,
                      icon: Icon(Icons.search,
                          size: iconSize, color: Colors.black54),
                      text: 'Object Search',
                      screen: ResponseScreen(),
                      keyName: "VideoRecordingButtonKey",
                    ),
                    _buildElevatedButton(
                      context: context,
                      icon: Icon(Icons.mic_rounded,
                          size: iconSize, color: Colors.black54),
                      text: 'Record Audio',
                      screen: AudioScreen(),
                      keyName: "AudioRecordingButtonKey",
                    ),
                    _buildElevatedButton(
                      context: context,
                      icon: Icon(Icons.location_history,
                          size: iconSize, color: Colors.black54),
                      text: 'Location',
                      screen: LocationHistoryScreen(),
                      keyName: "LocationObjectButtonKey",
                    ),
                    _buildElevatedButton(
                      context: context,
                      icon: Icon(Icons.flag,
                          size: iconSize, color: Colors.black54),
                      text: 'Tour Guide',
                      screen: TourScreen(),
                      keyName: "TourGuideButtonKey",
                    ),
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
  }) {
    return ElevatedButton(
      key: Key(keyName),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor:
        const Color(0xFFFFFFFF).withOpacity(0.30), // Button text color
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
              color: Color(0XFF000000),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
