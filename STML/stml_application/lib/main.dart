import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:memoryminder/services/caregiver_notification_service.dart';
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
  EmergencyHelpViewModel? viewModel;

  try {
    notificationService = CaregiverNotificationService();
    await notificationService.initialize();
    viewModel = EmergencyHelpViewModel(notificationService);

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(
        CaregiverNotificationService.backgroundMessageHandler);
  } catch (e) {
    debugPrint('Service initialization failed: $e');
  }

  runApp(STMLApp(
    notificationService: notificationService,
    viewModel: viewModel,
  ));
}

class STMLApp extends StatelessWidget {
  final CaregiverNotificationService? notificationService;
  final EmergencyHelpViewModel? viewModel;

  const STMLApp({
    super.key,
    this.notificationService,
    this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomePage(
        notificationService: notificationService,
        viewModel: viewModel,
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  final CaregiverNotificationService? notificationService;
  final EmergencyHelpViewModel? viewModel;

  const WelcomePage({
    super.key,
    this.notificationService,
    this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to [STML App]',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Image.asset('assets/welcome_image.png', height: 200),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Navigate to Home Screen with optional services
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(
                        viewModel: viewModel,
                        notificationService: notificationService,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Log In',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 15),
              OutlinedButton(
                onPressed: () {
                  // Navigate to Create Account Page
                  // You can add similar navigation with services for account creation
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: const BorderSide(color: Colors.blue, width: 2),
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 18, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
