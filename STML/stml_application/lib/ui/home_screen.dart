// ignore_for_file: avoid_print, prefer_const_constructors
// Imported libraries and packages

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
import 'package:memoryminder/ui/safe_zone_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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



  void _showSafeZoneExitAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Alert"),
        content: const Text("You have exited your safe zone!"),
        actions: [
          // ✅ "Get Directions" Button Now Calls _launchNavigation()
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _launchNavigation();
            },
            child: const Text("Return Me Home"),
          ),

          // "OK" Button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ✅ Launch Google Maps navigation to the safe zone
  Future<void> _launchNavigation() async {
    print("🔹 _launchNavigation started");

    try {
      // Get current user location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double currentLat = position.latitude;
      double currentLng = position.longitude;
      print("📍 Current Location: $currentLat, $currentLng");

      if (homeLatitude != null && homeLongitude != null) {
        // Construct the Google Maps URL for navigation
        final Uri googleMapsUrl = Uri.parse(
          "https://www.google.com/maps/dir/?api=1"
          "&origin=$currentLat,$currentLng"
          "&destination=$homeLatitude,$homeLongitude"
          "&travelmode=driving",
        );

        print("🌍 Generated Google Maps URL: $googleMapsUrl");

        // Try launching Google Maps App first
        final Uri googleMapsAppUrl = Uri.parse(
          "comgooglemaps://?saddr=$currentLat,$currentLng&daddr=$homeLatitude,$homeLongitude&directionsmode=driving",
        );

        if (await canLaunchUrl(googleMapsAppUrl)) {
          print("✅ Opening Google Maps App...");
          await launchUrl(googleMapsAppUrl,
              mode: LaunchMode.externalApplication);
        } else if (await canLaunchUrl(googleMapsUrl)) {
          print("✅ Opening Google Maps in Browser...");
          await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        } else {
          print("❌ Could not open Google Maps.");
        }
      } else {
        print("⚠️ Safe zone coordinates are not set.");
      }
    } catch (e) {
      print("❌ Error launching navigation: $e");
    }
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SafeZoneSettingsScreen()), // ✅ Open Safe Zone Settings
                );
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
          backgroundColor:
              const Color(0x00440000), // Set appbar background color
          elevation: 0.0,
          centerTitle: true, // This centers the title
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icons/app_icon.png', // Replace with your icon's path
                fit: BoxFit.contain,
                height: 32,
              ),
              const SizedBox(width: 10),
              const Text('CogniOpen',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54)),
            ],
          ),
          actions: [
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
            IconButton(
              icon: Icon(Icons.location_on),
              onPressed: () => _showLocationOptions(context),
            ),
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
              Expanded(
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 1.30,
                  padding: const EdgeInsets.all(26.0),
                  children: [
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
                      text: 'Tour Guide',
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
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: UiUtils.createBottomNavigationBar(context));
  }

  // Helper function to create each button for the GridView
  Widget _buildElevatedButton({
    required BuildContext context,
    required Icon icon,
    required String text,
    required Widget screen,
    required String keyName,
    VoidCallback? onTap,
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
