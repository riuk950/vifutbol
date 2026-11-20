import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/player_performance_profile.dart';
import 'package:vifutbol/domain/entities/standings_table.dart';
import 'package:vifutbol/domain/entities/team_detailed_stats.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/standings/widgets/player_performance_profile_card.dart';
import 'package:vifutbol/presentation/standings/widgets/team_detailed_stats_card.dart';

void main() {
  Widget buildTestableWidget(
    Widget child, {
    double textScale = 1.0,
    Size size = const Size(360, 800),
  }) {
    return MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  group('Player & Team Stats Widgets UI Tests', () {
    testWidgets(
      'US1: PlayerPerformanceProfileCard displays metrics with tabular-nums and match breakdown',
      (tester) async {
        final participation = PlayerMatchParticipation(
          matchId: 'm-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          scheduledAt: DateTime(2026, 11, 1),
          opponentTeamId: 't-opp',
          opponentTeamName: 'Rival FC',
          opponentShortCode: 'RIV',
          isHome: true,
          teamScore: 3,
          opponentScore: 1,
          wasStarter: true,
          goals: 2,
          assists: 1,
        );

        final profile = PlayerPerformanceProfile(
          playerId: 'p-1',
          tournamentId: 't-1',
          fullName: 'Lionel Messi',
          shirtNumber: 10,
          position: PlayerPosition.forward,
          teamId: 't-main',
          teamName: 'Inter Miami',
          teamShortCode: 'MIA',
          matchesPlayed: 4,
          startsCount: 3,
          goals: 2,
          assists: 1,
          yellowCards: 1,
          redCards: 0,
          isSuspended: false,
          matchParticipations: [participation],
        );

        await tester.pumpWidget(
          buildTestableWidget(PlayerPerformanceProfileCard(profile: profile)),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('player_performance_profile_card')),
          findsOneWidget,
        );
        expect(find.text('Lionel Messi'), findsOneWidget);
        expect(
          find.byKey(const Key('player_disciplinary_badge')),
          findsOneWidget,
        );
        expect(find.text('Habilitado'), findsOneWidget);

        expect(
          find.byKey(const Key('player_metric_matches_played')),
          findsOneWidget,
        );
        expect(find.text('4'), findsOneWidget); // 4 PJ
        expect(find.byKey(const Key('player_metric_starts')), findsOneWidget);
        expect(find.text('3'), findsOneWidget); // 3 Starts
        expect(find.byKey(const Key('player_metric_goals')), findsOneWidget);
        expect(find.byKey(const Key('player_metric_assists')), findsOneWidget);
        expect(
          find.byKey(const Key('player_metric_goal_average')),
          findsOneWidget,
        );
        expect(find.text('0.50'), findsOneWidget); // 2 goals / 4 matches = 0.50

        expect(
          find.byKey(
            Key('player_match_participation_${participation.matchId}'),
          ),
          findsOneWidget,
        );
        expect(find.text('Titular'), findsOneWidget);
        expect(find.text('vs Rival FC (RIV)'), findsOneWidget);
      },
    );

    testWidgets(
      'US3: Newly enrolled player with 0 matches shows exact empty message and 0.00 average',
      (tester) async {
        final zeroProfile = const PlayerPerformanceProfile(
          playerId: 'p-zero',
          tournamentId: 't-1',
          fullName: 'Mateo Debutante',
          shirtNumber: 18,
          position: PlayerPosition.midfielder,
          teamId: 't-main',
          teamName: 'Inter Miami',
          teamShortCode: 'MIA',
          matchesPlayed: 0,
          startsCount: 0,
          goals: 0,
          assists: 0,
          yellowCards: 0,
          redCards: 0,
          isSuspended: false,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            PlayerPerformanceProfileCard(profile: zeroProfile),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('0.00'), findsOneWidget);
        expect(
          find.byKey(const Key('player_empty_participations_message')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Aún no registras participaciones en partidos oficiales de este torneo.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'US2: TeamDetailedStatsCard displays form strip V, E, D, match history, and squad list',
      (tester) async {
        final row = const StandingsRow(
          position: 1,
          teamId: 't-team',
          teamName: 'Campeones FC',
          teamShortCode: 'CMP',
          played: 5,
          won: 3,
          drawn: 1,
          lost: 1,
          goalsFor: 8,
          goalsAgainst: 4,
          goalDifference: 4,
          points: 10,
        );

        final squadPlayer = const PlayerPerformanceProfile(
          playerId: 'pl-squad-1',
          tournamentId: 't-1',
          fullName: 'Sergio Busquets',
          shirtNumber: 5,
          position: PlayerPosition.midfielder,
          teamId: 't-team',
          teamName: 'Campeones FC',
          teamShortCode: 'CMP',
          matchesPlayed: 5,
          startsCount: 5,
          goals: 1,
          assists: 2,
        );

        final teamStats = TeamDetailedStats(
          tournamentId: 't-1',
          teamId: 't-team',
          teamName: 'Campeones FC',
          teamShortCode: 'CMP',
          standingsRow: row,
          recentForm: const [
            TeamFormResult.win,
            TeamFormResult.draw,
            TeamFormResult.loss,
            TeamFormResult.win,
            TeamFormResult.win,
          ],
          completedMatches: [
            TeamMatchHistoryItem(
              matchId: 'm-comp-1',
              roundNumber: 5,
              roundName: 'Jornada 5',
              scheduledAt: DateTime(2026, 11, 4),
              opponentTeamId: 't-rival',
              opponentTeamName: 'Subcampeon SC',
              opponentShortCode: 'SUB',
              isHome: true,
              teamScore: 2,
              opponentScore: 0,
              result: TeamFormResult.win,
            ),
          ],
          upcomingMatches: [
            TeamUpcomingMatchItem(
              matchId: 'm-up-1',
              roundNumber: 6,
              roundName: 'Jornada 6',
              scheduledAt: DateTime(2026, 11, 10),
              opponentTeamId: 't-next',
              opponentTeamName: 'Futuro CF',
              opponentShortCode: 'FUT',
              isHome: false,
            ),
          ],
          squadStats: [squadPlayer],
        );

        String? tappedPlayerId;
        await tester.pumpWidget(
          buildTestableWidget(
            TeamDetailedStatsCard(
              teamStats: teamStats,
              onPlayerSelected: (id) => tappedPlayerId = id,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('team_detailed_stats_card')),
          findsOneWidget,
        );
        expect(find.text('Campeones FC (CMP)'), findsOneWidget);
        expect(find.byKey(const Key('team_recent_form_strip')), findsOneWidget);

        expect(
          find.byKey(const Key('team_history_match_m-comp-1')),
          findsOneWidget,
        );
        expect(find.text('2 - 0'), findsOneWidget);

        expect(
          find.byKey(const Key('team_upcoming_match_m-up-1')),
          findsOneWidget,
        );

        final squadRowFinder = find.byKey(
          const Key('team_squad_player_row_pl-squad-1'),
        );
        expect(squadRowFinder, findsOneWidget);
        await tester.tap(squadRowFinder);
        expect(tappedPlayerId, 'pl-squad-1');
      },
    );

    testWidgets(
      'SC-004: Zero RenderFlex overflows at 320px width and 130% text scaling',
      (tester) async {
        final profile = const PlayerPerformanceProfile(
          playerId: 'p-long',
          tournamentId: 't-1',
          fullName: 'Maximilian Alexander Von Hohenzollern',
          shirtNumber: 99,
          position: PlayerPosition.forward,
          teamId: 't-long',
          teamName:
              'Real Club Deportivo Social Cultural y Deportivo Atlético San Martín',
          teamShortCode: 'RCD',
          matchesPlayed: 12,
          startsCount: 11,
          goals: 7,
          assists: 4,
          yellowCards: 2,
          redCards: 1,
          isSuspended: true,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            PlayerPerformanceProfileCard(profile: profile),
            textScale: 1.3,
            size: const Size(320, 700),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('player_performance_profile_card')),
          findsOneWidget,
        );
      },
    );
  });
}
