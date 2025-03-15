import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/widgets.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/eula_screen.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/welcome_screen.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:memoryminder/src/features/stml_user_dashboard/presentation/stml_user_dashboard.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memoryminder/src/camera_manager.dart';
import 'package:memoryminder/src/data_service.dart';
import 'package:memoryminder/src/s3_connection.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/permission_manager.dart';
import 'package:memoryminder/location_permission_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/registration_screen.dart';
import 'package:firebase_core/firebase_core.dart';



// New function to check and request location permissions
Future<void> checkAndRequestPermissions() async {
  PermissionStatus status = await Permission.location.status;

  if (status.isGranted) {
    print("✅ Location permission already granted.");
    return;
  }

  // If permission is denied, request it
  if (status.isDenied) {
    PermissionStatus newStatus = await Permission.location.request();
    if (newStatus.isGranted) {
      print("✅ User granted location permission.");
      return;
    }
  }
  // If permanently denied, open app settings
  if (status.isPermanentlyDenied) {
    print("⚠️ Location permission permanently denied. Asking user to open settings.");
    openAppSettings();
  }
}




void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  print("✅ Initializing Logging...");
  initializeLogging();

  print("✅ Checking and Requesting Permissions...");
  await checkAndRequestPermissions();

  print("✅ Loading .env file...");
  await dotenv.load(fileName: ".env");

  print("✅ Initializing Directories...");
  await DirectoryManager.instance.initializeDirectories();

  print("✅ Initializing DataService...");
  await DataService.instance.initializeData();

  print("✅ Running initializeData()...");
  initializeData();

  await checkDatabase(); //Check if database is created properly
  print("🚀 Running MyApp...");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully.");
  } catch (e) {  // ✅ Correct try-catch block
    print("❌ Firebase initialization failed: $e");
  }

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
       // You can add other routes as needed
      },
    );
  }
}

// These are all singleton objects and should be initialized at the beginning
void initializeData() async {
  //initialize backend services
  // ignore: unused_local_variable
  S3Bucket s3 = S3Bucket();
  CameraManager cm = CameraManager();
  await PermissionManager.requestInitialPermissions();
  await cm.initializeCamera();
}

Future<void> checkDatabase() async {
  String path = join(await getDatabasesPath(), 'location_history.db');
  bool exists = await databaseFactory.databaseExists(path);

  if (exists) {
    print("✅ Database exists at: $path");
  } else {
    print("❌ Database does NOT exist! Something is wrong.");
  }
}

