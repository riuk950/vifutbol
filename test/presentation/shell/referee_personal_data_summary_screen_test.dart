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
import 'package:vifutbol/presentation/shell/tabs/referee_personal_data_summary_screen.dart';

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

  Widget wrapScreen({
    required _TestAuthController controller,
    Map<String, WidgetBuilder> routes = const {},
    double textScale = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((_) => controller),
        documentStorageRepositoryProvider.overrideWithValue(storageRepository),
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routes: routes,
          home: const RefereePersonalDataSummaryScreen(),
        ),
      ),
    );
  }

  testWidgets(
    'renders referee avatar, demographics, certification, 3 document previews, zoom dialog, and Editar navigation',
    (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('ref_sum_test_');
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

      final referee = UserAccount(
        id: 'ref-sum-1',
        fullName: 'Sofía Mendoza',
        email: 'sofia@vifutbol.com',
        activeRole: UserRole.referee,
        authorizedRoles: {UserRole.referee},
        onboardingCompleted: true,
        phone: '3001112233',
        documentId: '10102020',
        roleProfile: RoleProfileData(
          firstName: 'Sofía',
          firstSurname: 'Mendoza',
          sex: 'female',
          birthDate: DateTime(1995, 6, 20),
          bloodType: 'O+',
          department: 'Antioquia',
          municipality: 'Medellín',
          certificationLevel: 'FIFA',
          documentFrontUrl: 'ref-sum-1/document_front.jpg',
          documentBackUrl: 'ref-sum-1/document_back.jpg',
          certificationDocumentUrl: 'ref-sum-1/referee_certification.jpg',
          photoUrl: docFile.path,
        ),
      );

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-ref-sum-1',
            user: referee,
            sessionToken: 'tok-ref-sum-1',
            authenticatedAt: DateTime(2026, 11, 25),
          ),
        ),
      );

      await tester.pumpWidget(
        wrapScreen(
          controller: controller,
          textScale: 1.4,
          routes: {
            '/profile/referee-personal-data': (_) => const Scaffold(
                  body: Text('Referee Edit Form'),
                ),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('referee_summary_header_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('referee_summary_avatar')),
        findsOneWidget,
      );
      expect(find.text('Sofía Mendoza'), findsOneWidget);
      expect(find.text('CC: 10102020'), findsOneWidget);
      expect(find.text('3001112233'), findsOneWidget);
      expect(find.text('Antioquia'), findsOneWidget);
      expect(find.text('Medellín'), findsOneWidget);
      expect(find.text('FIFA'), findsOneWidget);

      expect(
        find.byKey(const ValueKey('referee_summary_certification_doc_preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('referee_summary_doc_front_preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('referee_summary_doc_back_preview')),
        findsOneWidget,
      );

      // Tap certification doc preview to open zoom dialog
      final certPreview = find.byKey(
        const ValueKey('referee_summary_certification_doc_preview'),
      );
      await tester.ensureVisible(certPreview);
      await tester.tap(certPreview);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('referee_summary_viewer_close_button')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('referee_summary_viewer_close_button')),
      );
      await tester.pumpAndSettle();

      // Tap Editar in AppBar
      await tester.tap(
        find.byKey(const ValueKey('referee_summary_edit_action')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Referee Edit Form'), findsOneWidget);
    },
  );

  testWidgets(
    'shows fallback icon and placeholder when avatar and document previews fail offline',
    (tester) async {
      when(
        () => storageRepository.getSignedDocumentUrl(
          storagePath: any(named: 'storagePath'),
          expiresInSeconds: any(named: 'expiresInSeconds'),
        ),
      ).thenThrow(Exception('offline'));

      final referee = UserAccount(
        id: 'ref-sum-off',
        fullName: 'Jorge Árbitro',
        email: 'jorge@vifutbol.com',
        activeRole: UserRole.referee,
        authorizedRoles: {UserRole.referee},
        onboardingCompleted: true,
        phone: '3009998877',
        documentId: '44556677',
        roleProfile: RoleProfileData(
          firstName: 'Jorge',
          firstSurname: 'Árbitro',
          sex: 'male',
          birthDate: DateTime(1988, 2, 10),
          bloodType: 'A+',
          department: 'Valle del Cauca',
          municipality: 'Cali',
          certificationLevel: 'Nacional',
          documentFrontUrl: 'ref-sum-off/document_front.jpg',
          documentBackUrl: 'ref-sum-off/document_back.jpg',
          certificationDocumentUrl: 'ref-sum-off/referee_certification.jpg',
        ),
      );

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-ref-sum-off',
            user: referee,
            sessionToken: 'tok-ref-sum-off',
            authenticatedAt: DateTime(2026, 11, 25),
          ),
        ),
      );

      await tester.pumpWidget(wrapScreen(controller: controller));
      await tester.pumpAndSettle();

      final avatar = tester.widget<CircleAvatar>(
        find.byKey(const ValueKey('referee_summary_avatar')),
      );
      expect(avatar.backgroundImage, isNull);
      expect(avatar.child, isNotNull);
      expect(find.text('Vista previa no disponible'), findsNWidgets(3));
      expect(
        find.byKey(const ValueKey('referee_summary_edit_action')),
        findsOneWidget,
      );
    },
  );
}
