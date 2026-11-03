import 'dart:math' as math;

/// Immutable value object representing a validated geographical coordinate.
class GeoCoordinate {
  const GeoCoordinate({required this.latitude, required this.longitude})
    : assert(
        latitude >= -90.0 && latitude <= 90.0,
        'Latitude must be between -90.0 and 90.0',
      ),
      assert(
        longitude >= -180.0 && longitude <= 180.0,
        'Longitude must be between -180.0 and 180.0',
      );

  final double latitude;
  final double longitude;

  /// Default urban center coordinate for the championship (Bogotá, Colombia).
  static const GeoCoordinate defaultCityCenter = GeoCoordinate(
    latitude: 4.6097,
    longitude: -74.0817,
  );

  /// Validates whether the given [lat] and [lng] fall within valid geographical ranges.
  static bool isValidCoordinate(double lat, double lng) {
    if (lat.isNaN || lat.isInfinite || lng.isNaN || lng.isInfinite) {
      return false;
    }
    return lat >= -90.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0;
  }

  /// Calculates geodesic distance in kilometers to [other] using the Haversine formula.
  ///
  /// Uses the mean Earth radius R = 6371.0 km.
  double distanceInKilometersTo(GeoCoordinate other) {
    const double earthRadiusKm = 6371.0;

    final double lat1Rad = latitude * (math.pi / 180.0);
    final double lon1Rad = longitude * (math.pi / 180.0);
    final double lat2Rad = other.latitude * (math.pi / 180.0);
    final double lon2Rad = other.longitude * (math.pi / 180.0);

    final double deltaLat = lat2Rad - lat1Rad;
    final double deltaLon = lon2Rad - lon1Rad;

    final double a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  factory GeoCoordinate.fromJson(Map<String, dynamic> json) {
    return GeoCoordinate(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeoCoordinate &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() =>
      'GeoCoordinate(latitude: $latitude, longitude: $longitude)';
}
