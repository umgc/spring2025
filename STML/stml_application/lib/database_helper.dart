import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:geolocator/geolocator.dart';
import '../notification_service.dart';



class DatabaseHelper {
  static Database? _database;

  // Singleton pattern
  static final DatabaseHelper instance = DatabaseHelper._internal();

  factory DatabaseHelper() {
    return instance;
  }

  DatabaseHelper._internal();

  // Initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Create or open the database
  Future<Database> _initDatabase() async {
  return await openDatabase(
    join(await getDatabasesPath(), 'location_history.db'),
    onCreate: (db, version) {
      db.execute(
        'CREATE TABLE location_history(id INTEGER PRIMARY KEY, latitude REAL, longitude REAL, timestamp TEXT)',
      );
      db.execute(
        'CREATE TABLE emergency_events(id INTEGER PRIMARY KEY, type TEXT, caregiver_fcm_token TEXT, timestamp TEXT)',
      );
      db.execute(
        'CREATE TABLE safe_zone(id INTEGER PRIMARY KEY, latitude REAL, longitude REAL, radius REAL, address TEXT)', // This includes the new 'address' column
      );
    },
    onUpgrade: (db, oldVersion, newVersion) {
      if (oldVersion < 2) {
        // Add the missing column if upgrading from version 1 to version 2
        db.execute('ALTER TABLE safe_zone ADD COLUMN address TEXT');
      }
    },
    version: 2, // Increment this version number
  );
}

  Future<void> saveSafeZone(double latitude, double longitude, double radius, String address) async {
  final db = await database;
  await db.insert(
    'safe_zone',
    {
      'id': 1, // Only one safe zone entry
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'address': address,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

  Future<Map<String, dynamic>?> getSafeZone() async {
  final db = await database;
  final List<Map<String, dynamic>> safeZones = await db.query('safe_zone');

  if (safeZones.isNotEmpty) {
    return safeZones.first; // Returns {latitude, longitude, radius, address}
  }
  return null;
}

  Future<List<Map<String, dynamic>>> getAllSafeZones() async {
    final db = await database;
    return await db.query('safe_zone');
}

  Future<void> clearSafeZone() async {
    final db = await database;
    await db.delete('safe_zone');
    print("🧹 Safe zone table cleared");
}

  // Reset the database completely (use with caution!)
  Future<void> resetDatabase() async {
    final db = await database;
    await db.execute('DROP TABLE IF EXISTS safe_zone');
    await db.execute('CREATE TABLE safe_zone(id INTEGER PRIMARY KEY, latitude REAL, longitude REAL, radius REAL, address TEXT)');
    print("🔄 Database reset complete");
}


  // Insert a location entry and trigger notification if user leaves safe zone
  Future<void> insertLocationAndCheckSafeZone(
      double latitude,
      double longitude,
      double safeZoneLatitude,
      double safeZoneLongitude,
      double safeZoneRadius,
      String caregiverFcmToken) async {
      
     // ✅ Check location permission before proceeding
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print("❌ Location permission permanently denied.");
        return;
      }
    }


    final db = await database;

    await db.insert(
      'location_history',
      {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Check if the user is in the safe zone
    double distanceInMeters = Geolocator.distanceBetween(
      latitude,
      longitude,
      safeZoneLatitude,
      safeZoneLongitude,
    );

    bool isInsideSafeZone = distanceInMeters <= safeZoneRadius;

    if (!isInsideSafeZone) {
      print("🚨 User has left the safe zone!");

      // ✅ Send a notification to the caregiver
      await NotificationService().sendNotificationToCaregiver(
          caregiverFcmToken,
          "🚨 Alert: User Left Safe Zone!",
          "Your loved one has exited their designated safe zone.");
    } else {
      print("✅ User is inside the safe zone.");
    }
  }

  // Insert an emergency event and notify caregiver
  Future<void> insertEmergencyEvent(
      String type, String caregiverFcmToken) async {
    final db = await database;

    await db.insert(
      'emergency_events',
      {
        'type': type,
        'caregiver_fcm_token': caregiverFcmToken,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print("🚨 Emergency Event Recorded: $type");

    // ✅ Notify caregiver
    await NotificationService().sendNotificationToCaregiver(caregiverFcmToken,
        "🚨 Emergency Alert!", "An emergency ($type) has been reported.");
  }
}
