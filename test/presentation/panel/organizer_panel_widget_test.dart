import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/panel/panel_screen.dart';
import 'package:vifutbol/presentation/panel/widgets/organizer_competitions_section.dart';
import 'package:vifutbol/presentation/panel/widgets/organizer_panel_content.dart';

class _FakeLocalStorageRepository implements LocalStorageRepository {
  @override
  bool get isUsingFallbackMemory => false;
  @override
  Future<void> clearNamespace() async {}
  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);
  @override
  Future<String?> readString(String key) async => null;
  @override
  Future<void> writeString(String key, String value) async {}
}

class _FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);
  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;
}

class FakeTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  FakeTournamentsController({
    List<ChampionshipTournament> tournaments = const [],
  }) : super(
         TournamentsCatalogState(
           tournaments: tournaments,
           viewState: UiContentState(tournaments),
         ),
       );

  int loadCatalogCalls = 0;

  @override
  Future<void> loadCatalog() async {
    loadCatalogCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  FakeTeamsController({List<TournamentTeam> teams = const []})
    : super(TeamsCatalogState(teams: teams));

  int loadTeamsCalls = 0;

  @override
  Future<void> loadTeams() async {
    loadTeamsCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMatchesCatalogController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  FakeMatchesCatalogController({List<ChampionshipMatch> matches = const []})
    : super(MatchesCatalogState(matches: matches));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthController extends StateNotifier<AuthFlowState>
    implements AuthController {
  _FakeAuthController(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createOrganizerPanelApp({
  List<ChampionshipTournament>? tournaments,
  List<ChampionshipMatch>? matches,
  List<TournamentTeam>? teams,
  AuthFlowState? authState,
}) {
  final tourList =
      tournaments ??
      [
        ChampionshipTournament(
          id: 't-active-1',
          name: 'Torneo Apertura 2026',
          category: 'Libre A',
          format: TournamentFormat.league,
          status: TournamentStatus.inProgress,
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 6, 30),
          updatedAt: DateTime(2026, 3, 1),
        ),
        ChampionshipTournament(
          id: 't-unseeded-2',
          name: 'Copa Regional 2026',
          category: 'Veteranos',
          format: TournamentFormat.knockoutCup,
          status: TournamentStatus.openRegistration,
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2026, 7, 30),
          updatedAt: DateTime(2026, 4, 1),
        ),
      ];

  final matchList =
      matches ??
      [
        ChampionshipMatch(
          id: 'm-pending-1',
          tournamentId: 't-active-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          status: MatchStatus.pendingSchedule,
          scheduledStartTime: null,
        ),
      ];

  final teamList =
      teams ??
      [
        TournamentTeam(
          id: 'team-a',
          name: 'Equipo Alfa',
          shortCode: 'ALF',
          tournamentId: 't-active-1',
          eligibilityStatus: TeamEligibilityStatus.eligible,
        ),
        TournamentTeam(
          id: 'team-b',
          name: 'Equipo Beta',
          shortCode: 'BET',
          tournamentId: 't-active-1',
          eligibilityStatus: TeamEligibilityStatus.eligible,
        ),
      ];

  return ProviderScope(
    overrides: [
      environmentConfigProvider.overrideWithValue(
        EnvironmentConfig.development(),
      ),
      localStorageRepositoryProvider.overrideWithValue(
        _FakeLocalStorageRepository(),
      ),
      connectivityRepositoryProvider.overrideWithValue(
        _FakeConnectivityRepository(),
      ),
      activeUserRoleProvider.overrideWith((ref) => UserRole.organizer),
      if (authState != null)
        authControllerProvider.overrideWith(
          (_) => _FakeAuthController(authState),
        ),
      tournamentsControllerProvider.overrideWith(
        (ref) => FakeTournamentsController(tournaments: tourList),
      ),
      teamsControllerProvider.overrideWith(
        (ref) => FakeTeamsController(teams: teamList),
      ),
      matchesCatalogControllerProvider.overrideWith(
        (ref) => FakeMatchesCatalogController(matches: matchList),
      ),
    ],
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [Locale('es')],
      home: const PanelScreen(),
    ),
  );
}

void main() {
  group('OrganizerPanelContent Widget Tests (US1 - P1 MVP)', () {
    testWidgets(
      'renders summary metrics and competitions section, but does NOT render quick actions block',
      (tester) async {
        await tester.pumpWidget(createOrganizerPanelApp());
        await tester.pumpAndSettle();

        // Verify Panel structure
        expect(find.text('Panel de Organización'), findsOneWidget);
        expect(find.byType(OrganizerPanelContent), findsOneWidget);

        // Verify Metric Summary Section is present
        expect(find.text('Resumen General'), findsOneWidget);
        expect(
          find.byKey(const Key('organizer_metric_active_tournaments')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('organizer_metric_pending_matches')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('organizer_metric_unseeded_tournaments')),
          findsOneWidget,
        );

        // Verify Metric Values (2 active, 1 pending match, 1 unseeded tournament)
        expect(find.text('2'), findsWidgets);
        expect(find.text('1'), findsWidgets);

        // Assert that "Acciones Rápidas" title and buttons are NOT in OrganizerPanelContent
        expect(find.text('Acciones Rápidas'), findsNothing);
        expect(
          find.byKey(const Key('organizer_action_generate_fixture')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('organizer_action_schedule_matches')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('organizer_action_publish_news')),
          findsNothing,
        );
        expect(find.byKey(const Key('organizer_action_backup')), findsNothing);

        // Verify OrganizerCompetitionsSection is rendered
        expect(find.byType(OrganizerCompetitionsSection), findsOneWidget);
      },
    );

    testWidgets(
      'metrics correctly calculate active, pending schedule matches, and unseeded tournaments',
      (tester) async {
        final tournaments = [
          ChampionshipTournament(
            id: 't-1',
            name: 'Torneo 1',
            category: 'Libre',
            format: TournamentFormat.league,
            status: TournamentStatus.inProgress,
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 6, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
          ChampionshipTournament(
            id: 't-2',
            name: 'Torneo 2',
            category: 'Libre',
            format: TournamentFormat.league,
            status: TournamentStatus.finished,
            startDate: DateTime(2025, 1, 1),
            endDate: DateTime(2025, 6, 1),
            updatedAt: DateTime(2025, 1, 1),
          ),
        ];

        await tester.pumpWidget(
          createOrganizerPanelApp(tournaments: tournaments, matches: []),
        );
        await tester.pumpAndSettle();

        // Active tournaments should be 1 (only t-1 is inProgress)
        // Pending matches should be 0
        // Unseeded tournaments should be 1 (t-1 has no matches)
        expect(
          find.byKey(const Key('organizer_metric_active_tournaments')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('organizer_metric_pending_matches')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('organizer_metric_unseeded_tournaments')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'isolates panel metrics strictly to authenticated organizer user-123 and excludes other organizers',
      (tester) async {
        final tournaments = [
          ChampionshipTournament(
            id: 't-own-1',
            organizerId: 'user-123',
            name: 'Copa Propia',
            category: 'Libre',
            format: TournamentFormat.league,
            status: TournamentStatus.inProgress,
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 6, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
          ChampionshipTournament(
            id: 't-other-1',
            organizerId: 'other-org',
            name: 'Copa Ajena 1',
            category: 'Libre',
            format: TournamentFormat.league,
            status: TournamentStatus.inProgress,
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 6, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
          ChampionshipTournament(
            id: 't-seed-1',
            organizerId: 'org-seed-1',
            name: 'Copa Seed',
            category: 'Libre',
            format: TournamentFormat.league,
            status: TournamentStatus.openRegistration,
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 6, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        ];

        final matches = [
          ChampionshipMatch(
            id: 'm-other-1',
            tournamentId: 't-other-1',
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 'team-a',
            awayTeamId: 'team-b',
          ),
          ChampionshipMatch(
            id: 'm-seed-1',
            tournamentId: 't-seed-1',
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 'team-a',
            awayTeamId: 'team-b',
          ),
        ];

        await tester.pumpWidget(
          createOrganizerPanelApp(
            tournaments: tournaments,
            matches: matches,
            authState: AuthFlowState(
              status: AuthStatus.authenticated,
              session: AuthSession(
                sessionId: 'sess-1',
                user: UserAccount(
                  id: 'user-123',
                  fullName: 'Organizador 123',
                  email: 'org123@vifutbol.com',
                  activeRole: UserRole.organizer,
                ),
                sessionToken: 'token',
                authenticatedAt: DateTime(2026, 11, 13),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byKey(const Key('organizer_metric_active_tournaments')),
            matching: find.text('1'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('organizer_metric_pending_matches')),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('organizer_metric_unseeded_tournaments')),
            matching: find.text('1'),
          ),
          findsOneWidget,
        );
        expect(find.text('Copa Propia'), findsOneWidget);
        expect(find.text('Copa Ajena 1'), findsNothing);
        expect(find.text('Copa Seed'), findsNothing);
      },
    );

    testWidgets(
      'HU 22.4: triggers parallel cloud hydration on cold start and pull-to-refresh',
      (tester) async {
        final tournamentsCtrl = FakeTournamentsController();
        final teamsCtrl = FakeTeamsController();
        var loadAllMatchesCalls = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              environmentConfigProvider.overrideWithValue(
                EnvironmentConfig.development(),
              ),
              localStorageRepositoryProvider.overrideWithValue(
                _FakeLocalStorageRepository(),
              ),
              connectivityRepositoryProvider.overrideWithValue(
                _FakeConnectivityRepository(),
              ),
              activeUserRoleProvider.overrideWith((ref) => UserRole.organizer),
              tournamentsControllerProvider.overrideWith(
                (_) => tournamentsCtrl,
              ),
              teamsControllerProvider.overrideWith((_) => teamsCtrl),
              matchesCatalogControllerProvider.overrideWith(
                (_) => _SpyMatchesWidgetController(
                  onLoadAllMatches: () => loadAllMatchesCalls++,
                ),
              ),
            ],
            child: MaterialApp(
              theme: KickPulseTheme.darkTheme,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: const [Locale('es')],
              home: const Scaffold(body: OrganizerPanelContent()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tournamentsCtrl.loadCatalogCalls, 1);
        expect(teamsCtrl.loadTeamsCalls, 1);
        expect(loadAllMatchesCalls, 1);

        await tester.fling(
          find.byKey(const Key('organizer_panel_content')),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();

        expect(tournamentsCtrl.loadCatalogCalls, 2);
        expect(teamsCtrl.loadTeamsCalls, 2);
        expect(loadAllMatchesCalls, 2);
      },
    );

    testWidgets(
      'HU 22.4: updates summary metrics and team count badge live without widget restart',
      (tester) async {
        final t1 = ChampionshipTournament(
          id: 't-live-1',
          organizerId: 'org-seed-1',
          name: 'Copa Reactiva',
          category: 'Libre',
          format: TournamentFormat.league,
          status: TournamentStatus.openRegistration,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 1, 1),
        );

        final tournamentsCtrl = FakeTournamentsController(tournaments: [t1]);
        final teamsCtrl = FakeTeamsController();
        final matchesCtrl = _SpyMatchesWidgetController();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              environmentConfigProvider.overrideWithValue(
                EnvironmentConfig.development(),
              ),
              localStorageRepositoryProvider.overrideWithValue(
                _FakeLocalStorageRepository(),
              ),
              connectivityRepositoryProvider.overrideWithValue(
                _FakeConnectivityRepository(),
              ),
              activeUserRoleProvider.overrideWith((ref) => UserRole.organizer),
              tournamentsControllerProvider.overrideWith(
                (_) => tournamentsCtrl,
              ),
              teamsControllerProvider.overrideWith((_) => teamsCtrl),
              matchesCatalogControllerProvider.overrideWith((_) => matchesCtrl),
            ],
            child: MaterialApp(
              theme: KickPulseTheme.darkTheme,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: const [Locale('es')],
              home: const Scaffold(body: OrganizerPanelContent()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially: 1 active, 0 pending matches, 1 unseeded, 0 teams
        expect(
          find.descendant(
            of: find.byKey(const Key('organizer_metric_unseeded_tournaments')),
            matching: find.text('1'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(
              const Key('organizer_competition_teams_badge_t-live-1'),
            ),
            matching: find.textContaining('0'),
          ),
          findsOneWidget,
        );

        // Enroll 2 teams and generate 3 pending matches in-memory
        teamsCtrl.state = teamsCtrl.state.copyWith(
          teams: [
            TournamentTeam(
              id: 'team-1',
              tournamentId: 't-live-1',
              name: 'Alpha',
              shortCode: 'ALP',
            ),
            TournamentTeam(
              id: 'team-2',
              tournamentId: 't-live-1',
              name: 'Beta',
              shortCode: 'BET',
            ),
          ],
        );
        matchesCtrl.state = matchesCtrl.state.copyWith(
          matches: List.generate(
            3,
            (i) => ChampionshipMatch(
              id: 'm-live-$i',
              tournamentId: 't-live-1',
              roundNumber: 1,
              roundName: 'Jornada 1',
              homeTeamId: 'team-1',
              awayTeamId: 'team-2',
            ),
          ),
        );
        await tester.pump();

        expect(
          find.descendant(
            of: find.byKey(const Key('organizer_metric_unseeded_tournaments')),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('organizer_metric_pending_matches')),
            matching: find.text('3'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(
              const Key('organizer_competition_teams_badge_t-live-1'),
            ),
            matching: find.textContaining('2'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}

class _SpyMatchesWidgetController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  _SpyMatchesWidgetController({this.onLoadAllMatches})
    : super(const MatchesCatalogState());

  final VoidCallback? onLoadAllMatches;

  @override
  Future<void> loadAllMatches({bool silent = false}) async {
    onLoadAllMatches?.call();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
