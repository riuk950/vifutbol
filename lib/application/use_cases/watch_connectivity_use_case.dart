import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';

/// Use case that exposes a stream of continuous connectivity updates.
class WatchConnectivityUseCase {
  final ConnectivityRepository _repository;

  const WatchConnectivityUseCase(this._repository);

  Stream<NetworkConnectionStatus> call() {
    return _repository.onConnectivityChanged;
  }
}
