import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/panel/widgets/coach_panel_content.dart';
import 'package:vifutbol/presentation/teams/models/team_squad_roster.dart';

class _MockTeamsRepository extends Mock implements TeamsRepository {}

class _MockMatchesRepository extends Mock
    implements TournamentMatchesRepository {}

class _MockTournamentsRepository extends Mock implements TournamentsRepository {}

class _FakeAuthController extends StateNotifier<AuthFlowState>
    implements AuthController {
  _FakeAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMatchesCatalogController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  _FakeMatchesCatalogController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockTeamsRepository teamsRepo;
  late _MockMatchesRepository matchesRepo;
  late _MockTournamentsRepository tournamentsRepo;

  setUpAll(() {
    registerFallbackValue(
      TournamentTeam(id: 'fb', name: 'Fallback FC', shortCode: 'FBK'),
    );
  });

  setUp(() {
    teamsRepo = _MockTeamsRepository();
    matchesRepo = _MockMatchesRepository();
    tournamentsRepo = _MockTournamentsRepository();
    when(() => matchesRepo.loadAllMatches()).thenAnswer((_) async => []);
    when(() => matchesRepo.loadMatchesForTournament(any()))
        .thenAnswer((_) async => []);
    when(() => tournamentsRepo.loadTournaments()).thenAnswer((_) async => []);
    when(() => teamsRepo.deleteTeam(any())).thenAnswer((_) async {});
  });

  Widget buildHarness({
    required List<TournamentTeam> initialTeams,
    List<ChampionshipTournament> tournaments = const [],
    String coachId = 'coach-1',
    List<String>? pushedRoutes,
    List<Object?>? pushedArgs,
  }) {
    final mutableTeams = List<TournamentTeam>.from(initialTeams);
    when(() => teamsRepo.loadTeams()).thenAnswer((_) async => mutableTeams);
    when(() => tournamentsRepo.loadTournaments())
        .thenAnswer((_) async => tournaments);
    when(() => teamsRepo.deleteTeam(any())).thenAnswer((invocation) async {
      final id = invocation.positionalArguments[0] as String;
      mutableTeams.removeWhere((t) => t.id == id);
    });

    final useCase = ManageTeamsEligibilityUseCase(teamsRepo, matchesRepo);
    final controller = TeamsController(
      teamsRepository: teamsRepo,
      manageTeamsEligibilityUseCase: useCase,
    );
    controller.state = controller.state.copyWith(teams: mutableTeams);

    final tournCtrl = TournamentsController(
      tournamentsRepository: tournamentsRepo,
      manageTournamentsUseCase: ManageTournamentsUseCase(tournamentsRepo),
    );

    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _FakeAuthController(
            AuthFlowState(
              status: AuthStatus.authenticated,
              session: AuthSession(
                sessionId: 'sess-coach',
                user: UserAccount(
                  id: coachId,
                  fullName: 'Entrenador Uno',
                  email: 'coach1@vifutbol.com',
                  activeRole: UserRole.coach,
                  authorizedRoles: const {UserRole.coach},
                  isGuestFan: false,
                  onboardingCompleted: true,
                ),
                sessionToken: 'tok-coach',
                authenticatedAt: DateTime(2026),
              ),
            ),
          ),
        ),
        teamsControllerProvider.overrideWith((ref) => controller),
        tournamentsControllerProvider.overrideWith((ref) => tournCtrl),
        matchesCatalogControllerProvider.overrideWith(
          (ref) => _FakeMatchesCatalogController(const MatchesCatalogState()),
        ),
        teamSquadRosterProvider.overrideWith(
          (ref, teamId) => TeamSquadRoster.fromCatalog(
            teamId: teamId,
            teams: ref.watch(teamsControllerProvider).teams,
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        onGenerateRoute: (settings) {
          pushedRoutes?.add(settings.name ?? '');
          pushedArgs?.add(settings.arguments);
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('NextRoute')),
          );
        },
        home: const Scaffold(body: CoachPanelContent()),
      ),
    );
  }

  testWidgets(
    'lists only coach teams, switches active team reactively, and navigates to edit',
    (tester) async {
      final team1 = TournamentTeam(
        id: 't-1',
        coachId: 'coach-1',
        name: 'Leones FC',
        shortCode: 'LEO',
        players: const [
          RegisteredPlayer(
            id: 'p1',
            fullName: 'Jugador 1',
            documentId: '11111111',
            shirtNumber: 1,
            position: PlayerPosition.goalkeeper,
          ),
        ],
      );
      final team2 = TournamentTeam(
        id: 't-2',
        coachId: 'coach-1',
        name: 'Tigres FC',
        shortCode: 'TIG',
      );
      final otherTeam = TournamentTeam(
        id: 't-other',
        coachId: 'coach-999',
        name: 'Ajeno FC',
        shortCode: 'AJE',
      );

      final routes = <String>[];
      final args = <Object?>[];

      await tester.pumpWidget(
        buildHarness(
          initialTeams: [team1, team2, otherTeam],
          pushedRoutes: routes,
          pushedArgs: args,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('coach_team_card_t-1')), findsOneWidget);
      expect(find.byKey(const Key('coach_team_card_t-2')), findsOneWidget);
      expect(find.byKey(const Key('coach_team_card_t-other')), findsNothing);
      expect(
        find.byKey(const Key('coach_action_add_another_team')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('coach_team_card_t-2')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('coach_team_edit_t-2')));
      await tester.pumpAndSettle();

      expect(routes.last, '/teams/edit');
      expect(args.last, team2);
    },
  );

  testWidgets(
    'delete confirmation cancels safely and confirms deletion into empty state',
    (tester) async {
      final team1 = TournamentTeam(
        id: 't-del-1',
        coachId: 'coach-1',
        name: 'Borrar FC',
        shortCode: 'BOR',
      );

      await tester.pumpWidget(buildHarness(initialTeams: [team1]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('coach_team_delete_t-del-1')));
      await tester.pumpAndSettle();
      expect(find.text('Eliminar equipo'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('coach_delete_team_cancel_button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('coach_team_card_t-del-1')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('coach_team_delete_t-del-1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('coach_delete_team_confirm_button')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('coach_no_team_card')), findsOneWidget);
      verify(() => teamsRepo.deleteTeam('t-del-1')).called(1);
    },
  );
}
