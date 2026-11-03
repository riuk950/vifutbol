import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';

/// Orchestrates startup initialization and storage namespace isolation.
class InitializeAppFoundationUseCase {
  final LocalStorageRepository _localStorageRepository;

  const InitializeAppFoundationUseCase(this._localStorageRepository);

  Future<LocalStorageStatus> call(EnvironmentConfig config) async {
    return _localStorageRepository.initialize(config.localStoragePrefix);
  }
}
