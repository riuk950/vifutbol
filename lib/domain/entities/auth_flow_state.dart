import 'package:clock/clock.dart';

import '../failures/app_failure.dart';
import 'auth_session.dart';

/// Represents the high-level authentication lifecycle status.
enum AuthStatus {
  /// Session is being hydrated from local storage.
  initializing,

  /// No authenticated session active; user must log in or continue as guest.
  unauthenticated,

  /// Account exists but has not completed required role onboarding.
  needsOnboarding,

  /// Fully authenticated session with completed role onboarding.
  authenticated,
}

/// Immutable state modeling the complete authentication flow.
class AuthFlowState {
  const AuthFlowState({
    this.status = AuthStatus.initializing,
    this.session,
    this.isSubmitting = false,
    this.failedAttempts = 0,
    this.lockedUntil,
    this.draftEmail = '',
    this.draftFullName = '',
    this.lastFailure,
  });

  /// Current authentication stage.
  final AuthStatus status;

  /// Active authentication session, if any.
  final AuthSession? session;

  /// Single-flight in-progress operation flag to prevent double-tap submissions.
  final bool isSubmitting;

  /// Counter of consecutive failed login attempts.
  final int failedAttempts;

  /// Timestamp until which login attempts are locked out (60-second brute-force guard).
  final DateTime? lockedUntil;

  /// Preserved draft email to retain user input across app backgrounding.
  final String draftEmail;

  /// Preserved draft full name to retain registration input across app backgrounding.
  final String draftFullName;

  /// Last failure encountered during an auth operation, if any.
  final AppFailure? lastFailure;

  /// Convenience getter checking if login attempts are currently locked out.
  bool get isLockedOut {
    final lock = lockedUntil;
    if (lock == null) return false;
    return clock.now().isBefore(lock);
  }

  /// Remaining seconds in brute-force lockout window.
  int get remainingLockoutSeconds {
    final lock = lockedUntil;
    if (lock == null) return 0;
    final diff = lock.difference(clock.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Returns true if a valid authenticated user or guest session is present.
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;

  /// Returns true if currently operating as a guest fan.
  bool get isGuestFan => session?.isGuestFan ?? false;

  AuthFlowState copyWith({
    AuthStatus? status,
    AuthSession? Function()? session,
    bool? isSubmitting,
    int? failedAttempts,
    DateTime? Function()? lockedUntil,
    String? draftEmail,
    String? draftFullName,
    AppFailure? Function()? lastFailure,
  }) {
    return AuthFlowState(
      status: status ?? this.status,
      session: session != null ? session() : this.session,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil != null ? lockedUntil() : this.lockedUntil,
      draftEmail: draftEmail ?? this.draftEmail,
      draftFullName: draftFullName ?? this.draftFullName,
      lastFailure: lastFailure != null ? lastFailure() : this.lastFailure,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthFlowState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          session == other.session &&
          isSubmitting == other.isSubmitting &&
          failedAttempts == other.failedAttempts &&
          lockedUntil == other.lockedUntil &&
          draftEmail == other.draftEmail &&
          draftFullName == other.draftFullName &&
          lastFailure == other.lastFailure;

  @override
  int get hashCode => Object.hash(
    status,
    session,
    isSubmitting,
    failedAttempts,
    lockedUntil,
    draftEmail,
    draftFullName,
    lastFailure,
  );
}
