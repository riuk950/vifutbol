import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_fixture_tab_view.dart';

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

class FakeTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  FakeTeamsController({List<TournamentTeam> teams = const []})
    : super(TeamsCatalogState(teams: teams));

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

Widget createFixtureTestApp({
  required String tournamentId,
  List<ChampionshipMatch>? matches,
  List<TournamentTeam>? teams,
}) {
  final defaultTeams =
      teams ??
      [
        TournamentTeam(
          id: 'team-a',
          tournamentId: 't-1',
          name: 'Águilas Doradas',
          shortCode: 'AGU',
        ),
        TournamentTeam(
          id: 'team-b',
          tournamentId: 't-1',
          name: 'Tigres del Norte',
          shortCode: 'TIG',
        ),
        TournamentTeam(
          id: 'team-c',
          tournamentId: 't-1',
          name: 'Cóndores FC',
          shortCode: 'CON',
        ),
        TournamentTeam(
          id: 'team-d',
          tournamentId: 't-1',
          name: 'Halcones Urbanos',
          shortCode: 'HAL',
        ),
      ];

  final defaultMatches =
      matches ??
      [
        ChampionshipMatch(
          id: 'match-r1-1',
          tournamentId: 't-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          status: MatchStatus.completed,
          homeScore: 2,
          awayScore: 1,
          scheduledStartTime: DateTime(2026, 3, 10, 15, 0),
          pitchName: 'Cancha 1',
        ),
        ChampionshipMatch(
          id: 'match-r1-2',
          tournamentId: 't-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-c',
          awayTeamId: 'team-d',
          status: MatchStatus.scheduled,
          scheduledStartTime: DateTime(2026, 3, 10, 17, 0),
          pitchName: 'Cancha 2',
        ),
        ChampionshipMatch(
          id: 'match-r2-1',
          tournamentId: 't-1',
          roundNumber: 2,
          roundName: 'Jornada 2',
          homeTeamId: 'team-a',
          awayTeamId: 'team-c',
          status: MatchStatus.pendingSchedule,
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
      teamsControllerProvider.overrideWith(
        (ref) => FakeTeamsController(teams: defaultTeams),
      ),
      matchesCatalogControllerProvider.overrideWith(
        (ref) => FakeMatchesCatalogController(matches: defaultMatches),
      ),
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
      home: Scaffold(
        body: CompetitionFixtureTabView(tournamentId: tournamentId),
      ),
    ),
  );
}

void main() {
  group('CompetitionFixtureTabView', () {
    testWidgets(
      'renders full fixture grouped chronologically by rounds (US1 - MVP)',
      (tester) async {
        await tester.pumpWidget(createFixtureTestApp(tournamentId: 't-1'));
        await tester.pumpAndSettle();

        // Verify Fixture List is rendered
        expect(
          find.byKey(const Key('competition_detail_fixture_list')),
          findsOneWidget,
        );

        // Verify Round Headers
        expect(find.byKey(const Key('fixture_round_header_1')), findsOneWidget);
        expect(find.byKey(const Key('fixture_round_header_2')), findsOneWidget);
        expect(find.text('Jornada 1'), findsOneWidget);
        expect(find.text('Jornada 2'), findsOneWidget);

        // Verify Match Items under Round 1
        expect(
          find.byKey(const Key('fixture_match_item_match-r1-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('fixture_match_item_match-r1-2')),
          findsOneWidget,
        );

        // Verify Match Item under Round 2
        expect(
          find.byKey(const Key('fixture_match_item_match-r2-1')),
          findsOneWidget,
        );

        // Verify Teams and Scores
        expect(
          find.text('Águilas Doradas'),
          findsNWidgets(2),
        ); // Played in r1 and r2
        expect(find.text('Tigres del Norte'), findsOneWidget);
        expect(find.text('2 - 1'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping a match card opens the Match Center modal bottom sheet (US3)',
      (tester) async {
        await tester.pumpWidget(createFixtureTestApp(tournamentId: 't-1'));
        await tester.pumpAndSettle();

        final firstMatchFinder = find.byKey(
          const Key('fixture_match_item_match-r1-1'),
        );
        expect(firstMatchFinder, findsOneWidget);

        await tester.tap(firstMatchFinder);
        await tester.pumpAndSettle();

        // Verify Bottom Sheet Modal content
        expect(
          find.text('Águilas Doradas vs Tigres del Norte'),
          findsOneWidget,
        );
        expect(find.text('Cancha 1'), findsOneWidget);
      },
    );

    testWidgets('renders empty state when tournament has no matches (US4)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createFixtureTestApp(tournamentId: 't-empty', matches: const []),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fixture_empty_matches_state')),
        findsOneWidget,
      );
      expect(find.text('Calendario en Preparación'), findsOneWidget);
      expect(
        find.text(
          'Esta competición aún no tiene partidos programados en su calendario oficial.',
        ),
        findsOneWidget,
      );
    });
  });
}
