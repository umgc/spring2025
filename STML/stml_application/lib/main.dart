import 'package:flutter/material.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/eula_screen.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/welcome_screen.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/service/notification_service.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:memoryminder/src/features/stml_user_dashboard/presentation/stml_user_dashboard.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memoryminder/src/camera_manager.dart';
import 'package:memoryminder/src/data_service.dart';
import 'package:memoryminder/src/s3_connection.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/permission_manager.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/registration_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:memoryminder/features/caregiver_task_management/caregiver_task_screen.dart';

void main() async {
  initializeLogging();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  await DirectoryManager.instance.initializeDirectories();
  await DataService.instance.initializeData();
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
          '/welcomeScreen', // The initial screen when the application starts
      routes: {
        '/welcomeScreen': (context) => WelcomeScreem(),
        '/loginScreen': (context) => LoginScreen(),
        '/registrationScreen': (context) => RegistrationScreen(),
        '/eulaScreen': (context) => EulaScreen(),
        '/homeScreen': (context) => HomeScreen(),
        '/caregiverTaskScreen': (context) => CaregiverTaskScreen(), // Added route
      },
    );
  }
}

// Initialize backend services
void initializeData() async {
  S3Bucket s3 = S3Bucket();
  CameraManager cm = CameraManager();
  await PermissionManager.requestInitialPermissions();
  await cm.initializeCamera();
  NotificationService().initialize();
}
