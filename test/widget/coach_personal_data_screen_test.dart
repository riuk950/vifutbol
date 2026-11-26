import 'dart:async';
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
import 'package:vifutbol/domain/entities/colombian_id_scan_result.dart';
import 'package:vifutbol/domain/entities/player_personal_enums.dart';
import 'package:vifutbol/domain/entities/role_profile_data.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/domain/repositories/colombian_id_scanner_service.dart';
import 'package:vifutbol/domain/repositories/document_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/shell/tabs/coach_personal_data_screen.dart';
import 'package:vifutbol/presentation/shell/widgets/id_document_capture_card.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAuthenticateUserUseCase extends Mock
    implements AuthenticateUserUseCase {}

class _MockDocumentStorageRepository extends Mock
    implements DocumentStorageRepository {}

class _MockColombianIdScannerService extends Mock
    implements ColombianIdScannerService {}

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
  late _MockColombianIdScannerService scannerService;

  final oneByOnePng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  setUpAll(() {
    registerFallbackValue(UserRole.coach);
    registerFallbackValue(const RoleProfileData());
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    storageRepository = _MockDocumentStorageRepository();
    scannerService = _MockColombianIdScannerService();

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
        colombianIdScannerServiceProvider.overrideWithValue(scannerService),
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
          home: const CoachPersonalDataScreen(),
        ),
      ),
    );
  }

  _TestAuthController buildController(UserAccount user) {
    return _TestAuthController(
      authRepository: authRepository,
      initialState: AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 's-coach-1',
          user: user,
          sessionToken: 'tok-coach-1',
          authenticatedAt: DateTime(2026, 11, 26),
        ),
      ),
    );
  }

  testWidgets(
    'renders ID capture card, technical section, pre-fills partial coach profile, and blocks missing photos/fields',
    (tester) async {
      final partialCoach = UserAccount(
        id: 'coach-1',
        fullName: 'Pedro DT',
        email: 'pedro@vifutbol.com',
        activeRole: UserRole.coach,
        authorizedRoles: {UserRole.coach},
        onboardingCompleted: true,
        phone: '3001112233',
        roleProfile: const RoleProfileData(
          clubName: 'Club Deportivo Norte',
          licenseLevel: 'Licencia B',
        ),
      );

      await tester.pumpWidget(
        wrapScreen(controller: buildController(partialCoach)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IdDocumentCaptureCard), findsOneWidget);
      expect(find.text('Acreditación Técnica'), findsOneWidget);
      expect(find.text('Club Deportivo Norte'), findsOneWidget);
      expect(find.text('Licencia B'), findsOneWidget);

      final saveBtn = find.byKey(const Key('coach_save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Debes capturar ambas caras de tu cédula (frente y reverso) para continuar',
        ),
        findsOneWidget,
      );
      expect(
        find.text('El número de documento es obligatorio'),
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
    'rejects under-18 birth date with clear Spanish validation message',
    (tester) async {
      final now = DateTime.now();
      final minorCoach = UserAccount(
        id: 'coach-minor',
        fullName: 'Joven DT',
        email: 'joven@vifutbol.com',
        activeRole: UserRole.coach,
        authorizedRoles: {UserRole.coach},
        onboardingCompleted: true,
        phone: '3001112233',
        documentId: '1020304050',
        roleProfile: RoleProfileData(
          firstName: 'Joven',
          firstSurname: 'DT',
          sex: 'M',
          birthDate: DateTime(now.year - 16, 1, 15),
          bloodType: 'O+',
          department: 'Antioquia',
          municipality: 'Medellín',
          clubName: 'Independiente',
          licenseLevel: 'Sin licencia',
          documentFrontUrl: 'coach/front.jpg',
          documentBackUrl: 'coach/back.jpg',
        ),
      );

      await tester.pumpWidget(
        wrapScreen(controller: buildController(minorCoach)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Debes ser mayor de edad (mínimo 18 años)'),
        findsOneWidget,
      );

      final saveBtn = find.byKey(const Key('coach_save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

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
    'dual scan autocompletes fields, uploads both ID sides privately, enforces single-flight, and saves Independiente / Sin licencia',
    (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('coach_form_test_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });
      final frontFile = File('${tempDir.path}/front.png')
        ..writeAsBytesSync(oneByOnePng);
      final backFile = File('${tempDir.path}/back.png')
        ..writeAsBytesSync(oneByOnePng);

      when(() => scannerService.captureDocumentPhoto(isFront: true))
          .thenAnswer((_) async => frontFile.path);
      when(() => scannerService.captureDocumentPhoto(isFront: false))
          .thenAnswer((_) async => backFile.path);
      when(
        () => scannerService.scanDocumentImages(
          frontImagePath: frontFile.path,
          backImagePath: backFile.path,
        ),
      ).thenAnswer(
        (_) async => ColombianIdScanResult(
          documentId: '1020304050',
          firstName: 'Carlos',
          secondName: 'Andrés',
          firstSurname: 'Martínez',
          secondSurname: 'Gómez',
          sex: PlayerSex.male,
          birthDate: DateTime(1988, 4, 12),
          bloodType: BloodType.oPositive,
        ),
      );

      final uploadCompleter = Completer<({String frontUrl, String backUrl})>();
      when(
        () => storageRepository.uploadPlayerIdDocuments(
          userId: 'coach-2',
          frontLocalPath: frontFile.path,
          backLocalPath: backFile.path,
          existingFrontUrl: null,
          existingBackUrl: null,
        ),
      ).thenAnswer((_) => uploadCompleter.future);

      final coach = UserAccount(
        id: 'coach-2',
        fullName: 'Carlos',
        email: 'carlos@vifutbol.com',
        activeRole: UserRole.coach,
        authorizedRoles: {UserRole.coach},
        onboardingCompleted: true,
        phone: '3004445566',
        roleProfile: const RoleProfileData(
          department: 'Antioquia',
          municipality: 'Medellín',
          clubName: 'Independiente',
          licenseLevel: 'Sin licencia',
        ),
      );

      when(
        () => authRepository.updateRoleProfile(
          userId: 'coach-2',
          role: UserRole.coach,
          fullName: 'Carlos Andrés Martínez Gómez',
          phone: '3004445566',
          documentId: '1020304050',
          roleProfile: any(named: 'roleProfile'),
        ),
      ).thenAnswer(
        (_) async => coach.copyWith(
          fullName: 'Carlos Andrés Martínez Gómez',
          documentId: '1020304050',
          roleProfile: RoleProfileData(
            firstName: 'Carlos',
            secondName: 'Andrés',
            firstSurname: 'Martínez',
            secondSurname: 'Gómez',
            sex: 'M',
            birthDate: DateTime(1988, 4, 12),
            bloodType: 'O+',
            department: 'Antioquia',
            municipality: 'Medellín',
            clubName: 'Independiente',
            licenseLevel: 'Sin licencia',
            documentFrontUrl: 'coach-2/front.png',
            documentBackUrl: 'coach-2/back.png',
          ),
        ),
      );

      await tester.pumpWidget(
        wrapScreen(controller: buildController(coach)),
      );
      await tester.pumpAndSettle();

      // Trigger dual scan
      await tester.tap(find.byKey(const Key('player_form_scan_id_button')));
      await tester.pumpAndSettle();

      expect(find.text('1020304050'), findsOneWidget);
      expect(find.text('Carlos'), findsOneWidget);
      expect(find.text('Martínez'), findsOneWidget);

      // Tap Save twice while upload is pending (single-flight)
      final saveBtn = find.byKey(const Key('coach_save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.tap(saveBtn);
      await tester.pump();

      verify(
        () => storageRepository.uploadPlayerIdDocuments(
          userId: 'coach-2',
          frontLocalPath: frontFile.path,
          backLocalPath: backFile.path,
          existingFrontUrl: null,
          existingBackUrl: null,
        ),
      ).called(1);

      uploadCompleter.complete((
        frontUrl: 'coach-2/front.png',
        backUrl: 'coach-2/back.png',
      ));
      await tester.pumpAndSettle();

      verify(
        () => authRepository.updateRoleProfile(
          userId: 'coach-2',
          role: UserRole.coach,
          fullName: 'Carlos Andrés Martínez Gómez',
          phone: '3004445566',
          documentId: '1020304050',
          roleProfile: any(named: 'roleProfile'),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'preserves inputs and shows offline error banner when upload fails offline',
    (tester) async {
      final completeEditCoach = UserAccount(
        id: 'coach-3',
        fullName: 'Laura DT',
        email: 'laura@vifutbol.com',
        activeRole: UserRole.coach,
        authorizedRoles: {UserRole.coach},
        onboardingCompleted: true,
        phone: '3007778899',
        documentId: '1099887766',
        roleProfile: RoleProfileData(
          firstName: 'Laura',
          firstSurname: 'Ríos',
          sex: 'F',
          birthDate: DateTime(1992, 3, 20),
          bloodType: 'A+',
          department: 'Cundinamarca',
          municipality: 'Chía',
          clubName: 'Independiente',
          licenseLevel: 'Licencia C',
          documentFrontUrl: 'coach-3/front.png',
          documentBackUrl: 'coach-3/back.png',
        ),
      );

      when(
        () => storageRepository.uploadPlayerIdDocuments(
          userId: 'coach-3',
          frontLocalPath: null,
          backLocalPath: null,
          existingFrontUrl: 'coach-3/front.png',
          existingBackUrl: 'coach-3/back.png',
        ),
      ).thenThrow(const OfflineAuthOperationFailure());

      await tester.pumpWidget(
        wrapScreen(controller: buildController(completeEditCoach)),
      );
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('coach_save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('coach_personal_data_error_banner')),
        findsOneWidget,
      );
      expect(find.text('Laura'), findsOneWidget);
      expect(find.text('1099887766'), findsOneWidget);
    },
  );
}
