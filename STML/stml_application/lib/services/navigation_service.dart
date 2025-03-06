// lib/services/navigation_service.dart

import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> navigateToEmergencyHelp(
      String location, DateTime timestamp) async {
    navigatorKey.currentState?.pushNamed(
      '/emergency-help',
      arguments: {
        'location': location,
        'timestamp': timestamp,
      },
    );
  }

  Future<void> navigateToFallAlert(String location, DateTime timestamp) async {
    navigatorKey.currentState?.pushNamed(
      '/fall-alert',
      arguments: {
        'location': location,
        'timestamp': timestamp,
      },
    );
  }

  Future<void> navigateToMedicalEmergency(
      String location, DateTime timestamp) async {
    navigatorKey.currentState?.pushNamed(
      '/medical-emergency',
      arguments: {
        'location': location,
        'timestamp': timestamp,
      },
    );
  }
}
