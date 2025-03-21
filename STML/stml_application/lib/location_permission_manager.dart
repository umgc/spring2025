import 'package:permission_handler/permission_handler.dart';

class LocationPermissionManager {
  // Request foreground location permission
  static Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      print("✅ Foreground location permission granted!");
      return true;
    } else if (status.isDenied) {
      print("⚠️ Location permission denied.");
      return false;
    } else if (status.isPermanentlyDenied) {
      print("❌ Location permission permanently denied. Open settings.");
      await openAppSettings();
      return false;
    }
    return false;
  }

  // Request background location permission separately (Android 10+ requirement)
  static Future<bool> requestBackgroundLocationPermission() async {
    if (await Permission.locationAlways.isDenied) {
      PermissionStatus status = await Permission.locationAlways.request();
      if (status.isGranted) {
        print("✅ Background location permission granted!");
        return true;
      } else {
        print("❌ Background location permission denied.");
        return false;
      }
    }
    return true;
  }

  // Main function to request permissions properly
  static Future<void> requestPermissions() async {
    bool foregroundGranted = await requestLocationPermission();

    if (foregroundGranted) {
      // Request background location separately
      bool backgroundGranted = await requestBackgroundLocationPermission();

      if (!backgroundGranted) {
        print("⚠️ Background location permission denied. Opening app settings...");
        openAppSettings(); // Opens app settings if user denied it
      }
    }
  }
}
