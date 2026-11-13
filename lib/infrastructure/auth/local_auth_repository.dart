import 'dart:convert';

import '../../domain/entities/app_environment.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/role_profile_data.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/connectivity_repository.dart';
import '../../domain/repositories/local_storage_repository.dart';

/// Implementation of [AuthRepository] persisting sessions and accounts
/// to local storage with network and environment enforcement.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    required this.storage,
    required this.connectivity,
    required this.config,
  });

  final LocalStorageRepository storage;
  final ConnectivityRepository connectivity;
  final EnvironmentConfig config;

  static const String _sessionKey = 'auth_session';
  static const String _accountsKey = 'auth_accounts';
  static const String _passwordsKey = 'auth_passwords';

  /// Standard official authorization code for organizers and referees in production.
  static const String officialAuthorizationCode = 'VIFUTBOL-PRO-2026';

  @override
  Stream<AuthSession?> get onSessionStateChanged => const Stream.empty();

  @override
  Future<AuthSession?> restoreSession() async {
    final raw = await storage.readString(_sessionKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AuthSession.fromJson(map);
    } catch (_) {
      await storage.writeString(_sessionKey, '');
      return null;
    }
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final conn = await connectivity.checkConnectivity();
    if (conn.isDisconnected) {
      throw const OfflineAuthOperationFailure(
        'No hay conexión a internet para iniciar sesión.',
      );
    }

    final normalizedEmail = email.trim().toLowerCase();
    final accounts = await _getStoredAccounts();
    final passwords = await _getStoredPasswords();

    final storedPassword = passwords[normalizedEmail];
    final account = accounts[normalizedEmail];

    if (storedPassword == null ||
        account == null ||
        storedPassword != password) {
      throw const InvalidCredentialsFailure('Correo o contraseña incorrectos.');
    }

    final now = DateTime.now();
    final sessionId = 'session-${now.millisecondsSinceEpoch}';
    final session = AuthSession(
      sessionId: sessionId,
      user: account,
      sessionToken: 'token-$sessionId-${account.id}',
      authenticatedAt: now,
    );

    await storage.writeString(_sessionKey, jsonEncode(session.toJson()));
    return session;
  }

  @override
  Future<AuthSession> registerAccount({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final conn = await connectivity.checkConnectivity();
    if (conn.isDisconnected) {
      throw const OfflineAuthOperationFailure(
        'No hay conexión a internet para registrar tu cuenta.',
      );
    }

    final normalizedEmail = email.trim().toLowerCase();
    final trimmedName = fullName.trim();
    final now = DateTime.now();
    final userId = 'user-${now.millisecondsSinceEpoch}';

    final account = UserAccount(
      id: userId,
      fullName: trimmedName,
      email: normalizedEmail,
      activeRole: UserRole.fan,
      authorizedRoles: const {UserRole.fan},
      isGuestFan: false,
      onboardingCompleted: false,
    );

    final accounts = await _getStoredAccounts();
    final passwords = await _getStoredPasswords();

    accounts[normalizedEmail] = account;
    passwords[normalizedEmail] = password;

    await _saveAccounts(accounts);
    await _savePasswords(passwords);

    final sessionId = 'session-${now.millisecondsSinceEpoch}';
    final session = AuthSession(
      sessionId: sessionId,
      user: account,
      sessionToken: 'token-$sessionId-$userId',
      authenticatedAt: now,
    );

    await storage.writeString(_sessionKey, jsonEncode(session.toJson()));
    return session;
  }

  @override
  Future<AuthSession> continueAsGuestFan() async {
    final now = DateTime.now();
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

    await storage.writeString(_sessionKey, jsonEncode(session.toJson()));
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

    final currentSession = await restoreSession();
    if (currentSession == null || currentSession.user.id != userId) {
      throw const InvalidCredentialsFailure('Sesión no encontrada.');
    }

    final currentUser = currentSession.user;
    final updatedRoles = Set<UserRole>.from(currentUser.authorizedRoles)
      ..add(selectedRole)
      ..add(UserRole.fan);

    final updatedUser = currentUser.copyWith(
      activeRole: selectedRole,
      authorizedRoles: updatedRoles,
      onboardingCompleted: true,
    );

    final updatedSession = currentSession.copyWith(user: updatedUser);
    await storage.writeString(_sessionKey, jsonEncode(updatedSession.toJson()));

    if (!updatedUser.isGuestFan && updatedUser.email.isNotEmpty) {
      final accounts = await _getStoredAccounts();
      accounts[updatedUser.email] = updatedUser;
      await _saveAccounts(accounts);
    }

    return updatedUser;
  }

  @override
  Future<UserAccount> switchActiveRole({
    required String userId,
    required UserRole targetRole,
  }) async {
    final currentSession = await restoreSession();
    if (currentSession == null || currentSession.user.id != userId) {
      throw const InvalidCredentialsFailure('Sesión no encontrada.');
    }

    final currentUser = currentSession.user;
    final isDev = config.environment == AppEnvironment.development;

    if (!isDev && !currentUser.authorizedRoles.contains(targetRole)) {
      throw const UnauthorizedRoleFailure(
        'No tienes autorización para activar este rol deportivo.',
      );
    }

    final updatedRoles = Set<UserRole>.from(currentUser.authorizedRoles)
      ..add(targetRole);

    final updatedUser = currentUser.copyWith(
      activeRole: targetRole,
      authorizedRoles: updatedRoles,
    );

    final updatedSession = currentSession.copyWith(user: updatedUser);
    await storage.writeString(_sessionKey, jsonEncode(updatedSession.toJson()));

    if (!updatedUser.isGuestFan && updatedUser.email.isNotEmpty) {
      final accounts = await _getStoredAccounts();
      accounts[updatedUser.email] = updatedUser;
      await _saveAccounts(accounts);
    }

    return updatedUser;
  }

  @override
  Future<UserAccount> updateRoleProfile({
    required String userId,
    required UserRole role,
    String? phone,
    String? documentId,
    RoleProfileData? roleProfile,
  }) async {
    final conn = await connectivity.checkConnectivity();
    if (conn.isDisconnected) {
      throw const OfflineAuthOperationFailure(
        'Se requiere conexión a internet para guardar tu perfil.',
      );
    }

    final currentSession = await restoreSession();
    if (currentSession == null || currentSession.user.id != userId) {
      throw const InvalidCredentialsFailure('Sesión no encontrada.');
    }

    final currentUser = currentSession.user;
    final mergedProfile = RoleProfileData(
      clubName: roleProfile?.clubName ?? currentUser.roleProfile?.clubName,
      licenseLevel:
          roleProfile?.licenseLevel ?? currentUser.roleProfile?.licenseLevel,
      organizationName: roleProfile?.organizationName ??
          currentUser.roleProfile?.organizationName,
      baseCity: roleProfile?.baseCity ?? currentUser.roleProfile?.baseCity,
      city: roleProfile?.city ?? currentUser.roleProfile?.city,
      preferences:
          roleProfile?.preferences ?? currentUser.roleProfile?.preferences,
      certificationLevel: roleProfile?.certificationLevel ??
          currentUser.roleProfile?.certificationLevel,
      linkedPlayerId: roleProfile?.linkedPlayerId ??
          currentUser.roleProfile?.linkedPlayerId,
      linkedRefereeId: roleProfile?.linkedRefereeId ??
          currentUser.roleProfile?.linkedRefereeId,
    );

    final updatedUser = currentUser.copyWith(
      activeRole: role,
      phone: phone?.trim().isNotEmpty == true
          ? phone!.trim()
          : currentUser.phone,
      documentId: documentId?.trim().isNotEmpty == true
          ? documentId!.trim()
          : currentUser.documentId,
      roleProfile: mergedProfile,
    );

    final updatedSession = currentSession.copyWith(user: updatedUser);
    await storage.writeString(_sessionKey, jsonEncode(updatedSession.toJson()));

    if (!updatedUser.isGuestFan && updatedUser.email.isNotEmpty) {
      final accounts = await _getStoredAccounts();
      accounts[updatedUser.email] = updatedUser;
      await _saveAccounts(accounts);
    }

    return updatedUser;
  }

  @override
  Future<void> signOut() async {
    await storage.writeString(_sessionKey, '');
  }

  Future<Map<String, UserAccount>> _getStoredAccounts() async {
    final raw = await storage.readString(_accountsKey);
    if (raw == null || raw.trim().isEmpty) {
      return {};
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map(
        (key, value) =>
            MapEntry(key, UserAccount.fromJson(value as Map<String, dynamic>)),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAccounts(Map<String, UserAccount> accounts) async {
    final encoded = jsonEncode(
      accounts.map((key, value) => MapEntry(key, value.toJson())),
    );
    await storage.writeString(_accountsKey, encoded);
  }

  Future<Map<String, String>> _getStoredPasswords() async {
    final raw = await storage.readString(_passwordsKey);
    if (raw == null || raw.trim().isEmpty) {
      return {};
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _savePasswords(Map<String, String> passwords) async {
    await storage.writeString(_passwordsKey, jsonEncode(passwords));
  }
}
