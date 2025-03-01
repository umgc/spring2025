//only to test SQLite functionality and not clutter main.dart

import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = DatabaseHelper.instance;

  // Insert test data
  await db.insertUser("John Doe", "admin_fcm_token");
  await db.insertSafeZone(37.7749, -122.4194, 500);
  await db.insertLocationHistory(37.7749, -122.4194);

  // Retrieve and print data
  final user = await db.getUser();
  print("User: $user");

  final safeZone = await db.getSafeZone();
  print("Safe Zone: $safeZone");

  final history = await db.getLocationHistory();
  print("Location History: $history");

  // Get user location for testing
  Position? position = await db.getUserLocation();
  if (position != null) {
    print("User's location: ${position.latitude}, ${position.longitude}");
  } else {
    print("Failed to get location.");
  }

  runApp(TestDatabaseApp(position: position, user: user, safeZone: safeZone, history: history));
}
// Display retrieved data in UI
class TestDatabaseApp extends StatelessWidget {
  final Position? position;
  final Map<String, dynamic>? user;
  final Map<String, double>? safeZone;
  final List<Map<String, dynamic>> history;

  TestDatabaseApp({this.position, this.user, this.safeZone, required this.history});



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("SQLite Database Test")),
        body: Padding(
          padding: EdgeInsets.all(20), // ✅ Correct padding placement
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user != null
                      ? "User: ${user!['name']}, Caregiver Token: ${user!['caregiver_token']}"
                      : "No user data found.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 10),
                Text(
                  safeZone != null
                      ? "Safe Zone: \nLat: ${safeZone!['latitude']}, \nLng: ${safeZone!['longitude']}, \nRadius: ${safeZone!['radius']}m"
                      : "No Safe Zone set.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 10),
                Text(
                  position != null
                      ? "Your Location: \nLat: ${position!.latitude}, \nLng: ${position!.longitude}"
                      : "Failed to get location.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 10),
                Text(
                  history.isNotEmpty
                      ? " Last Location Entry: \nLat: ${history.first['latitude']}, \nLng: ${history.first['longitude']}, \nTime: ${history.first['timestamp']}"
                      : " No location history.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
