import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/use_cases/authenticate_user_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/auth/auth_gate.dart';
import 'package:vifutbol/presentation/auth/role_onboarding_screen.dart';
import 'package:vifutbol/presentation/auth/welcome_auth_screen.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/presentation/auth/widgets/kick_pulse_role_guard.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/shell/app_shell_screen.dart';
import 'package:vifutbol/presentation/shell/tabs/profile_tab_view.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLocalStorageRepository extends Mock
    implements LocalStorageRepository {}

class MockConnectivityRepository extends Mock
    implements ConnectivityRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockLocalStorageRepository mockLocalStorageRepository;
  late MockConnectivityRepository mockConnectivityRepository;
  late EnvironmentConfig devConfig;

  final testAccount = UserAccount(
    id: 'user-001',
    fullName: 'Carlos Bilardo',
    email: 'bilardo@vifutbol.com',
    activeRole: UserRole.coach,
    authorizedRoles: const {UserRole.coach, UserRole.fan},
    isGuestFan: false,
    onboardingCompleted: true,
  );

  final testSession = AuthSession(
    sessionId: 'session-001',
    user: testAccount,
    sessionToken: 'token-bilardo',
    authenticatedAt: DateTime.now(),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockLocalStorageRepository = MockLocalStorageRepository();
    mockConnectivityRepository = MockConnectivityRepository();
    devConfig = EnvironmentConfig.development();

    when(
      () => mockAuthRepository.restoreSession(),
    ).thenAnswer((_) async => null);
    when(
      () => mockConnectivityRepository.onConnectivityChanged,
    ).thenAnswer((_) => Stream.value(NetworkConnectionStatus.connected));
    when(
      () => mockConnectivityRepository.checkConnectivity(),
    ).thenAnswer((_) async => NetworkConnectionStatus.connected);
  });

  Widget createTestWidget({
    required Widget child,
    AuthController? customController,
    double textScaleFactor = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        environmentConfigProvider.overrideWithValue(devConfig),
        localStorageRepositoryProvider.overrideWithValue(
          mockLocalStorageRepository,
        ),
        connectivityRepositoryProvider.overrideWithValue(
          mockConnectivityRepository,
        ),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        if (customController != null)
          authControllerProvider.overrideWith((ref) => customController),
      ],
      child: MaterialApp(
        theme: KickPulseTheme.darkTheme,
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  group('WelcomeAuthScreen Widget Tests (US1)', () {
    testWidgets(
      'renders Spanish labels, tabs and guest fan button with >= 44px target',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          createTestWidget(child: const WelcomeAuthScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Bienvenido a vifutbol'), findsOneWidget);
        expect(find.text('Iniciar sesión'), findsWidgets);
        expect(find.text('Crear cuenta'), findsOneWidget);
        expect(find.text('Continuar como Aficionado'), findsOneWidget);

        final guestButton = tester.getRect(
          find.widgetWithText(KickPulseButton, 'Continuar como Aficionado'),
        );
        expect(guestButton.height, greaterThanOrEqualTo(44.0));
      },
    );

    testWidgets('supports 130% text scaling without layout overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          child: const WelcomeAuthScreen(),
          textScaleFactor: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Bienvenido a vifutbol'), findsOneWidget);
    });

    testWidgets('displays lockout notice when account is rate limited', (
      tester,
    ) async {
      final controller = AuthController(
        authRepository: mockAuthRepository,
        authenticateUserUseCase: AuthenticateUserUseCase(mockAuthRepository),
      );
      controller.state = controller.state.copyWith(
        status: AuthStatus.unauthenticated,
        failedAttempts: 5,
        lockedUntil: () => DateTime.now().add(const Duration(seconds: 45)),
        lastFailure: () => const AuthRateLimitFailure(
          retryAfterSeconds: 45,
          message:
              'Demasiados intentos fallidos. Intenta de nuevo en 45 segundos.',
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          child: const WelcomeAuthScreen(),
          customController: controller,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_clock_rounded), findsOneWidget);
      expect(
        find.textContaining('Demasiados intentos fallidos'),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping Continuar como Aficionado invokes continueAsGuestFan',
      (tester) async {
        when(
          () => mockAuthRepository.continueAsGuestFan(),
        ).thenAnswer((_) async => testSession);

        await tester.pumpWidget(
          createTestWidget(child: const WelcomeAuthScreen()),
        );
        await tester.pumpAndSettle();

        final guestBtn = find.text('Continuar como Aficionado');
        await tester.ensureVisible(guestBtn);
        await tester.tap(guestBtn);
        await tester.pumpAndSettle();

        verify(() => mockAuthRepository.continueAsGuestFan()).called(1);
      },
    );
  });

  group('RoleOnboardingScreen Widget Tests (US1)', () {
    testWidgets('renders 5 sports role cards and allows selection', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(child: const RoleOnboardingScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selecciona tu Rol Deportivo'), findsOneWidget);
      expect(find.text('Organizador'), findsWidgets);
      expect(find.text('Entrenador'), findsWidgets);
      expect(find.text('Árbitro'), findsWidgets);
      expect(find.text('Jugador'), findsWidgets);
      expect(find.text('Aficionado'), findsWidgets);
      expect(find.text('Confirmar y entrar al torneo'), findsOneWidget);

      await tester.tap(find.text('Entrenador').first);
      await tester.pumpAndSettle();
    });

    testWidgets('shows discard confirmation dialog on back press', (
      tester,
    ) async {
      when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});

      await tester.pumpWidget(
        createTestWidget(child: const RoleOnboardingScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('¿Descartar cambios?'), findsOneWidget);
      expect(find.text('Descartar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();

      verify(() => mockAuthRepository.signOut()).called(1);
    });
  });

  group('AuthGate Widget Tests (US1)', () {
    testWidgets(
      'routes reactively between WelcomeAuth, Onboarding and AppShell',
      (tester) async {
        final controller = AuthController(
          authRepository: mockAuthRepository,
          authenticateUserUseCase: AuthenticateUserUseCase(mockAuthRepository),
        );

        await tester.pumpWidget(
          createTestWidget(
            child: const AuthGate(),
            customController: controller,
          ),
        );
        await tester.pumpAndSettle();

        // Default status is unauthenticated
        expect(find.byType(WelcomeAuthScreen), findsOneWidget);

        // Transition to needsOnboarding
        controller.state = controller.state.copyWith(
          status: AuthStatus.needsOnboarding,
          session: () => testSession.copyWith(
            user: testAccount.copyWith(onboardingCompleted: false),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RoleOnboardingScreen), findsOneWidget);

        // Transition to authenticated
        controller.state = controller.state.copyWith(
          status: AuthStatus.authenticated,
          session: () => testSession,
        );
        await tester.pumpAndSettle();
        expect(find.byType(AppShellScreen), findsOneWidget);
      },
    );
  });

  group('RBAC & ProfileTabView Widget Tests (US2)', () {
    testWidgets(
      'KickPulseRoleGuard renders child when user has required capability',
      (tester) async {
        final coachAccount = testAccount.copyWith(activeRole: UserRole.coach);
        final coachSession = testSession.copyWith(user: coachAccount);
        when(
          () => mockAuthRepository.restoreSession(),
        ).thenAnswer((_) async => coachSession);

        final controller = AuthController(
          authRepository: mockAuthRepository,
          authenticateUserUseCase: AuthenticateUserUseCase(mockAuthRepository),
        );
        await tester.pumpWidget(
          createTestWidget(
            child: const KickPulseRoleGuard(
              requiredCapability: RoleCapability.manageLineups,
              child: Text('Protected Coach Lineup View'),
            ),
            customController: controller,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Protected Coach Lineup View'), findsOneWidget);
        expect(
          find.text('Acceso restringido para tu rol actual'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'KickPulseRoleGuard displays Spanish restriction notice when denied',
      (tester) async {
        final fanAccount = testAccount.copyWith(activeRole: UserRole.fan);
        final fanSession = testSession.copyWith(user: fanAccount);
        when(
          () => mockAuthRepository.restoreSession(),
        ).thenAnswer((_) async => fanSession);

        final controller = AuthController(
          authRepository: mockAuthRepository,
          authenticateUserUseCase: AuthenticateUserUseCase(mockAuthRepository),
        );
        await tester.pumpWidget(
          createTestWidget(
            child: const KickPulseRoleGuard(
              requiredCapability: RoleCapability.manageTournaments,
              child: Text('Protected Tournament View'),
            ),
            customController: controller,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Protected Tournament View'), findsNothing);
        expect(
          find.text('Acceso restringido para tu rol actual'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ProfileTabView displays active role badge and allows switching',
      (tester) async {
        final coachAccount = testAccount.copyWith(
          activeRole: UserRole.coach,
          authorizedRoles: {UserRole.coach, UserRole.fan, UserRole.player},
        );
        final coachSession = testSession.copyWith(user: coachAccount);
        when(
          () => mockAuthRepository.restoreSession(),
        ).thenAnswer((_) async => coachSession);

        final controller = AuthController(
          authRepository: mockAuthRepository,
          authenticateUserUseCase: AuthenticateUserUseCase(mockAuthRepository),
        );

        when(
          () => mockAuthRepository.switchActiveRole(
            userId: 'user-001',
            targetRole: UserRole.player,
          ),
        ).thenAnswer(
          (_) async => coachAccount.copyWith(activeRole: UserRole.player),
        );

        await tester.pumpWidget(
          createTestWidget(
            child: const ProfileTabView(),
            customController: controller,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Carlos Bilardo'), findsOneWidget);
        expect(find.text('Entrenador'), findsWidgets);
        expect(find.text('Permisos y capacidades del rol'), findsOneWidget);

        // Tap on Jugador chip to switch role
        final playerChip = find.widgetWithText(ChoiceChip, 'Jugador');
        await tester.ensureVisible(playerChip);
        await tester.tap(playerChip);
        await tester.pumpAndSettle();

        verify(
          () => mockAuthRepository.switchActiveRole(
            userId: 'user-001',
            targetRole: UserRole.player,
          ),
        ).called(1);
      },
    );
  });
}
