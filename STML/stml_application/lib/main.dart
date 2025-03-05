import 'package:flutter/material.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:memoryminder/ui/home_screen.dart';
import 'package:memoryminder/ui/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memoryminder/src/camera_manager.dart';
import 'package:memoryminder/src/data_service.dart';
import 'package:memoryminder/src/s3_connection.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/permission_manager.dart';
import 'package:memoryminder/ui/caregiver_task_screen.dart'; // Added import

void main() async {
  initializeLogging();
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
      title: 'CogniOpen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/loginScreen', // App starts at the login screen
      routes: {
        '/loginScreen': (context) => LoginScreen(),
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
}
