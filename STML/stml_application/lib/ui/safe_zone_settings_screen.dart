import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'package:memoryminder/ui/SafeZoneMapScreen.dart'; // import Map screen
import 'package:geocoding/geocoding.dart';

class SafeZoneSettingsScreen extends StatefulWidget {
  const SafeZoneSettingsScreen({super.key});

  @override
  _SafeZoneSettingsScreenState createState() => _SafeZoneSettingsScreenState();
}

class _SafeZoneSettingsScreenState extends State<SafeZoneSettingsScreen> {
  double? homeLatitude;
  double? homeLongitude;
  double safeZoneRadius = 100; // Default radius
  String _safeZoneAddress = "No Safe Zone Set";
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    addressController = TextEditingController(text: _safeZoneAddress);
    _loadSafeZone();

    Future.delayed(Duration(milliseconds: 500), _debugDatabase);
  }

  @override
  void dispose() {
    addressController.dispose(); // Clean up the controller
    super.dispose();
  }

  /// ✅ Load Safe Zone from Database
  Future<void> _loadSafeZone() async {
    try {
      final safeZone = await DatabaseHelper.instance.getSafeZone();
      if (safeZone != null) {
        setState(() {
          homeLatitude = (safeZone['latitude'] as num?)?.toDouble();
          homeLongitude = (safeZone['longitude'] as num?)?.toDouble();
          safeZoneRadius = (safeZone['radius'] as num?)?.toDouble() ?? 100;
          _safeZoneAddress = safeZone["address"] ?? "No address set";
          addressController.text = _safeZoneAddress;
        });
        print("✅ Safe Zone Loaded: $_safeZoneAddress");
      } else {
        setState(() {
          _safeZoneAddress = "No Safe Zone Set";
          addressController.text = _safeZoneAddress;
        });
        print("⚠️ No Safe Zone Found in Database.");
      }
    } catch (e, stackTrace) {
      print("❌ Error loading safe zone: $e");
      print(stackTrace);
    }
  }

  Future<void> _debugDatabase() async {
    final zones = await DatabaseHelper.instance.getAllSafeZones();
    print("DEBUG: Found ${zones.length} safe zone entries:");
    for (var zone in zones) {
      print("  - ID: ${zone['id']}, Address: ${zone['address']}, Lat: ${zone['latitude']}, Lng: ${zone['longitude']}");
    }
  }
  // Add to your SafeZoneSettingsScreen
  Future<void> _searchAddressAndUpdateMap() async {
    try {
      String searchAddress = addressController.text.trim();

      setState(() {
        _safeZoneAddress = searchAddress;
      });

      print("Searching for address: '$searchAddress'");

      // Use searchAddress for geocoding (not _safeZoneAddress)
      List<Location> locations = await locationFromAddress(searchAddress);

      if (locations.isNotEmpty) {
        Location location = locations.first;
        print(
        "GEOCODING CHECK: Address '$searchAddress' resolved to coordinates ${location.latitude}, ${location.longitude}");
        await DatabaseHelper.instance.clearSafeZone();
        setState(() {
          homeLatitude = location.latitude;
          homeLongitude = location.longitude;
        });
        
        // Save to database using searchAddress
        await DatabaseHelper.instance.saveSafeZone(
          location.latitude,
          location.longitude,
          safeZoneRadius,
          searchAddress, 
        );

        await _debugDatabase();

        print(
            "✅ Saved to database: ${location.latitude}, ${location.longitude}, '$searchAddress'");

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Location updated based on: $searchAddress")));
      } else {
        print("⚠️ Geocoding returned no results for: $searchAddress");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Could not find location for this address")));
      }
    } catch (e) {
      print("❌ Error geocoding address: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not find location for this address")));

      
    }
  }

  Future<void> _openMap() async {
    try {
      print("Opening map with: $homeLatitude, $homeLongitude");
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SafeZoneScreen(
                  initialLatitude: homeLatitude,
                  initialLongitude: homeLongitude,
                  initialAddress: _safeZoneAddress,
                )), // Open Map
      );

      if (!mounted)
        return; // ✅ Prevent calling setState() if the widget is disposed

      if (result != null && result is Map<String, dynamic>) {
        await DatabaseHelper.instance.clearSafeZone();
        setState(() {
          homeLatitude = (result["lat"] as num?)?.toDouble() ?? homeLatitude;
          homeLongitude = (result["lng"] as num?)?.toDouble() ?? homeLongitude;
          _safeZoneAddress = result["address"] ?? "Unknown Address";
        });
         // Save to database
        await DatabaseHelper.instance.saveSafeZone(
          homeLatitude!,
          homeLongitude!,
          safeZoneRadius,
          _safeZoneAddress,
        );

        print("📍 Safe Zone Set: ${homeLatitude}, ${homeLongitude}");
        await _debugDatabase();
      } else {
        print("⚠️ Safe Zone selection was canceled or returned null.");
      }
    } catch (e, stackTrace) {
      print("❌ Error opening map: $e");
      print(stackTrace); // ✅ Print detailed error stack trace
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Safe Zone Settings")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Current Safe Zone:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text(_safeZoneAddress),
            SizedBox(height: 20),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: "Enter Address",
                hintText: "Enter a full address",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchAddressAndUpdateMap,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _safeZoneAddress = value;
                });
              },
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (homeLatitude != null && homeLongitude != null) {
                  await DatabaseHelper.instance.clearSafeZone();
                  await DatabaseHelper.instance.saveSafeZone(
                    homeLatitude!,
                    homeLongitude!,
                    safeZoneRadius,
                    _safeZoneAddress,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Address details saved")));
                }
              },
              child: Text("Save Address Details"),
            ),
            SizedBox(height: 20),
            // Map button stays the same
            ElevatedButton(
              onPressed: _openMap,
              child: Text("Set Safe Zone Location"),
            ),
          ],
        ),
      ),
    );
  }
}