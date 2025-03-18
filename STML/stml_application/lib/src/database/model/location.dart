class LocationDataModel {
  int? id;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime timestamp;

  LocationDataModel({
    this.id,
    this.latitude,
    this.longitude,
    this.address,
    required this.timestamp
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Convert a Map into a LocationDataModel
  static LocationDataModel fromMap(Map<String, dynamic> map) {
    return LocationDataModel(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      address: map['address'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
