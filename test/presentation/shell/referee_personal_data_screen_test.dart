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
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/domain/repositories/document_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/shell/tabs/referee_personal_data_screen.dart';
import 'package:vifutbol/presentation/shell/widgets/id_document_capture_card.dart';

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

  setUpAll(() {
    registerFallbackValue(UserRole.referee);
    registerFallbackValue(const RoleProfileData());
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    storageRepository = _MockDocumentStorageRepository();
    when(
      () => storageRepository.getSignedDocumentUrl(
        storagePath: any(named: 'storagePath'),
        expiresInSeconds: any(named: 'expiresInSeconds'),
      ),
    ).thenAnswer((_) async => null);
  });

  Widget wrapScreen({
    required _TestAuthController controller,
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
          home: const RefereePersonalDataScreen(),
        ),
      ),
    );
  }

  testWidgets(
    'renders ID capture card, identity, location, certification section, and blocks save when documents are missing',
    (tester) async {
      final incompleteReferee = UserAccount(
        id: 'ref-1',
        fullName: 'Carlos Árbitro',
        email: 'ref@vifutbol.com',
        activeRole: UserRole.referee,
        authorizedRoles: {UserRole.referee},
        onboardingCompleted: true,
      );
      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-ref-1',
            user: incompleteReferee,
            sessionToken: 'tok-ref-1',
            authenticatedAt: DateTime(2026, 11, 25),
          ),
        ),
      );

      await tester.pumpWidget(wrapScreen(controller: controller));
      await tester.pumpAndSettle();

      expect(find.byType(IdDocumentCaptureCard), findsOneWidget);
      expect(find.text('Certificación Arbitral'), findsOneWidget);
      expect(
        find.byKey(const Key('referee_certification_level_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('referee_certification_capture_button')),
        findsOneWidget,
      );

      final saveBtn = find.byKey(const Key('referee_save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Debes adjuntar la imagen de tu documento de certificación arbitral.'),
        findsOneWidget,
      );
      verifyNever(
        () => authRepository.updateRoleProfile(
          userId: any(named: 'userId'),
          role: any(named: 'role'),
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          documentId: any(named: 'documentId'),
          roleProfile: any(named: 'roleProfile'),
        ),
      );
    },
  );

  testWidgets(
    'saves pre-hydrated referee profile with single-flight lock and persists certificationDocumentUrl',
    (tester) async {
      final completeReferee = UserAccount(
        id: 'ref-2',
        fullName: 'Ana Arbitraje',
        email: 'ana@vifutbol.com',
        activeRole: UserRole.referee,
        authorizedRoles: {UserRole.referee},
        onboardingCompleted: true,
        phone: '3101234567',
        documentId: '10203040',
        roleProfile: RoleProfileData(
          firstName: 'Ana',
          firstSurname: 'Arbitraje',
          sex: 'female',
          birthDate: DateTime(1994, 8, 10),
          bloodType: 'O+',
          department: 'Antioquia',
          municipality: 'Medellín',
          certificationLevel: 'Nacional',
          documentFrontUrl: 'ref-2/document_front.jpg',
          documentBackUrl: 'ref-2/document_back.jpg',
          certificationDocumentUrl: 'ref-2/referee_certification.jpg',
        ),
      );

      when(
        () => storageRepository.uploadPlayerIdDocuments(
          userId: 'ref-2',
          frontLocalPath: any(named: 'frontLocalPath'),
          backLocalPath: any(named: 'backLocalPath'),
          existingFrontUrl: 'ref-2/document_front.jpg',
          existingBackUrl: 'ref-2/document_back.jpg',
        ),
      ).thenAnswer(
        (_) async => (
          frontUrl: 'ref-2/document_front.jpg',
          backUrl: 'ref-2/document_back.jpg',
        ),
      );

      when(
        () => authRepository.updateRoleProfile(
          userId: 'ref-2',
          role: UserRole.referee,
          fullName: any(named: 'fullName'),
          phone: '3101234567',
          documentId: '10203040',
          roleProfile: any(named: 'roleProfile'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 60));
        return completeReferee;
      });

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-ref-2',
            user: completeReferee,
            sessionToken: 'tok-ref-2',
            authenticatedAt: DateTime(2026, 11, 25),
          ),
        ),
      );

      await tester.pumpWidget(
        wrapScreen(controller: controller, textScale: 1.5),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Documento adjunto'), findsOneWidget);
      expect(find.text('Reemplazar documento'), findsOneWidget);

      final saveBtn = find.byKey(const Key('referee_save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.tap(saveBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      verify(
        () => authRepository.updateRoleProfile(
          userId: 'ref-2',
          role: UserRole.referee,
          fullName: 'Ana Arbitraje',
          phone: '3101234567',
          documentId: '10203040',
          roleProfile: any(
            named: 'roleProfile',
            that: isA<RoleProfileData>().having(
              (p) => p.certificationDocumentUrl,
              'certificationDocumentUrl',
              'ref-2/referee_certification.jpg',
            ),
          ),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'retains entered fields and shows Spanish error banner when save fails',
    (tester) async {
      final completeReferee = UserAccount(
        id: 'ref-3',
        fullName: 'Luis Juez',
        email: 'luis@vifutbol.com',
        activeRole: UserRole.referee,
        authorizedRoles: {UserRole.referee},
        onboardingCompleted: true,
        phone: '3109876543',
        documentId: '55443322',
        roleProfile: RoleProfileData(
          firstName: 'Luis',
          firstSurname: 'Juez',
          sex: 'male',
          birthDate: DateTime(1992, 3, 20),
          bloodType: 'B+',
          department: 'Cundinamarca',
          municipality: 'Bogotá',
          certificationLevel: 'FIFA',
          documentFrontUrl: 'ref-3/document_front.jpg',
          documentBackUrl: 'ref-3/document_back.jpg',
          certificationDocumentUrl: 'ref-3/referee_certification.jpg',
        ),
      );

      when(
        () => storageRepository.uploadPlayerIdDocuments(
          userId: 'ref-3',
          frontLocalPath: any(named: 'frontLocalPath'),
          backLocalPath: any(named: 'backLocalPath'),
          existingFrontUrl: 'ref-3/document_front.jpg',
          existingBackUrl: 'ref-3/document_back.jpg',
        ),
      ).thenThrow(
        const OfflineAuthOperationFailure(
          'Se requiere conexión a internet para subir los documentos de identidad.',
        ),
      );

      final controller = _TestAuthController(
        authRepository: authRepository,
        initialState: AuthFlowState(
          status: AuthStatus.authenticated,
          session: AuthSession(
            sessionId: 's-ref-3',
            user: completeReferee,
            sessionToken: 'tok-ref-3',
            authenticatedAt: DateTime(2026, 11, 25),
          ),
        ),
      );

      await tester.pumpWidget(wrapScreen(controller: controller));
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('referee_save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('referee_personal_data_error_banner')),
        findsOneWidget,
      );
      expect(
        find.text(
          'No hay conexión a internet. Los datos no se pudieron sincronizar.',
        ),
        findsOneWidget,
      );
      expect(find.text('FIFA'), findsOneWidget);
      expect(find.text('55443322'), findsOneWidget);
    },
  );
}
