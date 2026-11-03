import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/location_permission_state.dart';
import 'package:vifutbol/domain/repositories/location_permission_repository.dart';

/// Infrastructure implementation of [LocationPermissionRepository] providing
/// resilient just-in-time location permission handling and dev-mode state simulation.
///
/// NOTE: In accordance with FR-009, coordinates are never persisted to disk or logs.
class DeviceLocationPermissionRepository
    implements LocationPermissionRepository {
  DeviceLocationPermissionRepository();

  LocationPermissionState _currentState = LocationPermissionState.initial;

  /// Default mock coordinate used when permission is granted in mobile/dev runtime
  /// (near Parque Simón Bolívar, Bogotá).
  static const GeoCoordinate simulatedUserCoordinate = GeoCoordinate(
    latitude: 4.6584,
    longitude: -74.0938,
  );

  @override
  Future<LocationPermissionState> getCurrentState() async {
    return _currentState;
  }

  @override
  Future<LocationPermissionState> requestPermissionAndLocation() async {
    if (_currentState.status == LocationPermissionStatus.permanentlyDenied) {
      return _currentState;
    }

    _currentState = const LocationPermissionState(
      status: LocationPermissionStatus.granted,
      userCoordinate: simulatedUserCoordinate,
    );
    return _currentState;
  }

  @override
  Future<LocationPermissionState> simulatePermissionStatusForDev(
    LocationPermissionStatus status,
  ) async {
    final GeoCoordinate? coord = status == LocationPermissionStatus.granted
        ? simulatedUserCoordinate
        : null;

    _currentState = LocationPermissionState(
      status: status,
      userCoordinate: coord,
    );
    return _currentState;
  }
}
