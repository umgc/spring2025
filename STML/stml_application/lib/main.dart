import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseHelper.instance; 

  Future.delayed(Duration(seconds: 1), () {
    db.startSafeZoneTracking(); // Start Safe Zone Tracking after delay
  });
  runApp(STMLApp());
}

class STMLApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomePage(),
    );
  }
}

// Convert WelcomePage to a StatefulWidget (Fixes `initState()` issue)
class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    requestLocationPermission(); // ✅ Request location permission here
  }

//Function to request location permissions
Future<void> requestLocationPermission() async {
  LocationPermission permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied) {
    print("Location permission denied.");
  } else if (permission == LocationPermission.deniedForever) {
    print("Location permission permanently denied. Open settings to enable.");
  } else {
    print("Location permission granted!");
  }
}


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
              Text(
                'Welcome to [STML App]',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Image.asset('assets/welcome_image.png',
                  height: 200), // Add a nice image
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Navigate to Login Page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Log In',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              SizedBox(height: 15),
              OutlinedButton(
                onPressed: () {
                  // Navigate to Create Account Page
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: Colors.blue, width: 2),
                ),
                child: Text('Create Account',
                    style: TextStyle(fontSize: 18, color: Colors.blue)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
