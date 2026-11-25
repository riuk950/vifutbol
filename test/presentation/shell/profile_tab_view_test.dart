import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/team_join_requests_providers.dart';
import 'package:vifutbol/application/use_cases/authenticate_user_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/role_profile_data.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/shell/tabs/profile_faq_screen.dart';
import 'package:vifutbol/presentation/shell/tabs/profile_legal_document_screen.dart';
import 'package:vifutbol/presentation/shell/tabs/profile_tab_view.dart';
import 'package:vifutbol/presentation/shell/tabs/widgets/remove_ads_dialog.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAuthenticateUserUseCase extends Mock
    implements AuthenticateUserUseCase {}

class _MockEnvironmentConfig extends Mock implements EnvironmentConfig {}

class _TestAuthController extends AuthController {
  _TestAuthController({
    required super.authRepository,
    required AuthFlowState initialState,
  }) : super(authenticateUserUseCase: _MockAuthenticateUserUseCase()) {
    state = initialState;
  }
}

Widget _wrapWithApp(
  Widget child, {
  required _TestAuthController controller,
  required EnvironmentConfig config,
  Map<String, WidgetBuilder>? routes,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith((_) => controller),
      environmentConfigProvider.overrideWithValue(config),
      playerPendingRequestsCountProvider.overrideWith((ref) => 0),
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routes: routes ?? const {},
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  late _MockAuthRepository authRepository;
  late _MockEnvironmentConfig config;

  setUp(() {
    authRepository = _MockAuthRepository();
    config = _MockEnvironmentConfig();
    when(() => config.environment).thenReturn(AppEnvironment.development);
  });

  testWidgets('shows amber Datos incompletos badge and CTA when incomplete',
      (tester) async {
    final user = UserAccount(
      id: 'u1',
      fullName: 'Carlos Ruiz',
      email: 'carlos@test.com',
      activeRole: UserRole.player,
      authorizedRoles: {UserRole.player, UserRole.fan},
      onboardingCompleted: true,
    );
    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's1',
          user: user,
          sessionToken: 't1',
          authenticatedAt: DateTime(2026, 11, 13),
        ),
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        const ProfileTabView(),
        controller: controller,
        config: config,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Datos incompletos'), findsOneWidget);
    expect(find.text('Completar mi perfil'), findsOneWidget);

    final badge = tester.widget<KickPulseBadge>(
      find.byKey(const ValueKey('profile_completeness_badge')),
    );
    expect(badge.variant, KickPulseBadgeVariant.warning);
  });

  testWidgets('shows green Perfil completo badge and hides banner when complete',
      (tester) async {
    final user = UserAccount(
      id: 'u2',
      fullName: 'DT Luis',
      email: 'luis@test.com',
      activeRole: UserRole.coach,
      authorizedRoles: {UserRole.coach, UserRole.fan},
      onboardingCompleted: true,
      phone: '3001112233',
      documentId: '77665544',
      roleProfile: const RoleProfileData(
        clubName: 'Club Norte',
        licenseLevel: 'PRO',
      ),
    );
    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's2',
          user: user,
          sessionToken: 't2',
          authenticatedAt: DateTime(2026, 11, 13),
        ),
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        const ProfileTabView(),
        controller: controller,
        config: config,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perfil completo'), findsOneWidget);
    expect(find.text('Completar mi perfil'), findsNothing);

    final badge = tester.widget<KickPulseBadge>(
      find.byKey(const ValueKey('profile_completeness_badge')),
    );
    expect(badge.variant, KickPulseBadgeVariant.success);
  });

  testWidgets('excludes guest fan from incomplete profile badge and banner',
      (tester) async {
    final guest = UserAccount.guestFan(id: 'guest-1');
    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's3',
          user: guest,
          sessionToken: 't3',
          authenticatedAt: DateTime(2026, 11, 13),
        ),
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        const ProfileTabView(),
        controller: controller,
        config: config,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Datos incompletos'), findsNothing);
    expect(find.text('Perfil completo'), findsNothing);
    expect(find.text('Completar mi perfil'), findsNothing);
  });

  testWidgets('renders NetworkImage when user photoUrl starts with http',
      (tester) async {
    final user = UserAccount(
      id: 'u4',
      fullName: 'Carlos Ruiz',
      email: 'carlos@test.com',
      activeRole: UserRole.player,
      authorizedRoles: {UserRole.player, UserRole.fan},
      roleProfile: const RoleProfileData(
        photoUrl: 'https://images.example.com/avatar.jpg',
      ),
    );
    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's4',
          user: user,
          sessionToken: 't4',
          authenticatedAt: DateTime(2026, 11, 13),
        ),
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        const ProfileTabView(),
        controller: controller,
        config: config,
      ),
    );
    await tester.pumpAndSettle();

    final avatar = tester.widget<CircleAvatar>(
      find.byKey(const ValueKey('profile_identity_avatar')),
    );
    expect(avatar.backgroundImage, isA<NetworkImage>());
    expect(
      (avatar.backgroundImage as NetworkImage).url,
      'https://images.example.com/avatar.jpg',
    );
    expect(avatar.child, isNull);
  });

  testWidgets('renders FileImage when user photoUrl points to existing local file',
      (tester) async {
    final tempDir = Directory.systemTemp.createTempSync('avatar_test');
    final tempFile = File('${tempDir.path}/local_avatar.png')
      ..writeAsBytesSync([1, 2, 3]);

    final user = UserAccount(
      id: 'u5',
      fullName: 'Carlos Ruiz',
      email: 'carlos@test.com',
      activeRole: UserRole.player,
      authorizedRoles: {UserRole.player, UserRole.fan},
      roleProfile: RoleProfileData(
        photoUrl: tempFile.path,
      ),
    );
    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's5',
          user: user,
          sessionToken: 't5',
          authenticatedAt: DateTime(2026, 11, 13),
        ),
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        const ProfileTabView(),
        controller: controller,
        config: config,
      ),
    );
    await tester.pumpAndSettle();

    final avatar = tester.widget<CircleAvatar>(
      find.byKey(const ValueKey('profile_identity_avatar')),
    );
    expect(avatar.backgroundImage, isA<FileImage>());
    expect(
      (avatar.backgroundImage as FileImage).file.path,
      tempFile.path,
    );
    expect(avatar.child, isNull);

    tempDir.deleteSync(recursive: true);
  });

  testWidgets('renders default fallback icon when user has no photoUrl',
      (tester) async {
    final user = UserAccount(
      id: 'u6',
      fullName: 'Carlos Ruiz',
      email: 'carlos@test.com',
      activeRole: UserRole.player,
      authorizedRoles: {UserRole.player, UserRole.fan},
    );
    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's6',
          user: user,
          sessionToken: 't6',
          authenticatedAt: DateTime(2026, 11, 13),
        ),
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        const ProfileTabView(),
        controller: controller,
        config: config,
      ),
    );
    await tester.pumpAndSettle();

    final avatar = tester.widget<CircleAvatar>(
      find.byKey(const ValueKey('profile_identity_avatar')),
    );
    expect(avatar.backgroundImage, isNull);
    expect(avatar.child, isA<Icon>());
    final icon = avatar.child as Icon;
    expect(icon.icon, Icons.sports_soccer);
  });

  testWidgets(
      'navigates to /profile/personal-data when profile is incomplete and tile is tapped',
      (tester) async {
    final user = UserAccount(
      id: 'u7',
      fullName: 'Carlos Ruiz',
      email: 'carlos@test.com',
      activeRole: UserRole.player,
      authorizedRoles: {UserRole.player, UserRole.fan},
      onboardingCompleted: true,
      // Incomplete profile
    );
    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's7',
          user: user,
          sessionToken: 't7',
          authenticatedAt: DateTime(2026, 11, 13),
        ),
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        const ProfileTabView(),
        controller: controller,
        config: config,
        routes: {
          '/profile/personal-data': (context) =>
              const Scaffold(body: Text('Personal Data Form Screen')),
          '/profile/personal-data/summary': (context) =>
              const Scaffold(body: Text('Personal Data Summary Screen')),
        },
      ),
    );
    await tester.pumpAndSettle();

    final tile = find.byKey(const Key('profile_personal_data_tile'));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text('Personal Data Form Screen'), findsOneWidget);
  });

  testWidgets(
      'navigates to /profile/personal-data/summary when profile is complete and tile is tapped',
      (tester) async {
    final user = UserAccount(
      id: 'u8',
      fullName: 'Carlos Ruiz',
      email: 'carlos@test.com',
      activeRole: UserRole.player,
      authorizedRoles: {UserRole.player, UserRole.fan},
      onboardingCompleted: true,
      phone: '3001234567',
      documentId: '1098765432',
      roleProfile: RoleProfileData(
        firstName: 'Carlos',
        firstSurname: 'Ruiz',
        sex: 'M',
        birthDate: DateTime(1998, 5, 15),
        bloodType: 'O+',
        department: 'Santander',
        municipality: 'Bucaramanga',
        primaryPosition: PlayerPosition.forward,
        secondaryPositions: const ['midfielder'],
        documentFrontUrl: 'https://example.com/front.jpg',
        documentBackUrl: 'https://example.com/back.jpg',
        photoUrl: 'https://example.com/carlos.jpg',
      ),
    );
    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's8',
          user: user,
          sessionToken: 't8',
          authenticatedAt: DateTime(2026, 11, 13),
        ),
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        const ProfileTabView(),
        controller: controller,
        config: config,
        routes: {
          '/profile/personal-data': (context) =>
              const Scaffold(body: Text('Personal Data Form Screen')),
          '/profile/personal-data/summary': (context) =>
              const Scaffold(body: Text('Personal Data Summary Screen')),
        },
      ),
    );
    await tester.pumpAndSettle();

    final tile = find.byKey(const Key('profile_personal_data_tile'));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text('Personal Data Summary Screen'), findsOneWidget);
  });

  group('HU 24.1 - Read-only active role & disabled role switching', () {
    String expectedRoleLabel(UserRole role) {
      return switch (role) {
        UserRole.organizer => 'Organizador',
        UserRole.coach => 'Entrenador',
        UserRole.referee => 'Árbitro',
        UserRole.player => 'Jugador',
        UserRole.fan => 'Aficionado',
      };
    }

    for (final env in [AppEnvironment.development, AppEnvironment.production]) {
      final envLabel = env == AppEnvironment.development ? 'dev' : 'prod';

      for (final role in UserRole.values) {
        testWidgets(
          'hides role switcher and shows read-only badge for ${role.name} in $envLabel',
          (tester) async {
            when(() => config.environment).thenReturn(env);
            final user = UserAccount(
              id: 'u-${role.name}-$envLabel',
              fullName: 'Usuario Prueba',
              email: 'test@vifutbol.com',
              activeRole: role,
              authorizedRoles: UserRole.values.toSet(),
              onboardingCompleted: true,
            );
            final controller = _TestAuthController(
              authRepository: authRepository,
              initialState: AuthFlowState(
                status: AuthStatus.authenticated,
                session: AuthSession(
                  sessionId: 's-${role.name}-$envLabel',
                  user: user,
                  sessionToken: 'tok',
                  authenticatedAt: DateTime(2026, 11, 25),
                ),
              ),
            );

            await tester.pumpWidget(
              _wrapWithApp(
                const ProfileTabView(),
                controller: controller,
                config: config,
              ),
            );
            await tester.pumpAndSettle();

            expect(find.byType(ChoiceChip), findsNothing);
            expect(find.text('Cambiar rol activo'), findsNothing);
            expect(
              find.textContaining('Entorno DEV activo'),
              findsNothing,
            );
            expect(
              find.text('Roles autorizados en tu cuenta:'),
              findsNothing,
            );

            final badgeFinder = find.byKey(
              const ValueKey('profile_active_role_badge'),
            );
            expect(badgeFinder, findsOneWidget);
            expect(
              find.descendant(
                of: badgeFinder,
                matching: find.text(expectedRoleLabel(role)),
              ),
              findsOneWidget,
            );
          },
        );
      }

      testWidgets(
        'hides role switcher and shows read-only Aficionado badge for guest in $envLabel',
        (tester) async {
          when(() => config.environment).thenReturn(env);
          final guest = UserAccount.guestFan(id: 'guest-$envLabel');
          final controller = _TestAuthController(
            authRepository: authRepository,
            initialState: AuthFlowState(
              status: AuthStatus.authenticated,
              session: AuthSession(
                sessionId: 's-guest-$envLabel',
                user: guest,
                sessionToken: 'tok-guest',
                authenticatedAt: DateTime(2026, 11, 25),
              ),
            ),
          );

          await tester.pumpWidget(
            _wrapWithApp(
              const ProfileTabView(),
              controller: controller,
              config: config,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(ChoiceChip), findsNothing);
          expect(find.text('Cambiar rol activo'), findsNothing);
          final badgeFinder = find.byKey(
            const ValueKey('profile_active_role_badge'),
          );
          expect(badgeFinder, findsOneWidget);
          expect(
            find.descendant(
              of: badgeFinder,
              matching: find.text('Aficionado'),
            ),
            findsOneWidget,
          );
        },
      );
    }

    testWidgets(
      'active role badge exposes readOnly semantics and renders without overflow at 1.5x text scale',
      (tester) async {
        final user = UserAccount(
          id: 'u-a11y',
          fullName: 'Carlos Organizador',
          email: 'org@vifutbol.com',
          activeRole: UserRole.organizer,
          authorizedRoles: {UserRole.organizer, UserRole.fan},
          onboardingCompleted: true,
        );
        final controller = _TestAuthController(
          authRepository: authRepository,
          initialState: AuthFlowState(
            status: AuthStatus.authenticated,
            session: AuthSession(
              sessionId: 's-a11y',
              user: user,
              sessionToken: 'tok-a11y',
              authenticatedAt: DateTime(2026, 11, 25),
            ),
          ),
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: _wrapWithApp(
              const ProfileTabView(),
              controller: controller,
              config: config,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final badgeFinder = find.byKey(
          const ValueKey('profile_active_role_badge'),
        );
        expect(badgeFinder, findsOneWidget);
        final semantics = tester.getSemantics(badgeFinder);
        expect(semantics.label, contains('Organizador'));
        expect(semantics.flagsCollection.isReadOnly, isTrue);
      },
    );

    testWidgets(
      'repeated taps on active role badge and widget recreation keep activeRole unchanged and preserve profile actions',
      (tester) async {
        final user = UserAccount(
          id: 'u-preserve',
          fullName: 'Jugador Fiel',
          email: 'jugador@vifutbol.com',
          activeRole: UserRole.player,
          authorizedRoles: {UserRole.player, UserRole.coach, UserRole.fan},
          onboardingCompleted: true,
        );
        final controller = _TestAuthController(
          authRepository: authRepository,
          initialState: AuthFlowState(
            status: AuthStatus.authenticated,
            session: AuthSession(
              sessionId: 's-preserve',
              user: user,
              sessionToken: 'tok-preserve',
              authenticatedAt: DateTime(2026, 11, 25),
            ),
          ),
        );

        await tester.pumpWidget(
          _wrapWithApp(
            const ProfileTabView(key: ValueKey('profile_first_mount')),
            controller: controller,
            config: config,
          ),
        );
        await tester.pumpAndSettle();

        final badgeFinder = find.byKey(
          const ValueKey('profile_active_role_badge'),
        );
        for (var i = 0; i < 5; i++) {
          await tester.tap(badgeFinder);
        }
        await tester.pumpAndSettle();

        // Recreate / re-pump ProfileTabView to simulate navigation or resume
        await tester.pumpWidget(
          _wrapWithApp(
            const ProfileTabView(key: ValueKey('profile_remount')),
            controller: controller,
            config: config,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          controller.state.session?.user.activeRole,
          UserRole.player,
        );
        for (final target in UserRole.values) {
          verifyNever(
            () => authRepository.switchActiveRole(
              userId: 'u-preserve',
              targetRole: target,
            ),
          );
        }

        // Preserved profile sections remain intact
        expect(find.text('Permisos y capacidades del rol'), findsOneWidget);
        expect(
          find.byKey(const Key('profile_personal_data_tile')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('profile_complete_action_button')),
          findsOneWidget,
        );
        expect(find.text('Cerrar sesión'), findsOneWidget);
      },
    );
  });

  group('HU 24.2 - Legal, support and remove ads actions in Profile', () {
    for (final env in [AppEnvironment.development, AppEnvironment.production]) {
      final envLabel = env == AppEnvironment.development ? 'dev' : 'prod';

      for (final role in UserRole.values) {
        testWidgets(
          'renders 4 ordered action tiles below capabilities and above logout for ${role.name} in $envLabel',
          (tester) async {
            when(() => config.environment).thenReturn(env);
            final user = UserAccount(
              id: 'u-legal-${role.name}-$envLabel',
              fullName: 'Usuario Legal',
              email: 'legal@vifutbol.com',
              activeRole: role,
              authorizedRoles: {role},
              onboardingCompleted: true,
            );
            final controller = _TestAuthController(
              authRepository: authRepository,
              initialState: AuthFlowState(
                status: AuthStatus.authenticated,
                session: AuthSession(
                  sessionId: 's-legal-${role.name}-$envLabel',
                  user: user,
                  sessionToken: 'tok-legal',
                  authenticatedAt: DateTime(2026, 11, 25),
                ),
              ),
            );

            await tester.pumpWidget(
              _wrapWithApp(
                const ProfileTabView(),
                controller: controller,
                config: config,
              ),
            );
            await tester.pumpAndSettle();

            final capabilitiesFinder = find.byKey(
              const Key('profile_capabilities_section'),
            );
            final removeAdsFinder = find.byKey(
              const Key('profile_remove_ads_tile'),
            );
            final termsFinder = find.byKey(const Key('profile_terms_tile'));
            final privacyFinder = find.byKey(
              const Key('profile_privacy_policy_tile'),
            );
            final faqFinder = find.byKey(const Key('profile_faq_tile'));
            final logoutFinder = find.byKey(
              const Key('profile_logout_action_button'),
            );

            expect(capabilitiesFinder, findsOneWidget);
            expect(removeAdsFinder, findsOneWidget);
            expect(termsFinder, findsOneWidget);
            expect(privacyFinder, findsOneWidget);
            expect(faqFinder, findsOneWidget);
            expect(logoutFinder, findsOneWidget);

            expect(find.text('Quitar anuncios'), findsOneWidget);
            expect(find.text('Términos y condiciones'), findsOneWidget);
            expect(
              find.text('Políticas de tratamiento de datos'),
              findsOneWidget,
            );
            expect(find.text('Preguntas frecuentes'), findsOneWidget);

            final capabilitiesBottom = tester
                .getBottomLeft(capabilitiesFinder)
                .dy;
            final removeAdsTop = tester.getTopLeft(removeAdsFinder).dy;
            final termsTop = tester.getTopLeft(termsFinder).dy;
            final privacyTop = tester.getTopLeft(privacyFinder).dy;
            final faqTop = tester.getTopLeft(faqFinder).dy;
            final logoutTop = tester.getTopLeft(logoutFinder).dy;

            expect(removeAdsTop, greaterThan(capabilitiesBottom));
            expect(termsTop, greaterThan(removeAdsTop));
            expect(privacyTop, greaterThan(termsTop));
            expect(faqTop, greaterThan(privacyTop));
            expect(logoutTop, greaterThan(faqTop));

            for (final finder in [
              removeAdsFinder,
              termsFinder,
              privacyFinder,
              faqFinder,
            ]) {
              expect(tester.getSize(finder).height, greaterThanOrEqualTo(44));
            }
          },
        );
      }

      testWidgets(
        'renders all 4 ordered action tiles for guest fan in $envLabel',
        (tester) async {
          when(() => config.environment).thenReturn(env);
          final guest = UserAccount.guestFan(id: 'guest-legal-$envLabel');
          final controller = _TestAuthController(
            authRepository: authRepository,
            initialState: AuthFlowState(
              status: AuthStatus.authenticated,
              session: AuthSession(
                sessionId: 's-guest-legal-$envLabel',
                user: guest,
                sessionToken: 'tok-guest',
                authenticatedAt: DateTime(2026, 11, 25),
              ),
            ),
          );

          await tester.pumpWidget(
            _wrapWithApp(
              const ProfileTabView(),
              controller: controller,
              config: config,
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('profile_remove_ads_tile')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('profile_terms_tile')), findsOneWidget);
          expect(
            find.byKey(const Key('profile_privacy_policy_tile')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('profile_faq_tile')), findsOneWidget);
        },
      );
    }

    testWidgets(
      'renders 4 action tiles without overflow at 1.5x text scale',
      (tester) async {
        final user = UserAccount(
          id: 'u-legal-a11y',
          fullName: 'Usuario Accesible',
          email: 'a11y@vifutbol.com',
          activeRole: UserRole.fan,
          authorizedRoles: {UserRole.fan},
          onboardingCompleted: true,
        );
        final controller = _TestAuthController(
          authRepository: authRepository,
          initialState: AuthFlowState(
            status: AuthStatus.authenticated,
            session: AuthSession(
              sessionId: 's-legal-a11y',
              user: user,
              sessionToken: 'tok-a11y',
              authenticatedAt: DateTime(2026, 11, 25),
            ),
          ),
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: _wrapWithApp(
              const ProfileTabView(),
              controller: controller,
              config: config,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'navigates to Terms, Privacy Policy, and FAQ screens offline and returns cleanly to Profile',
      (tester) async {
        final user = UserAccount(
          id: 'u-legal-nav',
          fullName: 'Usuario Navegacion',
          email: 'nav@vifutbol.com',
          activeRole: UserRole.organizer,
          authorizedRoles: {UserRole.organizer},
          onboardingCompleted: true,
        );
        final controller = _TestAuthController(
          authRepository: authRepository,
          initialState: AuthFlowState(
            status: AuthStatus.authenticated,
            session: AuthSession(
              sessionId: 's-legal-nav',
              user: user,
              sessionToken: 'tok-nav',
              authenticatedAt: DateTime(2026, 11, 25),
            ),
          ),
        );

        await tester.pumpWidget(
          _wrapWithApp(
            const ProfileTabView(),
            controller: controller,
            config: config,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Terms & Conditions
        final termsTile = find.byKey(const Key('profile_terms_tile'));
        await tester.ensureVisible(termsTile);
        await tester.tap(termsTile);
        await tester.pumpAndSettle();

        expect(find.byType(ProfileLegalDocumentScreen), findsOneWidget);
        expect(find.text('1. Aceptación y uso de la plataforma'), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProfileTabView), findsOneWidget);

        // 2. Privacy Policy
        final privacyTile = find.byKey(
          const Key('profile_privacy_policy_tile'),
        );
        await tester.ensureVisible(privacyTile);
        await tester.tap(privacyTile);
        await tester.pumpAndSettle();

        expect(find.byType(ProfileLegalDocumentScreen), findsOneWidget);
        expect(find.text('1. Datos personales recolectados'), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProfileTabView), findsOneWidget);

        // 3. FAQ
        final faqTile = find.byKey(const Key('profile_faq_tile'));
        await tester.ensureVisible(faqTile);
        await tester.tap(faqTile);
        await tester.pumpAndSettle();

        expect(find.byType(ProfileFaqScreen), findsOneWidget);
        expect(
          find.text('¿Cómo funciona ViFutbol sin conexión a internet?'),
          findsOneWidget,
        );

        await tester.tap(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProfileTabView), findsOneWidget);
      },
    );

    testWidgets(
      'opens RemoveAdsDialog on tap, closes cleanly, and guards against rapid double taps',
      (tester) async {
        final user = UserAccount(
          id: 'u-remove-ads',
          fullName: 'Usuario Anuncios',
          email: 'ads@vifutbol.com',
          activeRole: UserRole.fan,
          authorizedRoles: {UserRole.fan},
          onboardingCompleted: true,
        );
        final controller = _TestAuthController(
          authRepository: authRepository,
          initialState: AuthFlowState(
            status: AuthStatus.authenticated,
            session: AuthSession(
              sessionId: 's-remove-ads',
              user: user,
              sessionToken: 'tok-ads',
              authenticatedAt: DateTime(2026, 11, 25),
            ),
          ),
        );

        await tester.pumpWidget(
          _wrapWithApp(
            const ProfileTabView(),
            controller: controller,
            config: config,
          ),
        );
        await tester.pumpAndSettle();

        final removeAdsTile = find.byKey(const Key('profile_remove_ads_tile'));
        await tester.ensureVisible(removeAdsTile);

        // Rapid double tap must open only a single RemoveAdsDialog
        await tester.tap(removeAdsTile);
        await tester.tap(removeAdsTile, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.byType(RemoveAdsDialog), findsOneWidget);
        expect(find.text('Próximamente'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey('remove_ads_dialog_close_button')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RemoveAdsDialog), findsNothing);

        // Rapid double tap on Terms must push only 1 screen
        final termsTile = find.byKey(const Key('profile_terms_tile'));
        await tester.ensureVisible(termsTile);
        await tester.tap(termsTile);
        await tester.tap(termsTile, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.byType(ProfileLegalDocumentScreen), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProfileLegalDocumentScreen), findsNothing);
      },
    );
  });
}
