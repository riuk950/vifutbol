import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/auth/local_auth_repository.dart';

class MockLocalStorageRepository extends Mock
    implements LocalStorageRepository {}

class MockConnectivityRepository extends Mock
    implements ConnectivityRepository {}

void main() {
  late MockLocalStorageRepository mockStorage;
  late MockConnectivityRepository mockConnectivity;
  late LocalAuthRepository prodRepo;
  late LocalAuthRepository devRepo;

  final inMemoryStore = <String, String>{};

  final testAccount = UserAccount(
    id: 'user-777',
    fullName: 'Javier Mascherano',
    email: 'jefe@vifutbol.com',
    activeRole: UserRole.coach,
    authorizedRoles: const {UserRole.coach, UserRole.fan},
    isGuestFan: false,
    onboardingCompleted: true,
  );

  final testSession = AuthSession(
    sessionId: 'session-777',
    user: testAccount,
    sessionToken: 'super-secret-token-xyz',
    authenticatedAt: DateTime(2026, 11, 3),
  );

  setUp(() {
    mockStorage = MockLocalStorageRepository();
    mockConnectivity = MockConnectivityRepository();
    inMemoryStore.clear();

    when(() => mockStorage.readString(any())).thenAnswer((inv) async {
      final key = inv.positionalArguments[0] as String;
      return inMemoryStore[key];
    });

    when(() => mockStorage.writeString(any(), any())).thenAnswer((inv) async {
      final key = inv.positionalArguments[0] as String;
      final val = inv.positionalArguments[1] as String;
      inMemoryStore[key] = val;
    });

    prodRepo = LocalAuthRepository(
      storage: mockStorage,
      connectivity: mockConnectivity,
      config: EnvironmentConfig.production(),
    );

    devRepo = LocalAuthRepository(
      storage: mockStorage,
      connectivity: mockConnectivity,
      config: EnvironmentConfig.development(),
    );
  });

  group('LocalAuthRepository unit tests (US3)', () {
    test(
      'rehydrates stored session offline without network connectivity (< 2s)',
      () async {
        inMemoryStore['auth_session'] = jsonEncode(testSession.toJson());

        // Device is completely disconnected from internet
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => NetworkConnectionStatus.disconnected);

        final restored = await prodRepo.restoreSession();

        expect(restored, isNotNull);
        expect(restored!.sessionId, 'session-777');
        expect(restored.user.fullName, 'Javier Mascherano');
        expect(restored.user.activeRole, UserRole.coach);
        // Ensure session token is masked in string outputs
        expect(restored.toString(), contains('[REDACTED]'));
        expect(restored.toString(), isNot(contains('super-secret-token-xyz')));
      },
    );

    test('rejects new signIn when offline', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => NetworkConnectionStatus.disconnected);

      expect(
        () => prodRepo.signInWithEmail(
          email: 'jefe@vifutbol.com',
          password: 'Password123!',
        ),
        throwsA(isA<OfflineAuthOperationFailure>()),
      );
    });

    test('rejects new registerAccount when offline', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => NetworkConnectionStatus.disconnected);

      expect(
        () => prodRepo.registerAccount(
          fullName: 'Lionel Scaloni',
          email: 'scaloni@vifutbol.com',
          password: 'Password123!',
        ),
        throwsA(isA<OfflineAuthOperationFailure>()),
      );
    });

    test(
      'guest fan onboarding operates 100% offline and persists session',
      () async {
        final guestSession = await prodRepo.continueAsGuestFan();

        expect(guestSession.isGuestFan, isTrue);
        expect(guestSession.user.activeRole, UserRole.fan);
        expect(guestSession.user.onboardingCompleted, isTrue);
        expect(inMemoryStore['auth_session'], isNotEmpty);
      },
    );

    test('enforces authorization code for organizer in production', () async {
      inMemoryStore['auth_session'] = jsonEncode(
        testSession
            .copyWith(user: testAccount.copyWith(onboardingCompleted: false))
            .toJson(),
      );

      // Invalid code in prod should throw
      expect(
        () => prodRepo.completeRoleOnboarding(
          userId: 'user-777',
          selectedRole: UserRole.organizer,
          authorizationCode: 'WRONG-CODE',
        ),
        throwsA(isA<InvalidAuthorizationCodeFailure>()),
      );

      // Valid official code should succeed
      final updatedUser = await prodRepo.completeRoleOnboarding(
        userId: 'user-777',
        selectedRole: UserRole.organizer,
        authorizationCode: LocalAuthRepository.officialAuthorizationCode,
      );

      expect(updatedUser.activeRole, UserRole.organizer);
      expect(updatedUser.onboardingCompleted, isTrue);
    });

    test(
      'allows organizer role onboarding in development without authorization code',
      () async {
        inMemoryStore['auth_session'] = jsonEncode(
          testSession
              .copyWith(user: testAccount.copyWith(onboardingCompleted: false))
              .toJson(),
        );

        final updatedUser = await devRepo.completeRoleOnboarding(
          userId: 'user-777',
          selectedRole: UserRole.organizer,
          authorizationCode: null,
        );

        expect(updatedUser.activeRole, UserRole.organizer);
        expect(updatedUser.onboardingCompleted, isTrue);
      },
    );

    test('signOut wipes stored session token completely (< 1s)', () async {
      inMemoryStore['auth_session'] = jsonEncode(testSession.toJson());

      await prodRepo.signOut();

      final restored = await prodRepo.restoreSession();
      expect(restored, isNull);
      expect(inMemoryStore['auth_session'], isEmpty);
    });
  });
}
