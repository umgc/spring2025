// ignore_for_file: avoid_print, prefer_const_constructors
// Imported libraries and packages

import 'package:memoryminder/src/features/caregiver-dashboard/presentation/app_bar.dart';
import 'package:memoryminder/src/features/help/help_screen.dart';
import 'package:memoryminder/ui/response_screen.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/presentation/audio_screen.dart';
import 'package:memoryminder/ui/gallery_screen.dart';
import 'package:memoryminder/ui/profile_screen.dart';
import 'package:memoryminder/ui/scam_detection_screen.dart';
import 'package:memoryminder/ui/location_history_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memoryminder/src/camera_manager.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:memoryminder/features/caregiver_task_management/caregiver_task_screen.dart';
import 'package:memoryminder/ui/safe_zone_settings_screen.dart';
import 'package:memoryminder/src/safe_zone_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memoryminder/ui/ReturnMeHome.dart';

// Main HomeScreen widget which is a stateless widget.
class STMLUserDashboardScreen extends StatefulWidget {
  @override
  _STMLUserDashboardScreenState createState() =>
      _STMLUserDashboardScreenState();
}

class _STMLUserDashboardScreenState extends State<STMLUserDashboardScreen> {
  bool hasBeenInitialized = false;
  double iconSize = 65;

  // To keep track of the current location
  LocationEntry? currentLocationEntry;
  bool hasAlertBeenShown = false;

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

