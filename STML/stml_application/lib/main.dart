import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitbitter/fitbitter.dart';
import 'package:flutter/material.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/eula_screen.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/welcome_screen.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/service/notification_service.dart';
import 'package:memoryminder/src/features/caregiver_task_management/presentation/caregiver_task_screen.dart';
import 'package:memoryminder/src/features/common/service/s3_connection.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:memoryminder/src/features/stml_user_dashboard/presentation/stml_user_dashboard.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memoryminder/src/camera_manager.dart';
import 'package:memoryminder/src/data_service.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/permission_manager.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/registration_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:memoryminder/src/features/wearable-integration/health_dashboard.dart';
import 'package:memoryminder/src/features/wearable-integration/fitbit_login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

void main() async {
  initializeLogging();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  await DirectoryManager.instance.initializeDirectories();
  await DataService.instance.initializeData();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  initializeData();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MemoryMinder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute:
          '/loginScreen', // The initial screen when the application starts
      routes: {
        '/welcomeScreen': (context) => WelcomeScreen(),
        '/loginScreen': (context) => LoginScreen(),
        '/registrationScreen': (context) => RegistrationScreen(),
        '/eulaScreen': (context) => EulaScreen(),
        '/homeScreen': (context) => STMLUserDashboardScreen(),
        '/caregiverTaskScreen': (context) =>
            CaregiverTaskScreen(), // Added route
        '/healthMetrics': (context) => FutureBuilder<FitbitCredentials?>(
          future: _loadFitbitCredentials(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(); // Show a loader while checking token
            }
            if (snapshot.hasData && snapshot.data != null) {
              return HealthDashboard(fitbitCredentials: snapshot.data!);
            }
            return FitbitLoginPage();
          },
        ),
      },
    );
  }
}

// Initialize backend services
void initializeData() async {
  //initialize backend services
  // ignore: unused_local_variable
  S3Service s3 = S3Service();
  CameraManager cm = CameraManager();
  await PermissionManager.requestInitialPermissions();
  await cm.initializeCamera();
  NotificationService().initialize();
}

// Handle notifications when the app is in the background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("⚠️ Background message: ${message.notification?.title}");
}

Future<FitbitCredentials?> _loadFitbitCredentials() async {
  String? storedAccessToken = await storage.read(key: 'fitbitAccessToken');
  String? storedRefreshToken = await storage.read(key: 'fitbitRefreshToken');
  String? storedUserId = await storage.read(key: 'fitbitUserId');

  if (storedAccessToken != null &&
      storedRefreshToken != null &&
      storedUserId != null) {
    return FitbitCredentials(
      fitbitAccessToken: storedAccessToken,
      fitbitRefreshToken: storedRefreshToken,
      userID: storedUserId,
    );
  }
  return null;
}