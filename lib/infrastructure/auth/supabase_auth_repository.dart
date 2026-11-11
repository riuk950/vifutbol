import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as gotrue show User;

import '../../domain/entities/app_environment.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/connectivity_repository.dart';
import '../../domain/repositories/local_storage_repository.dart';
import 'local_auth_repository.dart';

/// Abstraction over PostgREST queries targeting `vifutboldev.user_accounts`
/// to keep [SupabaseAuthRepository] cleanly testable without mocking builders.
abstract class SupabaseUserProfileDataSource {
  /// Fetches a `user_accounts` row matching [authUserId], or `null` if absent.
  Future<Map<String, dynamic>?> fetchByAuthUserId(String authUserId);

  /// Idempotently upserts a profile row keyed on `auth_user_id` and returns it.
  Future<Map<String, dynamic>> upsertProfile(Map<String, dynamic> payload);

  /// Updates the role selection and onboarding status for [authUserId].
  Future<Map<String, dynamic>> updateRoleState({
    required String authUserId,
    required String activeRole,
    required List<String> authorizedRoles,
    required bool onboardingCompleted,
  });
}

class _PostgrestUserProfileDataSource implements SupabaseUserProfileDataSource {
  _PostgrestUserProfileDataSource({required this.client, required this.schema});

  final SupabaseClient client;
  final String schema;

