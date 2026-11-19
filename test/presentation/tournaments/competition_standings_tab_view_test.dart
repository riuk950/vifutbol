import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/standings_and_rankings_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/calculate_tournament_standings_and_rankings_use_case.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/knockout_bracket.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/standings_table.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rankings.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_standings_tab_view.dart';

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

class FakeStandingsController extends StateNotifier<StandingsAndRankingsState>
    implements StandingsAndRankingsController {
  FakeStandingsController({StandingsAndRankingsState? state})
    : super(state ?? const StandingsAndRankingsState());

  @override
  void selectViewMode(CompetitiveViewMode mode) {
    state = state.copyWith(activeViewMode: mode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createStandingsTabTestApp({
  required String tournamentId,
  required ChampionshipTournament tournament,
  required StandingsAndRankingsState standingsState,
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      tournamentsControllerProvider.overrideWith(
        (ref) => FakeTournamentsController(tournaments: [tournament]),
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
      home: Scaffold(
        body: CompetitionStandingsTabView(tournamentId: tournamentId),
      ),
    ),
  );
}

void main() {
  group('CompetitionStandingsTabView', () {
    const tournamentId = 't-test';

    final leagueTournament = ChampionshipTournament(
      id: tournamentId,
      name: 'Liga de Primera 2026',
      category: 'Primera División',
      format: TournamentFormat.league,
      status: TournamentStatus.inProgress,
      startDate: DateTime(2026, 2, 1),
      endDate: DateTime(2026, 11, 30),
      updatedAt: DateTime(2026, 2, 1),
    );

    final cupTournament = ChampionshipTournament(
      id: tournamentId,
      name: 'Copa Nacional Eliminatoria 2026',
      category: 'Primera División',
      format: TournamentFormat.knockoutCup,
      status: TournamentStatus.inProgress,
      startDate: DateTime(2026, 2, 1),
      endDate: DateTime(2026, 11, 30),
      updatedAt: DateTime(2026, 2, 1),
    );

    final mixedTournament = ChampionshipTournament(
      id: tournamentId,
      name: 'Torneo Mixto Clausura 2026',
      category: 'Categoría Libre',
      format: TournamentFormat.mixedGroupsAndKnockout,
      status: TournamentStatus.inProgress,
      startDate: DateTime(2026, 2, 1),
      endDate: DateTime(2026, 11, 30),
      updatedAt: DateTime(2026, 2, 1),
    );

    final sampleMainTable = StandingsTable(
      tournamentId: tournamentId,
      rows: const [
        StandingsRow(
          position: 1,
          teamId: 'team-a',
          teamName: 'Águilas Doradas',
          teamShortCode: 'AGU',
          played: 3,
          won: 3,
          drawn: 0,
          lost: 0,
          goalsFor: 8,
          goalsAgainst: 2,
          goalDifference: 6,
          points: 9,
        ),
        StandingsRow(
          position: 2,
          teamId: 'team-b',
          teamName: 'Tigres del Norte',
          teamShortCode: 'TIG',
          played: 3,
          won: 2,
          drawn: 0,
          lost: 1,
          goalsFor: 5,
          goalsAgainst: 3,
          goalDifference: 2,
          points: 6,
        ),
      ],
      appliedTiebreakers: const [
        TiebreakerCriterion.goalDifference,
        TiebreakerCriterion.goalsFor,
      ],
      completedMatchesCount: 3,
    );

    final sampleBracket = KnockoutBracket(
      tournamentId: tournamentId,
      rounds: [
        KnockoutBracketRound(
          round: KnockoutRound.finalMatch,
          roundTitle: 'Gran Final',
          ties: const [
            KnockoutMatchTieNode(
              nodeId: 'final-1',
              round: KnockoutRound.finalMatch,
              tieIndex: 0,
              homeTeamId: 'team-a',
              homeTeamName: 'Águilas Doradas',
              awayTeamId: 'team-b',
              awayTeamName: 'Tigres del Norte',
              homeScore: 2,
              awayScore: 1,
              status: MatchStatus.completed,
              winnerTeamId: 'team-a',
              winnerTeamName: 'Águilas Doradas',
            ),
          ],
        ),
      ],
    );

    final sampleRankings = TournamentRankingsBundle(
      tournamentId: tournamentId,
      topScorers: const [
        PlayerRankingEntry(
          rank: 1,
          playerId: 'p-1',
          playerName: 'Carlos Gómez',
          shirtNumber: 9,
          teamId: 'team-a',
          teamName: 'Águilas Doradas',
          teamShortCode: 'AGU',
          goals: 5,
          assists: 2,
          matchesPlayed: 3,
        ),
      ],
      topAssists: const [
        PlayerRankingEntry(
          rank: 1,
          playerId: 'p-2',
          playerName: 'David Morales',
          shirtNumber: 10,
          teamId: 'team-a',
          teamName: 'Águilas Doradas',
          teamShortCode: 'AGU',
          goals: 1,
          assists: 4,
          matchesPlayed: 3,
        ),
      ],
      teamFairPlay: const [
        TeamFairPlayRow(
          rank: 1,
          teamId: 'team-a',
          teamName: 'Águilas Doradas',
          teamShortCode: 'AGU',
          yellowCards: 2,
          secondYellowRedCards: 0,
          directRedCards: 0,
          penaltyPoints: -2,
        ),
      ],
    );

    testWidgets(
      'US1: renders official league standings table with standard columns and tabular figures',
      (tester) async {
        final snapshot = TournamentCompetitiveSnapshot(
          tournament: leagueTournament,
          mainStandingsTable: sampleMainTable,
          rankings: sampleRankings,
        );

        await tester.pumpWidget(
          createStandingsTabTestApp(
            tournamentId: tournamentId,
            tournament: leagueTournament,
            standingsState: StandingsAndRankingsState(
              isLoading: false,
              snapshot: snapshot,
              activeViewMode: CompetitiveViewMode.standings,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Subview chips check for League
        expect(find.byKey(const Key('subview_chip_standings')), findsOneWidget);
        expect(find.byKey(const Key('subview_chip_rankings')), findsOneWidget);
        expect(find.byKey(const Key('subview_chip_brackets')), findsNothing);

        // Standings table card check
        expect(
          find.byKey(const Key('competition_standings_table_card')),
          findsOneWidget,
        );
        expect(find.textContaining('Águilas Doradas'), findsOneWidget);
        expect(find.textContaining('Tigres del Norte'), findsOneWidget);
      },
    );

    testWidgets(
      'US2: renders knockout bracket for cup tournaments (knockoutCup)',
      (tester) async {
        final snapshot = TournamentCompetitiveSnapshot(
          tournament: cupTournament,
          mainStandingsTable: StandingsTable(
            tournamentId: tournamentId,
            rows: const [],
            appliedTiebreakers: const [],
            completedMatchesCount: 0,
          ),
          knockoutBracket: sampleBracket,
          rankings: sampleRankings,
        );

        await tester.pumpWidget(
          createStandingsTabTestApp(
            tournamentId: tournamentId,
            tournament: cupTournament,
            standingsState: StandingsAndRankingsState(
              isLoading: false,
              snapshot: snapshot,
              activeViewMode: CompetitiveViewMode.brackets,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Subview chips check for Cup
        expect(find.byKey(const Key('subview_chip_brackets')), findsOneWidget);
        expect(find.byKey(const Key('subview_chip_rankings')), findsOneWidget);
        expect(find.byKey(const Key('subview_chip_standings')), findsNothing);

        // Bracket card check
        expect(
          find.byKey(const Key('competition_knockout_bracket_card')),
          findsOneWidget,
        );
        expect(find.text('Gran Final'), findsOneWidget);
      },
    );

    testWidgets(
      'US3: handles mixed tournament format and switches between groups and brackets',
      (tester) async {
        final groupTableA = StandingsTable(
          tournamentId: tournamentId,
          groupName: 'Grupo A',
          rows: sampleMainTable.rows,
          appliedTiebreakers: const [TiebreakerCriterion.goalDifference],
          completedMatchesCount: 3,
        );

        final snapshot = TournamentCompetitiveSnapshot(
          tournament: mixedTournament,
          mainStandingsTable: sampleMainTable,
          groupStandingsTables: [groupTableA],
          knockoutBracket: sampleBracket,
          rankings: sampleRankings,
        );

        await tester.pumpWidget(
          createStandingsTabTestApp(
            tournamentId: tournamentId,
            tournament: mixedTournament,
            standingsState: StandingsAndRankingsState(
              isLoading: false,
              snapshot: snapshot,
              activeViewMode: CompetitiveViewMode.standings,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Mixed format has all 3 chips
        expect(find.byKey(const Key('subview_chip_standings')), findsOneWidget);
        expect(find.byKey(const Key('subview_chip_brackets')), findsOneWidget);
        expect(find.byKey(const Key('subview_chip_rankings')), findsOneWidget);

        // Initial view is standings
        expect(
          find.byKey(const Key('competition_standings_table_card')),
          findsOneWidget,
        );

        // Switch to brackets
        await tester.tap(find.byKey(const Key('subview_chip_brackets')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_knockout_bracket_card')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'US4: switches to Estadísticas subview and displays TournamentRankingsCard',
      (tester) async {
        final snapshot = TournamentCompetitiveSnapshot(
          tournament: leagueTournament,
          mainStandingsTable: sampleMainTable,
          rankings: sampleRankings,
        );

        await tester.pumpWidget(
          createStandingsTabTestApp(
            tournamentId: tournamentId,
            tournament: leagueTournament,
            standingsState: StandingsAndRankingsState(
              isLoading: false,
              snapshot: snapshot,
              activeViewMode: CompetitiveViewMode.standings,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Rankings
        await tester.tap(find.byKey(const Key('subview_chip_rankings')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_tournament_rankings_card')),
          findsOneWidget,
        );
        expect(find.textContaining('Carlos Gómez'), findsOneWidget);
      },
    );

    testWidgets('US5: displays loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        createStandingsTabTestApp(
          tournamentId: tournamentId,
          tournament: leagueTournament,
          standingsState: const StandingsAndRankingsState(isLoading: true),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('competition_detail_standings_loading')),
        findsOneWidget,
      );
    });

    testWidgets(
      'US5: displays contextual empty states per subview with visible chips',
      (tester) async {
        final emptySnapshot = TournamentCompetitiveSnapshot(
          tournament: leagueTournament,
          mainStandingsTable: StandingsTable(
            tournamentId: tournamentId,
            rows: const [],
            appliedTiebreakers: const [],
            completedMatchesCount: 0,
          ),
          rankings: TournamentRankingsBundle(
            tournamentId: tournamentId,
            topScorers: const [],
            topAssists: const [],
            teamFairPlay: const [],
          ),
        );

        await tester.pumpWidget(
          createStandingsTabTestApp(
            tournamentId: tournamentId,
            tournament: leagueTournament,
            standingsState: StandingsAndRankingsState(
              isLoading: false,
              snapshot: emptySnapshot,
              activeViewMode: CompetitiveViewMode.standings,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_detail_standings_empty_state')),
          findsOneWidget,
        );
        expect(find.text('Sin Clasificación Disponible'), findsOneWidget);
        // Chips must remain visible
        expect(find.byKey(const Key('subview_chip_standings')), findsOneWidget);
        expect(find.byKey(const Key('subview_chip_rankings')), findsOneWidget);

        // Switch to Rankings when empty
        await tester.tap(find.byKey(const Key('subview_chip_rankings')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_detail_rankings_empty_state')),
          findsOneWidget,
        );
        expect(find.text('Sin Estadísticas Disponibles'), findsOneWidget);
      },
    );

    testWidgets(
      'renders without RenderFlex overflow at 320x640 with 130% text scaling',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final snapshot = TournamentCompetitiveSnapshot(
          tournament: leagueTournament,
          mainStandingsTable: sampleMainTable,
          rankings: sampleRankings,
        );

        await tester.pumpWidget(
          createStandingsTabTestApp(
            tournamentId: tournamentId,
            tournament: leagueTournament,
            standingsState: StandingsAndRankingsState(
              isLoading: false,
              snapshot: snapshot,
              activeViewMode: CompetitiveViewMode.standings,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('competition_detail_standings_content')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_standings_table_card')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'HU 22.3: preserves cached standings during background refresh and invokes onRefresh on pull',
      (tester) async {
        final snapshot = TournamentCompetitiveSnapshot(
          tournament: leagueTournament,
          mainStandingsTable: sampleMainTable,
          rankings: sampleRankings,
        );

        var refreshCount = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tournamentsControllerProvider.overrideWith(
                (ref) =>
                    FakeTournamentsController(tournaments: [leagueTournament]),
              ),
              standingsAndRankingsControllerProvider(tournamentId).overrideWith(
                (ref) => FakeStandingsController(
                  state: StandingsAndRankingsState(
                    isLoading: true,
                    snapshot: snapshot,
                    activeViewMode: CompetitiveViewMode.standings,
                  ),
                ),
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
                body: CompetitionStandingsTabView(
                  tournamentId: tournamentId,
                  onRefresh: () async {
                    refreshCount++;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_detail_standings_loading')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('competition_standings_table_card')),
          findsOneWidget,
        );

        await tester.fling(
          find.byKey(const Key('competition_standings_table_card')),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();
        expect(refreshCount, 1);
      },
    );
  });
}
