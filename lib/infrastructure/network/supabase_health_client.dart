import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/backend_health_status.dart';

/// HTTP Client probe for performing deterministic health check handshakes
/// against the PostgREST root endpoint (`/rest/v1/`) on the Supabase host.
class SupabaseHealthClient {
  final http.Client _client;

  SupabaseHealthClient({http.Client? client})
    : _client = client ?? http.Client();

  /// Probes the Supabase PostgREST root (`/rest/v1/`) with the provided [config].
  Future<BackendHealthCheckResult> checkHealth(
    SupabaseConfig config, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!config.isConfigured) {
      return BackendHealthCheckResult.unconfigured();
    }

    final normalizedUrl = config.url.endsWith('/')
        ? config.url.substring(0, config.url.length - 1)
        : config.url;
    final usesIsolatedSchema = config.schema != 'public';
    final probeUri = usesIsolatedSchema
        ? Uri.parse('$normalizedUrl/rest/v1/tournaments?select=id&limit=1')
        : Uri.parse('$normalizedUrl/rest/v1/');

    final headers = usesIsolatedSchema
        ? {
            'apikey': config.anonKey,
            'Authorization': 'Bearer ${config.anonKey}',
            'Accept-Profile': config.schema,
            'Accept': 'application/json',
          }
        : {
            'apikey': config.anonKey,
            'Accept': 'application/openapi+json, application/json',
          };

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .get(probeUri, headers: headers)
          .timeout(timeout);
      stopwatch.stop();

      if (response.statusCode == 200) {
        return BackendHealthCheckResult(
          status: BackendHealthStatus.healthy,
          httpStatusCode: response.statusCode,
          latency: stopwatch.elapsed,
          timestamp: DateTime.now(),
        );
      } else {
        return BackendHealthCheckResult(
          status: BackendHealthStatus.unreachable,
          httpStatusCode: response.statusCode,
          latency: stopwatch.elapsed,
          errorMessage:
              'Backend responded with HTTP status ${response.statusCode}.',
          timestamp: DateTime.now(),
        );
      }
    } on TimeoutException {
      stopwatch.stop();
      return BackendHealthCheckResult(
        status: BackendHealthStatus.unreachable,
        latency: stopwatch.elapsed,
        errorMessage:
            'Health check probe timed out after ${timeout.inSeconds}s.',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      stopwatch.stop();
      return BackendHealthCheckResult(
        status: BackendHealthStatus.unreachable,
        latency: stopwatch.elapsed,
        errorMessage: 'Health check failed: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Closes internal resources if created.
  void dispose() {
    _client.close();
  }
}
