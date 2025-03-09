// lib/services/navigation_service.dart

import 'package:flutter/material.dart';
import '../services/emergency_service.dart';
import 'package:memoryminder/models/emergency_type.dart';

/// Service responsible for handling navigation and emergency routing in the application
class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final EmergencyService _emergencyService;

  NavigationService({
    EmergencyService? emergencyService,
  }) : _emergencyService =
            emergencyService ?? EmergencyService(baseUrl: 'YOUR_API_BASE_URL');

  /// Navigates to emergency help screen and creates an emergency request
  Future<void> navigateToEmergencyHelp(
      String location, DateTime timestamp) async {
    try {
      // Create emergency request
      await _emergencyService.createEmergencyRequest(
        type: EmergencyType.urgent,
        location: location,
        userId:
            'CURRENT_USER_ID', // Replace with actual user ID from auth service
      );

      // Navigate to emergency screen
      navigatorKey.currentState?.pushNamed(
        '/emergency-help',
        arguments: {
          'location': location,
          'timestamp': timestamp,
        },
      );
    } catch (e) {
      // Handle navigation or emergency request errors
      print('Failed to navigate to emergency help: $e');
      // You might want to show an error dialog or fallback navigation
    }
  }

  /// Navigates to fall alert screen and creates a fall emergency request
  Future<void> navigateToFallAlert(String location, DateTime timestamp) async {
    try {
      // Create fall emergency request
      await _emergencyService.createEmergencyRequest(
        type: EmergencyType.fall,
        location: location,
        userId:
            'CURRENT_USER_ID', // Replace with actual user ID from auth service
      );

      // Navigate to fall alert screen
      navigatorKey.currentState?.pushNamed(
        '/fall-alert',
        arguments: {
          'location': location,
          'timestamp': timestamp,
        },
      );
    } catch (e) {
      // Handle navigation or emergency request errors
      print('Failed to navigate to fall alert: $e');
      // You might want to show an error dialog or fallback navigation
    }
  }

  /// Navigates to medical emergency screen and creates a medical emergency request
  Future<void> navigateToMedicalEmergency(
      String location, DateTime timestamp) async {
    try {
      // Create medical emergency request
      await _emergencyService.createEmergencyRequest(
        type: EmergencyType.medical,
        location: location,
        userId:
            'CURRENT_USER_ID', // Replace with actual user ID from auth service
      );

      // Navigate to medical emergency screen
      navigatorKey.currentState?.pushNamed(
        '/medical-emergency',
        arguments: {
          'location': location,
          'timestamp': timestamp,
        },
      );
    } catch (e) {
      // Handle navigation or emergency request errors
      print('Failed to navigate to medical emergency: $e');
      // You might want to show an error dialog or fallback navigation
    }
  }

  /// Navigates to confusion alert screen and creates a confusion emergency request
  Future<void> navigateToConfusionAlert(
      String location, DateTime timestamp) async {
    try {
      // Create confusion emergency request
      await _emergencyService.createEmergencyRequest(
        type: EmergencyType.confusion,
        location: location,
        userId:
            'CURRENT_USER_ID', // Replace with actual user ID from auth service
      );

      // Navigate to confusion alert screen
      navigatorKey.currentState?.pushNamed(
        '/confusion-alert',
        arguments: {
          'location': location,
          'timestamp': timestamp,
        },
      );
    } catch (e) {
      // Handle navigation or emergency request errors
      print('Failed to navigate to confusion alert: $e');
      // You might want to show an error dialog or fallback navigation
    }
  }

  /// Navigates to general assistance screen and creates a general assistance request
  Future<void> navigateToGeneralAssistance(
      String location, DateTime timestamp) async {
    try {
      // Create general assistance request
      await _emergencyService.createEmergencyRequest(
        type: EmergencyType.general,
        location: location,
        userId:
            'CURRENT_USER_ID', // Replace with actual user ID from auth service
      );

      // Navigate to general assistance screen
      navigatorKey.currentState?.pushNamed(
        '/general-assistance',
        arguments: {
          'location': location,
          'timestamp': timestamp,
        },
      );
    } catch (e) {
      // Handle navigation or emergency request errors
      print('Failed to navigate to general assistance: $e');
      // You might want to show an error dialog or fallback navigation
    }
  }

  /// Handles general navigation to a named route with optional arguments
  Future<void> navigateTo(String routeName, {Object? arguments}) async {
    try {
      navigatorKey.currentState?.pushNamed(
        routeName,
        arguments: arguments,
      );
    } catch (e) {
      print('Navigation error: $e');
      // Handle general navigation errors
    }
  }

  /// Pops the current route off the navigation stack
  void goBack() {
    if (navigatorKey.currentState?.canPop() ?? false) {
      navigatorKey.currentState?.pop();
    }
  }
}
