import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
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
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/teams/create_team_screen.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAuthenticateUserUseCase extends Mock
    implements AuthenticateUserUseCase {}

class _MockTeamsRepository extends Mock implements TeamsRepository {}

class _MockTournamentsRepository extends Mock implements TournamentsRepository {}

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

    when(() => teamsRepository.loadTeams()).thenAnswer((_) async => []);
    when(() => tournamentsRepository.loadTournaments())
        .thenAnswer((_) async => []);
  });

  Widget wrapScreen({
    required UserAccount user,
    TeamsController? teamsController,
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
      ],
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: CreateTeamScreen(),
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
}
