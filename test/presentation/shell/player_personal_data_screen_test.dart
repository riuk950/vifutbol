import 'package:flutter/material.dart';
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
import 'package:vifutbol/domain/entities/detailed_football_position.dart';
import 'package:vifutbol/domain/entities/player_personal_enums.dart';
import 'package:vifutbol/domain/entities/role_profile_data.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/navigation/app_router.dart';
import 'package:vifutbol/presentation/shell/tabs/player_personal_data_screen.dart';
import 'package:vifutbol/presentation/shell/tabs/profile_tab_view.dart';

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

void main() {
  late _MockAuthRepository authRepository;
  late _MockEnvironmentConfig config;

  setUpAll(() {
    registerFallbackValue(UserRole.player);
    registerFallbackValue(const RoleProfileData());
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    config = _MockEnvironmentConfig();
    when(() => config.environment).thenReturn(AppEnvironment.development);
    AppRouter.setupRouter();
  });

  Widget buildApp({
    required _TestAuthController controller,
    Widget? home,
    double textScaleFactor = 1.0,
    Size surfaceSize = const Size(390, 844),
  }) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((_) => controller),
        environmentConfigProvider.overrideWithValue(config),
        playerPendingRequestsCountProvider.overrideWith((ref) => 0),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: surfaceSize,
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: child!,
        ),
        routes: {
          '/profile/personal-data': (_) =>
              const Scaffold(body: PlayerPersonalDataScreen()),
        },
        home: home ?? const Scaffold(body: PlayerPersonalDataScreen()),
      ),
    );
  }

  group('PlayerPersonalDataScreen Widget Tests', () {
    testWidgets('renders all form fields with required widget keys',
        (tester) async {
      final user = UserAccount(
        id: 'u-player',
        fullName: 'Mateo Gómez',
        email: 'mateo@test.com',
        activeRole: UserRole.player,
        authorizedRoles: {UserRole.player, UserRole.fan},
        onboardingCompleted: true,
      );

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-1',
            user: user,
            sessionToken: 't-1',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(buildApp(controller: controller));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('player_personal_data_screen')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('player_form_document_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('player_form_phone_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('player_form_first_name_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('player_form_second_name_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('player_form_first_surname_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('player_form_second_surname_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('player_form_sex_selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('player_form_birth_date_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('player_form_age_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('player_form_blood_type_selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('player_form_department_selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('player_form_municipality_selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('player_form_save_button')),
        findsOneWidget,
      );

      // Verify all 15 position chips exist
      for (final pos in DetailedFootballPosition.values) {
        expect(
          find.byKey(Key('player_form_position_chip_${pos.code}')),
          findsOneWidget,
        );
      }
    });

    testWidgets(
        'validates mandatory fields and displays position error when none selected',
        (tester) async {
      final user = UserAccount(
        id: 'u-player',
        fullName: '',
        email: 'mateo@test.com',
        activeRole: UserRole.player,
        authorizedRoles: {UserRole.player, UserRole.fan},
        onboardingCompleted: true,
      );

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-1',
            user: user,
            sessionToken: 't-1',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(buildApp(controller: controller));
      await tester.pumpAndSettle();

      // Scroll to bottom and tap save
      final saveButton = find.byKey(const Key('player_form_save_button'));
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Validation errors should be present
      expect(
        find.byKey(const Key('player_form_positions_error')),
        findsOneWidget,
      );
      expect(
        find.text('El número de documento es obligatorio'),
        findsOneWidget,
      );
      expect(find.text('El teléfono es obligatorio'), findsOneWidget);
      expect(find.text('El primer nombre es obligatorio'), findsOneWidget);
      expect(find.text('El primer apellido es obligatorio'), findsOneWidget);
    });

    testWidgets('preloads existing player profile data and computes age',
        (tester) async {
      final existingUser = UserAccount(
        id: 'u-existing',
        fullName: 'Mateo Andrés Gómez Ruiz',
        email: 'mateo@test.com',
        activeRole: UserRole.player,
        authorizedRoles: {UserRole.player, UserRole.fan},
        onboardingCompleted: true,
        phone: '3009876543',
        documentId: '1098765432',
        roleProfile: RoleProfileData(
          firstName: 'Mateo',
          secondName: 'Andrés',
          firstSurname: 'Gómez',
          secondSurname: 'Ruiz',
          sex: 'male',
          birthDate: DateTime(2000, 1, 1),
          bloodType: 'O+',
          department: 'Antioquia',
          municipality: 'Medellín',
          primaryPosition: PlayerPosition.defender,
          secondaryPositions: const ['LD', 'CAD'],
        ),
      );

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-1',
            user: existingUser,
            sessionToken: 't-1',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(buildApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('1098765432'), findsOneWidget);
      expect(find.text('3009876543'), findsOneWidget);
      expect(find.text('Mateo'), findsOneWidget);
      expect(find.text('Andrés'), findsOneWidget);
      expect(find.text('Gómez'), findsOneWidget);
      expect(find.text('Ruiz'), findsOneWidget);
      expect(find.text('Antioquia'), findsOneWidget);
      expect(find.text('Medellín'), findsOneWidget);

      // Reactive age field should display completed years
      expect(find.byKey(const Key('player_form_age_field')), findsOneWidget);
      expect(find.textContaining('años'), findsOneWidget);
    });

    testWidgets(
        'selecting department clears previous municipality in cascading selection',
        (tester) async {
      final user = UserAccount(
        id: 'u-player',
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
            sessionId: 's-1',
            user: user,
            sessionToken: 't-1',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(buildApp(controller: controller));
      await tester.pumpAndSettle();

      // Tap department selector
      final depFinder = find.byKey(const Key('player_form_department_selector'));
      await tester.ensureVisible(depFinder);
      await tester.pumpAndSettle();
      await tester.tap(depFinder);
      await tester.pumpAndSettle();

      // In sheet, search "Antioquia"
      expect(find.byKey(const Key('location_picker_search_field')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('location_picker_search_field')),
        'antioquia',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Antioquia'));
      await tester.pumpAndSettle();

      expect(find.text('Antioquia'), findsOneWidget);

      // Tap municipality selector
      final munFinder = find.byKey(const Key('player_form_municipality_selector'));
      await tester.ensureVisible(munFinder);
      await tester.pumpAndSettle();
      await tester.tap(munFinder);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('location_picker_search_field')),
        'medellin',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medellín'));
      await tester.pumpAndSettle();

      expect(find.text('Medellín'), findsOneWidget);

      // Now change department to "Caldas" -> municipality should be cleared
      await tester.ensureVisible(depFinder);
      await tester.pumpAndSettle();
      await tester.tap(depFinder);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('location_picker_search_field')),
        'caldas',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Caldas'));
      await tester.pumpAndSettle();

      expect(find.text('Caldas'), findsOneWidget);
      // "Medellín" should no longer be shown in municipality selector
      expect(find.text('Medellín'), findsNothing);
    });

    testWidgets(
        'multi-position chips toggle selection and derive primaryPosition correctly',
        (tester) async {
      final user = UserAccount(
        id: 'u-player',
        fullName: '',
        email: 'mateo@test.com',
        activeRole: UserRole.player,
        authorizedRoles: {UserRole.player, UserRole.fan},
        onboardingCompleted: true,
      );

      RoleProfileData? savedProfile;
      String? savedFullName;

      when(
        () => authRepository.updateRoleProfile(
          userId: any(named: 'userId'),
          role: any(named: 'role'),
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          documentId: any(named: 'documentId'),
          roleProfile: any(named: 'roleProfile'),
        ),
      ).thenAnswer((invocation) async {
        savedFullName = invocation.namedArguments[#fullName] as String?;
        savedProfile =
            invocation.namedArguments[#roleProfile] as RoleProfileData?;
        return user.copyWith(
          fullName: savedFullName ?? '',
          phone: '3001234567',
          documentId: '10203040',
          roleProfile: savedProfile,
        );
      });

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-1',
            user: user,
            sessionToken: 't-1',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(buildApp(controller: controller));
      await tester.pumpAndSettle();

      // Enter valid fields
      await tester.enterText(
        find.byKey(const Key('player_form_document_field')),
        '10203040',
      );
      await tester.enterText(
        find.byKey(const Key('player_form_phone_field')),
        '3001234567',
      );
      await tester.enterText(
        find.byKey(const Key('player_form_first_name_field')),
        'Santiago',
      );
      await tester.enterText(
        find.byKey(const Key('player_form_first_surname_field')),
        'Arias',
      );

      // Use state hook to set custom fields cleanly
      final state = tester.state<PlayerPersonalDataScreenState>(
        find.byType(PlayerPersonalDataScreen),
      );
      state.applyDocumentScanData(
        sex: PlayerSex.male,
        birthDate: DateTime(1992, 1, 13),
        bloodType: BloodType.oPositive,
      );
      await tester.pumpAndSettle();

      // Pick department & municipality
      final depFinder = find.byKey(const Key('player_form_department_selector'));
      await tester.ensureVisible(depFinder);
      await tester.pumpAndSettle();
      await tester.tap(depFinder);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('location_picker_search_field')),
        'antioquia',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Antioquia'));
      await tester.pumpAndSettle();

      final munFinder = find.byKey(const Key('player_form_municipality_selector'));
      await tester.ensureVisible(munFinder);
      await tester.pumpAndSettle();
      await tester.tap(munFinder);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('location_picker_search_field')),
        'medellin',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medellín'));
      await tester.pumpAndSettle();

      // Scroll to position chips
      final ldChip = find.byKey(const Key('player_form_position_chip_LD'));
      await tester.ensureVisible(ldChip);
      await tester.pumpAndSettle();
      // Select LD and CAD
      await tester.tap(ldChip);
      final cadChip = find.byKey(const Key('player_form_position_chip_CAD'));
      await tester.ensureVisible(cadChip);
      await tester.pumpAndSettle();
      await tester.tap(cadChip);
      await tester.pumpAndSettle();

      // Save
      final saveBtn = find.byKey(const Key('player_form_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(savedFullName, 'Santiago Arias');
      expect(savedProfile, isNotNull);
      expect(savedProfile?.primaryPosition, PlayerPosition.defender);
      expect(savedProfile?.secondaryPositions, contains('LD'));
      expect(savedProfile?.secondaryPositions, contains('CAD'));
    });

    testWidgets('displays error banner and preserves form state on conflict error',
        (tester) async {
      final user = UserAccount(
        id: 'u-player',
        fullName: 'Carlos Ruiz',
        email: 'carlos@test.com',
        activeRole: UserRole.player,
        authorizedRoles: {UserRole.player, UserRole.fan},
        onboardingCompleted: true,
      );

      when(
        () => authRepository.updateRoleProfile(
          userId: any(named: 'userId'),
          role: any(named: 'role'),
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          documentId: any(named: 'documentId'),
          roleProfile: any(named: 'roleProfile'),
        ),
      ).thenThrow(const DocumentAlreadyLinkedFailure());

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-1',
            user: user,
            sessionToken: 't-1',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(buildApp(controller: controller));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('player_form_document_field')),
        '99999999',
      );
      await tester.enterText(
        find.byKey(const Key('player_form_phone_field')),
        '3001234567',
      );
      await tester.enterText(
        find.byKey(const Key('player_form_first_name_field')),
        'Carlos',
      );
      await tester.enterText(
        find.byKey(const Key('player_form_first_surname_field')),
        'Ruiz',
      );

      final state = tester.state<PlayerPersonalDataScreenState>(
        find.byType(PlayerPersonalDataScreen),
      );
      state.applyDocumentScanData(
        sex: PlayerSex.male,
        birthDate: DateTime(1998, 5, 20),
        bloodType: BloodType.oPositive,
      );
      await tester.pumpAndSettle();

      // Pick department and municipality
      final depFinder = find.byKey(const Key('player_form_department_selector'));
      await tester.ensureVisible(depFinder);
      await tester.pumpAndSettle();
      await tester.tap(depFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Antioquia'));
      await tester.pumpAndSettle();

      final munFinder = find.byKey(const Key('player_form_municipality_selector'));
      await tester.ensureVisible(munFinder);
      await tester.pumpAndSettle();
      await tester.tap(munFinder);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('location_picker_search_field')),
        'medellin',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medellín'));
      await tester.pumpAndSettle();

      // Select DC chip
      final dcChip = find.byKey(const Key('player_form_position_chip_DC'));
      await tester.ensureVisible(dcChip);
      await tester.pumpAndSettle();
      await tester.tap(dcChip);
      await tester.pumpAndSettle();

      // Save
      final saveBtn = find.byKey(const Key('player_form_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('player_personal_data_error_banner')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Este número de documento ya está asociado a otro jugador.',
        ),
        findsOneWidget,
      );
      // Preserves document input
      expect(find.text('99999999'), findsOneWidget);
    });

    testWidgets('unsaved-changes dialog warns before discarding on pop',
        (tester) async {
      final user = UserAccount(
        id: 'u-player',
        fullName: '',
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
            sessionId: 's-1',
            user: user,
            sessionToken: 't-1',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(buildApp(controller: controller));
      await tester.pumpAndSettle();

      // Make dirty
      await tester.enterText(
        find.byKey(const Key('player_form_document_field')),
        '12345',
      );
      await tester.pumpAndSettle();

      // Simulate back navigation
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(find.text('¿Descartar cambios?'), findsOneWidget);

      // Tap keep editing
      await tester.tap(find.text('Continuar editando'));
      await tester.pumpAndSettle();

      expect(find.text('¿Descartar cambios?'), findsNothing);
      expect(find.text('12345'), findsOneWidget);
    });

    testWidgets(
        'renders without overflow on compact 320px screen with 130% text scale',
        (tester) async {
      final user = UserAccount(
        id: 'u-compact',
        fullName: 'Mateo Gómez',
        email: 'mateo@test.com',
        activeRole: UserRole.player,
        authorizedRoles: {UserRole.player, UserRole.fan},
        onboardingCompleted: true,
      );

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-1',
            user: user,
            sessionToken: 't-1',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(
        buildApp(
          controller: controller,
          surfaceSize: const Size(320, 600),
          textScaleFactor: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      // Verify no assertion error or RenderFlex overflow occurred
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('player_personal_data_screen')),
        findsOneWidget,
      );
    });

    testWidgets(
        'profile tab routes player to /profile/personal-data from button and tile',
        (tester) async {
      final incompletePlayer = UserAccount(
        id: 'u-player-tile',
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
            sessionId: 's-tile',
            user: incompletePlayer,
            sessionToken: 't-tile',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(
        buildApp(
          controller: controller,
          home: const Scaffold(body: ProfileTabView()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify permanent tile exists
      final tileFinder = find.byKey(const Key('profile_personal_data_tile'));
      await tester.ensureVisible(tileFinder);
      await tester.pumpAndSettle();
      expect(tileFinder, findsOneWidget);

      // Tap "Completar mi perfil" button
      final btnFinder =
          find.byKey(const ValueKey('profile_complete_action_button'));
      await tester.ensureVisible(btnFinder);
      await tester.pumpAndSettle();
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      // Navigated to PlayerPersonalDataScreen
      expect(
        find.byKey(const Key('player_personal_data_screen')),
        findsOneWidget,
      );
    });
  });
}
