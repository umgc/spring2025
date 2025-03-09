// lib/models/emergency_type.dart

/// Represents different types of emergencies that can be handled by the MemoryMinder application
enum EmergencyType {
  /// Immediate assistance needed (highest priority)
  urgent,

  /// Medical-related emergency requiring healthcare attention
  medical,

  /// Fall detection from wearable devices or user report
  fall,

  /// User experiencing disorientation or confusion
  confusion,

  /// General assistance needed (lowest priority)
  general;

  /// Returns a human-readable string representation of the emergency type
  String toDisplayString() {
    switch (this) {
      case EmergencyType.urgent:
        return 'Urgent Emergency';
      case EmergencyType.medical:
        return 'Medical Emergency';
      case EmergencyType.fall:
        return 'Fall Detected';
      case EmergencyType.confusion:
        return 'Disorientation Alert';
      case EmergencyType.general:
        return 'General Assistance';
    }
  }

  /// Returns the priority level of the emergency type (1 highest, 5 lowest)
  int getPriorityLevel() {
    switch (this) {
      case EmergencyType.urgent:
        return 1;
      case EmergencyType.medical:
        return 2;
      case EmergencyType.fall:
        return 3;
      case EmergencyType.confusion:
        return 4;
      case EmergencyType.general:
        return 5;
    }
  }
}
