// ignore_for_file: avoid_print, prefer_const_constructors
// Imported libraries and packages

import 'package:memoryminder/src/features/caregiver-dashboard/presentation/caregiver-dashboard.dart';
import 'package:memoryminder/ui/dementia_resources.dart';
import 'package:memoryminder/ui/response_screen.dart';
import 'package:memoryminder/ui/assistant_screen.dart';
import 'package:memoryminder/ui/audio_screen.dart';
import 'package:memoryminder/ui/gallery_screen.dart';
import 'package:memoryminder/ui/profile_screen.dart';
import 'package:memoryminder/ui/tour_screen.dart';
import 'package:memoryminder/ui/location_history_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memoryminder/src/camera_manager.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:memoryminder/database_helper.dart';

// Main HomeScreen widget which is a stateless widget.
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool hasBeenInitialized = false;
  double iconSize = 65;

  // User-defined safe zone variables
  double? homeLatitude;
  double? homeLongitude;
  double safeZoneRadius = 100; // Default radius in meters

  // To keep track of the current location
  LocationEntry? currentLocationEntry;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadSafeZone();
    _listenToLocationChanges();
  }

  // ✅ Load safe zone from database when the app starts
  Future<void> _loadSafeZone() async {
    final safeZone = await DatabaseHelper.instance.getSafeZone();
    if (safeZone != null) {
      setState(() {
        homeLatitude = safeZone['latitude'];
        homeLongitude = safeZone['longitude'];
        safeZoneRadius = safeZone['radius'];
      });
    }
  }

  //✅ Open a dialog for user to set a safe zone
  void _setSafeZone() async {
    TextEditingController latController = TextEditingController();
    TextEditingController longController = TextEditingController();
    TextEditingController radiusController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Safe Zone"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(labelText: "Latitude"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: longController,
              decoration: const InputDecoration(labelText: "Longitude"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: radiusController,
              decoration: const InputDecoration(labelText: "Radius (meters)"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                homeLatitude = double.tryParse(latController.text);
                homeLongitude = double.tryParse(longController.text);
                safeZoneRadius = double.tryParse(radiusController.text) ?? 100;
              });

              // ✅ Save to database
              await DatabaseHelper.instance.saveSafeZone(
                homeLatitude!,
                homeLongitude!,
                safeZoneRadius,
              );

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ✅ Show an alert when user leaves the safe zone
  void _showSafeZoneExitAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Alert"),
        content: const Text("You have exited your safe zone!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showLocationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.history, color: Colors.blueAccent),
              title: Text("View Location History"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LocationHistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shield, color: Colors.green),
              title: Text("Set Safe Zone"),
              onTap: () {
                Navigator.pop(context);
                _setSafeZone(); // ✅ Open Safe Zone dialog
              },
            ),
          ],
        );
      },
    );
  }

  _initializeCamera() {
    if (!hasBeenInitialized) {
      CameraManager cm = CameraManager();
      cm.startAutoRecording();
      hasBeenInitialized = true;
    }
  }

  bool _alertTriggered = false; // Prevent repeated alerts

  Future<void> _listenToLocationChanges() async {
    final locationStream = Geolocator.getPositionStream();

    locationStream.listen((Position position) async {
      try {
        double userLat = position.latitude;
        double userLong = position.longitude;

        // ✅ Reverse geocoding to get address
        List<Placemark> placemarks =
            await placemarkFromCoordinates(userLat, userLong);
        if (placemarks.isNotEmpty) {
          final Placemark placemark = placemarks.first;
          final address =
              "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.isoCountryCode}";

          // ✅ Check if the location has changed before updating database
          if (currentLocationEntry == null ||
              currentLocationEntry!.address != address) {
            if (currentLocationEntry != null &&
                currentLocationEntry!.endTime == null) {
              currentLocationEntry!.endTime = DateTime.now();
              await LocationDatabase.instance.update(currentLocationEntry!);
            }

            final newEntry =
                LocationEntry(address: address, startTime: DateTime.now());
            final id = await LocationDatabase.instance.create(newEntry);
            newEntry.id = id;
            currentLocationEntry = newEntry;
          }
        }

        // ✅ Safe Zone Check
        if (homeLatitude != null && homeLongitude != null) {
          double distance = Geolocator.distanceBetween(
              userLat, userLong, homeLatitude!, homeLongitude!);

          if (distance > safeZoneRadius) {
            if (!_alertTriggered) {
              print("🚨 User has left the safe zone!");
              _showSafeZoneExitAlert();
              _alertTriggered = true; // Prevent multiple alerts
            }
          } else {
            _alertTriggered =
                false; // Reset alert when user returns to safe zone
          }
        }
      } catch (e) {
        print("❌ Error in location tracking: $e");
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
            // ✅ Safe Zone Button
            IconButton(
              icon: const Icon(Icons.shield, color: Colors.black54),
              onPressed: _setSafeZone, // Opens safe zone input dialog
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
                      onTap: () =>
                          _showLocationOptions(context), // ✅ Open options menu
                    ),
                    _buildElevatedButton(
                      context: context,
                      icon: Icon(Icons.flag,
                          size: iconSize, color: Colors.black54),
                      text: 'Free Tour',
                      screen: TourScreen(),
                      keyName: "TourGuideButtonKey",
                    ),
                    _buildElevatedButton(
                      context: context,
                      icon: Icon(Icons.bookmark_outline,
                          size: iconSize, color: Colors.black54),
                      text: 'Dementia Resources',
                      screen: DementiaResourcesScreen(),
                      keyName: "DementiaResourcesButtonKey",
                    ),
                    _buildElevatedButton(
                      context: context,
                      icon: Icon(Icons.bookmark_outline,
                          size: iconSize, color: Colors.black54),
                      text: 'Caregiver Dashboard',
                      screen: CaregiverDashboardScreen(),
                      keyName: "DementiaResourcesButtonKey",
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
    VoidCallback? onTap, // ✅ Allow custom action when button is tapped
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
      onPressed: onTap ??
          () {
            // ✅ If onTap is null, default to navigation
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
