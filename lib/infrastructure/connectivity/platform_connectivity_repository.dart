import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';

/// Platform implementation of ConnectivityRepository using connectivity_plus.
class PlatformConnectivityRepository implements ConnectivityRepository {
  final Connectivity _connectivity;

  PlatformConnectivityRepository({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_mapResultsToStatus);
  }

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return _mapResultsToStatus(results);
  }

  NetworkConnectionStatus _mapResultsToStatus(
    List<ConnectivityResult> results,
  ) {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return NetworkConnectionStatus.disconnected;
    }
    return NetworkConnectionStatus.connected;
  }
}
