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

/// Emitted when authentication fails due to incorrect email or password.
class InvalidCredentialsFailure extends AppFailure {
  const InvalidCredentialsFailure([
    super.message = 'Correo o contraseña incorrectos',
    super.cause,
  ]);
}

/// Emitted when login attempts exceed the rate limit threshold (5 attempts -> 60s lockout).
class AuthRateLimitFailure extends AppFailure {
  final int retryAfterSeconds;

  const AuthRateLimitFailure({
    this.retryAfterSeconds = 60,
    String message = 'Demasiados intentos fallidos. Intenta más tarde.',
    Object? cause,
  }) : super(message, cause);
}

/// Emitted when a new login or registration is attempted without active internet connection.
class OfflineAuthOperationFailure extends AppFailure {
  const OfflineAuthOperationFailure([
    super.message =
        'Se requiere conexión a internet para iniciar sesión o registrarse',
    super.cause,
  ]);
}

/// Emitted when an action is attempted by a user lacking the required role or capability.
class UnauthorizedRoleFailure extends AppFailure {
  const UnauthorizedRoleFailure([
    super.message = 'Acceso restringido para tu rol actual',
    super.cause,
  ]);
}

/// Emitted when an invalid tournament authorization code is supplied for organizer or referee.
class InvalidAuthorizationCodeFailure extends AppFailure {
  const InvalidAuthorizationCodeFailure([
    super.message = 'Código de autorización inválido para el rol seleccionado',
    super.cause,
  ]);
}

/// Emitted when venue or pitch data validation fails.
class InvalidVenueDataFailure extends AppFailure {
  const InvalidVenueDataFailure([
    super.message = 'Datos de la sede o canchas inválidos',
    super.cause,
  ]);
}

/// Emitted when location permission or service access encounters an issue.
class LocationPermissionFailure extends AppFailure {
  const LocationPermissionFailure([
    super.message = 'No se pudo obtener la ubicación del dispositivo',
    super.cause,
  ]);
}
