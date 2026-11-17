import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/use_cases/authenticate_user_use_case.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/role_profile_data.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/domain/services/player_personal_data_utils.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/shell/tabs/player_personal_data_summary_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAuthenticateUserUseCase extends Mock
    implements AuthenticateUserUseCase {}

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
  Map<String, WidgetBuilder>? routes,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith((_) => controller),
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: routes ?? const {},
      home: child,
    ),
  );
}

void main() {
  late _MockAuthRepository authRepository;

  setUp(() {
    authRepository = _MockAuthRepository();
  });

  testWidgets(
      'renders identity header with photo avatar, full name, document, and calculated age',
      (tester) async {
    final birthDate = DateTime(2000, 1, 15);
    final expectedAge = PlayerPersonalDataUtils.calculateAge(birthDate);

    final user = UserAccount(
      id: 'p-1',
      fullName: 'Andrés Felipe Gómez',
      email: 'andres@example.com',
      activeRole: UserRole.player,
      phone: '3109876543',
      documentId: '1098765432',
      roleProfile: RoleProfileData(
        firstName: 'Andrés',
        secondName: 'Felipe',
        firstSurname: 'Gómez',
        birthDate: birthDate,
        photoUrl: 'https://example.com/avatar.jpg',
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
      _wrapWithApp(
        const PlayerPersonalDataSummaryScreen(),
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('player_summary_header_card')), findsOneWidget);
    expect(find.text('Andrés Felipe Gómez'), findsOneWidget);
    expect(find.text('CC: 1098765432'), findsOneWidget);
    expect(find.text('$expectedAge años'), findsOneWidget);

    final avatar = tester.widget<CircleAvatar>(
      find.byKey(const ValueKey('player_summary_avatar')),
    );
    expect(avatar.backgroundImage, isA<NetworkImage>());
  });

  testWidgets('displays age unknown placeholder when birthDate is null',
      (tester) async {
    final user = UserAccount(
      id: 'p-2',
      fullName: 'Mateo Ortiz',
      email: 'mateo@example.com',
      activeRole: UserRole.player,
      documentId: '98765432',
      roleProfile: const RoleProfileData(
        firstName: 'Mateo',
        firstSurname: 'Ortiz',
      ),
    );

    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's-2',
          user: user,
          sessionToken: 't-2',
          authenticatedAt: DateTime.now(),
        ),
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        const PlayerPersonalDataSummaryScreen(),
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edad no registrada'), findsOneWidget);
  });

  testWidgets('renders demographics card with all personal fields',
      (tester) async {
    final user = UserAccount(
      id: 'p-3',
      fullName: 'Carlos Ruiz',
      email: 'carlos@example.com',
      activeRole: UserRole.player,
      roleProfile: RoleProfileData(
        firstName: 'Carlos',
        firstSurname: 'Ruiz',
        sex: 'male',
        birthDate: DateTime(1995, 6, 20),
        bloodType: 'O+',
        department: 'Santander',
        municipality: 'Bucaramanga',
      ),
    );

    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's-3',
          user: user,
          sessionToken: 't-3',
          authenticatedAt: DateTime.now(),
        ),
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        const PlayerPersonalDataSummaryScreen(),
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('player_summary_demographics_card')), findsOneWidget);
    expect(find.text('Información Demográfica'), findsOneWidget);
    expect(find.text('Masculino'), findsOneWidget);
    expect(find.text('1995-06-20'), findsOneWidget);
    expect(find.text('O+'), findsOneWidget);
    expect(find.text('Santander'), findsOneWidget);
    expect(find.text('Bucaramanga'), findsOneWidget);
  });

  testWidgets('renders tactical profile with primary and secondary position chips',
      (tester) async {
    final user = UserAccount(
      id: 'p-4',
      fullName: 'David Silva',
      email: 'david@example.com',
      activeRole: UserRole.player,
      roleProfile: const RoleProfileData(
        primaryPosition: PlayerPosition.midfielder,
        secondaryPositions: ['MCO', 'ED'],
      ),
    );

    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's-4',
          user: user,
          sessionToken: 't-4',
          authenticatedAt: DateTime.now(),
        ),
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        const PlayerPersonalDataSummaryScreen(),
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('player_summary_tactical_card')), findsOneWidget);
    expect(find.text('Perfil Táctico'), findsOneWidget);
    expect(find.text('Mediocampo'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('player_summary_secondary_chip_MCO')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('player_summary_secondary_chip_ED')),
      findsOneWidget,
    );
  });

  testWidgets(
      'renders empty documentation placeholders when ID documents are missing',
      (tester) async {
    final user = UserAccount(
      id: 'p-5',
      fullName: 'Juan Pérez',
      email: 'juan@example.com',
      activeRole: UserRole.player,
      roleProfile: const RoleProfileData(),
    );

    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's-5',
          user: user,
          sessionToken: 't-5',
          authenticatedAt: DateTime.now(),
        ),
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        const PlayerPersonalDataSummaryScreen(),
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('player_summary_documentation_card')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('player_summary_front_doc_empty')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('player_summary_back_doc_empty')), findsOneWidget);
    expect(find.text('No capturada'), findsNWidgets(2));
  });

  testWidgets(
      'renders ID thumbnails, opens zoom dialog on tap, and closes on button tap',
      (tester) async {
    final user = UserAccount(
      id: 'p-6',
      fullName: 'Santiago Cruz',
      email: 'santiago@example.com',
      activeRole: UserRole.player,
      roleProfile: const RoleProfileData(
        documentFrontUrl: 'https://example.com/front.jpg',
        documentBackUrl: 'https://example.com/back.jpg',
      ),
    );

    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's-6',
          user: user,
          sessionToken: 't-6',
          authenticatedAt: DateTime.now(),
        ),
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        const PlayerPersonalDataSummaryScreen(),
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    final frontThumbnail =
        find.byKey(const ValueKey('player_summary_front_doc_thumbnail'));
    expect(frontThumbnail, findsOneWidget);
    await tester.ensureVisible(frontThumbnail);
    await tester.tap(frontThumbnail);
    await tester.pumpAndSettle();

    // Verify dialog opened with InteractiveViewer and close button
    expect(find.byType(InteractiveViewer), findsOneWidget);
    final closeBtn =
        find.byKey(const ValueKey('player_summary_viewer_close_button'));
    expect(closeBtn, findsOneWidget);

    // Tap close button and verify dismissed
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('tapping Editar Datos navigates to /profile/personal-data',
      (tester) async {
    final user = UserAccount(
      id: 'p-7',
      fullName: 'Carlos Gómez',
      email: 'carlos@example.com',
      activeRole: UserRole.player,
      roleProfile: const RoleProfileData(),
    );

    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's-7',
          user: user,
          sessionToken: 't-7',
          authenticatedAt: DateTime.now(),
        ),
      ),
    );

    await tester.pumpWidget(
      _wrapWithApp(
        const PlayerPersonalDataSummaryScreen(),
        controller: controller,
        routes: {
          '/profile/personal-data': (context) =>
              const Scaffold(body: Text('Personal Data Form Screen')),
        },
      ),
    );
    await tester.pumpAndSettle();

    final editAction = find.byKey(const ValueKey('player_summary_edit_action'));
    expect(editAction, findsOneWidget);
    await tester.tap(editAction);
    await tester.pumpAndSettle();

    expect(find.text('Personal Data Form Screen'), findsOneWidget);
  });
}
