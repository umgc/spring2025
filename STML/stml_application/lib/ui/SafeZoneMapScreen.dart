import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../database_helper.dart';

class SafeZoneScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const SafeZoneScreen({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  }) : super(key: key);

  @override
  _SafeZoneScreenState createState() => _SafeZoneScreenState();
}

class _SafeZoneScreenState extends State<SafeZoneScreen> {
  GoogleMapController? _mapController;
  LatLng _safeZoneLocation = LatLng(0, 0);
  String _safeZoneAddress = "Not Set";
  final double _safeZoneRadius = 100; // Default 100 meters

  // Declare homeLatitude and homeLongitude to store home location
  double? homeLatitude;
  double? homeLongitude;

  @override
  void initState() {
    super.initState();
    // Use the passed values if available, otherwise get current location
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _safeZoneLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _safeZoneAddress = widget.initialAddress ?? "Unknown Address";
      homeLatitude = widget.initialLatitude;
      homeLongitude = widget.initialLongitude;
      print(
          "Map initialized with saved location: ${widget.initialLatitude}, ${widget.initialLongitude}");
    } else {
      // Default to San Francisco until we get current location
      _safeZoneLocation = LatLng(37.7749, -122.4194);
      _getCurrentLocation();
    }
  }
  void _debugLocationAndAddress() {
    print("DEBUG MAP: Location pin at: $_safeZoneLocation");
    print("DEBUG MAP: Address shown: $_safeZoneAddress");
  }

  /// ✅ Fetch User's Current Location
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _safeZoneLocation = LatLng(position.latitude, position.longitude);
    });

    _getAddressFromLatLng(_safeZoneLocation);
  }

  /// ✅ Convert LatLng to Address
Future<void> _getAddressFromLatLng(LatLng position) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude, 
      position.longitude
    );
    
    if (placemarks.isNotEmpty) {
      setState(() {
        String street = placemarks.first.street ?? '';
        String locality = placemarks.first.locality ?? '';
        String country = placemarks.first.country ?? '';
        _safeZoneAddress = "$street, $locality, $country".trim();
        
        // Remove any double commas from empty fields
        _safeZoneAddress = _safeZoneAddress.replaceAll(", ,", ",");
        if (_safeZoneAddress.startsWith(", ")) {
          _safeZoneAddress = _safeZoneAddress.substring(2);
        }
      });
    } else {
      print("No placemark found for location: $position");
    }
  } catch (e) {
    print("Error getting address: $e");
  }
}

  /// ✅ Handle Map Tap to Set Safe Zone
  void _onMapTapped(LatLng position) async {
    setState(() {
      _safeZoneLocation = position;
    });

    await _getAddressFromLatLng(position);
    _debugLocationAndAddress(); // Add this line
  }

  /// ✅ Show Alert when User is Out of Safe Zone
  void _showSafeZoneExitAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("You're out of your safe zone!"),
        content: Text("Do you need help returning home?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _moveToHome(); // Trigger the camera movement to home location
            },
            child: Text("Yes, Help Me!"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("No, I'm Fine"),
          ),
        ],
      ),
    );
  }

  // ✅ Move Camera to Home Location when "Help Me" is pressed
  void _moveToHome() {
    if (_mapController != null &&
        homeLatitude != null &&
        homeLongitude != null) {
      print("Moving to Home Location: $homeLatitude, $homeLongitude");
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(homeLatitude!, homeLongitude!), // Use home location
            zoom: 16.0,
          ),
        ),
      );
    } else {
      print("Error: Map controller or Home location is null.");
    }
  }

  /// ✅ Save Safe Zone in Database & Return Data
  void _saveSafeZone() async {
    _debugLocationAndAddress();
    await DatabaseHelper.instance.clearSafeZone(); 
    await DatabaseHelper.instance.saveSafeZone(
      _safeZoneLocation.latitude,
      _safeZoneLocation.longitude,
      _safeZoneRadius,
      _safeZoneAddress,
    );
    homeLatitude = _safeZoneLocation.latitude; // Store home latitude
    homeLongitude = _safeZoneLocation.longitude; // Store home longitude
    _moveToHome(); // Move to home location after saving
    Navigator.pop(context, {
      "lat": _safeZoneLocation.latitude,
      "lng": _safeZoneLocation.longitude,
      "address": _safeZoneAddress
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Safe Zone")),
      body: Column(
        children: [
          // Make sure GoogleMap takes up space in the Column
          Expanded(
            flex: 3,
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                print(
                    "Map is created"); // Debugging message to confirm map is created
                print("Initial location: $_safeZoneLocation");
              },
              initialCameraPosition:
                  CameraPosition(target: _safeZoneLocation, zoom: 5.0),
              onTap: _onMapTapped,
              markers: {
                Marker(
                  markerId: MarkerId("safe_zone"),
                  position: _safeZoneLocation,
                ),
              },
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              minMaxZoomPreference: MinMaxZoomPreference(1.0, 20.0),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("Safe Zone: $_safeZoneAddress"),
                ElevatedButton(
                  onPressed: _saveSafeZone,
                  child: Text("Confirm Safe Zone"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
