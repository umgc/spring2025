class SafeZone {
  final double latitude;
  final double longitude;
  final double radius;

  SafeZone({required this.latitude, required this.longitude, required this.radius});

  // Convert SafeZone data to Map (for storage)
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
  }

  // Convert from Map to SafeZone object
  static SafeZone fromMap(Map<String, dynamic> map) {
    return SafeZone(
      latitude: map['latitude'],
      longitude: map['longitude'],
      radius: map['radius'],
    );
  }
}
