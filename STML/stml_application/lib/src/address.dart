/*
  Description
  -----------
  This class provides the address of the phone running an app.
  
  1. Obtain permission to access the device's Global Position System (GPS) receiver.
  2. Get the geospatial location from GPS.
  3. Use a web service to translate the coordinates to an address. 

  Usage
  -----
  1. Add to AndroidManifest.xml files:
     <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

  2. Add to ios/Info.plist
	   <key>NSLocationWhenInUseUsageDescription</key>
   	 <string>This app needs access to location when open.</string>
	   <key>NSLocationAlwaysUsageDescription</key>
	   <string>This app needs access to location when in the background.</string>

  3. Add to pubspec.yaml
     dependencies:    
        # A Flutter geocoding plugin which provides easy geocoding and reverse-geocoding features. 
        geocoding: ^2.1.1
  
        # A Flutter geolocation plugin which provides easy access to platform specific location services.
        geolocator: ^10.1.0

  4. Import file
     import "address.dart";

  5. Make static function call
     var physicalAddress = "";
       await Address.whereIAm().then((String address) {
         physicalAddress = address;
       });
     debugPrint(physicalAddress);

  Note
  ----
  If run on an emulator, the return will always be "1650 Amphitheatre Pkwy, Mountain View, 94043, United States".
*/

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memoryminder/src/utils/logger.dart';

class Address {
  // The testing suite does not allow for mocking permissions, so we need to manually skip them if called during a test
  // isTesting is off by default, and only enabled during testing calls
  static Future<String> whereIAm({bool isTesting = false}) async {
    // Ensure GPS access

    if (!isTesting) {
      LocationPermission locationPermission =
          await Geolocator.checkPermission();

      if (locationPermission == LocationPermission.denied ||
          locationPermission == LocationPermission.deniedForever) {
        return "";
      }
    }

    await Geolocator.requestPermission();

    // Ask GPS to provide its current latitude and longitude coordinates
    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);

    // Ask Geocoder to match the coordinates to a geophysical address
    try {
      List<Placemark> currentPlacemarks = await placemarkFromCoordinates(
          currentPosition.latitude, currentPosition.longitude);
      Placemark currentPlace = currentPlacemarks[0];
      var address =
          "${currentPlace.street}, ${currentPlace.locality}, ${currentPlace.administrativeArea}, ${currentPlace.postalCode}, ${currentPlace.isoCountryCode}";
      return address;
    } catch (e) {
      appLogger.severe(e);
      return "";
    }
  }
}
