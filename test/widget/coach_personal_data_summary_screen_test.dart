import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/document_scanner_providers.dart';
import 'package:vifutbol/application/use_cases/authenticate_user_use_case.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/role_profile_data.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/domain/repositories/document_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/shell/tabs/coach_personal_data_summary_screen.dart';
import 'package:vifutbol/presentation/shell/tabs/profile_tab_view.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAuthenticateUserUseCase extends Mock
    implements AuthenticateUserUseCase {}

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
  late _MockDocumentStorageRepository storageRepository;

  final oneByOnePng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  setUp(() {
    authRepository = _MockAuthRepository();
    storageRepository = _MockDocumentStorageRepository();
  });

  _TestAuthController buildController(UserAccount user) {
    return _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's-coach-sum-1',
          user: user,
          sessionToken: 'tok-coach-sum-1',
          authenticatedAt: DateTime(2026, 11, 26),
        ),
      ),
    );
  }

  Widget wrapSummary({
    required _TestAuthController controller,
    Map<String, WidgetBuilder> routes = const {},
  }) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((_) => controller),
        documentStorageRepositoryProvider.overrideWithValue(storageRepository),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routes: routes,
        home: const CoachPersonalDataSummaryScreen(),
      ),
    );
  }

  Widget wrapProfileTab({
    required _TestAuthController controller,
    Map<String, WidgetBuilder> routes = const {},
  }) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((_) => controller),
        documentStorageRepositoryProvider.overrideWithValue(storageRepository),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routes: routes,
        home: const Scaffold(body: ProfileTabView()),
      ),
    );
  }

  testWidgets(
    'renders coach summary cards, inline signed thumbnails, zoom viewer, and Edit navigation',
    (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('coach_sum_test_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });
      final docFile = File('${tempDir.path}/doc.png')
        ..writeAsBytesSync(oneByOnePng);

      when(
        () => storageRepository.getSignedDocumentUrl(
          storagePath: any(named: 'storagePath'),
          expiresInSeconds: any(named: 'expiresInSeconds'),
        ),
      ).thenAnswer((_) async => docFile.path);

      final coach = UserAccount(
        id: 'coach-sum-1',
        fullName: 'Carlos Martínez',
        email: 'carlos@vifutbol.com',
        activeRole: UserRole.coach,
        authorizedRoles: {UserRole.coach},
        onboardingCompleted: true,
        phone: '3001112233',
        documentId: '1020304050',
        roleProfile: RoleProfileData(
          firstName: 'Carlos',
          firstSurname: 'Martínez',
          sex: 'male',
          birthDate: DateTime(1990, 6, 20),
          bloodType: 'O+',
          department: 'Antioquia',
          municipality: 'Medellín',
          clubName: 'Independiente',
          licenseLevel: 'Sin licencia',
          documentFrontUrl: 'coach/front.png',
          documentBackUrl: 'coach/back.png',
        ),
      );

      var navigatedToEdit = false;
      await tester.pumpWidget(
        wrapSummary(
          controller: buildController(coach),
          routes: {
            '/profile/coach-personal-data': (_) {
              navigatedToEdit = true;
              return const Scaffold(body: Text('Editar Entrenador'));
            },
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('coach_summary_header_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('coach_summary_demographics_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('coach_summary_technical_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('coach_summary_documentation_card')),
        findsOneWidget,
      );

      expect(find.text('Carlos Martínez'), findsOneWidget);
      expect(find.text('CC: 1020304050'), findsOneWidget);
      expect(find.text('Independiente'), findsOneWidget);
      expect(find.text('Sin licencia'), findsOneWidget);

      // Tap front thumbnail to open zoom viewer
      final frontThumb = find.byKey(
        const ValueKey('coach_summary_doc_front_preview'),
      );
      await tester.ensureVisible(frontThumb);
      await tester.tap(frontThumb);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('coach_summary_viewer_close_button')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('coach_summary_viewer_close_button')),
      );
      await tester.pumpAndSettle();

      // Tap Edit button
      await tester.tap(
        find.byKey(const ValueKey('coach_summary_edit_action')),
      );
      await tester.pumpAndSettle();
      expect(navigatedToEdit, isTrue);
    },
  );

  testWidgets(
    'ProfileTabView routes incomplete coach to form',
    (tester) async {
      final incompleteCoach = UserAccount(
        id: 'coach-inc',
        fullName: 'DT Incompleto',
        email: 'inc@vifutbol.com',
        activeRole: UserRole.coach,
        authorizedRoles: {UserRole.coach},
        onboardingCompleted: true,
      );

      var routedToForm = false;
      await tester.pumpWidget(
        wrapProfileTab(
          controller: buildController(incompleteCoach),
          routes: {
            '/profile/coach-personal-data': (_) {
              routedToForm = true;
              return const Scaffold(body: Text('Formulario Entrenador'));
            },
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Datos incompletos'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('profile_complete_action_button')),
      );
      await tester.pumpAndSettle();
      expect(routedToForm, isTrue);
    },
  );

  testWidgets(
    'ProfileTabView routes complete coach to summary',
    (tester) async {
      final completeCoach = UserAccount(
        id: 'coach-comp',
        fullName: 'DT Completo',
        email: 'comp@vifutbol.com',
        activeRole: UserRole.coach,
        authorizedRoles: {UserRole.coach},
        onboardingCompleted: true,
        phone: '3001112233',
        documentId: '1020304050',
        roleProfile: RoleProfileData(
          firstName: 'DT',
          firstSurname: 'Completo',
          sex: 'M',
          birthDate: DateTime(1985, 2, 10),
          bloodType: 'O+',
          department: 'Antioquia',
          municipality: 'Medellín',
          clubName: 'Independiente',
          licenseLevel: 'Licencia A',
          documentFrontUrl: 'coach/front.png',
          documentBackUrl: 'coach/back.png',
        ),
      );

      var routedToSummary = false;
      await tester.pumpWidget(
        wrapProfileTab(
          controller: buildController(completeCoach),
          routes: {
            '/profile/coach-personal-data/summary': (_) {
              routedToSummary = true;
              return const Scaffold(body: Text('Resumen Entrenador'));
            },
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perfil completo'), findsOneWidget);
      final tile = find.byKey(const Key('profile_coach_personal_data_tile'));
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(routedToSummary, isTrue);
    },
  );
}
