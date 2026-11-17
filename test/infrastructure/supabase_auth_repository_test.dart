import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as gotrue show User;
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/auth/supabase_auth_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseUserProfileDataSource extends Mock
    implements SupabaseUserProfileDataSource {}

class MockLocalStorageRepository extends Mock
    implements LocalStorageRepository {}

class MockConnectivityRepository extends Mock
    implements ConnectivityRepository {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockSupabaseUserProfileDataSource mockProfileDataSource;
  late MockLocalStorageRepository mockStorage;
  late MockConnectivityRepository mockConnectivity;
  late StreamController<AuthState> authStateController;
  late Map<String, String> inMemoryStore;
  late EnvironmentConfig devConfig;
  late EnvironmentConfig prodConfig;

  const uid = '11111111-1111-4111-8111-111111111111';
  const email = 'diego@vifutbol.com';

  String buildJwt({int? expEpochSeconds}) {
    final exp =
        expEpochSeconds ??
        DateTime.now()
                .toUtc()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000;
    final header = base64Url
        .encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'))
        .replaceAll('=', '');
    final payload = base64Url
        .encode(utf8.encode('{"sub":"$uid","exp":$exp}'))
        .replaceAll('=', '');
    return '$header.$payload.sig-secret-123';
  }

  final rawJwt = buildJwt();

  gotrue.User buildUser({String userEmail = email, String fullName = 'Diego'}) {
    return gotrue.User(
      id: uid,
      appMetadata: const {},
      userMetadata: {'full_name': fullName},
      aud: 'authenticated',
      createdAt: '2026-11-11T00:00:00Z',
      email: userEmail,
    );
  }

  Session buildSession({gotrue.User? user, int? expiresAt}) {
    final effectiveUser = user ?? buildUser();
    return Session(
      accessToken: expiresAt == null
          ? rawJwt
          : buildJwt(expEpochSeconds: expiresAt),
      tokenType: 'bearer',
      refreshToken: 'refresh-secret-token',
      expiresIn: 3600,
      user: effectiveUser,
    );
  }

  Map<String, dynamic> buildRow({
    String fullName = 'Diego',
    String userEmail = email,
    String activeRole = 'fan',
    List<String> authorizedRoles = const ['fan'],
    bool onboardingCompleted = false,
  }) {
    return {
      'id': uid,
      'auth_user_id': uid,
      'full_name': fullName,
      'email': userEmail,
      'active_role': activeRole,
      'authorized_roles': authorizedRoles,
      'is_guest_fan': false,
      'onboarding_completed': onboardingCompleted,
    };
  }

  SupabaseAuthRepository buildRepository({EnvironmentConfig? config}) {
    return SupabaseAuthRepository(
      client: mockClient,
      storage: mockStorage,
      connectivity: mockConnectivity,
      config: config ?? devConfig,
      profileDataSource: mockProfileDataSource,
    );
  }

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockProfileDataSource = MockSupabaseUserProfileDataSource();
    mockStorage = MockLocalStorageRepository();
    mockConnectivity = MockConnectivityRepository();
    authStateController = StreamController<AuthState>.broadcast();
    inMemoryStore = <String, String>{};

    devConfig = EnvironmentConfig.development(
      supabase: const SupabaseConfig(
        url: 'https://supabase.artbusinesstechnology.com',
        anonKey: 'dev-anon-key',
        schema: 'vifutboldev',
      ),
    );
    prodConfig = EnvironmentConfig.production(
      supabase: const SupabaseConfig(
        url: 'https://prod-project.supabase.co',
        anonKey: 'prod-anon-key',
        schema: 'public',
      ),
    );

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(
      () => mockProfileDataSource.fetchRoleProfileDetails(any()),
    ).thenAnswer((_) async => null);
    when(
      () => mockProfileDataSource.completeRoleProfile(
        activeRole: any(named: 'activeRole'),
        authorizedRoles: any(named: 'authorizedRoles'),
        onboardingCompleted: any(named: 'onboardingCompleted'),
        fullName: any(named: 'fullName'),
        phone: any(named: 'phone'),
        documentId: any(named: 'documentId'),
        roleProfile: any(named: 'roleProfile'),
      ),
    ).thenAnswer((inv) async => buildRow(
          activeRole: inv.namedArguments[#activeRole] as String? ?? 'fan',
          authorizedRoles:
              (inv.namedArguments[#authorizedRoles] as List<dynamic>?)
                      ?.cast<String>() ??
                  const ['fan'],
          onboardingCompleted:
              inv.namedArguments[#onboardingCompleted] as bool? ?? false,
        ));
    when(
      () => mockAuth.onAuthStateChange,
    ).thenAnswer((_) => authStateController.stream);
    when(
      () => mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => NetworkConnectionStatus.connected);

    when(() => mockStorage.readString(any())).thenAnswer((inv) async {
      final key = inv.positionalArguments[0] as String;
      return inMemoryStore[key];
    });
    when(() => mockStorage.writeString(any(), any())).thenAnswer((inv) async {
      final key = inv.positionalArguments[0] as String;
      final val = inv.positionalArguments[1] as String;
      inMemoryStore[key] = val;
    });
  });

  tearDown(() async {
    await authStateController.close();
  });

  group('US1: signInWithEmail, profile mapping & role management', () {
    test(
      'signInWithEmail normalizes email, fetches vifutboldev profile and caches session',
      () async {
        final session = buildSession();
        when(
          () => mockAuth.signInWithPassword(
            email: email,
            password: 'Password123!',
          ),
        ).thenAnswer(
          (_) async => AuthResponse(session: session, user: session.user),
        );
        when(() => mockProfileDataSource.fetchByAuthUserId(uid)).thenAnswer(
          (_) async => buildRow(
            fullName: 'Diego Técnico',
            activeRole: 'coach',
            authorizedRoles: const ['coach', 'fan'],
            onboardingCompleted: true,
          ),
        );

        final repo = buildRepository();
        final result = await repo.signInWithEmail(
          email: '  DIEGO@VIFUTBOL.COM ',
          password: 'Password123!',
        );

        expect(result.sessionId, 'supa-$uid');
        expect(result.sessionToken, rawJwt);
        expect(result.user.id, uid);
        expect(result.user.fullName, 'Diego Técnico');
        expect(result.user.email, email);
        expect(result.user.activeRole, UserRole.coach);
        expect(result.user.authorizedRoles, {UserRole.coach, UserRole.fan});
        expect(result.user.onboardingCompleted, isTrue);

        verify(() => mockProfileDataSource.fetchByAuthUserId(uid)).called(1);
        verifyNever(() => mockProfileDataSource.upsertProfile(any()));
        expect(inMemoryStore['auth_session'], isNotNull);
        final cached = AuthSession.fromJson(
          jsonDecode(inMemoryStore['auth_session']!) as Map<String, dynamic>,
        );
        expect(cached.user.activeRole, UserRole.coach);
      },
    );

    test(
      'signInWithEmail falls back to idempotent upsert when user_accounts row is missing',
      () async {
        final session = buildSession(
          user: buildUser(fullName: 'Usuario Sin Fila'),
        );
        when(
          () => mockAuth.signInWithPassword(
            email: email,
            password: 'Password123!',
          ),
        ).thenAnswer(
          (_) async => AuthResponse(session: session, user: session.user),
        );
        when(
          () => mockProfileDataSource.fetchByAuthUserId(uid),
        ).thenAnswer((_) async => null);
        when(() => mockProfileDataSource.upsertProfile(any())).thenAnswer(
          (inv) async => inv.positionalArguments[0] as Map<String, dynamic>,
        );

        final repo = buildRepository();
        final result = await repo.signInWithEmail(
          email: email,
          password: 'Password123!',
        );

        expect(result.user.id, uid);
        expect(result.user.fullName, 'Usuario Sin Fila');
        expect(result.user.activeRole, UserRole.fan);
        expect(result.user.isGuestFan, isFalse);
        expect(result.user.onboardingCompleted, isFalse);

        final captured =
            verify(
                  () => mockProfileDataSource.upsertProfile(captureAny()),
                ).captured.single
                as Map<String, dynamic>;
        expect(captured['id'], uid);
        expect(captured['auth_user_id'], uid);
        expect(captured['is_guest_fan'], isFalse);
      },
    );

    test(
      'completeRoleOnboarding allows organizer without auth code in DEV and persists to vifutboldev',
      () async {
        final session = buildSession();
        when(() => mockAuth.currentSession).thenReturn(session);
        when(
          () => mockProfileDataSource.fetchByAuthUserId(uid),
        ).thenAnswer((_) async => buildRow());
        when(
          () => mockProfileDataSource.updateRoleState(
            authUserId: uid,
            activeRole: 'organizer',
            authorizedRoles: any(named: 'authorizedRoles'),
            onboardingCompleted: true,
          ),
        ).thenAnswer(
          (_) async => buildRow(
            activeRole: 'organizer',
            authorizedRoles: const ['fan', 'organizer'],
            onboardingCompleted: true,
          ),
        );

        final repo = buildRepository(config: devConfig);
        final updated = await repo.completeRoleOnboarding(
          userId: uid,
          selectedRole: UserRole.organizer,
        );

        expect(updated.activeRole, UserRole.organizer);
        expect(updated.authorizedRoles, {UserRole.organizer, UserRole.fan});
        expect(updated.onboardingCompleted, isTrue);

        final cached = AuthSession.fromJson(
          jsonDecode(inMemoryStore['auth_session']!) as Map<String, dynamic>,
        );
        expect(cached.user.activeRole, UserRole.organizer);
        expect(cached.user.onboardingCompleted, isTrue);
      },
    );

    test(
      'completeRoleOnboarding enforces officialAuthorizationCode in production',
      () async {
        final session = buildSession();
        when(() => mockAuth.currentSession).thenReturn(session);
        when(
          () => mockProfileDataSource.fetchByAuthUserId(uid),
        ).thenAnswer((_) async => buildRow());

        final repo = buildRepository(config: prodConfig);

        await expectLater(
          () => repo.completeRoleOnboarding(
            userId: uid,
            selectedRole: UserRole.referee,
            authorizationCode: 'WRONG-CODE',
          ),
          throwsA(isA<InvalidAuthorizationCodeFailure>()),
        );
      },
    );

    test(
      'switchActiveRole freely switches between all 5 roles in DEV and updates remote & cache',
      () async {
        final session = buildSession();
        when(() => mockAuth.currentSession).thenReturn(session);
        when(() => mockProfileDataSource.fetchByAuthUserId(uid)).thenAnswer(
          (_) async => buildRow(
            activeRole: 'fan',
            authorizedRoles: const ['fan'],
            onboardingCompleted: true,
          ),
        );
        when(
          () => mockProfileDataSource.updateRoleState(
            authUserId: uid,
            activeRole: 'referee',
            authorizedRoles: any(named: 'authorizedRoles'),
            onboardingCompleted: true,
          ),
        ).thenAnswer(
          (_) async => buildRow(
            activeRole: 'referee',
            authorizedRoles: const ['fan', 'referee'],
            onboardingCompleted: true,
          ),
        );

        final repo = buildRepository(config: devConfig);
        final updated = await repo.switchActiveRole(
          userId: uid,
          targetRole: UserRole.referee,
        );

        expect(updated.activeRole, UserRole.referee);
        expect(updated.authorizedRoles, {UserRole.fan, UserRole.referee});

        final cached = AuthSession.fromJson(
          jsonDecode(inMemoryStore['auth_session']!) as Map<String, dynamic>,
        );
        expect(cached.user.activeRole, UserRole.referee);
      },
    );

    test(
      'switchActiveRole throws UnauthorizedRoleFailure in production for unauthorized role',
      () async {
        final session = buildSession();
        when(() => mockAuth.currentSession).thenReturn(session);
        when(() => mockProfileDataSource.fetchByAuthUserId(uid)).thenAnswer(
          (_) async => buildRow(
            activeRole: 'fan',
            authorizedRoles: const ['fan'],
            onboardingCompleted: true,
          ),
        );

        final repo = buildRepository(config: prodConfig);
        await expectLater(
          () => repo.switchActiveRole(
            userId: uid,
            targetRole: UserRole.organizer,
          ),
          throwsA(isA<UnauthorizedRoleFailure>()),
        );
      },
    );
  });

  group('US2: registerAccount & vifutboldev profile consistency', () {
    test(
      'registerAccount sends full_name metadata, ensures profile and caches session when autoconfirm is active',
      () async {
        final session = buildSession(
          user: buildUser(fullName: 'Valeria Quintero'),
        );
        when(
          () => mockAuth.signUp(
            email: email,
            password: 'Password123!',
            data: const {'full_name': 'Valeria Quintero'},
          ),
        ).thenAnswer(
          (_) async => AuthResponse(session: session, user: session.user),
        );
        when(() => mockProfileDataSource.fetchByAuthUserId(uid)).thenAnswer(
          (_) async => buildRow(
            fullName: 'Valeria Quintero',
            activeRole: 'fan',
            authorizedRoles: const ['fan'],
            onboardingCompleted: false,
          ),
        );

        final repo = buildRepository();
        final result = await repo.registerAccount(
          fullName: '  Valeria Quintero  ',
          email: ' DIEGO@VIFUTBOL.COM ',
          password: 'Password123!',
        );

        expect(result.sessionId, 'supa-$uid');
        expect(result.user.fullName, 'Valeria Quintero');
        expect(result.user.activeRole, UserRole.fan);
        expect(result.user.authorizedRoles, {UserRole.fan});
        expect(result.user.onboardingCompleted, isFalse);
        expect(inMemoryStore['auth_session'], isNotNull);
        verify(
          () => mockAuth.signUp(
            email: email,
            password: 'Password123!',
            data: const {'full_name': 'Valeria Quintero'},
          ),
        ).called(1);
      },
    );

    test(
      'registerAccount throws EmailVerificationRequiredFailure without caching when response.session is null',
      () async {
        final user = buildUser(fullName: 'Usuario Pendiente');
        when(
          () => mockAuth.signUp(
            email: email,
            password: 'Password123!',
            data: const {'full_name': 'Usuario Pendiente'},
          ),
        ).thenAnswer((_) async => AuthResponse(session: null, user: user));

        final repo = buildRepository();
        await expectLater(
          () => repo.registerAccount(
            fullName: 'Usuario Pendiente',
            email: email,
            password: 'Password123!',
          ),
          throwsA(
            isA<EmailVerificationRequiredFailure>().having(
              (f) => f.message,
              'message',
              contains('confirmar tu cuenta'),
            ),
          ),
        );

        expect(inMemoryStore.containsKey('auth_session'), isFalse);
      },
    );
  });

  group('US3: restoreSession, offline fallback, guest fan & signOut', () {
    test(
      'restoreSession syncs remote profile from vifutboldev overriding stale cached role',
      () async {
        final session = buildSession();
        final staleCached = AuthSession(
          sessionId: 'supa-$uid',
          user: SupabaseAuthRepository.mapRowToUserAccount(
            buildRow(activeRole: 'fan', onboardingCompleted: false),
          ),
          sessionToken: rawJwt,
          authenticatedAt: DateTime.utc(2026, 11, 10),
        );
        inMemoryStore['auth_session'] = jsonEncode(staleCached.toJson());

        when(() => mockAuth.currentSession).thenReturn(session);
        when(() => mockProfileDataSource.fetchByAuthUserId(uid)).thenAnswer(
          (_) async => buildRow(
            fullName: 'Diego Remoto',
            activeRole: 'organizer',
            authorizedRoles: const ['fan', 'organizer'],
            onboardingCompleted: true,
          ),
        );

        final repo = buildRepository();
        final restored = await repo.restoreSession();

        expect(restored, isNotNull);
        expect(restored!.user.activeRole, UserRole.organizer);
        expect(restored.user.onboardingCompleted, isTrue);

        final updatedCache = AuthSession.fromJson(
          jsonDecode(inMemoryStore['auth_session']!) as Map<String, dynamic>,
        );
        expect(updatedCache.user.activeRole, UserRole.organizer);
      },
    );

    test(
      'restoreSession calls refreshSession when currentSession JWT is expired',
      () async {
        final expiredEpoch =
            DateTime.now()
                .toUtc()
                .subtract(const Duration(minutes: 10))
                .millisecondsSinceEpoch ~/
            1000;
        final expiredSession = buildSession(expiresAt: expiredEpoch);
        final refreshedSession = buildSession();

        when(() => mockAuth.currentSession).thenReturn(expiredSession);
        when(() => mockAuth.refreshSession()).thenAnswer(
          (_) async => AuthResponse(
            session: refreshedSession,
            user: refreshedSession.user,
          ),
        );
        when(
          () => mockProfileDataSource.fetchByAuthUserId(uid),
        ).thenAnswer((_) async => buildRow(onboardingCompleted: true));

        final repo = buildRepository();
        final restored = await repo.restoreSession();

        expect(restored, isNotNull);
        expect(restored!.sessionToken, rawJwt);
        verify(() => mockAuth.refreshSession()).called(1);
      },
    );

    test(
      'restoreSession falls back safely to cached auth_session when offline',
      () async {
        final session = buildSession();
        final cached = AuthSession(
          sessionId: 'supa-$uid',
          user: SupabaseAuthRepository.mapRowToUserAccount(
            buildRow(
              fullName: 'Offline Cached',
              activeRole: 'coach',
              authorizedRoles: const ['fan', 'coach'],
              onboardingCompleted: true,
            ),
          ),
          sessionToken: rawJwt,
          authenticatedAt: DateTime.utc(2026, 11, 10),
        );
        inMemoryStore['auth_session'] = jsonEncode(cached.toJson());

        when(() => mockAuth.currentSession).thenReturn(session);
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => NetworkConnectionStatus.disconnected);

        final repo = buildRepository();
        final restored = await repo.restoreSession();

        expect(restored, isNotNull);
        expect(restored!.user.fullName, 'Offline Cached');
        expect(restored.user.activeRole, UserRole.coach);
        verifyNever(() => mockAuth.refreshSession());
        verifyNever(() => mockProfileDataSource.fetchByAuthUserId(any()));
      },
    );

    test(
      'restoreSession restores local guest fan session when currentSession is null',
      () async {
        when(() => mockAuth.currentSession).thenReturn(null);
        final repo = buildRepository();

        final guest = await repo.continueAsGuestFan();
        expect(guest.isGuestFan, isTrue);
        verifyNever(
          () => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );

        final restored = await repo.restoreSession();
        expect(restored, isNotNull);
        expect(restored!.isGuestFan, isTrue);
      },
    );

    test(
      'signOut closes remote session and clears local cache even if offline',
      () async {
        final cached = AuthSession(
          sessionId: 'supa-$uid',
          user: SupabaseAuthRepository.mapRowToUserAccount(buildRow()),
          sessionToken: rawJwt,
          authenticatedAt: DateTime.utc(2026, 11, 10),
        );
        inMemoryStore['auth_session'] = jsonEncode(cached.toJson());

        when(
          () => mockAuth.signOut(),
        ).thenThrow(const SocketException('Offline'));

        final repo = buildRepository();
        await repo.signOut();

        verify(() => mockAuth.signOut()).called(1);
        expect(inMemoryStore['auth_session'], isEmpty);
      },
    );
  });

  group('US4: error translation, reactive lifecycle & token redaction', () {
    test(
      'maps GoTrue, Postgrest and network exceptions into typed Spanish AppFailures',
      () async {
        final repo = buildRepository();

        when(
          () => mockAuth.signInWithPassword(
            email: email,
            password: 'WrongPassword1!',
          ),
        ).thenThrow(
          const AuthException(
            'Invalid login credentials',
            code: 'invalid_credentials',
          ),
        );
        await expectLater(
          () => repo.signInWithEmail(email: email, password: 'WrongPassword1!'),
          throwsA(
            isA<InvalidCredentialsFailure>().having(
              (f) => f.message,
              'message',
              contains('Correo o contraseña incorrectos'),
            ),
          ),
        );

        when(
          () => mockAuth.signUp(
            email: email,
            password: 'Password123!',
            data: const {'full_name': 'Diego'},
          ),
        ).thenThrow(
          const AuthException(
            'User already registered',
            code: 'user_already_exists',
          ),
        );
        await expectLater(
          () => repo.registerAccount(
            fullName: 'Diego',
            email: email,
            password: 'Password123!',
          ),
          throwsA(
            isA<InvalidCredentialsFailure>().having(
              (f) => f.message,
              'message',
              contains('ya se encuentra registrado'),
            ),
          ),
        );

        when(
          () => mockAuth.signInWithPassword(
            email: email,
            password: 'Password123!',
          ),
        ).thenThrow(
          const AuthException(
            'Email not confirmed',
            code: 'email_not_confirmed',
          ),
        );
        await expectLater(
          () => repo.signInWithEmail(email: email, password: 'Password123!'),
          throwsA(isA<EmailVerificationRequiredFailure>()),
        );

        when(
          () => mockAuth.signInWithPassword(
            email: email,
            password: 'Password123!',
          ),
        ).thenThrow(
          const AuthException(
            'Rate limit exceeded',
            statusCode: '429',
            code: 'over_request_rate_limit',
          ),
        );
        await expectLater(
          () => repo.signInWithEmail(email: email, password: 'Password123!'),
          throwsA(isA<AuthRateLimitFailure>()),
        );

        when(
          () => mockAuth.signInWithPassword(
            email: email,
            password: 'Password123!',
          ),
        ).thenThrow(const SocketException('No route to host'));
        await expectLater(
          () => repo.signInWithEmail(email: email, password: 'Password123!'),
          throwsA(isA<OfflineAuthOperationFailure>()),
        );

        final session = buildSession();
        when(
          () => mockAuth.signInWithPassword(
            email: email,
            password: 'Password123!',
          ),
        ).thenAnswer(
          (_) async => AuthResponse(session: session, user: session.user),
        );
        when(() => mockProfileDataSource.fetchByAuthUserId(uid)).thenThrow(
          const PostgrestException(message: 'permission denied', code: '42501'),
        );
        await expectLater(
          () => repo.signInWithEmail(email: email, password: 'Password123!'),
          throwsA(isA<UnauthorizedRoleFailure>()),
        );
      },
    );

    test(
      'onSessionStateChanged bridges tokenRefreshed and signedOut without exposing tokens',
      () async {
        final refreshedSession = buildSession();
        inMemoryStore['auth_session'] = 'stale-session';
        when(() => mockProfileDataSource.fetchByAuthUserId(uid)).thenAnswer(
          (_) async => buildRow(
            activeRole: 'organizer',
            authorizedRoles: const ['fan', 'organizer'],
            onboardingCompleted: true,
          ),
        );

        final repo = buildRepository();
        final emitted = <AuthSession?>[];
        final sub = repo.onSessionStateChanged.listen(emitted.add);
        addTearDown(sub.cancel);

        authStateController.add(
          AuthState(AuthChangeEvent.tokenRefreshed, refreshedSession),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        authStateController.add(
          const AuthState(AuthChangeEvent.signedOut, null),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(emitted.length, 2);
        expect(emitted[0], isNotNull);
        expect(emitted[0]!.user.activeRole, UserRole.organizer);
        expect(emitted[0]!.toSafeDiagnosticMap()['sessionToken'], '[REDACTED]');
        expect(emitted[0].toString().contains(rawJwt), isFalse);
        expect(emitted[0].toString().contains('[REDACTED]'), isTrue);

        expect(emitted[1], isNull);
        expect(inMemoryStore['auth_session'], isEmpty);
      },
    );
  });
}
