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

/// Emitted when user registration or sign-in requires email verification before issuing a session.
class EmailVerificationRequiredFailure extends AppFailure {
  const EmailVerificationRequiredFailure([
    super.message =
        'Cuenta creada. Revisa tu correo para confirmar tu cuenta antes de iniciar sesión.',
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

/// Machine-readable error codes for championship tournament validation rules.
enum TournamentValidationErrorCode {
  invalidName,
  invalidCategory,
  invalidDateRange,
  invalidPointsDistribution,
  invalidTiebreakerOrder,
  invalidYellowCardLimit,
  invalidSquadSizeRange,
  invalidHalfDuration,
  invalidLeagueRounds,
  invalidGroupStageConfig,
  criticalRulesImmutableWithoutAudit,
  tournamentAlreadyFinished,
  invalidBackupPackage,
  missingTwoStepConfirmation,
  pendingMandatoryMatchesForSeasonClosure,
  invalidStatusTransition,
  insufficientTeamsToStart,
  missingFixtureToStart,
  tournamentCannotBeDeleted,
}

/// Emitted when championship tournament or custom rule validation fails.
class TournamentValidationFailure extends AppFailure {
  final TournamentValidationErrorCode code;

  const TournamentValidationFailure(
    this.code, [
    super.message = 'Configuración de campeonato o reglas inválida',
    super.cause,
  ]);
}

/// Machine-readable error codes for team registration and player eligibility.
enum TeamEligibilityErrorCode {
  tournamentRegistrationsClosed,
  invalidTeamName,
  invalidShortCode,
  duplicateTeamNameInTournament,
  invalidPlayerName,
  invalidDocumentId,
  invalidShirtNumber,
  duplicateShirtNumberInTeam,
  playerAlreadyRegisteredInTournament,
  maxPlayersQuotaReached,
  insufficientPlayersForApproval,
  teamNotFound,
  teamHasPlayedMatches,
  playerAlreadyHasPendingRequest,
  shirtNumberAlreadyReserved,
  joinRequestNotFound,
}

/// Emitted when team enrollment, player registration, or eligibility validation fails.
class TeamEligibilityValidationFailure extends AppFailure {
  final TeamEligibilityErrorCode code;

  const TeamEligibilityValidationFailure(
    this.code, [
    super.message = 'Validación de equipo o elegibilidad fallida',
    super.cause,
  ]);
}

/// Machine-readable error codes for coach match convocations and internal tracking.
enum LineupConvocationErrorCode {
  unauthorizedRole,
  teamNotFound,
  teamNotEligible,
  suspendedPlayerSelected,
  invalidStartersCount,
  missingCaptain,
  invalidTrackingMetrics,
}

/// Emitted when match convocation, lineup validation, or internal tracking fails.
class LineupConvocationValidationFailure extends AppFailure {
  final LineupConvocationErrorCode code;
  final String? details;

  const LineupConvocationValidationFailure(
    this.code, [
    super.message = 'Validación de convocatoria o alineación fallida',
    this.details,
    super.cause,
  ]);
}

/// Machine-readable error codes for tournament fixture generation and match scheduling.
enum FixtureScheduleErrorCode {
  unauthorizedRole,
  insufficientTeams,
  tournamentClosed,
  regenerationBlocked,
  invalidScheduleTimes,
  pitchScheduleCollision,
  refereeScheduleCollision,
  teamScheduleCollision,
}

/// Emitted when fixture generation, match scheduling, or collision validation fails.
class FixtureScheduleValidationFailure extends AppFailure {
  final FixtureScheduleErrorCode code;
  final String? conflictingMatchId;
  final String? conflictingEntityName;

  const FixtureScheduleValidationFailure(
    this.code, [
    super.message = 'Validación de fixture o programación fallida',
    this.conflictingMatchId,
    this.conflictingEntityName,
    super.cause,
  ]);
}

/// Machine-readable error codes for digital match report operations.
enum MatchReportErrorCode {
  unauthorizedRole,
  reportAlreadyClosed,
  matchNotInProgress,
  invalidMinute,
  playerAlreadyExpelled,
  invalidAssistantPlayer,
  invalidSubstitutionPlayers,
}

/// Emitted when digital match report operations or event validations fail.
class MatchReportValidationFailure extends AppFailure {
  final MatchReportErrorCode code;
  final String? details;

  const MatchReportValidationFailure(
    this.code, [
    super.message = 'Validación de acta digital de partido fallida',
    this.details,
    super.cause,
  ]);
}

/// Emitted when a player or referee attempts to link an identity document
/// that is already claimed by a different user account.
class DocumentAlreadyLinkedFailure extends AppFailure {
  const DocumentAlreadyLinkedFailure([
    super.message =
        'El documento ingresado ya está vinculado a otra cuenta de usuario.',
    super.cause,
  ]);
}

/// Emitted when camera access is denied by the user or restricted by the OS.
class CameraPermissionDeniedFailure extends AppFailure {
  final bool isPermanentlyDenied;

  const CameraPermissionDeniedFailure([
    super.message = 'Se requiere permiso de cámara para capturar la cédula.',
    this.isPermanentlyDenied = false,
    super.cause,
  ]);
}

/// Emitted when uploading document photos to private storage fails.
class DocumentUploadFailure extends AppFailure {
  const DocumentUploadFailure([
    super.message =
        'Error al subir las imágenes de la cédula. Inténtalo nuevamente.',
    super.cause,
  ]);
}

