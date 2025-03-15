//lib/ui/home_scree.dart

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memoryminder/models/caregiver.dart';
import 'package:memoryminder/models/emergency_type.dart';
import 'package:memoryminder/models/location_entry.dart' as location_model;
import 'package:memoryminder/services/location_database.dart'
    as location_service;
import 'package:memoryminder/services/caregiver_notification_service.dart';
import 'package:memoryminder/services/emergency_services.dart';
import 'package:memoryminder/viewmodels/emergency_help_viewmodel.dart';
import 'package:memoryminder/widgets/emergency_help_button.dart';
import 'package:memoryminder/ui/assistant_screen.dart';
import 'package:memoryminder/ui/audio_screen.dart';
import 'package:memoryminder/ui/gallery_screen.dart';
import 'package:memoryminder/ui/location_history_screen.dart';
import 'package:memoryminder/ui/profile_screen.dart';
import 'package:memoryminder/ui/response_screen.dart';
import 'package:memoryminder/ui/tour_screen.dart';
import 'package:memoryminder/src/camera_manager.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';

class HomeScreen extends StatefulWidget {
  final EmergencyHelpViewModel? _viewModel;
  final CaregiverNotificationService? _notificationService;
  // ignore: unused_field
  final EmergencyService? _emergencyService;

  const HomeScreen({
    super.key,
    EmergencyHelpViewModel? viewModel,
    CaregiverNotificationService? notificationService,
    EmergencyService? emergencyService,
  })  : _viewModel = viewModel,
        _notificationService = notificationService,
        _emergencyService = emergencyService;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool hasBeenInitialized = false;
  double iconSize = 65;
  location_model.LocationEntry? currentLocationEntry;

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
                await location_service.LocationDatabase.instance
                    .update(currentLocationEntry!);
              }
            }

            final newEntry = location_model.LocationEntry(
              address: address,
              startTime: DateTime.now(),
            );
            final id = await location_service.LocationDatabase.instance
                .create(newEntry);
            newEntry.id = id;
            currentLocationEntry = newEntry;
          }
        }
      } catch (e) {
        debugPrint('Location tracking error: $e');
      }
    });
  }

  Future<String> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final placemark = placemarks.first;
      return "${placemark.street}, ${placemark.locality}";
    } catch (e) {
      debugPrint('Error getting location: $e');
      return "Unknown location";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color(0x00440000),
        elevation: 0.0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/app_icon.png',
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
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
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
      body: Stack(
        children: [
          Container(
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
                        screen: const AssistantScreen(),
                        keyName: "VirtualAssistantButtonKey",
                      ),
                      _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.photo,
                            size: iconSize, color: Colors.black54),
                        text: 'Gallery',
                        screen: const GalleryScreen(),
                        keyName: "GalleryButtonKey",
                      ),
                      _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.search,
                            size: iconSize, color: Colors.black54),
                        text: 'Object Search',
                        screen: const ResponseScreen(),
                        keyName: "VideoRecordingButtonKey",
                      ),
                      _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.mic_rounded,
                            size: iconSize, color: Colors.black54),
                        text: 'Record Audio',
                        screen: const AudioScreen(),
                        keyName: "AudioRecordingButtonKey",
                      ),
                      _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.location_history,
                            size: iconSize, color: Colors.black54),
                        text: 'Location',
                        screen: const LocationHistoryScreen(),
                        keyName: "LocationObjectButtonKey",
                      ),
                      _buildElevatedButton(
                        context: context,
                        icon: Icon(Icons.flag,
                            size: iconSize, color: Colors.black54),
                        text: 'Tour Guide',
                        screen: const TourScreen(),
                        keyName: "TourGuideButtonKey",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: EmergencyHelpButton(
              onPressed: () async {
                if (widget._viewModel == null) {
                  debugPrint('Emergency view model not initialized');
                  return false;
                }

                try {
                  final location = await _getCurrentLocation();

                  // Utiliser le ViewModel pour envoyer la requête d'urgence
                  await widget._viewModel?.sendEmergencyRequest(
                    location: location,
                    userId: '1', // À remplacer par l'ID utilisateur réel
                  );

                  // Notification de secours via le service de notification
                  if (widget._notificationService != null) {
                    final caregiver = Caregiver(
                      userId: '1',
                      lastName: 'Primary Caregiver',
                      phoneNumber: '+1234567890',
                      email: 'caregiver@example.com',
                      firstName: '',
                      relationship: '',
                      fcmToken: '',
                    );

                    await widget._notificationService?.sendEmergencyAlert(
                      caregiver: caregiver,
                      patientLocation: location,
                      emergencyType: EmergencyType.urgent,
                      additionalData: {
                        'timestamp': DateTime.now().toIso8601String(),
                      },
                    );
                  }

                  return true;
                } catch (e) {
                  debugPrint('Emergency request failed: $e');
                  return false;
                }
              },
              buttonText: 'EMERGENCY',
              successMessage: 'Help is on the way!',
              errorMessage: 'Failed to send help request. Please try again.',
            ),
          ),
        ],
      ),
      bottomNavigationBar: UiUtils.createBottomNavigationBar(context),
    );
  }

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
        backgroundColor: const Color(0xFFFFFFFF).withOpacity(0.30),
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
