import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class SafeZoneManager {
  static const double defaultRadiusMeters = 200;

  Future<bool> isUserOutsideSafeZone() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('safe_zone_lat');
    final lng = prefs.getDouble('safe_zone_lng');

    if (lat == null || lng == null) return false; // Safe zone not set

    final currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final distance = _calculateDistanceInMeters(
      currentPosition.latitude,
      currentPosition.longitude,
      lat,
      lng,
    );

    return distance > defaultRadiusMeters;
  }

  double _calculateDistanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000; // in meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
