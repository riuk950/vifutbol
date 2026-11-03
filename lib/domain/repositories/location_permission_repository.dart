import 'package:vifutbol/domain/entities/location_permission_state.dart';

/// Contract for managing device geolocation permissions and retrieving volatile coordinates.
abstract class LocationPermissionRepository {
  /// Returns the current permission status and volatile user coordinate if granted.
  Future<LocationPermissionState> getCurrentState();

  /// Requests location permission in context (just-in-time) and returns the resulting state.
  Future<LocationPermissionState> requestPermissionAndLocation();

  /// Simulates a specific permission status in development environment.
  Future<LocationPermissionState> simulatePermissionStatusForDev(
    LocationPermissionStatus status,
  );
}
