// will be used to manages SQLite database (tables & helper functions)
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io'; 
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class DatabaseHelper 
{
  static final DatabaseHelper instance =  DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();
  
  Future<Database> get database async {
    if (_database !=null) return _database!;
    _database = await _initDB('safeguard.db');
    return _database!; 
  }

   Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        caregiver_token TEXT NOT NULL
      );
    ''');
  

    await db.execute('''
      CREATE TABLE safe_zone (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius REAL NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE location_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp TEXT NOT NULL
      );
    ''');
    }
  
  // Correctly placed Safe Zone Tracking function
  void startSafeZoneTracking() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      checkSafeZone().then((status) {
        print("Safe Zone Check: $status");
      });
    });
  }



   //Get user's gps location
  Future<Position?> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return null;
    }
  // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permission denied.");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permission permanently denied. Open settings to enable.");
      return null;
    }

    // Get the user's current location
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

String _lastStatus = "Unknown"; // Keep track of the last status

Future<String> checkSafeZone() async {
  Position? userPosition = await getUserLocation();
  Map<String, double>? safeZone = await getSafeZone();

  if (userPosition == null) return "Unable to get user location.";
  if (safeZone == null) return "Safe Zone not set.";

  double distance = Geolocator.distanceBetween(
    userPosition.latitude, userPosition.longitude,
    safeZone['latitude']!, safeZone['longitude']!,
  );

  await insertLocationHistory(userPosition.latitude, userPosition.longitude);

  String newStatus = (distance > safeZone['radius']!) ? "🚨 User has LEFT the Safe Zone!" : "✅ User is INSIDE the Safe Zone.";

  //  Only log if the status changes (prevents duplicate logs)
  if (newStatus != _lastStatus) {
    print("Safe Zone Status Changed: $newStatus");
    _lastStatus = newStatus;  // Update last status
  }

  return newStatus;
}



  // Insert User (STML User + Caregiver Token)
  Future<int> insertUser(String name, String caregiverToken) async {
    final db = await instance.database;
    return await db.insert(
      'users',
      {'name': name, 'caregiver_token': caregiverToken},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert Safe Zone (Home Area)
  Future<int> insertSafeZone(double latitude, double longitude, double radius) async {
    final db = await instance.database;
    return await db.insert(
      'safe_zone',
      {'latitude': latitude, 'longitude': longitude, 'radius': radius},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert Location History (Track movement)
  Future<int> insertLocationHistory(double latitude, double longitude) async {
    final db = await instance.database;
    String timestamp = DateTime.now().toIso8601String();
    return await db.insert(
      'location_history',
      {'latitude': latitude, 'longitude': longitude, 'timestamp': timestamp},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Retrieve User
  Future<Map<String, dynamic>?> getUser() async {
    final db = await instance.database;
    final result = await db.query('users', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  // Retrieve Safe Zone
  Future<Map<String, double>?> getSafeZone() async {
    final db = await instance.database;
    final result = await db.query('safe_zone', limit: 1);
    if (result.isNotEmpty) {
      return {
        'latitude': result.first['latitude'] as double,
        'longitude': result.first['longitude'] as double,
        'radius': result.first['radius'] as double,
      };
    }
    return null;
  }

  // Retrieve Last 10 Location History Entries
  Future<List<Map<String, dynamic>>> getLocationHistory() async {
    final db = await instance.database;
    return await db.query('location_history', orderBy: 'timestamp DESC', limit: 10);
  }

  // Close Database
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }


}