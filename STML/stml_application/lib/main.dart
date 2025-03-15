//With my modifications

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:memoryminder/services/caregiver_notification_service.dart';
import 'package:memoryminder/services/emergency_service.dart';
import 'package:memoryminder/ui/home_screen.dart';
import 'package:memoryminder/views_model/emergency_help_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize services with null-safety
  CaregiverNotificationService? notificationService;
  EmergencyService? emergencyService;
  EmergencyHelpViewModel? viewModel;

  try {
    // Initialize Emergency Service
    emergencyService = EmergencyService(baseUrl: 'YOUR_API_BASE_URL');

    // Initialize Notification Service
    notificationService = CaregiverNotificationService();
    await notificationService.initialize();

    // Initialize ViewModel with Emergency Service
    viewModel = EmergencyHelpViewModel(emergencyService);

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(
        CaregiverNotificationService.backgroundMessageHandler);
  } catch (e) {
    debugPrint('Service initialization failed: $e');
  }

  runApp(MemoryMinderApp(
    notificationService: notificationService,
    emergencyService: emergencyService,
    viewModel: viewModel,
  ));
}

class MemoryMinderApp extends StatelessWidget {
  final CaregiverNotificationService? notificationService;
  final EmergencyService? emergencyService;
  final EmergencyHelpViewModel? viewModel;

  const MemoryMinderApp({
    super.key,
    this.notificationService,
    this.emergencyService,
    this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Minder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WelcomePage(
        notificationService: notificationService,
        emergencyService: emergencyService,
        viewModel: viewModel,
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  final CaregiverNotificationService? notificationService;
  final EmergencyService? emergencyService;
  final EmergencyHelpViewModel? viewModel;

  const WelcomePage({
    super.key,
    this.notificationService,
    this.emergencyService,
    this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to Memory Minder',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Image.asset(
                  'assets/welcome_image.png',
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(
                          viewModel: viewModel,
                          notificationService: notificationService,
                          emergencyService: emergencyService,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                OutlinedButton(
                  onPressed: () {
                    // TODO: Implement account creation navigation
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
