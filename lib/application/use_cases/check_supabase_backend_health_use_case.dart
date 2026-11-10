import 'package:flutter/widgets.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/backend_health_status.dart';
import 'package:vifutbol/infrastructure/network/supabase_health_client.dart';

/// Contract for checking the health and connectivity of the Supabase backend.
abstract class CheckSupabaseBackendHealthUseCase {
  /// Executes the handshake against PostgREST and returns the detailed result.
  Future<BackendHealthCheckResult> call({
    Duration timeout = const Duration(seconds: 5),
  });
}

/// Concrete implementation of [CheckSupabaseBackendHealthUseCase].
class CheckSupabaseBackendHealthUseCaseImpl
    implements CheckSupabaseBackendHealthUseCase {
  final SupabaseHealthClient healthClient;
  final SupabaseConfig config;

  CheckSupabaseBackendHealthUseCaseImpl({
    required this.healthClient,
    required this.config,
  });

  @override
  Future<BackendHealthCheckResult> call({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final result = await healthClient.checkHealth(config, timeout: timeout);

    if (result.isHealthy) {
      debugPrint('[SupabaseDev] Conectado exitosamente al host self-hosted');
    }

    return result;
  }
}
