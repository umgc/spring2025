// lib/viewmodels/emergency_help_viewmodel.dart
// By sandrine

import 'package:flutter/material.dart';
import 'package:memoryminder/services/emergency_services.dart';
import 'package:memoryminder/models/emergency_type.dart';

class EmergencyHelpViewModel {
  final EmergencyService _emergencyService;

  EmergencyHelpViewModel(this._emergencyService);

  Future<void> sendEmergencyRequest({
    required String location,
    required String userId,
  }) async {
    try {
      await _emergencyService.createEmergencyRequest(
        type: EmergencyType.urgent,
        location: location,
        userId: userId,
      );
    } catch (e) {
      debugPrint('Error sending emergency request: $e');
      throw Exception('Failed to send emergency request');
    }
  }
}