  @override
  Future<Map<String, dynamic>?> fetchByAuthUserId(String authUserId) {
    return client
        .schema(schema)
        .from('user_accounts')
        .select()
        .eq('auth_user_id', authUserId)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> upsertProfile(Map<String, dynamic> payload) {
    return client
        .schema(schema)
        .from('user_accounts')
        .upsert(payload, onConflict: 'auth_user_id')
        .select()
        .single();
  }

  @override
  Future<Map<String, dynamic>> updateRoleState({
    required String authUserId,
    required String activeRole,
    required List<String> authorizedRoles,
    required bool onboardingCompleted,
  }) {
    return client
        .schema(schema)
        .from('user_accounts')
        .update({
          'active_role': activeRole,
          'authorized_roles': authorizedRoles,
          'onboarding_completed': onboardingCompleted,
        })
        .eq('auth_user_id', authUserId)
        .select()
        .single();
  }
}

/// Remote [AuthRepository] adapter backed by Supabase Auth (GoTrue) and
/// the `user_accounts` table in the configured schema (`vifutboldev` in DEV).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required this.client,
    required this.storage,
    required this.connectivity,
    required this.config,
    SupabaseUserProfileDataSource? profileDataSource,
    String? schema,
  }) : schema = schema ?? config.supabase.schema,
       _profileDataSource =
           profileDataSource ??
           _PostgrestUserProfileDataSource(
             client: client,
             schema: schema ?? config.supabase.schema,
           );

  final SupabaseClient client;
  final LocalStorageRepository storage;
  final ConnectivityRepository connectivity;
  final EnvironmentConfig config;
  final String schema;
  final SupabaseUserProfileDataSource _profileDataSource;

  static const String _sessionKey = 'auth_session';
  static const String officialAuthorizationCode =
      LocalAuthRepository.officialAuthorizationCode;

  /// Maps a database row from `user_accounts` into a domain [UserAccount].
  static UserAccount mapRowToUserAccount(Map<String, dynamic> row) {
    final activeRole = _parseUserRole(row['active_role'] as String?);
    final rawRoles = row['authorized_roles'];
    final authorizedRoles = <UserRole>{activeRole, UserRole.fan};
    if (rawRoles is Iterable) {
      for (final item in rawRoles) {
        if (item is String) {
          authorizedRoles.add(_parseUserRole(item));
        }
      }
    }

    final rawName = (row['full_name'] as String?)?.trim() ?? '';
    final email = (row['email'] as String? ?? '').trim().toLowerCase();
    final id = (row['id'] ?? row['auth_user_id'] ?? '').toString();

    return UserAccount(
      id: id,
      fullName: rawName.isEmpty ? 'Usuario KickPulse' : rawName,
      email: email,
      activeRole: activeRole,
      authorizedRoles: authorizedRoles,
      isGuestFan: row['is_guest_fan'] as bool? ?? false,
      onboardingCompleted: row['onboarding_completed'] as bool? ?? false,
    );
  }

  /// Builds an idempotent `user_accounts` insert/upsert payload from GoTrue [user].
  static Map<String, dynamic> buildInitialProfilePayload(
    gotrue.User user, {
    String? fallbackFullName,
  }) {
    final normalizedEmail = (user.email ?? '').trim().toLowerCase();
    final metadataName =
        (user.userMetadata?['full_name'] as String?)?.trim() ?? '';
    final preferredName = fallbackFullName?.trim() ?? '';
    final emailPrefix = normalizedEmail.contains('@')
        ? normalizedEmail.split('@').first
        : '';

    final resolvedName = metadataName.length >= 2
        ? metadataName
        : preferredName.length >= 2
        ? preferredName
        : emailPrefix.length >= 2
        ? emailPrefix
        : 'Usuario KickPulse';

    return {
      'id': user.id,
      'auth_user_id': user.id,
      'full_name': resolvedName,
      'email': normalizedEmail,
      'active_role': UserRole.fan.name,
      'authorized_roles': <String>[UserRole.fan.name],
      'is_guest_fan': false,
      'onboarding_completed': false,
    };
  }

  static UserRole _parseUserRole(String? rawRole) {
    if (rawRole == null) return UserRole.fan;
    for (final role in UserRole.values) {
      if (role.name == rawRole) {
        return role;
      }
    }
    return UserRole.fan;
  }

  Future<void> _saveSessionToCache(AuthSession session) async {
    await storage.writeString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<AuthSession?> _readSessionFromCache() async {
    final raw = await storage.readString(_sessionKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AuthSession.fromJson(map);
    } catch (_) {
      await _clearSessionCache();
      return null;
    }
  }

  Future<void> _clearSessionCache() async {
    await storage.writeString(_sessionKey, '');
  }

  bool _isNetworkError(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is ClientException;
  }

  Future<void> _ensureConnectivity(String offlineMessage) async {
    final conn = await connectivity.checkConnectivity();
    if (conn.isDisconnected) {
      throw OfflineAuthOperationFailure(offlineMessage);
    }
  }

  AuthSession _buildAuthSession(Session session, UserAccount user) {
    return AuthSession(
      sessionId: 'supa-${session.user.id}',
      user: user,
      sessionToken: session.accessToken,
      authenticatedAt: DateTime.now().toUtc(),
    );
  }

  Future<UserAccount> _ensureProfileForUser(
    gotrue.User user, {
    String? fallbackFullName,
  }) async {
    final existing = await _profileDataSource.fetchByAuthUserId(user.id);
    if (existing != null) {
      return mapRowToUserAccount(existing);
    }

    final payload = buildInitialProfilePayload(
      user,
      fallbackFullName: fallbackFullName,
    );
    final created = await _profileDataSource.upsertProfile(payload);
    return mapRowToUserAccount(created);
  }

  AppFailure _translateError(
    Object error, {
    String fallbackMessage = 'Ocurrió un error al comunicarse con el servidor.',
  }) {
    if (error is AppFailure) {
      return error;
    }
    if (_isNetworkError(error)) {
      return const OfflineAuthOperationFailure(
        'No fue posible conectar con el servidor. Verifica tu conexión a internet.',
      );
    }
    if (error is AuthException) {
      return _mapAuthException(error);
    }
    if (error is PostgrestException) {
      if (error.code == '42501' || error.code == 'PGRST301') {
        return const UnauthorizedRoleFailure(
          'No cuentas con permisos para completar esta operación.',
        );
      }
      return OfflineAuthOperationFailure(fallbackMessage);
    }
    return OfflineAuthOperationFailure(fallbackMessage);
  }

  AppFailure _mapAuthException(AuthException error) {
    final code = (error.code ?? '').toLowerCase();
    final msg = error.message.toLowerCase();

    if (code == 'invalid_credentials' ||
        msg.contains('invalid login credentials')) {
      return const InvalidCredentialsFailure(
        'Correo o contraseña incorrectos.',
      );
    }
    if (code == 'user_already_exists' ||
        msg.contains('already registered') ||
        msg.contains('user already exists')) {
      return const InvalidCredentialsFailure(
        'Este correo ya se encuentra registrado.',
      );
    }
    if (code == 'email_not_confirmed' || msg.contains('email not confirmed')) {
      return const EmailVerificationRequiredFailure(
        'Debes confirmar tu correo electrónico antes de iniciar sesión.',
      );
    }
    if (code == 'over_request_rate_limit' ||
        error.statusCode == '429' ||
        msg.contains('rate limit')) {
      return const AuthRateLimitFailure();
    }
    return const InvalidCredentialsFailure(
      'No se pudo completar la autenticación. Verifica tus datos.',
    );
  }

  @override
  Stream<AuthSession?> get onSessionStateChanged {
    return client.auth.onAuthStateChange.asyncExpand((authState) async* {
      switch (authState.event) {
        case AuthChangeEvent.signedOut:
          await _clearSessionCache();
          yield null;
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          final session = authState.session;
          if (session == null) {
            return;
          }
          UserAccount account;
          try {
            account = await _ensureProfileForUser(session.user);
          } catch (_) {
            final cached = await _readSessionFromCache();
            if (cached != null && cached.user.id == session.user.id) {
              account = cached.user;
            } else {
              account = mapRowToUserAccount(
                buildInitialProfilePayload(session.user),
              );
            }
          }
          final mappedSession = _buildAuthSession(session, account);
          await _saveSessionToCache(mappedSession);
          yield mappedSession;
        default:
          return;
      }
    });
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final activeSession = client.auth.currentSession;
    final cached = await _readSessionFromCache();

    if (activeSession == null) {
      if (cached != null && cached.isGuestFan) {
        return cached;
      }
      return null;
    }

    final conn = await connectivity.checkConnectivity();
    if (conn.isDisconnected) {
      if (cached != null && !cached.isGuestFan) {
        return cached;
      }
      final fallbackUser = mapRowToUserAccount(
        buildInitialProfilePayload(activeSession.user),
      );
      return _buildAuthSession(activeSession, fallbackUser);
    }

    try {
      var effectiveSession = activeSession;
      if (activeSession.isExpired) {
        final refreshed = await client.auth.refreshSession();
        if (refreshed.session == null) {
          await _clearSessionCache();
          return null;
        }
        effectiveSession = refreshed.session!;
      }

      final account = await _ensureProfileForUser(effectiveSession.user);
      final authSession = _buildAuthSession(effectiveSession, account);
      await _saveSessionToCache(authSession);
      return authSession;
    } on AuthException {
      await _clearSessionCache();
      return null;
    } catch (error) {
      if (_isNetworkError(error) && cached != null && !cached.isGuestFan) {
        return cached;
      }
      return cached != null && !cached.isGuestFan ? cached : null;
    }
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _ensureConnectivity(
      'No hay conexión a internet para iniciar sesión.',
    );

    final normalizedEmail = email.trim().toLowerCase();
    try {
      final response = await client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      final session = response.session;
      if (session == null) {
        throw const InvalidCredentialsFailure(
          'No se pudo iniciar sesión en el servidor.',
        );
      }

      final account = await _ensureProfileForUser(session.user);
      final authSession = _buildAuthSession(session, account);
      await _saveSessionToCache(authSession);
      return authSession;
    } catch (error) {
      throw _translateError(
        error,
        fallbackMessage: 'No se pudo iniciar sesión. Intenta nuevamente.',
      );
    }
  }

  @override
  Future<AuthSession> registerAccount({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _ensureConnectivity(
      'No hay conexión a internet para registrar tu cuenta.',
    );

    final trimmedName = fullName.trim();
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final response = await client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {'full_name': trimmedName},
      );

      final session = response.session;
      if (session == null) {
        throw const EmailVerificationRequiredFailure();
      }

      final account = await _ensureProfileForUser(
        session.user,
        fallbackFullName: trimmedName,
      );
      final authSession = _buildAuthSession(session, account);
      await _saveSessionToCache(authSession);
      return authSession;
    } catch (error) {
      throw _translateError(
        error,
        fallbackMessage:
            'No se pudo completar el registro. Intenta nuevamente.',
      );
    }
  }

  @override
  Future<AuthSession> continueAsGuestFan() async {
    final now = DateTime.now().toUtc();
    final guestId = 'guest-${now.millisecondsSinceEpoch}';

    final guestAccount = UserAccount(
      id: guestId,
      fullName: 'Aficionado Invitado',
      email: 'guest@vifutbol.local',
      activeRole: UserRole.fan,
      authorizedRoles: const {UserRole.fan},
      isGuestFan: true,
      onboardingCompleted: true,
    );

    final sessionId = 'session-${now.millisecondsSinceEpoch}';
    final session = AuthSession(
      sessionId: sessionId,
      user: guestAccount,
      sessionToken: 'guest-token-$sessionId',
      authenticatedAt: now,
    );

    await _saveSessionToCache(session);
    return session;
  }

  @override
  Future<UserAccount> completeRoleOnboarding({
    required String userId,
    required UserRole selectedRole,
    String? authorizationCode,
  }) async {
    final isProd = config.environment == AppEnvironment.production;
    if (isProd && selectedRole.requiresAuthorizationCodeInProd) {
      final code = authorizationCode?.trim().toUpperCase();
      if (code == null || code != officialAuthorizationCode) {
        throw const InvalidAuthorizationCodeFailure(
          'El código de autorización para este rol oficial es inválido.',
        );
      }
    }

    final session = client.auth.currentSession;
    if (session == null) {
      throw const InvalidCredentialsFailure('Sesión no encontrada.');
    }

    await _ensureConnectivity(
      'Se requiere conexión a internet para guardar tu rol.',
    );

    try {
      final currentAccount = await _ensureProfileForUser(session.user);
      if (currentAccount.id != userId && session.user.id != userId) {
        throw const InvalidCredentialsFailure('Sesión no encontrada.');
      }

      final updatedRoles = Set<UserRole>.from(currentAccount.authorizedRoles)
        ..add(selectedRole)
        ..add(UserRole.fan);

      final updatedRow = await _profileDataSource.updateRoleState(
        authUserId: session.user.id,
        activeRole: selectedRole.name,
        authorizedRoles: updatedRoles.map((r) => r.name).toList(),
        onboardingCompleted: true,
      );

      final updatedAccount = mapRowToUserAccount(updatedRow);
      await _saveSessionToCache(_buildAuthSession(session, updatedAccount));
      return updatedAccount;
    } catch (error) {
      throw _translateError(
        error,
        fallbackMessage: 'No se pudo completar la configuración de rol.',
      );
    }
  }

  @override
  Future<UserAccount> switchActiveRole({
    required String userId,
    required UserRole targetRole,
  }) async {
    final session = client.auth.currentSession;
    if (session == null) {
      throw const InvalidCredentialsFailure('Sesión no encontrada.');
    }

    final isDev = config.environment == AppEnvironment.development;

    try {
      final currentAccount = await _ensureProfileForUser(session.user);
      if (currentAccount.id != userId && session.user.id != userId) {
        throw const InvalidCredentialsFailure('Sesión no encontrada.');
      }

      if (!isDev && !currentAccount.authorizedRoles.contains(targetRole)) {
        throw const UnauthorizedRoleFailure(
          'No tienes autorización para activar este rol deportivo.',
        );
      }

      await _ensureConnectivity(
        'Se requiere conexión a internet para cambiar de rol.',
      );

      final updatedRoles = Set<UserRole>.from(currentAccount.authorizedRoles)
        ..add(targetRole)
        ..add(UserRole.fan);

      final updatedRow = await _profileDataSource.updateRoleState(
        authUserId: session.user.id,
        activeRole: targetRole.name,
        authorizedRoles: updatedRoles.map((r) => r.name).toList(),
        onboardingCompleted: currentAccount.onboardingCompleted,
      );

      final updatedAccount = mapRowToUserAccount(updatedRow);
      await _saveSessionToCache(_buildAuthSession(session, updatedAccount));
      return updatedAccount;
    } catch (error) {
      throw _translateError(
        error,
        fallbackMessage: 'No se pudo cambiar el rol activo.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (_) {
      // Tolerates offline sign-out so local session cleanup always succeeds.
    } finally {
      await _clearSessionCache();
    }
  }
}
