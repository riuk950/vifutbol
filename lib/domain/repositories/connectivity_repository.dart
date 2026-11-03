import 'package:vifutbol/domain/entities/connectivity_status.dart';

/// Contract for observing device network connectivity.
abstract class ConnectivityRepository {
  /// Stream emitting changes to network connection status.
  Stream<NetworkConnectionStatus> get onConnectivityChanged;

  /// Retrieves the current immediate connection status.
  Future<NetworkConnectionStatus> checkConnectivity();
}
