import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/document_scanner_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/team_join_requests_providers.dart';
import 'package:vifutbol/application/use_cases/authenticate_user_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/colombian_id_scan_result.dart';
import 'package:vifutbol/domain/entities/detailed_football_position.dart';
import 'package:vifutbol/domain/entities/player_personal_enums.dart';
import 'package:vifutbol/domain/entities/role_profile_data.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/domain/repositories/colombian_id_scanner_service.dart';
import 'package:vifutbol/domain/repositories/document_storage_repository.dart';
import 'package:vifutbol/infrastructure/storage/supabase_document_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/navigation/app_router.dart';
import 'package:vifutbol/presentation/shell/tabs/player_personal_data_screen.dart';
import 'package:vifutbol/presentation/shell/tabs/profile_tab_view.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAuthenticateUserUseCase extends Mock
    implements AuthenticateUserUseCase {}

class _MockEnvironmentConfig extends Mock implements EnvironmentConfig {}

class _MockScannerService extends Mock implements ColombianIdScannerService {}

class _MockDocumentStorageRepository extends Mock
    implements DocumentStorageRepository {}

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
    when(() => config.supabase).thenReturn(
      const SupabaseConfig(
        url: '',
        anonKey: '',
        schema: 'vifutboldev',
      ),
    );
    AppRouter.setupRouter();
  });

  Widget buildApp({
    required _TestAuthController controller,
    Widget? home,
    double textScaleFactor = 1.0,
    Size surfaceSize = const Size(390, 844),
    ColombianIdScannerService? scannerService,
    DocumentStorageRepository? storageRepository,
  }) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((_) => controller),
        environmentConfigProvider.overrideWithValue(config),
        playerPendingRequestsCountProvider.overrideWith((ref) => 0),
        documentStorageRepositoryProvider.overrideWithValue(
          storageRepository ?? const LocalDocumentStorageRepository(),
        ),
        if (scannerService != null)
          colombianIdScannerServiceProvider
              .overrideWithValue(scannerService),
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
        roleProfile: const RoleProfileData(
          documentFrontUrl: 'https://storage/front.jpg',
          documentBackUrl: 'https://storage/back.jpg',
        ),
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
        roleProfile: const RoleProfileData(
          documentFrontUrl: 'https://storage/front.jpg',
          documentBackUrl: 'https://storage/back.jpg',
        ),
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
        roleProfile: const RoleProfileData(
          documentFrontUrl: 'https://storage/front.jpg',
          documentBackUrl: 'https://storage/back.jpg',
        ),
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
        roleProfile: const RoleProfileData(
          documentFrontUrl: 'https://storage/front.jpg',
          documentBackUrl: 'https://storage/back.jpg',
        ),
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
        roleProfile: const RoleProfileData(
          documentFrontUrl: 'https://storage/front.jpg',
          documentBackUrl: 'https://storage/back.jpg',
        ),
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
        roleProfile: const RoleProfileData(
          documentFrontUrl: 'https://storage/front.jpg',
          documentBackUrl: 'https://storage/back.jpg',
        ),
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
        roleProfile: const RoleProfileData(
          documentFrontUrl: 'https://storage/front.jpg',
          documentBackUrl: 'https://storage/back.jpg',
        ),
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
        roleProfile: const RoleProfileData(
          documentFrontUrl: 'https://storage/front.jpg',
          documentBackUrl: 'https://storage/back.jpg',
        ),
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

    testWidgets('captures front and back ID photos sequentially via scan button',
        (tester) async {
      final user = UserAccount(
        id: 'u-scan',
        fullName: 'Test Player',
        email: 'test@vifutbol.com',
        activeRole: UserRole.player,
        authorizedRoles: {UserRole.player, UserRole.fan},
        onboardingCompleted: true,
      );

      final scanner = _MockScannerService();
      when(() => scanner.captureDocumentPhoto(isFront: true))
          .thenAnswer((_) async => '/tmp/doc_front.jpg');
      when(() => scanner.captureDocumentPhoto(isFront: false))
          .thenAnswer((_) async => '/tmp/doc_back.jpg');
      when(
        () => scanner.scanDocumentImages(
          frontImagePath: any(named: 'frontImagePath'),
          backImagePath: any(named: 'backImagePath'),
        ),
      ).thenAnswer(
        (_) async => const ColombianIdScanResult(
          documentId: '10203040',
          firstName: 'Juan',
          firstSurname: 'Pérez',
          source: ColombianIdScanSource.pdf417,
        ),
      );

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-scan',
            user: user,
            sessionToken: 'token-1',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(
        buildApp(controller: controller, scannerService: scanner),
      );
      await tester.pumpAndSettle();

      final scanBtn = find.byKey(const Key('player_form_scan_id_button'));
      await tester.ensureVisible(scanBtn);
      await tester.tap(scanBtn);
      await tester.pumpAndSettle();

      verify(() => scanner.captureDocumentPhoto(isFront: true)).called(1);
      verify(() => scanner.captureDocumentPhoto(isFront: false)).called(1);
      verify(
        () => scanner.scanDocumentImages(
          frontImagePath: '/tmp/doc_front.jpg',
          backImagePath: '/tmp/doc_back.jpg',
        ),
      ).called(1);

      // Verifies fields were autocompleted
      expect(find.text('10203040'), findsOneWidget);
      expect(find.text('Juan'), findsOneWidget);
      expect(find.text('Pérez'), findsOneWidget);
    });

    testWidgets(
        'displays camera permission banner and open settings button when denied',
        (tester) async {
      final user = UserAccount(
        id: 'u-perm',
        fullName: 'Test Player',
        email: 'perm@vifutbol.com',
        activeRole: UserRole.player,
        authorizedRoles: {UserRole.player, UserRole.fan},
        onboardingCompleted: true,
      );

      final scanner = _MockScannerService();
      when(() => scanner.captureDocumentPhoto(isFront: any(named: 'isFront')))
          .thenThrow(
        const CameraPermissionDeniedFailure(
          'Se requiere permiso de cámara para capturar la cédula.',
          true,
        ),
      );
      when(() => scanner.openCameraSettings()).thenAnswer((_) async {});

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-perm',
            user: user,
            sessionToken: 'token-1',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(
        buildApp(controller: controller, scannerService: scanner),
      );
      await tester.pumpAndSettle();

      final scanBtn = find.byKey(const Key('player_form_scan_id_button'));
      await tester.ensureVisible(scanBtn);
      await tester.tap(scanBtn);
      await tester.pumpAndSettle();

      // Banner and open settings button are visible
      expect(
        find.byKey(const Key('player_form_camera_permission_banner')),
        findsOneWidget,
      );
      final settingsBtn =
          find.byKey(const Key('player_form_open_settings_button'));
      expect(settingsBtn, findsOneWidget);

      await tester.tap(settingsBtn);
      await tester.pumpAndSettle();
      verify(() => scanner.openCameraSettings()).called(1);

      // Manual input fields remain completely editable
      final docField = find.byKey(const Key('player_form_document_field'));
      await tester.enterText(docField, '12345678');
      expect(find.text('12345678'), findsOneWidget);
    });

    testWidgets(
        'requires both document front and back photos before saving and displays error',
        (tester) async {
      final user = UserAccount(
        id: 'u-missing-photos',
        fullName: 'Mateo Gómez',
        email: 'mateo@vifutbol.com',
        activeRole: UserRole.player,
        authorizedRoles: {UserRole.player, UserRole.fan},
        onboardingCompleted: true,
        // No documentFrontUrl or documentBackUrl
      );

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-no-photos',
            user: user,
            sessionToken: 'token-1',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(buildApp(controller: controller));
      await tester.pumpAndSettle();

      // Fill in text fields
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
        'Mateo',
      );
      await tester.enterText(
        find.byKey(const Key('player_form_first_surname_field')),
        'Gómez',
      );

      final state = tester.state<PlayerPersonalDataScreenState>(
        find.byType(PlayerPersonalDataScreen),
      );
      state.applyDocumentScanData(
        sex: PlayerSex.male,
        birthDate: DateTime(1995, 5, 20),
        bloodType: BloodType.oPositive,
      );
      await tester.pumpAndSettle();

      // Pick department & municipality
      final depFinder = find.byKey(const Key('player_form_department_selector'));
      await tester.ensureVisible(depFinder);
      await tester.tap(depFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Antioquia'));
      await tester.pumpAndSettle();

      final munFinder =
          find.byKey(const Key('player_form_municipality_selector'));
      await tester.ensureVisible(munFinder);
      await tester.tap(munFinder);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('location_picker_search_field')),
        'medellin',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medellín'));
      await tester.pumpAndSettle();

      // Select position chip
      final ldChip = find.byKey(const Key('player_form_position_chip_LD'));
      await tester.ensureVisible(ldChip);
      await tester.tap(ldChip);
      await tester.pumpAndSettle();

      // Attempt save without photos
      final saveBtn = find.byKey(const Key('player_form_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Validation error displayed
      expect(
        find.byKey(const Key('player_form_id_images_error')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Debes capturar ambas caras de tu cédula (frente y reverso) para continuar',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'upload-before-save uploads local photos to storage and persists URLs',
        (tester) async {
      final user = UserAccount(
        id: 'u-upload',
        fullName: 'Mateo Gómez',
        email: 'mateo@vifutbol.com',
        activeRole: UserRole.player,
        authorizedRoles: {UserRole.player, UserRole.fan},
        onboardingCompleted: true,
      );

      final storage = _MockDocumentStorageRepository();
      when(
        () => storage.uploadPlayerIdDocuments(
          userId: any(named: 'userId'),
          frontLocalPath: any(named: 'frontLocalPath'),
          backLocalPath: any(named: 'backLocalPath'),
          existingFrontUrl: any(named: 'existingFrontUrl'),
          existingBackUrl: any(named: 'existingBackUrl'),
        ),
      ).thenAnswer(
        (_) async => (
          frontUrl: 'u-upload/document_front.jpg',
          backUrl: 'u-upload/document_back.jpg',
        ),
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
      ).thenAnswer((invocation) async {
        final profile = invocation.namedArguments[#roleProfile] as RoleProfileData?;
        return user.copyWith(roleProfile: profile);
      });

      final scanner = _MockScannerService();
      when(() => scanner.captureDocumentPhoto(isFront: true))
          .thenAnswer((_) async => '/local/front.jpg');
      when(() => scanner.captureDocumentPhoto(isFront: false))
          .thenAnswer((_) async => '/local/back.jpg');
      when(() => scanner.scanDocumentImages(
            frontImagePath: any(named: 'frontImagePath'),
            backImagePath: any(named: 'backImagePath'),
          )).thenAnswer((_) async => ColombianIdScanResult.empty);

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-upload',
            user: user,
            sessionToken: 'token-1',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(
        buildApp(
          controller: controller,
          scannerService: scanner,
          storageRepository: storage,
        ),
      );
      await tester.pumpAndSettle();

      final scanBtn = find.byKey(const Key('player_form_scan_id_button'));
      await tester.ensureVisible(scanBtn);
      await tester.tap(scanBtn);
      await tester.pumpAndSettle();

      // Fill in text fields
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
        'Mateo',
      );
      await tester.enterText(
        find.byKey(const Key('player_form_first_surname_field')),
        'Gómez',
      );

      final state = tester.state<PlayerPersonalDataScreenState>(
        find.byType(PlayerPersonalDataScreen),
      );
      state.applyDocumentScanData(
        sex: PlayerSex.male,
        birthDate: DateTime(1995, 5, 20),
        bloodType: BloodType.oPositive,
      );
      await tester.pumpAndSettle();

      // Pick department & municipality
      final depFinder = find.byKey(const Key('player_form_department_selector'));
      await tester.ensureVisible(depFinder);
      await tester.tap(depFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Antioquia'));
      await tester.pumpAndSettle();

      final munFinder =
          find.byKey(const Key('player_form_municipality_selector'));
      await tester.ensureVisible(munFinder);
      await tester.tap(munFinder);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('location_picker_search_field')),
        'medellin',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medellín'));
      await tester.pumpAndSettle();

      // Select position chip
      final ldChip = find.byKey(const Key('player_form_position_chip_LD'));
      await tester.ensureVisible(ldChip);
      await tester.tap(ldChip);
      await tester.pumpAndSettle();

      // Tap save
      final saveBtn = find.byKey(const Key('player_form_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      verify(() => storage.uploadPlayerIdDocuments(
            userId: 'u-upload',
            frontLocalPath: '/local/front.jpg',
            backLocalPath: '/local/back.jpg',
            existingFrontUrl: null,
            existingBackUrl: null,
          )).called(1);

      verify(() => authRepository.updateRoleProfile(
            userId: any(named: 'userId'),
            role: UserRole.player,
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            documentId: any(named: 'documentId'),
            roleProfile: any(named: 'roleProfile'),
          )).called(1);
    });

    testWidgets(
        'preserves local photos and inputs when storage upload fails',
        (tester) async {
      final user = UserAccount(
        id: 'u-upload-fail',
        fullName: 'Mateo Gómez',
        email: 'mateo@vifutbol.com',
        activeRole: UserRole.player,
        authorizedRoles: {UserRole.player, UserRole.fan},
        onboardingCompleted: true,
      );

      final storage = _MockDocumentStorageRepository();
      when(
        () => storage.uploadPlayerIdDocuments(
          userId: any(named: 'userId'),
          frontLocalPath: any(named: 'frontLocalPath'),
          backLocalPath: any(named: 'backLocalPath'),
          existingFrontUrl: any(named: 'existingFrontUrl'),
          existingBackUrl: any(named: 'existingBackUrl'),
        ),
      ).thenThrow(
        const DocumentUploadFailure(
          'Error al subir las imágenes de la cédula. Inténtalo nuevamente.',
        ),
      );

      final scanner = _MockScannerService();
      when(() => scanner.captureDocumentPhoto(isFront: true))
          .thenAnswer((_) async => '/local/front.jpg');
      when(() => scanner.captureDocumentPhoto(isFront: false))
          .thenAnswer((_) async => '/local/back.jpg');
      when(() => scanner.scanDocumentImages(
            frontImagePath: any(named: 'frontImagePath'),
            backImagePath: any(named: 'backImagePath'),
          )).thenAnswer((_) async => ColombianIdScanResult.empty);

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-fail',
            user: user,
            sessionToken: 'token-1',
            authenticatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(
        buildApp(
          controller: controller,
          scannerService: scanner,
          storageRepository: storage,
        ),
      );
      await tester.pumpAndSettle();

      final scanBtn = find.byKey(const Key('player_form_scan_id_button'));
      await tester.ensureVisible(scanBtn);
      await tester.tap(scanBtn);
      await tester.pumpAndSettle();

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
        'Mateo',
      );
      await tester.enterText(
        find.byKey(const Key('player_form_first_surname_field')),
        'Gómez',
      );

      final state = tester.state<PlayerPersonalDataScreenState>(
        find.byType(PlayerPersonalDataScreen),
      );
      state.applyDocumentScanData(
        sex: PlayerSex.male,
        birthDate: DateTime(1995, 5, 20),
        bloodType: BloodType.oPositive,
      );
      await tester.pumpAndSettle();

      final depFinder = find.byKey(const Key('player_form_department_selector'));
      await tester.ensureVisible(depFinder);
      await tester.tap(depFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Antioquia'));
      await tester.pumpAndSettle();

      final munFinder =
          find.byKey(const Key('player_form_municipality_selector'));
      await tester.ensureVisible(munFinder);
      await tester.tap(munFinder);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('location_picker_search_field')),
        'medellin',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medellín'));
      await tester.pumpAndSettle();

      final ldChip = find.byKey(const Key('player_form_position_chip_LD'));
      await tester.ensureVisible(ldChip);
      await tester.tap(ldChip);
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('player_form_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Displays upload error banner
      expect(
        find.text('Error al subir las imágenes de la cédula. Inténtalo nuevamente.'),
        findsOneWidget,
      );
      // Preserves entered text
      expect(find.text('10203040'), findsOneWidget);
      expect(find.text('Mateo'), findsOneWidget);
    });

    testWidgets(
        'HU 21.3: renders circular profile photo section and opens bottom sheet options',
        (tester) async {
      final user = UserAccount(
        id: 'u-1',
        fullName: 'Mateo Gómez',
        email: 'mateo@test.com',
        activeRole: UserRole.player,
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
        buildApp(controller: controller, home: const PlayerPersonalDataScreen()),
      );
      await tester.pumpAndSettle();

      // Profile avatar and button exist
      expect(find.byKey(const Key('player_form_profile_avatar')), findsOneWidget);
      final photoBtn = find.byKey(const Key('player_profile_photo_action'));
      expect(photoBtn, findsOneWidget);
      expect(find.text('Tomar Foto de Perfil'), findsOneWidget);

      // Tap opens modal bottom sheet
      await tester.tap(photoBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('player_photo_source_camera')), findsOneWidget);
      expect(find.byKey(const Key('player_photo_source_gallery')), findsOneWidget);
      expect(find.text('Tomar con la cámara'), findsOneWidget);
      expect(find.text('Elegir de la galería'), findsOneWidget);
    });

    testWidgets(
        'HU 21.3: allows saving form when profile photo is not provided (optional on save)',
        (tester) async {
      final user = UserAccount(
        id: 'u-1',
        fullName: 'Mateo Gómez',
        email: 'mateo@test.com',
        activeRole: UserRole.player,
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

      when(
        () => authRepository.updateRoleProfile(
          userId: any(named: 'userId'),
          role: any(named: 'role'),
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          documentId: any(named: 'documentId'),
          roleProfile: any(named: 'roleProfile'),
        ),
      ).thenAnswer((_) async => user);

      final mockStorage = _MockDocumentStorageRepository();
      when(
        () => mockStorage.uploadPlayerIdDocuments(
          userId: any(named: 'userId'),
          frontLocalPath: any(named: 'frontLocalPath'),
          backLocalPath: any(named: 'backLocalPath'),
          existingFrontUrl: any(named: 'existingFrontUrl'),
          existingBackUrl: any(named: 'existingBackUrl'),
        ),
      ).thenAnswer(
        (_) async => (
          frontUrl: 'uploaded_front.jpg',
          backUrl: 'uploaded_back.jpg',
        ),
      );

      final mockScanner = _MockScannerService();
      when(() => mockScanner.captureDocumentPhoto(isFront: true))
          .thenAnswer((_) async => 'fake_front.jpg');
      when(() => mockScanner.captureDocumentPhoto(isFront: false))
          .thenAnswer((_) async => 'fake_back.jpg');

      await tester.pumpWidget(
        buildApp(
          controller: controller,
          home: const PlayerPersonalDataScreen(),
          scannerService: mockScanner,
          storageRepository: mockStorage,
        ),
      );
      await tester.pumpAndSettle();

      // Capture documents via scan button
      final scanBtn = find.byKey(const Key('player_form_scan_id_button'));
      await tester.ensureVisible(scanBtn);
      await tester.tap(scanBtn);
      await tester.pumpAndSettle();

      // Enter required fields
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
        'Mateo',
      );
      await tester.enterText(
        find.byKey(const Key('player_form_first_surname_field')),
        'Gómez',
      );

      final state = tester.state<PlayerPersonalDataScreenState>(
        find.byType(PlayerPersonalDataScreen),
      );
      state.applyDocumentScanData(
        sex: PlayerSex.male,
        birthDate: DateTime(1995, 5, 20),
        bloodType: BloodType.oPositive,
      );
      await tester.pumpAndSettle();

      final depFinder = find.byKey(const Key('player_form_department_selector'));
      await tester.ensureVisible(depFinder);
      await tester.tap(depFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Antioquia'));
      await tester.pumpAndSettle();

      final munFinder =
          find.byKey(const Key('player_form_municipality_selector'));
      await tester.ensureVisible(munFinder);
      await tester.tap(munFinder);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('location_picker_search_field')),
        'medellin',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medellín'));
      await tester.pumpAndSettle();

      final ldChip = find.byKey(const Key('player_form_position_chip_LD'));
      await tester.ensureVisible(ldChip);
      await tester.tap(ldChip);
      await tester.pumpAndSettle();

      // Do NOT pick a profile photo -> save directly
      final saveBtn = find.byKey(const Key('player_form_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Save was invoked successfully without error banner
      expect(find.byKey(const Key('player_personal_data_error_banner')), findsNothing);
      verify(
        () => authRepository.updateRoleProfile(
          userId: any(named: 'userId'),
          role: UserRole.player,
          fullName: 'Mateo Gómez',
          phone: '3001234567',
          documentId: '10203040',
          roleProfile: any(named: 'roleProfile'),
        ),
      ).called(1);
    });
  });
}
