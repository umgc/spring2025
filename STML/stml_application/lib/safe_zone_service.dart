import 'package:shared_preferences/shared_preferences.dart';
import 'safe_zone.dart'; // We'll create the SafeZone class in another file

class SafeZoneService {
  static const String safeZoneKey = 'safe_zone_key';

  // Save safe zone data
  Future<void> saveSafeZone(SafeZone safeZone) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(safeZoneKey, safeZone.toMap().toString()); // Save the SafeZone data
  }

  // Retrieve saved safe zone
  Future<SafeZone?> getSafeZone() async {
    final prefs = await SharedPreferences.getInstance();
    final String? safeZoneData = prefs.getString(safeZoneKey);
    if (safeZoneData != null) {
      final map = Map<String, dynamic>.from(safeZoneData);
      return SafeZone.fromMap(map); // Convert it back to SafeZone object
    }
    return null; // If there's no saved data, return null
  }
}
