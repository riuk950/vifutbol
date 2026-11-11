import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/standings_and_rankings_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
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
import 'package:vifutbol/presentation/tournaments/competition_detail_screen.dart';

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
           viewState: UiSuccessState<List<ChampionshipTournament>>(tournaments),
           tournaments: tournaments,
         ),
       );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  FakeTeamsController({List<TournamentTeam> teams = const []})
    : super(TeamsCatalogState(teams: teams));

  @override
  Future<bool> enrollTeamInCompetition({
    required TournamentTeam team,
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    state = state.copyWith(teams: [...state.teams, team]);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMatchesCatalogController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  FakeMatchesCatalogController({List<ChampionshipMatch> matches = const []})
    : super(MatchesCatalogState(matches: matches));

  @override
  Future<bool> generateFixture({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required UserRole userRole,
  }) async {
    final generated = [
      ChampionshipMatch(
        id: 'gen-1',
        tournamentId: tournament.id,
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 't-1',
        awayTeamId: 't-2',
      ),
    ];
    state = state.copyWith(matches: [...state.matches, ...generated]);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStandingsController extends StateNotifier<StandingsAndRankingsState>
    implements StandingsAndRankingsController {
  FakeStandingsController({StandingsAndRankingsState? state})
    : super(state ?? const StandingsAndRankingsState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createDetailTestApp({
  required String tournamentId,
  List<ChampionshipTournament>? tournaments,
  List<ChampionshipMatch>? matches,
  List<TournamentTeam>? teams,
  StandingsAndRankingsState? standingsState,
  UserRole userRole = UserRole.fan,
  Widget? home,
}) {
  final tournament = ChampionshipTournament(
    id: tournamentId,
    name: 'Liga de Honor 2026',
    category: 'Primera División',
    status: TournamentStatus.inProgress,
    format: TournamentFormat.league,
    startDate: DateTime(2026, 2, 1),
    endDate: DateTime(2026, 11, 30),
    updatedAt: DateTime(2026, 2, 1),
  );

  final defaultMatches =
      matches ??
      [
        ChampionshipMatch(
          id: 'm-1',
          tournamentId: tournamentId,
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 't-a',
          awayTeamId: 't-b',
          status: MatchStatus.completed,
          homeScore: 1,
          awayScore: 0,
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
      activeUserRoleProvider.overrideWith((ref) => userRole),
      tournamentsControllerProvider.overrideWith(
        (ref) =>
            FakeTournamentsController(tournaments: tournaments ?? [tournament]),
      ),
      teamsControllerProvider.overrideWith(
        (ref) => FakeTeamsController(teams: teams ?? const []),
      ),
      matchesCatalogControllerProvider.overrideWith(
        (ref) => FakeMatchesCatalogController(matches: defaultMatches),
      ),
      standingsAndRankingsControllerProvider(
        tournamentId,
      ).overrideWith((ref) => FakeStandingsController(state: standingsState)),
    ],
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: home ?? CompetitionDetailScreen(tournamentId: tournamentId),
    ),
  );
}

void main() {
  group('CompetitionDetailScreen', () {
    testWidgets(
      'renders AppBar with tournament title, category, and status badge',
      (tester) async {
        await tester.pumpWidget(createDetailTestApp(tournamentId: 't-detail'));
        await tester.pumpAndSettle();

        // Verify Screen Key
        expect(
          find.byKey(const Key('competition_detail_screen')),
          findsOneWidget,
        );

        // Verify Title and Subtitle
        expect(
          find.byKey(const Key('competition_detail_title')),
          findsOneWidget,
        );
        expect(find.text('Liga de Honor 2026'), findsOneWidget);
        expect(
          find.byKey(const Key('competition_detail_category')),
          findsOneWidget,
        );
        expect(find.text('Primera División'), findsOneWidget);

        // Verify Status Badge
        expect(
          find.byKey(const Key('competition_detail_status_badge')),
          findsOneWidget,
        );
        expect(find.text('En Curso'), findsOneWidget);

        // Verify Back Button
        expect(
          find.byKey(const Key('competition_detail_back_button')),
          findsOneWidget,
        );

        // Verify TabBar
        expect(
          find.byKey(const Key('competition_detail_tab_bar')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_detail_tab_matches')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_detail_tab_standings')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_detail_tab_teams')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_detail_tab_info')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'switches between Partidos, Clasificación, and Información tabs (US2)',
      (tester) async {
        await tester.pumpWidget(createDetailTestApp(tournamentId: 't-detail'));
        await tester.pumpAndSettle();

        // 1. Initial active tab: Partidos
        expect(
          find.byKey(const Key('competition_detail_fixture_list')),
          findsOneWidget,
        );

        // 2. Switch to Clasificación
        final standingsTab = find.byKey(
          const Key('competition_detail_tab_standings'),
        );
        await tester.tap(standingsTab);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_detail_standings_content')),
          findsOneWidget,
        );

        // 3. Switch to Equipos
        final teamsTab = find.byKey(const Key('competition_detail_tab_teams'));
        await tester.tap(teamsTab);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_teams_empty_state')),
          findsOneWidget,
        );

        // 4. Switch to Información
        final infoTab = find.byKey(const Key('competition_detail_tab_info'));
        await tester.tap(infoTab);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_detail_info_content')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_tournament_rules_card')),
          findsOneWidget,
        );
        expect(find.text('Sistema de Puntuación'), findsOneWidget);

        // 4. Switch back to Partidos
        final matchesTab = find.byKey(
          const Key('competition_detail_tab_matches'),
        );
        await tester.tap(matchesTab);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_detail_fixture_list')),
          findsOneWidget,
        );
      },
    );

    testWidgets('back button pops screen', (tester) async {
      await tester.pumpWidget(
        createDetailTestApp(
          tournamentId: 't-detail',
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const CompetitionDetailScreen(tournamentId: 't-detail'),
                  ),
                );
              },
              child: const Text('Open Detail'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('competition_detail_screen')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('competition_detail_back_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('competition_detail_screen')), findsNothing);
      expect(find.text('Open Detail'), findsOneWidget);
    });

    testWidgets('Organizer triggers direct fixture generation from FAB (US2)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createDetailTestApp(
          tournamentId: 't-detail',
          userRole: UserRole.organizer,
          matches: const [],
        ),
      );
      await tester.pumpAndSettle();

      // Expandable FAB menu is visible immediately
      final fabMenu = find.byKey(const Key('competition_detail_fab_menu'));
      expect(fabMenu, findsOneWidget);

      await tester.tap(fabMenu);
      await tester.pumpAndSettle();

      final generateAction = find.byKey(
        const Key('competition_detail_fab_generate_fixture'),
      );
      expect(generateAction, findsOneWidget);
      expect(find.text('Generar Fixture'), findsOneWidget);
      expect(
        find.byKey(const Key('competition_detail_fab_add_team')),
        findsOneWidget,
      );

      // Tap generate fixture action -> opens confirmation dialog
      await tester.tap(generateAction);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('confirm_generate_fixture_button')),
        findsOneWidget,
      );

      // Confirm fixture generation
      await tester.tap(
        find.byKey(const Key('confirm_generate_fixture_button')),
      );
      await tester.pumpAndSettle();

      // Dialog dismissed, snackbar shown
      expect(find.textContaining('Fixture generado'), findsOneWidget);
    });

    testWidgets(
      'hides FAB menu for non-organizer roles or finished tournaments (US2)',
      (tester) async {
        // 1. Fan on editable tournament
        await tester.pumpWidget(
          createDetailTestApp(tournamentId: 't-detail', userRole: UserRole.fan),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_detail_fab_menu')),
          findsNothing,
        );
      },
    );

    testWidgets('hides FAB menu for organizer on finished tournament (US2)', (
      tester,
    ) async {
      final finishedTournament = ChampionshipTournament(
        id: 't-finished',
        name: 'Torneo Finalizado 2025',
        category: 'Veteranos',
        status: TournamentStatus.finished,
        format: TournamentFormat.league,
        startDate: DateTime(2025, 2, 1),
        endDate: DateTime(2025, 11, 30),
        updatedAt: DateTime(2025, 11, 30),
      );

      await tester.pumpWidget(
        createDetailTestApp(
          tournamentId: 't-finished',
          tournaments: [finishedTournament],
          userRole: UserRole.organizer,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('competition_detail_fab_menu')),
        findsNothing,
      );
    });

    testWidgets(
      'CompetitionDetailScreen FAB menu renders without RenderFlex overflow on compact screen (320x640 at 130% text scale)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: createDetailTestApp(
              tournamentId: 't-detail',
              userRole: UserRole.organizer,
              matches: const [],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fabMenu = find.byKey(const Key('competition_detail_fab_menu'));
        expect(fabMenu, findsOneWidget);
        await tester.tap(fabMenu);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_detail_fab_generate_fixture')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_detail_fab_add_team')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'HU 18.4: non-organizer roles never see expandable FAB menu or its actions',
      (tester) async {
        for (final role in UserRole.values.where(
          (r) => r != UserRole.organizer,
        )) {
          await tester.pumpWidget(
            createDetailTestApp(tournamentId: 't-detail', userRole: role),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('competition_detail_fab_menu')),
            findsNothing,
            reason: '${role.name} must never see competition_detail_fab_menu',
          );
          expect(
            find.byKey(const Key('competition_detail_fab_add_team')),
            findsNothing,
            reason:
                '${role.name} must never see competition_detail_fab_add_team',
          );
        }
      },
    );
  });
}
