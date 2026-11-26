import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/document_scanner_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/authenticate_user_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/domain/repositories/document_storage_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/infrastructure/storage/supabase_document_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/teams/create_team_screen.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAuthenticateUserUseCase extends Mock
    implements AuthenticateUserUseCase {}

class _MockTeamsRepository extends Mock implements TeamsRepository {}

class _MockTournamentsRepository extends Mock implements TournamentsRepository {}

class _MockDocumentStorageRepository extends Mock
    implements DocumentStorageRepository {}

class _TestAuthController extends AuthController {
  _TestAuthController({
    required super.authRepository,
    required UserAccount user,
  }) : super(authenticateUserUseCase: _MockAuthenticateUserUseCase()) {
    state = AuthFlowState(
      status: AuthStatus.authenticated,
      session: AuthSession(
        sessionId: 's-team-1',
        user: user,
        sessionToken: 'tok-team-1',
        authenticatedAt: DateTime(2026, 11, 26),
      ),
    );
  }
}

void main() {
  late _MockAuthRepository authRepository;
  late _MockTeamsRepository teamsRepository;
  late _MockTournamentsRepository tournamentsRepository;
  late _MockDocumentStorageRepository storageRepository;

  final oneByOnePng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  setUpAll(() {
    registerFallbackValue(
      TournamentTeam(id: 'fb', name: 'Fallback', shortCode: 'FB'),
    );
    registerFallbackValue(
      ChampionshipTournament(
        id: 't-fb',
        name: 'T FB',
        category: 'Libre',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        format: TournamentFormat.league,
        updatedAt: DateTime(2026, 11, 26),
      ),
    );
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    teamsRepository = _MockTeamsRepository();
    tournamentsRepository = _MockTournamentsRepository();
    storageRepository = _MockDocumentStorageRepository();

    when(() => teamsRepository.loadTeams()).thenAnswer((_) async => []);
    when(() => tournamentsRepository.loadTournaments())
        .thenAnswer((_) async => []);
  });

  Widget wrapScreen({
    required UserAccount user,
    TeamsController? teamsController,
    Future<String?> Function(ImageSource source)? crestPickerOverride,
  }) {
    final authCtrl = _TestAuthController(
      authRepository: authRepository,
      user: user,
    );
    final tCtrl = teamsController ??
        TeamsController(
          teamsRepository: teamsRepository,
          manageTeamsEligibilityUseCase:
              ManageTeamsEligibilityUseCase(teamsRepository),
        );
    final tournCtrl = TournamentsController(
      tournamentsRepository: tournamentsRepository,
      manageTournamentsUseCase:
          ManageTournamentsUseCase(tournamentsRepository),
    );

    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((_) => authCtrl),
        teamsControllerProvider.overrideWith((_) => tCtrl),
        tournamentsControllerProvider.overrideWith((_) => tournCtrl),
        documentStorageRepositoryProvider.overrideWithValue(storageRepository),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: CreateTeamScreen(crestPickerOverride: crestPickerOverride),
      ),
    );
  }

  UserAccount coachUser() => UserAccount(
        id: 'coach-1',
        fullName: 'Carlos DT',
        email: 'carlos@vifutbol.com',
        activeRole: UserRole.coach,
        authorizedRoles: {UserRole.coach},
        onboardingCompleted: true,
      );

  testWidgets(
    'renders full-screen form, auto-suggests short code, updates live preview colors, and blocks identical colors',
    (tester) async {
      await tester.pumpWidget(wrapScreen(user: coachUser()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create_team_screen')), findsOneWidget);
      expect(
        find.byKey(const Key('create_team_identity_preview')),
        findsOneWidget,
      );

      // Type team name -> shortCode auto-suggested
      await tester.enterText(
        find.byKey(const Key('create_team_name_input')),
        'Real Sabana',
      );
      await tester.pumpAndSettle();

      final crestBefore = tester.widget<KickPulseTeamCrest>(
        find.byType(KickPulseTeamCrest),
      );
      expect(crestBefore.shortCode, 'RS');
      expect(crestBefore.primaryColorHex, kTeamDistinctiveColorPalette[0]);
      expect(crestBefore.secondaryColorHex, kTeamDistinctiveColorPalette[1]);

      // Select a new primary color (Electric Blue)
      final blueHex = kTeamDistinctiveColorPalette[2];
      final primaryBlueSwatch = find.byKey(
        Key('create_team_primary_color_${blueHex.toRadixString(16)}'),
      );
      await tester.ensureVisible(primaryBlueSwatch);
      await tester.tap(primaryBlueSwatch);
      await tester.pumpAndSettle();

      final crestAfterPrimary = tester.widget<KickPulseTeamCrest>(
        find.byType(KickPulseTeamCrest),
      );
      expect(crestAfterPrimary.primaryColorHex, blueHex);

      // Attempt selecting same color as secondary -> blocked with SnackBar
      final secondaryBlueSwatch = find.byKey(
        Key('create_team_secondary_color_${blueHex.toRadixString(16)}'),
      );
      await tester.ensureVisible(secondaryBlueSwatch);
      await tester.tap(secondaryBlueSwatch);
      await tester.pumpAndSettle();

      expect(
        find.text('El color primario y el color secundario deben ser distintos'),
        findsOneWidget,
      );
      final crestStillValid = tester.widget<KickPulseTeamCrest>(
        find.byType(KickPulseTeamCrest),
      );
      expect(
        crestStillValid.secondaryColorHex,
        isNot(crestStillValid.primaryColorHex),
      );
    },
  );

  testWidgets(
    'blocks unauthorized roles with Spanish banner',
    (tester) async {
      final fanUser = UserAccount(
        id: 'fan-1',
        fullName: 'Aficionado',
        email: 'fan@vifutbol.com',
        activeRole: UserRole.fan,
        authorizedRoles: {UserRole.fan},
        onboardingCompleted: true,
      );

      await tester.pumpWidget(wrapScreen(user: fanUser));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('create_team_unauthorized_banner')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'blocks invalid/missing fields with Spanish validation messages',
    (tester) async {
      await tester.pumpWidget(wrapScreen(user: coachUser()));
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const Key('create_team_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('El nombre del equipo debe tener al menos 3 caracteres'),
        findsOneWidget,
      );
      expect(
        find.text('El nombre del delegado es obligatorio'),
        findsOneWidget,
      );
      expect(
        find.text('La fecha de creación es obligatoria'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'submits valid detailed team with single-flight protection and saves delegate, foundedDate, and colors',
    (tester) async {
      final saveCompleter = Completer<TournamentTeam>();
      when(() => teamsRepository.saveTeam(any()))
          .thenAnswer((_) => saveCompleter.future);

      await tester.pumpWidget(wrapScreen(user: coachUser()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('create_team_name_input')),
        'Estrella del Sur',
      );
      await tester.enterText(
        find.byKey(const Key('create_team_delegate_input')),
        'María Gómez',
      );

      // Pick founded date via DatePicker (tap OK immediately -> today's date)
      final dateField = find.byKey(const Key('create_team_founded_date_field'));
      await tester.ensureVisible(dateField);
      await tester.tap(dateField);
      await tester.pumpAndSettle();
      final okFinder = find.text('Aceptar');
      if (okFinder.evaluate().isNotEmpty) {
        await tester.tap(okFinder);
      } else {
        await tester.tap(find.byType(TextButton).last);
      }
      await tester.pumpAndSettle();

      // Double tap submit while pending (single-flight)
      final submitBtn = find.byKey(const Key('create_team_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.tap(submitBtn);
      await tester.pump();

      final captured = verify(() => teamsRepository.saveTeam(captureAny()))
          .captured
          .single as TournamentTeam;
      expect(captured.name, 'Estrella del Sur');
      expect(captured.shortCode, 'EDS');
      expect(captured.delegateName, 'María Gómez');
      expect(captured.foundedDate, isNotNull);
      expect(captured.primaryColorHex, isNot(captured.secondaryColorHex));

      saveCompleter.complete(captured);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'uploads, replaces, and removes circular team crest photo in live preview',
    (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('crest_picker_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });
      final img1 = File('${tempDir.path}/crest1.png')
        ..writeAsBytesSync(oneByOnePng);
      final img2 = File('${tempDir.path}/crest2.jpg')
        ..writeAsBytesSync(oneByOnePng);
      var pickIndex = 0;

      await tester.pumpWidget(
        wrapScreen(
          user: coachUser(),
          crestPickerOverride: (_) async {
            pickIndex++;
            return pickIndex == 1 ? img1.path : img2.path;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Initially fallback circular crest
      expect(
        find.byKey(const Key('kick_pulse_team_crest_fallback')),
        findsOneWidget,
      );

      // Upload crest from gallery
      await tester.tap(
        find.byKey(const Key('create_team_upload_crest_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('create_team_crest_source_gallery')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('kick_pulse_team_crest_photo')),
        findsOneWidget,
      );
      expect(find.text('Cambiar escudo'), findsOneWidget);
      expect(
        find.byKey(const Key('create_team_remove_crest_button')),
        findsOneWidget,
      );

      // Remove crest -> back to circular fallback
      await tester.tap(
        find.byKey(const Key('create_team_remove_crest_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('kick_pulse_team_crest_fallback')),
        findsOneWidget,
      );
      expect(find.text('Subir escudo'), findsOneWidget);
    },
  );

  testWidgets(
    'rejects > 5 MB or invalid format and handles denied permission without losing form inputs',
    (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('crest_invalid_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });
      final gifFile = File('${tempDir.path}/bad.gif')
        ..writeAsBytesSync([1, 2, 3]);
      final hugePng = File('${tempDir.path}/huge.png')
        ..writeAsBytesSync(
          List<int>.filled(
            SupabaseDocumentStorageRepository.maxTeamCrestBytes + 1,
            0,
          ),
        );
      var step = 0;

      await tester.pumpWidget(
        wrapScreen(
          user: coachUser(),
          crestPickerOverride: (_) async {
            step++;
            if (step == 1) return gifFile.path;
            if (step == 2) return hugePng.path;
            throw PlatformException(code: 'camera_access_denied');
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('create_team_name_input')),
        'Club Resiliente',
      );
      await tester.enterText(
        find.byKey(const Key('create_team_delegate_input')),
        'Ana Sofía',
      );

      // 1. Invalid format (.gif)
      await tester.tap(
        find.byKey(const Key('create_team_upload_crest_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('create_team_crest_source_gallery')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Formato no soportado. Usa una imagen JPG, PNG o WebP'),
        findsOneWidget,
      );

      // 2. Oversized (> 5 MB)
      await tester.tap(
        find.byKey(const Key('create_team_upload_crest_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('create_team_crest_source_gallery')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'La imagen del escudo supera el tamaño máximo permitido de 5 MB',
        ),
        findsOneWidget,
      );

      // 3. Denied permission
      await tester.tap(
        find.byKey(const Key('create_team_upload_crest_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('create_team_crest_source_camera')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('create_team_crest_error')),
        findsOneWidget,
      );

      // Form inputs remain intact
      expect(find.text('Club Resiliente'), findsWidgets);
      expect(find.text('Ana Sofía'), findsOneWidget);
    },
  );

  testWidgets(
    'preserves local crest path offline-first when cloud upload fails temporarily',
    (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('crest_offline_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });
      final imgFile = File('${tempDir.path}/crest.png')
        ..writeAsBytesSync(oneByOnePng);

      when(
        () => storageRepository.uploadTeamCrest(
          userId: any(named: 'userId'),
          teamId: any(named: 'teamId'),
          localPath: imgFile.path,
          existingCrestUrl: any(named: 'existingCrestUrl'),
        ),
      ).thenThrow(const OfflineAuthOperationFailure());

      when(() => teamsRepository.saveTeam(any())).thenAnswer(
        (inv) async => inv.positionalArguments.first as TournamentTeam,
      );

      await tester.pumpWidget(
        wrapScreen(
          user: coachUser(),
          crestPickerOverride: (_) async => imgFile.path,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('create_team_upload_crest_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('create_team_crest_source_gallery')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('create_team_name_input')),
        'Club Offline',
      );
      await tester.enterText(
        find.byKey(const Key('create_team_delegate_input')),
        'Pedro Offline',
      );

      final dateField = find.byKey(const Key('create_team_founded_date_field'));
      await tester.ensureVisible(dateField);
      await tester.tap(dateField);
      await tester.pumpAndSettle();
      final okFinder = find.text('Aceptar');
      if (okFinder.evaluate().isNotEmpty) {
        await tester.tap(okFinder);
      } else {
        await tester.tap(find.byType(TextButton).last);
      }
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const Key('create_team_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      final saved = verify(() => teamsRepository.saveTeam(captureAny()))
          .captured
          .single as TournamentTeam;
      expect(saved.crestUrl, imgFile.path);
    },
  );
}
