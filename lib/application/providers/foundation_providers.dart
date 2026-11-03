import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';

/// Active environment configuration provider (overridden during application bootstrap).
final environmentConfigProvider = Provider<EnvironmentConfig>((ref) {
  throw UnimplementedError(
    'environmentConfigProvider must be initialized via ProviderScope override.',
  );
});

/// Local persistence storage repository provider.
final localStorageRepositoryProvider = Provider<LocalStorageRepository>((ref) {
  throw UnimplementedError(
    'localStorageRepositoryProvider must be initialized via ProviderScope override.',
  );
});

/// Device connectivity repository provider.
final connectivityRepositoryProvider = Provider<ConnectivityRepository>((ref) {
  throw UnimplementedError(
    'connectivityRepositoryProvider must be initialized via ProviderScope override.',
  );
});
