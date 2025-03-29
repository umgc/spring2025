import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SafeZoneSettingsScreen extends StatefulWidget {
  const SafeZoneSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SafeZoneSettingsScreen> createState() => _SafeZoneSettingsScreenState();
}

class _SafeZoneSettingsScreenState extends State<SafeZoneSettingsScreen> {
  final TextEditingController _addressController = TextEditingController();
  String? _savedAddress;
  LatLng? _savedCoordinates;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSafeZone();
  }

  Future<void> _loadSafeZone() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('safe_zone_address');
    final lat = prefs.getDouble('safe_zone_lat');
    final lng = prefs.getDouble('safe_zone_lng');

    if (address != null && lat != null && lng != null) {
      setState(() {
        _addressController.text = address;
        _savedAddress = address;
        _savedCoordinates = LatLng(lat, lng);
      });
    }
  }

  Future<void> _convertAndSaveAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locations = await locationFromAddress(address);
      final location = locations.first;

      final lat = location.latitude;
      final lng = location.longitude;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      await FirebaseFirestore.instance
          .collection('safe_zones')
          .doc(userId)
          .set({
        'address': address,
        'latitude': lat,
        'longitude': lng,
        'radius_meters': 200,
        'timestamp': FieldValue.serverTimestamp(),
        'careRecipientId': userId,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('safe_zone_address', address);
      await prefs.setDouble('safe_zone_lat', lat);
      await prefs.setDouble('safe_zone_lng', lng);

      setState(() {
        _savedAddress = address;
        _savedCoordinates = LatLng(lat, lng);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Your Safe Zone")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Enter your address',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _convertAndSaveAddress,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            if (_savedAddress != null && _savedCoordinates != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "✅ Safe Zone Set!",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text("Address: $_savedAddress"),
                    Text(
                      "Lat: ${_savedCoordinates!.latitude}, Lng: ${_savedCoordinates!.longitude}",
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;
  LatLng(this.latitude, this.longitude);
}
