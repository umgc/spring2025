// Author: Ben Sutter
// Description: This class is used to manage permissions required for the app and requesting permission access.

import 'package:memoryminder/src/camera_manager.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static Future<bool> requestInitialPermissions() async {
    // Check and request camera, microphone, location, and file permissions
    final cameraPermissionStatus = await Permission.camera.status;
    final microphonePermissionStatus = await Permission.microphone.status;
    final locationPermissionStatus = await Permission.location.status;
    final storagePermissionStatus = await Permission.storage.status;

    if (cameraPermissionStatus.isDenied ||
        cameraPermissionStatus.isPermanentlyDenied ||
        microphonePermissionStatus.isDenied ||
        microphonePermissionStatus.isPermanentlyDenied ||
        locationPermissionStatus.isDenied ||
        locationPermissionStatus.isPermanentlyDenied ||
        storagePermissionStatus.isDenied ||
        storagePermissionStatus.isPermanentlyDenied) {
      // Permissions are denied or permanently denied
      // Request camera, microphone, location, and storage permissions
      final cameraPermissionResult = await Permission.camera.request();
      final microphonePermissionResult = await Permission.microphone.request();
      final locationPermissionResult = await Permission.location.request();
      final storagePermissionResult = await Permission.storage.request();

      if ((cameraPermissionResult.isDenied ||
              cameraPermissionResult.isPermanentlyDenied) ||
          (microphonePermissionResult.isDenied ||
              microphonePermissionResult.isPermanentlyDenied) ||
          (locationPermissionResult.isDenied ||
              locationPermissionResult.isPermanentlyDenied) ||
          (storagePermissionResult.isDenied ||
              storagePermissionResult.isPermanentlyDenied)) {
        // User denied one or more permissions, handle the situation (e.g., show an error message)
        // You can navigate back to the previous screen, show a snackbar, etc.

        return false;
      }
    }
    return true;
  }

  static Future<bool> checkIfLocationServiceIsActive(BuildContext context) {
    return Geolocator.isLocationServiceEnabled()
        .then((isLocationServiceEnabled) {
      if (!isLocationServiceEnabled) {
        // Show a popup to prompt the user to enable location services
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Location Service Not Enabled"),
              content: const Text(
                  "Please enable location services in your device settings to enable location tracking."),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
        return false;
      }
      return true;
    });
  }

  static Future<bool> cameraPermissionGranted() async {
    // Check and request camera and microphone permissions
    final cameraPermissionStatus = await Permission.camera.status;
    final microphonePermissionStatus = await Permission.microphone.status;

    if (cameraPermissionStatus.isDenied ||
        cameraPermissionStatus.isPermanentlyDenied ||
        microphonePermissionStatus.isDenied ||
        microphonePermissionStatus.isPermanentlyDenied) {
      return false;
    }

    return true;
  }

 static Future<bool> filePermissionsGranted(BuildContext context) async {
    // Check if file storage permission is granted
    final filePermissionStatus = await Permission.storage.status;

    if (filePermissionStatus.isGranted) {
      // File storage permission is already granted
      return true;
    }

    // Request file storage permission
    final filePermissionResult = await Permission.storage.request();

    if (filePermissionResult.isGranted) {
      // File storage permission has been granted
      return true;
    } else {
      // User denied file storage permission, show a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('File Permission Required'),
          content: const Text(
              'Please enable file permissions to access this feature.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );

      return false;
    }
  }

  static bool attemptToShowVideoScreen(BuildContext context) {
    CameraManager controller = CameraManager();

    // Check camera permission status synchronously
    var cameraStatus = Permission.camera.status;

    if (controller.isInitialized) {
      return true;
    } else {
      showDialog(
        context: context,
        builder: (context) => cameraStatus == PermissionStatus.granted
            ? AlertDialog(
                title:
                    const Text('Camera Has Permission But Is Not Initialized'),
                content: const Text('Please wait a few more seconds.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              )
            : cameraStatus == PermissionStatus.denied
                ? AlertDialog(
                    title: const Text('Camera Permission Denied'),
                    content: const Text(
                      'You have denied camera permissions. Please enable camera permissions in your device settings.',
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  )
                : AlertDialog(
                    title: const Text('Camera Permission Required'),
                    content: const Text(
                      'Please enable camera permissions to access this feature.',
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
      );
    }
    return false;
  }
}
