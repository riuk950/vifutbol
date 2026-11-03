import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_flow_state.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../use_cases/authenticate_user_use_case.dart';

/// StateNotifier orchestrating authentication flows, role onboarding,
/// brute-force lockout timers, and form draft preservation.
class AuthController extends StateNotifier<AuthFlowState> {
  AuthController({
    required this.authRepository,
    required this.authenticateUserUseCase,
  }) : super(const AuthFlowState()) {
    initialize();
  }

  final AuthRepository authRepository;
  final AuthenticateUserUseCase authenticateUserUseCase;
  Timer? _lockoutTicker;

  @override
  void dispose() {
    _lockoutTicker?.cancel();
    super.dispose();
  }

  /// Restores any persisted session upon app initialization.
  Future<void> initialize() async {
    try {
      final session = await authRepository.restoreSession();
      if (session == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          session: () => null,
          isSubmitting: false,
        );
        return;
      }

      if (!session.user.onboardingCompleted) {
        state = state.copyWith(
          status: AuthStatus.needsOnboarding,
          session: () => session,
          isSubmitting: false,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          session: () => session,
          isSubmitting: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        session: () => null,
        isSubmitting: false,
      );
    }
  }

  /// Updates non-sensitive drafts during user typing or app backgrounding.
  void updateDrafts({String? email, String? fullName}) {
    state = state.copyWith(
      draftEmail: email ?? state.draftEmail,
      draftFullName: fullName ?? state.draftFullName,
    );
  }

  /// Attempts to sign in with email and password.
  /// Enforces single-flight lock, credential validation, and 60s brute-force lockout.
  Future<bool> signIn({required String email, required String password}) async {
    if (state.isSubmitting) return false;

    if (state.isLockedOut) {
      state = state.copyWith(
        lastFailure: () => AuthRateLimitFailure(
          retryAfterSeconds: state.remainingLockoutSeconds,
          message:
              'Acceso temporalmente bloqueado. Intenta nuevamente en ${state.remainingLockoutSeconds} segundos.',
        ),
      );
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      draftEmail: email,
      lastFailure: () => null,
    );

    try {
      final session = await authenticateUserUseCase.signIn(
        email: email,
        password: password,
      );

      _lockoutTicker?.cancel();
      state = state.copyWith(
        status: session.user.onboardingCompleted
            ? AuthStatus.authenticated
            : AuthStatus.needsOnboarding,
        session: () => session,
        isSubmitting: false,
        failedAttempts: 0,
        lockedUntil: () => null,
        draftEmail: '',
        lastFailure: () => null,
      );
      return true;
    } on InvalidCredentialsFailure catch (e) {
      final newFailures = state.failedAttempts + 1;
      DateTime? lockoutTime;

      if (newFailures >= 5) {
        lockoutTime = clock.now().add(const Duration(seconds: 60));
        _startLockoutTicker();
      }

      state = state.copyWith(
        isSubmitting: false,
        failedAttempts: newFailures,
        lockedUntil: () => lockoutTime,
        lastFailure: () => lockoutTime != null
            ? const AuthRateLimitFailure(
                retryAfterSeconds: 60,
                message:
                    'Has alcanzado 5 intentos fallidos consecutivos. Acceso bloqueado por 60 segundos.',
              )
            : e,
      );
      return false;
    } on AppFailure catch (e) {
      state = state.copyWith(isSubmitting: false, lastFailure: () => e);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        lastFailure: () => const InvalidCredentialsFailure(
          'Error inesperado al iniciar sesión. Intenta de nuevo.',
        ),
      );
      return false;
    }
  }

  /// Registers a new user account.
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(
      isSubmitting: true,
      draftFullName: fullName,
      draftEmail: email,
      lastFailure: () => null,
    );

    try {
      final session = await authenticateUserUseCase.register(
        fullName: fullName,
        email: email,
        password: password,
      );

      state = state.copyWith(
        status: AuthStatus.needsOnboarding,
        session: () => session,
        isSubmitting: false,
        failedAttempts: 0,
        lockedUntil: () => null,
        draftFullName: '',
        draftEmail: '',
        lastFailure: () => null,
      );
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(isSubmitting: false, lastFailure: () => e);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        lastFailure: () => const InvalidCredentialsFailure(
          'Error al registrar la cuenta. Intenta de nuevo.',
        ),
      );
      return false;
    }
  }

  /// Authenticates immediately as an offline guest fan.
  Future<bool> continueAsGuestFan() async {
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, lastFailure: () => null);

    try {
      final session = await authenticateUserUseCase.continueAsGuestFan();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        session: () => session,
        isSubmitting: false,
        failedAttempts: 0,
        lockedUntil: () => null,
        draftFullName: '',
        draftEmail: '',
        lastFailure: () => null,
      );
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(isSubmitting: false, lastFailure: () => e);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        lastFailure: () => const InvalidCredentialsFailure(
          'No se pudo iniciar el modo aficionado invitado.',
        ),
      );
      return false;
    }
  }

  /// Completes the sports role onboarding process.
  Future<bool> completeRoleOnboarding({
    required UserRole selectedRole,
    String? authorizationCode,
  }) async {
    final currentSession = state.session;
    if (currentSession == null) return false;
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, lastFailure: () => null);

    try {
      final updatedUser = await authRepository.completeRoleOnboarding(
        userId: currentSession.user.id,
        selectedRole: selectedRole,
        authorizationCode: authorizationCode,
      );

      final updatedSession = currentSession.copyWith(user: updatedUser);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        session: () => updatedSession,
        isSubmitting: false,
        lastFailure: () => null,
      );
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(isSubmitting: false, lastFailure: () => e);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        lastFailure: () => const InvalidCredentialsFailure(
          'Error al completar el onboarding de rol.',
        ),
      );
      return false;
    }
  }

  /// Switches active role among authorized roles.
  Future<bool> switchActiveRole(UserRole targetRole) async {
    final currentSession = state.session;
    if (currentSession == null) return false;

    try {
      final updatedUser = await authRepository.switchActiveRole(
        userId: currentSession.user.id,
        targetRole: targetRole,
      );

      final updatedSession = currentSession.copyWith(user: updatedUser);
      state = state.copyWith(
        session: () => updatedSession,
        lastFailure: () => null,
      );
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(lastFailure: () => e);
      return false;
    } catch (_) {
      state = state.copyWith(
        lastFailure: () =>
            const UnauthorizedRoleFailure('Error al cambiar de rol deportivo.'),
      );
      return false;
    }
  }

  /// Logs out the user and clears stored session.
  Future<void> signOut() async {
    _lockoutTicker?.cancel();
    try {
      await authRepository.signOut();
    } catch (_) {}

    state = const AuthFlowState(status: AuthStatus.unauthenticated);
  }

  void _startLockoutTicker() {
    _lockoutTicker?.cancel();
    _lockoutTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isLockedOut) {
        timer.cancel();
        state = state.copyWith(
          lockedUntil: () => null,
          failedAttempts: 0,
          lastFailure: () => null,
        );
      } else {
        // Trigger state refresh for countdown rendering
        state = state.copyWith();
      }
    });
  }
}
