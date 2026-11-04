import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_event.dart';
import 'package:vifutbol/domain/entities/match_lineup_convocation.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/standings_table.dart';
import 'package:vifutbol/domain/entities/team_detailed_stats.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/services/player_team_stats_calculator_service.dart';

void main() {
  group('PlayerTeamStatsCalculatorService', () {
    const service = PlayerTeamStatsCalculatorService();

    late ChampionshipTournament tournament;
    late TournamentTeam teamAlpha;
    late TournamentTeam teamBeta;
    late RegisteredPlayer playerAlpha1;
    late RegisteredPlayer playerAlpha2;
    late RegisteredPlayer playerBeta1;

    setUp(() {
      tournament = ChampionshipTournament(
        id: 'tour_1',
        name: 'Torneo Apertura 2026',
        category: 'Libre',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 12, 1),
        format: TournamentFormat.league,
        rules: const TournamentRulesConfig(yellowCardSuspensionLimit: 2),
        updatedAt: DateTime.now(),
      );

      playerAlpha1 = const RegisteredPlayer(
        id: 'p_a1',
        fullName: 'Carlos Goleador',
        documentId: '12345678',
        shirtNumber: 9,
        position: PlayerPosition.forward,
        isEligible: true,
      );

      playerAlpha2 = const RegisteredPlayer(
        id: 'p_a2',
        fullName: 'Luis Suplente',
        documentId: '87654321',
        shirtNumber: 14,
        position: PlayerPosition.midfielder,
        isEligible: true,
      );

      playerBeta1 = const RegisteredPlayer(
        id: 'p_b1',
        fullName: 'Mateo Rival',
        documentId: '55667788',
        shirtNumber: 10,
        position: PlayerPosition.midfielder,
        isEligible: true,
      );

      teamAlpha = TournamentTeam(
        id: 't_alpha',
        tournamentId: 'tour_1',
        name: 'Alpha FC',
        shortCode: 'ALP',
        players: [playerAlpha1, playerAlpha2],
      );

      teamBeta = TournamentTeam(
        id: 't_beta',
        tournamentId: 'tour_1',
        name: 'Beta Club',
        shortCode: 'BET',
        players: [playerBeta1],
      );
    });

    test(
      'Zero-division safety: handles players with 0 matches played cleanly',
      () {
        final mainTable = StandingsTable(
          tournamentId: tournament.id,
          completedMatchesCount: 0,
          appliedTiebreakers: const [TiebreakerCriterion.goalDifference],
          rows: [
            StandingsRow(
              position: 1,
              teamId: teamAlpha.id,
              teamName: teamAlpha.name,
              teamShortCode: teamAlpha.shortCode,
              played: 0,
              won: 0,
              drawn: 0,
              lost: 0,
              goalsFor: 0,
              goalsAgainst: 0,
              goalDifference: 0,
              points: 0,
            ),
            StandingsRow(
              position: 2,
              teamId: teamBeta.id,
              teamName: teamBeta.name,
              teamShortCode: teamBeta.shortCode,
              played: 0,
              won: 0,
              drawn: 0,
              lost: 0,
              goalsFor: 0,
              goalsAgainst: 0,
              goalDifference: 0,
              points: 0,
            ),
          ],
        );

        final result = service.calculateAll(
          tournament: tournament,
          teams: [teamAlpha, teamBeta],
          mainStandingsTable: mainTable,
          matches: const [],
          reports: const [],
        );

        final profileA1 = result.playerProfilesById[playerAlpha1.id]!;
        expect(profileA1.matchesPlayed, 0);
        expect(profileA1.startsCount, 0);
        expect(profileA1.goals, 0);
        expect(profileA1.assists, 0);
        expect(profileA1.goalsPerMatchAverage, 0.0);
        expect(profileA1.formattedGoalsAverage, '0.00');
        expect(profileA1.isSuspended, isFalse);
        expect(profileA1.hasParticipations, isFalse);
        expect(profileA1.matchParticipations, isEmpty);

        final teamStatsAlpha = result.teamStatsById[teamAlpha.id]!;
        expect(teamStatsAlpha.recentForm, isEmpty);
        expect(teamStatsAlpha.completedMatches, isEmpty);
        expect(teamStatsAlpha.upcomingMatches, isEmpty);
        expect(teamStatsAlpha.squadStats.length, 2);
      },
    );

    test(
      'Correctly attributes starter, substitute, goals, and assists from closed reports',
      () {
        final match = ChampionshipMatch(
          id: 'm_1',
          tournamentId: tournament.id,
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: teamAlpha.id,
          awayTeamId: teamBeta.id,
          scheduledStartTime: DateTime(2026, 11, 1, 10, 0),
          status: MatchStatus.completed,
        );

        final convocationAlpha = MatchLineupConvocation(
          id: 'conv_alpha',
          tournamentId: tournament.id,
          teamId: teamAlpha.id,
          starterPlayerIds: [playerAlpha1.id],
          substitutePlayerIds: [playerAlpha2.id],
        );

        final report = DigitalMatchReport(
          matchId: match.id,
          tournamentId: tournament.id,
          homeTeamId: teamAlpha.id,
          awayTeamId: teamBeta.id,
          homeScore: 2,
          awayScore: 1,
          currentPeriod: MatchPeriod.closed,
          closedAt: DateTime(2026, 11, 1, 11, 45),
          events: [
            MatchEvent(
              id: 'e_1',
              matchId: match.id,
              type: MatchEventType.goal,
              minute: 15,
              primaryPlayerId: playerAlpha1.id,
              teamId: teamAlpha.id,
            ),
            MatchEvent(
              id: 'e_2',
              matchId: match.id,
              type: MatchEventType.substitution,
              minute: 60,
              primaryPlayerId: playerAlpha2.id,
              secondaryPlayerId: playerAlpha1.id,
              teamId: teamAlpha.id,
            ),
            MatchEvent(
              id: 'e_3',
              matchId: match.id,
              type: MatchEventType.goal,
              minute: 75,
              primaryPlayerId: playerAlpha2.id,
              secondaryPlayerId: playerAlpha1.id, // assistant
              teamId: teamAlpha.id,
            ),
          ],
        );

        final mainTable = StandingsTable(
          tournamentId: tournament.id,
          completedMatchesCount: 1,
          appliedTiebreakers: const [TiebreakerCriterion.goalDifference],
          rows: [
            StandingsRow(
              position: 1,
              teamId: teamAlpha.id,
              teamName: teamAlpha.name,
              teamShortCode: teamAlpha.shortCode,
              played: 1,
              won: 1,
              drawn: 0,
              lost: 0,
              points: 3,
              goalsFor: 2,
              goalsAgainst: 1,
              goalDifference: 1,
            ),
            StandingsRow(
              position: 2,
              teamId: teamBeta.id,
              teamName: teamBeta.name,
              teamShortCode: teamBeta.shortCode,
              played: 1,
              won: 0,
              drawn: 0,
              lost: 1,
              points: 0,
              goalsFor: 1,
              goalsAgainst: 2,
              goalDifference: -1,
            ),
          ],
        );

        final result = service.calculateAll(
          tournament: tournament,
          teams: [teamAlpha, teamBeta],
          mainStandingsTable: mainTable,
          matches: [match],
          reports: [report],
          convocationsByTeamId: {teamAlpha.id: convocationAlpha},
        );

        // Player 1: Started, scored 1, assisted 1, 1 match played
        final profileA1 = result.playerProfilesById[playerAlpha1.id]!;
        expect(profileA1.matchesPlayed, 1);
        expect(profileA1.startsCount, 1);
        expect(profileA1.goals, 1);
        expect(profileA1.assists, 1);
        expect(profileA1.goalsPerMatchAverage, 1.0);
        expect(profileA1.formattedGoalsAverage, '1.00');
        expect(profileA1.matchParticipations.length, 1);
        expect(profileA1.matchParticipations.first.wasStarter, isTrue);

        // Player 2: Entered as sub, scored 1, 1 match played, 0 starts
        final profileA2 = result.playerProfilesById[playerAlpha2.id]!;
        expect(profileA2.matchesPlayed, 1);
        expect(profileA2.startsCount, 0);
        expect(profileA2.goals, 1);
        expect(profileA2.assists, 0);
        expect(profileA2.goalsPerMatchAverage, 1.0);
        expect(profileA2.matchParticipations.first.wasStarter, isFalse);

        // Team Alpha: 1 win in recent form
        final teamAlphaStats = result.teamStatsById[teamAlpha.id]!;
        expect(teamAlphaStats.recentForm, [TeamFormResult.win]);
        expect(teamAlphaStats.completedMatches.length, 1);
        expect(
          teamAlphaStats.completedMatches.first.result,
          TeamFormResult.win,
        );
        expect(teamAlphaStats.completedMatches.first.teamScore, 2);
        expect(teamAlphaStats.completedMatches.first.opponentScore, 1);
      },
    );

    test(
      'Disciplinary evaluation marks player suspended on direct red card or yellow card limit',
      () {
        final match = ChampionshipMatch(
          id: 'm_disc',
          tournamentId: tournament.id,
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: teamAlpha.id,
          awayTeamId: teamBeta.id,
          scheduledStartTime: DateTime(2026, 11, 2, 10, 0),
          status: MatchStatus.completed,
        );

        final report = DigitalMatchReport(
          matchId: match.id,
          tournamentId: tournament.id,
          homeTeamId: teamAlpha.id,
          awayTeamId: teamBeta.id,
          currentPeriod: MatchPeriod.closed,
          events: [
            MatchEvent(
              id: 'e_red',
              matchId: match.id,
              type: MatchEventType.directRedCard,
              minute: 44,
              primaryPlayerId: playerAlpha1.id,
              teamId: teamAlpha.id,
            ),
            MatchEvent(
              id: 'e_y1',
              matchId: match.id,
              type: MatchEventType.yellowCard,
              minute: 20,
              primaryPlayerId: playerAlpha2.id,
              teamId: teamAlpha.id,
            ),
            MatchEvent(
              id: 'e_y2',
              matchId: match.id,
              type: MatchEventType.yellowCard,
              minute: 80,
              primaryPlayerId: playerAlpha2.id,
              teamId: teamAlpha.id,
            ),
          ],
        );

        final mainTable = StandingsTable(
          tournamentId: tournament.id,
          completedMatchesCount: 1,
          appliedTiebreakers: const [TiebreakerCriterion.goalDifference],
          rows: [
            StandingsRow(
              position: 1,
              teamId: teamAlpha.id,
              teamName: teamAlpha.name,
              teamShortCode: teamAlpha.shortCode,
              played: 1,
              won: 0,
              drawn: 1,
              lost: 0,
              goalsFor: 0,
              goalsAgainst: 0,
              goalDifference: 0,
              points: 1,
            ),
          ],
        );

        final result = service.calculateAll(
          tournament: tournament,
          teams: [teamAlpha],
          mainStandingsTable: mainTable,
          matches: [match],
          reports: [report],
        );

        // Player 1 expelled in latest match -> suspended
        final profileA1 = result.playerProfilesById[playerAlpha1.id]!;
        expect(profileA1.redCards, 1);
        expect(profileA1.isSuspended, isTrue);

        // Player 2 reached yellowCardSuspensionLimit (2 cards) -> suspended
        final profileA2 = result.playerProfilesById[playerAlpha2.id]!;
        expect(profileA2.yellowCards, 2);
        expect(profileA2.isSuspended, isTrue);
      },
    );

    test('Recent form bounds to last 5 matches in chronological order', () {
      final matches = List.generate(6, (i) {
        return ChampionshipMatch(
          id: 'm_$i',
          tournamentId: tournament.id,
          roundNumber: i + 1,
          roundName: 'Jornada ${i + 1}',
          homeTeamId: teamAlpha.id,
          awayTeamId: teamBeta.id,
          scheduledStartTime: DateTime(2026, 11, i + 1, 10, 0),
          status: MatchStatus.completed,
        );
      });

      // 6 reports: W, D, L, W, W, L
      final scores = [
        [2, 0], // W (oldest - should be dropped from last 5)
        [1, 1], // D
        [0, 1], // L
        [3, 1], // W
        [2, 1], // W
        [0, 2], // L (newest)
      ];

      final reports = List.generate(6, (i) {
        return DigitalMatchReport(
          matchId: 'm_$i',
          tournamentId: tournament.id,
          homeTeamId: teamAlpha.id,
          awayTeamId: teamBeta.id,
          homeScore: scores[i][0],
          awayScore: scores[i][1],
          currentPeriod: MatchPeriod.closed,
          closedAt: DateTime(2026, 11, i + 1, 12, 0),
        );
      });

      final mainTable = StandingsTable(
        tournamentId: tournament.id,
        completedMatchesCount: 6,
        appliedTiebreakers: const [TiebreakerCriterion.goalDifference],
        rows: [
          StandingsRow(
            position: 1,
            teamId: teamAlpha.id,
            teamName: teamAlpha.name,
            teamShortCode: teamAlpha.shortCode,
            played: 6,
            won: 3,
            drawn: 1,
            lost: 2,
            goalsFor: 8,
            goalsAgainst: 5,
            goalDifference: 3,
            points: 10,
          ),
        ],
      );

      final result = service.calculateAll(
        tournament: tournament,
        teams: [teamAlpha],
        mainStandingsTable: mainTable,
        matches: matches,
        reports: reports,
      );

      final teamStatsAlpha = result.teamStatsById[teamAlpha.id]!;
      expect(teamStatsAlpha.recentForm.length, 5);
      expect(teamStatsAlpha.recentForm, [
        TeamFormResult.draw,
        TeamFormResult.loss,
        TeamFormResult.win,
        TeamFormResult.win,
        TeamFormResult.loss,
      ]);
      expect(teamStatsAlpha.completedMatches.length, 6);
    });
  });
}
