/// Status representing the health and connectivity check with the Supabase backend.
enum BackendHealthStatus {
  /// No credentials provided; operating purely in local offline mode (Hive).
  unconfigured,

  /// Health check probe currently in progress.
  checking,

  /// Handshake succeeded with HTTP 200 OK against PostgREST (/rest/v1/).
  healthy,

  /// Host unreachable, timeout, network error, or unexpected HTTP status.
  unreachable,
}

/// Detailed result of a backend health check probe.
class BackendHealthCheckResult {
  final BackendHealthStatus status;
  final int? httpStatusCode;
  final Duration latency;
  final String? errorMessage;
  final DateTime timestamp;

  const BackendHealthCheckResult({
    required this.status,
    this.httpStatusCode,
    required this.latency,
    this.errorMessage,
    required this.timestamp,
  });

  /// Factory constructor for unconfigured state.
  factory BackendHealthCheckResult.unconfigured() {
    return BackendHealthCheckResult(
      status: BackendHealthStatus.unconfigured,
      latency: Duration.zero,
      timestamp: DateTime.now(),
      errorMessage: 'Supabase credentials not configured.',
    );
  }

  /// Factory constructor for checking state.
  factory BackendHealthCheckResult.checking() {
    return BackendHealthCheckResult(
      status: BackendHealthStatus.checking,
      latency: Duration.zero,
      timestamp: DateTime.now(),
    );
  }

  /// Convenience getter indicating if the backend is confirmed healthy.
  bool get isHealthy => status == BackendHealthStatus.healthy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackendHealthCheckResult &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          httpStatusCode == other.httpStatusCode &&
          latency == other.latency &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      status.hashCode ^
      httpStatusCode.hashCode ^
      latency.hashCode ^
      errorMessage.hashCode;

  @override
  String toString() {
    return 'BackendHealthCheckResult(status: ${status.name}, '
        'httpStatusCode: $httpStatusCode, latency: ${latency.inMilliseconds}ms, '
        'errorMessage: $errorMessage, timestamp: $timestamp)';
  }
}