  _listenToLocationChanges() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("❌ Location permission denied.");
        return; // Exit if still denied
      }
    }
    final locationStream = Geolocator.getPositionStream();

    locationStream.listen((Position position) async {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final Placemark placemark = placemarks.first;
          final address =
              "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.isoCountryCode}";

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

        final safeZoneManager = SafeZoneManager();
        final isOutside = await safeZoneManager.isUserOutsideSafeZone();

        if (isOutside && !hasAlertBeenShown) {
          hasAlertBeenShown = true;
          await _notifyCaregiverOfSafeZoneExit(position);
          _sendSafeZoneAlertToFirestore();
          _showLeftSafeZoneNotification(context);
        }
      } catch (e) {
        print('❌ Location update error: $e');
      }
    });
  }

  void _sendSafeZoneAlertToFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': "User left their safe zone",
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'safe_zone_exit',
        // Optionally include more info:
        'userId': 'user_123', // Replace with actual user ID if available
        'message': 'The STML user exited their designated safe zone.',
      });
      print('🚨 Safe zone exit alert sent to Firestore');
    } catch (e) {
      print('❌ Error sending alert: $e');
    }
  }

  void _showLeftSafeZoneNotification(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("You've Left Your Safe Zone"),
          content: const Text(
              "Your caregiver has been notified. Do you need help getting home?"),
          actions: [
            TextButton(
                child: const Text("No"),
                onPressed: () {
                  if (Navigator.of(context, rootNavigator: true).canPop()) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                },
              ),
            TextButton(
              child: const Text("Yes"),
              onPressed: () {
                setState(() {
                  hasAlertBeenShown = false;
                });
                Navigator.of(context).pop();
                Navigator.of(context, rootNavigator: true)
                    .pushNamed('/returnMeHome');
              },
            ),
          ],
        );
      },
    );
  }

  // Notify caregiver in Firestore when user exits safe zone
  Future<void> _notifyCaregiverOfSafeZoneExit(Position position) async {
    try {
      //Gets the current user's safe zone document
      final safeZoneQuery = await FirebaseFirestore.instance
          .collection('safe_zones')
          .limit(1)
          .get();

      if (safeZoneQuery.docs.isEmpty) {
        print("❌ No safe zone found for this user.");
        return;
      }

      final safeZoneDoc = safeZoneQuery.docs.first;
      final data = safeZoneDoc.data();

        if (!data.containsKey('careRecipientId') || data['careRecipientId'] == null) {
          print("❌ careRecipientId is missing in the safe zone document.");
          return;
        }
      final careRecipientId = data['careRecipientId'];

      // Updates that care recipient’s Firestore record
      await FirebaseFirestore.instance
          .collection('careRecipients')
          .doc(careRecipientId)
          .set({
        'lastKnownLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Exited Safe Zone',
        },
        'needsAssistance': true,
      }, SetOptions(merge: true));

      print("📍 Caregiver updated for: $careRecipientId");
    } catch (e) {
      print('❌ Error notifying caregiver: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const CustomAppBar(
        title: 'My Dashboard',
      ),
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
                    // adding return me home button 
                    _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.home_filled,
                        size: iconSize, color: Colors.black54),
                        text: 'Take Me Home',
                        screen: ProfileScreen(),
                        keyName: "TakeMeHomeButtonKey",
                        backgroundColor: 
                            const Color(0xFF000000).withOpacity(0.30),
                      // below may cause conflicts - commented out for now
                        //onPressedOverride: () {
                        //showModalBottomSheet(
                    // Using the helper function to build each button in the grid
                    _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.home_filled,
                            size: iconSize, color: Colors.black54),
                        text: 'Take Me Home',
                        screen: ReturnMeHomePage(),
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
                        routeName: '/healthMetrics',
                        keyName: "healthMetrics",
                        backgroundColor:
                            const Color(0xFFFFFFFF).withOpacity(0.30)),
                    _buildElevatedButton(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (BuildContext context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  leading: const Icon(Icons.directions_walk),
                                  title: const Text('Return Me Home'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.of(context, rootNavigator: true)
                                        .pushNamed('/returnMeHome');
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.shield),
                                  title: const Text('Set Safe Zone'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.of(context, rootNavigator: true)
                                        .pushNamed('/safeZoneSettings');
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
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
                    backgroundColor: const Color(0xFFFFFFFF).withOpacity(0.30),
                  ),
                  _buildElevatedButton(
                    context: context,
                    icon: Icon(Icons.search,
                        size: iconSize, color: Colors.black54),
                    text: 'My Tasks',
                    screen: ResponseScreen(),
                    keyName: "MyTasksButtonKey",
                    backgroundColor: const Color(0xFFFFFFFF).withOpacity(0.30),
                  ),
                  _buildElevatedButton(
                    context: context,
                    icon: Icon(Icons.mic_rounded,
                        size: iconSize, color: Colors.black54),
                    text: 'Record Notes / Audio',
                    screen: AudioScreen(),
                    keyName: "AudioRecordingButtonKey",
                    backgroundColor: const Color(0xFFFFFFFF).withOpacity(0.30),
                  ),
                  _buildElevatedButton(
                    context: context,
                    icon: Icon(Icons.warning_amber_rounded,
                        size: iconSize, color: Colors.black54),
                    text: 'Scam Detection',
                    screen: ScamDetectionScreen(),
                    keyName: "potentialScamScanner",
                    backgroundColor: const Color(0xFFFFFFFF).withOpacity(0.30),
                  ),
                  _buildElevatedButton(
                    context: context,
                    icon: Icon(Icons.health_and_safety_outlined,
                        size: iconSize, color: Colors.black54),
                    text: 'My Health',
                    routeName: '/healthMetrics',
                    keyName: "healthMetrics",
                    backgroundColor: const Color(0xFFFFFFFF).withOpacity(0.30),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: UiUtils.createBottomNavigationBar(context),
    );
  }

  // Helper function to create each button for the GridView
  Widget _buildElevatedButton({
    required BuildContext context,
    required Icon icon,
    required String text,
    Widget? screen,
    String? routeName,
    VoidCallback? onPressedOverride,
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
        if (onPressedOverride != null) {
          onPressedOverride!(); // ✅ Use the override logic
        } else if (routeName != null) {
          Navigator.pushNamed(context, routeName);
        } else if (screen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
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
