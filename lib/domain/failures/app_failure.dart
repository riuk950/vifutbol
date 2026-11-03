/// Sealed failure hierarchy for the vifutbol application foundation.
/// All user-facing messages must be sanitized and free of sensitive credentials.
sealed class AppFailure {
  final String message;
  final Object? cause;

  const AppFailure(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message';
}

/// Emitted when local persistence storage fails to initialize.
class StorageInitializationFailure extends AppFailure {
  const StorageInitializationFailure(super.message, [super.cause]);
}

/// Emitted when configuration parameters for the environment are invalid or conflicted.
class EnvironmentValidationFailure extends AppFailure {
  const EnvironmentValidationFailure(super.message, [super.cause]);
}

/// Emitted when network connectivity checks or state streams fail.
class ConnectivityFailure extends AppFailure {
  const ConnectivityFailure(super.message, [super.cause]);
}

/// Emitted when a data loading operation fails unexpectedly.
class DataLoadFailure extends AppFailure {
  const DataLoadFailure(super.message, [super.cause]);
}
