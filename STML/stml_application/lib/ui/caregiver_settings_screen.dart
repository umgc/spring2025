// lib/ui/caregiver_settings_screen.dart
// By Sandrine

import 'package:flutter/material.dart';
import 'package:memoryminder/models/caregiver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CaregiverSettingsScreen extends StatefulWidget {
  final Caregiver caregiver;

  const CaregiverSettingsScreen({super.key, required this.caregiver});

  @override
  CaregiverSettingsScreenState createState() => CaregiverSettingsScreenState();
}

class CaregiverSettingsScreenState extends State<CaregiverSettingsScreen> {
  late Caregiver _caregiver;

  @override
  void initState() {
    super.initState();
    _caregiver = widget.caregiver;
  }

  /// Updates caregiver settings in Firestore
  Future<void> _updateSettings() async {
    final db = FirebaseFirestore.instance;
    await db
        .collection('caregivers')
        .doc(_caregiver.userId)
        .update(_caregiver.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Caregiver Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: Text('Enable Emergency Notifications'),
            value: _caregiver.enableEmergencyNotifications,
            onChanged: (value) {
              setState(() {
                _caregiver.enableEmergencyNotifications = value;
              });
              _updateSettings();
            },
          ),
          SwitchListTile(
            title: Text('Enable Location Sharing'),
            value: _caregiver.enableLocationSharing,
            onChanged: (value) {
              setState(() {
                _caregiver.enableLocationSharing = value;
              });
              _updateSettings();
            },
          ),
          SwitchListTile(
            title: Text('Enable Camera Access'),
            value: _caregiver.enableCameraAccess,
            onChanged: (value) {
              setState(() {
                _caregiver.enableCameraAccess = value;
              });
              _updateSettings();
            },
          ),
        ],
      ),
    );
  }
}
