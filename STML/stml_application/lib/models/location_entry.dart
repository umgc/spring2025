// lib/models/location_entry.dart

/// Represents a location entry with timestamp information for patient tracking
class LocationEntry {
  /// Unique identifier for the location entry
  int? id;

  /// Complete address of the location
  final String address;

  /// Time when the patient arrived at this location
  final DateTime startTime;

  /// Time when the patient left this location (null if still present)
  DateTime? endTime;

  LocationEntry({
    this.id,
    required this.address,
    required this.startTime,
    this.endTime,
  });

  /// Create a LocationEntry from a Map (database row)
  factory LocationEntry.fromMap(Map<String, dynamic> map) {
    return LocationEntry(
      id: map['id'] as int?,
      address: map['address'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null,
    );
  }

  /// Convert LocationEntry to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  /// Duration spent at this location
  Duration getDuration() {
    return endTime?.difference(startTime) ??
        DateTime.now().difference(startTime);
  }
}
