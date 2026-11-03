import 'geo_coordinate.dart';

/// Status of the device's geolocation permission and hardware service.
enum LocationPermissionStatus {
  notRequested,
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled;

  bool get isGranted => this == LocationPermissionStatus.granted;
  bool get isDenied =>
      this == LocationPermissionStatus.denied ||
      this == LocationPermissionStatus.permanentlyDenied ||
      this == LocationPermissionStatus.serviceDisabled;
}

/// Represents the current device location permission state and volatile in-memory coordinate.
///
/// NOTE: To comply with FR-009, [userCoordinate] is strictly an in-memory runtime value
/// and is never persisted to disk or output in plain text.
class LocationPermissionState {
  const LocationPermissionState({required this.status, this.userCoordinate});

  final LocationPermissionStatus status;

  /// Volatile user coordinate held only in memory when permission is granted.
  final GeoCoordinate? userCoordinate;

  static const LocationPermissionState initial = LocationPermissionState(
    status: LocationPermissionStatus.notRequested,
    userCoordinate: null,
  );

  LocationPermissionState copyWith({
    LocationPermissionStatus? status,
    GeoCoordinate? userCoordinate,
    bool clearCoordinate = false,
  }) {
    return LocationPermissionState(
      status: status ?? this.status,
      userCoordinate: clearCoordinate
          ? null
          : (userCoordinate ?? this.userCoordinate),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationPermissionState &&
        other.status == status &&
        other.userCoordinate == userCoordinate;
  }

  @override
  int get hashCode => Object.hash(status, userCoordinate);

  @override
  String toString() {
    final String coordRedacted = userCoordinate != null
        ? '[REDACTED_USER_LOCATION]'
        : 'null';
    return 'LocationPermissionState(status: $status, userCoordinate: $coordRedacted)';
  }
}
