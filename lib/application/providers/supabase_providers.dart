import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/use_cases/check_supabase_backend_health_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/backend_health_status.dart';
import 'package:vifutbol/infrastructure/network/supabase_health_client.dart';

/// Provider exposing the active Supabase configuration derived from [environmentConfigProvider].
final supabaseConfigProvider = Provider<SupabaseConfig>((ref) {
  final environmentConfig = ref.watch(environmentConfigProvider);
  return environmentConfig.supabase;
});

/// Provider exposing the active [SupabaseClient] instance, or `null` if unconfigured or offline.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final config = ref.watch(supabaseConfigProvider);
  if (!config.isConfigured) {
    return null;
  }
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
});

/// Provider exposing the lightweight HTTP health check client.
final supabaseHealthClientProvider = Provider<SupabaseHealthClient>((ref) {
  final client = SupabaseHealthClient();
  ref.onDispose(client.dispose);
  return client;
});

/// Provider exposing the [CheckSupabaseBackendHealthUseCase].
final checkSupabaseBackendHealthUseCaseProvider =
    Provider<CheckSupabaseBackendHealthUseCase>((ref) {
      final healthClient = ref.watch(supabaseHealthClientProvider);
      final config = ref.watch(supabaseConfigProvider);
      return CheckSupabaseBackendHealthUseCaseImpl(
        healthClient: healthClient,
        config: config,
      );
    });

/// Notifier managing reactive backend health check probes.
class BackendHealthNotifier extends StateNotifier<BackendHealthCheckResult> {
  final CheckSupabaseBackendHealthUseCase _useCase;

  BackendHealthNotifier(this._useCase, {BackendHealthCheckResult? initialState})
    : super(initialState ?? BackendHealthCheckResult.unconfigured());

  /// Triggers a health check probe against the backend host.
  Future<BackendHealthCheckResult> checkHealth({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    state = BackendHealthCheckResult.checking();
    final result = await _useCase(timeout: timeout);
    state = result;
    return result;
  }
}

/// State notifier provider for reactive backend health status.
final backendHealthStatusProvider =
    StateNotifierProvider<BackendHealthNotifier, BackendHealthCheckResult>((
      ref,
    ) {
      final useCase = ref.watch(checkSupabaseBackendHealthUseCaseProvider);
      return BackendHealthNotifier(useCase);
    });
