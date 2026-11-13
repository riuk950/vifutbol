import 'package:flutter/material.dart';
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
import 'package:vifutbol/domain/entities/role_profile_data.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
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
    registerFallbackValue(UserRole.fan);
    registerFallbackValue(const RoleProfileData());
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    config = _MockEnvironmentConfig();
    when(() => config.environment).thenReturn(AppEnvironment.development);
  });

  Widget buildApp(_TestAuthController controller) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((_) => controller),
        environmentConfigProvider.overrideWithValue(config),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ProfileTabView()),
      ),
    );
  }

  testWidgets('coach sees adaptive fields and immediately updates badge on save',
      (tester) async {
    final incompleteCoach = UserAccount(
      id: 'u1',
      fullName: 'DT Luis',
      email: 'luis@test.com',
      activeRole: UserRole.coach,
      authorizedRoles: {UserRole.coach, UserRole.fan},
      onboardingCompleted: true,
    );
    final completeCoach = incompleteCoach.copyWith(
      phone: '3001112233',
      documentId: '77665544',
      roleProfile: const RoleProfileData(
        clubName: 'Club Norte',
        licenseLevel: 'PRO',
      ),
    );

    when(
      () => authRepository.updateRoleProfile(
        userId: 'u1',
        role: UserRole.coach,
        phone: '3001112233',
        documentId: '77665544',
        roleProfile: any(named: 'roleProfile'),
      ),
    ).thenAnswer((_) async => completeCoach);

    final controller = _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's1',
          user: incompleteCoach,
          sessionToken: 't1',
          authenticatedAt: DateTime(2026, 11, 13),
        ),
      ),
    );

    await tester.pumpWidget(buildApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profile_complete_action_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('complete_profile_phone_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('complete_profile_document_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('complete_profile_club_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('complete_profile_license_field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('complete_profile_phone_field')),
      '3001112233',
    );
    await tester.enterText(
      find.byKey(const ValueKey('complete_profile_document_field')),
      '77665544',
    );
    await tester.enterText(
      find.byKey(const ValueKey('complete_profile_club_field')),
      'Club Norte',
    );
    await tester.enterText(
      find.byKey(const ValueKey('complete_profile_license_field')),
      'PRO',
    );

    await tester.tap(find.byKey(const ValueKey('complete_profile_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Perfil completo'), findsOneWidget);
    expect(find.text('Datos incompletos'), findsNothing);
  });

  testWidgets('fan omits document field and keeps inputs on conflict error',
      (tester) async {
    final incompletePlayer = UserAccount(
      id: 'u2',
      fullName: 'Carlos Ruiz',
      email: 'carlos@test.com',
      activeRole: UserRole.player,
      authorizedRoles: {UserRole.player, UserRole.fan},
      onboardingCompleted: true,
    );

    when(
      () => authRepository.updateRoleProfile(
        userId: 'u2',
        role: UserRole.player,
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
          sessionId: 's2',
          user: incompletePlayer,
          sessionToken: 't2',
          authenticatedAt: DateTime(2026, 11, 13),
        ),
      ),
    );

    await tester.pumpWidget(buildApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profile_complete_action_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('complete_profile_phone_field')),
      '3001234567',
    );
    await tester.enterText(
      find.byKey(const ValueKey('complete_profile_document_field')),
      '10203040',
    );

    await tester.tap(find.byKey(const ValueKey('complete_profile_save_button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'El documento ingresado ya está vinculado a otra cuenta de usuario.',
      ),
      findsOneWidget,
    );
    // Dialog stays open and preserves user input
    expect(find.text('3001234567'), findsOneWidget);
    expect(find.text('10203040'), findsOneWidget);
  });
}
