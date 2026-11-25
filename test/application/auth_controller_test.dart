import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/use_cases/authenticate_user_use_case.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late AuthenticateUserUseCase authenticateUserUseCase;
  late AuthController controller;

  final testAccount = UserAccount(
    id: 'user-123',
    fullName: 'Diego Armando',
    email: 'diego@vifutbol.com',
    activeRole: UserRole.fan,
    authorizedRoles: const {UserRole.fan},
    isGuestFan: false,
    onboardingCompleted: false,
  );

  final testSession = AuthSession(
    sessionId: 'session-123',
    user: testAccount,
    sessionToken: 'token-secret',
    authenticatedAt: DateTime(2026, 11, 3),
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    authenticateUserUseCase = AuthenticateUserUseCase(mockRepository);

    when(() => mockRepository.restoreSession()).thenAnswer((_) async => null);
    when(
      () => mockRepository.onSessionStateChanged,
    ).thenAnswer((_) => const Stream.empty());
  });

  group('AuthController unit tests (US1)', () {
    test(
      'initializes with unauthenticated status when no session exists',
      () async {
        controller = AuthController(
          authRepository: mockRepository,
          authenticateUserUseCase: authenticateUserUseCase,
        );

        await Future<void>.delayed(Duration.zero);

        expect(controller.state.status, AuthStatus.unauthenticated);
        expect(controller.state.session, isNull);
        expect(controller.state.isSubmitting, isFalse);
      },
    );

    test(
      'initializes with authenticated status when completed session exists',
      () async {
        final completedSession = testSession.copyWith(
          user: testAccount.copyWith(onboardingCompleted: true),
        );
        when(
          () => mockRepository.restoreSession(),
        ).thenAnswer((_) async => completedSession);

        controller = AuthController(
          authRepository: mockRepository,
          authenticateUserUseCase: authenticateUserUseCase,
        );

        await Future<void>.delayed(Duration.zero);

        expect(controller.state.status, AuthStatus.authenticated);
        expect(controller.state.session, equals(completedSession));
      },
    );

    test('registers successfully and moves to needsOnboarding', () async {
      when(
        () => mockRepository.registerAccount(
          fullName: 'Diego Armando',
          email: 'diego@vifutbol.com',
          password: 'Password123!',
        ),
      ).thenAnswer((_) async => testSession);

      controller = AuthController(
        authRepository: mockRepository,
        authenticateUserUseCase: authenticateUserUseCase,
      );
      await Future<void>.delayed(Duration.zero);

      final success = await controller.register(
        fullName: 'Diego Armando',
        email: 'diego@vifutbol.com',
        password: 'Password123!',
      );

      expect(success, isTrue);
      expect(controller.state.status, AuthStatus.needsOnboarding);
      expect(controller.state.session?.user.onboardingCompleted, isFalse);
      expect(controller.state.draftFullName, isEmpty);
      expect(controller.state.draftEmail, isEmpty);
    });

    test('completes role onboarding and moves to authenticated', () async {
      final onboardedUser = testAccount.copyWith(
        activeRole: UserRole.coach,
        authorizedRoles: {UserRole.fan, UserRole.coach},
        onboardingCompleted: true,
      );

      when(
        () => mockRepository.completeRoleOnboarding(
          userId: 'user-123',
          selectedRole: UserRole.coach,
          authorizationCode: null,
        ),
      ).thenAnswer((_) async => onboardedUser);

      controller = AuthController(
        authRepository: mockRepository,
        authenticateUserUseCase: authenticateUserUseCase,
      );
      controller.state = controller.state.copyWith(
        status: AuthStatus.needsOnboarding,
        session: () => testSession,
      );

      final success = await controller.completeRoleOnboarding(
        selectedRole: UserRole.coach,
      );

      expect(success, isTrue);
      expect(controller.state.status, AuthStatus.authenticated);
      expect(controller.state.session?.user.activeRole, UserRole.coach);
      expect(controller.state.session?.user.onboardingCompleted, isTrue);
    });

    test(
      'authenticates as guest fan immediately without network credentials',
      () async {
        final guestSession = AuthSession(
          sessionId: 'guest-session',
          user: UserAccount(
            id: 'guest-1',
            fullName: 'Aficionado Invitado',
            email: 'guest@vifutbol.local',
            activeRole: UserRole.fan,
            authorizedRoles: const {UserRole.fan},
            isGuestFan: true,
            onboardingCompleted: true,
          ),
          sessionToken: 'guest-token',
          authenticatedAt: DateTime.now(),
        );

        when(
          () => mockRepository.continueAsGuestFan(),
        ).thenAnswer((_) async => guestSession);

        controller = AuthController(
          authRepository: mockRepository,
          authenticateUserUseCase: authenticateUserUseCase,
        );
        await Future<void>.delayed(Duration.zero);

        final success = await controller.continueAsGuestFan();

        expect(success, isTrue);
        expect(controller.state.status, AuthStatus.authenticated);
        expect(controller.state.isGuestFan, isTrue);
        expect(controller.state.session?.user.activeRole, UserRole.fan);
      },
    );

    test(
      'preserves draftEmail on invalid credentials and locks out after 5 consecutive failures',
      () {
        fakeAsync((async) {
          when(
            () => mockRepository.signInWithEmail(
              email: 'diego@vifutbol.com',
              password: 'wrong-password-123',
            ),
          ).thenThrow(
            const InvalidCredentialsFailure('Correo o contraseña incorrectos.'),
          );

          controller = AuthController(
            authRepository: mockRepository,
            authenticateUserUseCase: authenticateUserUseCase,
          );
          async.flushMicrotasks();

          // 4 failed attempts
          for (var i = 1; i <= 4; i++) {
            controller.signIn(
              email: 'diego@vifutbol.com',
              password: 'wrong-password-123',
            );
            async.flushMicrotasks();

            expect(controller.state.failedAttempts, i);
            expect(controller.state.draftEmail, 'diego@vifutbol.com');
            expect(controller.state.isLockedOut, isFalse);
            expect(
              controller.state.lastFailure,
              isA<InvalidCredentialsFailure>(),
            );
          }

          // 5th attempt triggers 60s lockout
          controller.signIn(
            email: 'diego@vifutbol.com',
            password: 'wrong-password-123',
          );
          async.flushMicrotasks();

          expect(controller.state.failedAttempts, 5);
          expect(controller.state.isLockedOut, isTrue);
          expect(controller.state.lastFailure, isA<AuthRateLimitFailure>());
          expect(
            controller.state.remainingLockoutSeconds,
            inInclusiveRange(59, 60),
          );

          // 6th attempt while locked out should immediately reject without calling repository
          controller.signIn(
            email: 'diego@vifutbol.com',
            password: 'wrong-password-123',
          );
          async.flushMicrotasks();
          verify(
            () => mockRepository.signInWithEmail(
              email: 'diego@vifutbol.com',
              password: 'wrong-password-123',
            ),
          ).called(5);

          // Advance timer by 61 seconds
          async.elapse(const Duration(seconds: 61));

          expect(controller.state.isLockedOut, isFalse);
          expect(controller.state.failedAttempts, 0);
        });
      },
    );

    test('enforces single-flight lock during concurrent submission', () async {
      when(() => mockRepository.continueAsGuestFan()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return testSession;
      });

      controller = AuthController(
        authRepository: mockRepository,
        authenticateUserUseCase: authenticateUserUseCase,
      );
      await Future<void>.delayed(Duration.zero);

      final firstCall = controller.continueAsGuestFan();
      final secondCall = controller.continueAsGuestFan();

      final results = await Future.wait([firstCall, secondCall]);

      expect(results[0], isTrue);
      expect(results[1], isFalse);
      verify(() => mockRepository.continueAsGuestFan()).called(1);
    });

    test(
      'signOut clears active session and resets state to unauthenticated',
      () async {
        when(() => mockRepository.signOut()).thenAnswer((_) async {});

        controller = AuthController(
          authRepository: mockRepository,
          authenticateUserUseCase: authenticateUserUseCase,
        );
        controller.state = controller.state.copyWith(
          status: AuthStatus.authenticated,
          session: () => testSession,
        );

        await controller.signOut();

        expect(controller.state.status, AuthStatus.unauthenticated);
        expect(controller.state.session, isNull);
        verify(() => mockRepository.signOut()).called(1);
      },
    );

    test(
      'subscribes to onSessionStateChanged, reacts to tokenRefreshed/signedOut and cancels on dispose',
      () async {
        final sessionStream = StreamController<AuthSession?>();
        when(
          () => mockRepository.onSessionStateChanged,
        ).thenAnswer((_) => sessionStream.stream);

        final localController = AuthController(
          authRepository: mockRepository,
          authenticateUserUseCase: authenticateUserUseCase,
        );
        await Future<void>.delayed(Duration.zero);

        expect(sessionStream.hasListener, isTrue);

        final completedSession = testSession.copyWith(
          user: testAccount.copyWith(onboardingCompleted: true),
        );
        sessionStream.add(completedSession);
        await Future<void>.delayed(Duration.zero);

        expect(localController.state.status, AuthStatus.authenticated);
        expect(localController.state.session, equals(completedSession));

        sessionStream.add(null);
        await Future<void>.delayed(Duration.zero);

        expect(localController.state.status, AuthStatus.unauthenticated);
        expect(localController.state.session, isNull);

        localController.dispose();
        expect(sessionStream.hasListener, isFalse);
        await sessionStream.close();
      },
    );

    group('HU 24.3 - deleteAccount', () {
      test(
        'deletes account, clears session, and transitions to unauthenticated on success',
        () async {
          when(
            () => mockRepository.deleteAccount(userId: testAccount.id),
          ).thenAnswer((_) async {});

          controller = AuthController(
            authRepository: mockRepository,
            authenticateUserUseCase: authenticateUserUseCase,
          );
          await Future<void>.delayed(Duration.zero);
          controller.state = controller.state.copyWith(
            status: AuthStatus.authenticated,
            session: () => testSession,
          );

          final result = await controller.deleteAccount();

          expect(result, isTrue);
          expect(controller.state.status, AuthStatus.unauthenticated);
          expect(controller.state.session, isNull);
          expect(controller.state.isSubmitting, isFalse);
          expect(controller.state.lastFailure, isNull);
          verify(
            () => mockRepository.deleteAccount(userId: testAccount.id),
          ).called(1);
        },
      );

      test('rejects guest fan session without calling repository', () async {
        final guestAccount = UserAccount.guestFan(id: 'guest-001');
        final guestSession = testSession.copyWith(
          user: guestAccount,
        );
        controller = AuthController(
          authRepository: mockRepository,
          authenticateUserUseCase: authenticateUserUseCase,
        );
        await Future<void>.delayed(Duration.zero);
        controller.state = controller.state.copyWith(
          status: AuthStatus.authenticated,
          session: () => guestSession,
        );

        final result = await controller.deleteAccount();

        expect(result, isFalse);
        expect(controller.state.status, AuthStatus.authenticated);
        expect(controller.state.session, equals(guestSession));
        verifyNever(() => mockRepository.deleteAccount(userId: any(named: 'userId')));
      });

      test(
        'aborts local transition and preserves session on remote/offline failure',
        () async {
          const failure = OfflineAuthOperationFailure(
            'Se requiere conexión a internet para eliminar tu cuenta.',
          );
          when(
            () => mockRepository.deleteAccount(userId: testAccount.id),
          ).thenThrow(failure);

          controller = AuthController(
            authRepository: mockRepository,
            authenticateUserUseCase: authenticateUserUseCase,
          );
          await Future<void>.delayed(Duration.zero);
          controller.state = controller.state.copyWith(
            status: AuthStatus.authenticated,
            session: () => testSession,
          );

          final result = await controller.deleteAccount();

          expect(result, isFalse);
          expect(controller.state.status, AuthStatus.authenticated);
          expect(controller.state.session, equals(testSession));
          expect(controller.state.lastFailure, equals(failure));
          expect(controller.state.isSubmitting, isFalse);
        },
      );

      test(
        'enforces single-flight lock during concurrent deleteAccount calls',
        () async {
          when(
            () => mockRepository.deleteAccount(userId: testAccount.id),
          ).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          });

          controller = AuthController(
            authRepository: mockRepository,
            authenticateUserUseCase: authenticateUserUseCase,
          );
          await Future<void>.delayed(Duration.zero);
          controller.state = controller.state.copyWith(
            status: AuthStatus.authenticated,
            session: () => testSession,
          );

          final first = controller.deleteAccount();
          final second = controller.deleteAccount();
          final results = await Future.wait([first, second]);

          expect(results[0], isTrue);
          expect(results[1], isFalse);
          verify(
            () => mockRepository.deleteAccount(userId: testAccount.id),
          ).called(1);
        },
      );
    });
  });
}
