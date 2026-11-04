import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/match_event.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/services/sports_rankings_calculator_service.dart';

void main() {
  group('SportsRankingsCalculatorService Unit Tests', () {
    const calculator = SportsRankingsCalculatorService();
    final baseDate = DateTime(2026, 11, 4);

    final tournament = ChampionshipTournament(
      id: 't-1',
      name: 'Liga Relámpago',
      category: 'Libre',
      startDate: baseDate,
      endDate: baseDate.add(const Duration(days: 30)),
      format: TournamentFormat.league,
      status: TournamentStatus.inProgress,
      updatedAt: baseDate,
    );

    final teamA = TournamentTeam(
      id: 'team-a',
      tournamentId: 't-1',
      name: 'Atlético Norte',
      shortCode: 'ATN',
      eligibilityStatus: TeamEligibilityStatus.eligible,
      players: const [
        RegisteredPlayer(
          id: 'p-1',
          fullName: 'Carlos Valderrama',
          documentId: '1001',
          shirtNumber: 10,
          position: PlayerPosition.midfielder,
        ),
        RegisteredPlayer(
          id: 'p-2',
          fullName: 'Radamel Falcao',
          documentId: '1002',
          shirtNumber: 9,
          position: PlayerPosition.forward,
        ),
      ],
    );

    final teamB = TournamentTeam(
      id: 'team-b',
      tournamentId: 't-1',
      name: 'Deportivo Sur',
      shortCode: 'DPS',
      eligibilityStatus: TeamEligibilityStatus.eligible,
      players: const [
        RegisteredPlayer(
          id: 'p-3',
          fullName: 'James Rodríguez',
          documentId: '2001',
          shirtNumber: 10,
          position: PlayerPosition.midfielder,
        ),
      ],
    );

    test(
      'US3 Scenario 1 & 2: Computes Top Scorers (with assists tiebreaker), Top Assists, and Fair Play (-1/-3/-3)',
      () {
        // Falcao scores 2 goals (1 assisted by Valderrama).
        // James scores 2 goals AND has 1 assist -> James ranks #1 in Goleadores due to assists tiebreaker!
        // Team A receives 1 standalone yellow (-1) and 1 direct red (-3) = -4 pts.
        // Team B receives 1 double-yellow expulsion (first yellow -1, second yellow linked to secondYellowRedCard -3) = -4 pts,
        // but Team B has 0 direct red cards so Team B ranks above Team A on directRedCards tiebreaker.
        final report = DigitalMatchReport(
          matchId: 'm-1',
          tournamentId: 't-1',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          homeScore: 2,
          awayScore: 2,
          currentPeriod: MatchPeriod.closed,
          closedAt: baseDate,
          events: [
            MatchEvent(
              id: 'g-1',
              matchId: 'm-1',
              type: MatchEventType.goal,
              minute: 12,
              teamId: 'team-a',
              primaryPlayerId: 'p-2',
              primaryPlayerName: 'Radamel Falcao',
              primaryPlayerShirtNumber: 9,
              secondaryPlayerId: 'p-1',
              secondaryPlayerName: 'Carlos Valderrama',
              secondaryPlayerShirtNumber: 10,
              createdAt: baseDate,
            ),
            MatchEvent(
              id: 'g-2',
              matchId: 'm-1',
              type: MatchEventType.goal,
              minute: 34,
              teamId: 'team-a',
              primaryPlayerId: 'p-2',
              primaryPlayerName: 'Radamel Falcao',
              primaryPlayerShirtNumber: 9,
              createdAt: baseDate,
            ),
            MatchEvent(
              id: 'g-3',
              matchId: 'm-1',
              type: MatchEventType.goal,
              minute: 50,
              teamId: 'team-b',
              primaryPlayerId: 'p-3',
              primaryPlayerName: 'James Rodríguez',
              primaryPlayerShirtNumber: 10,
              createdAt: baseDate,
            ),
            MatchEvent(
              id: 'g-4',
              matchId: 'm-1',
              type: MatchEventType.goal,
              minute: 75,
              teamId: 'team-b',
              primaryPlayerId: 'p-3',
              primaryPlayerName: 'James Rodríguez',
              primaryPlayerShirtNumber: 10,
              secondaryPlayerId: 'p-1',
              secondaryPlayerName: 'Carlos Valderrama',
              secondaryPlayerShirtNumber: 10,
              createdAt: baseDate,
            ),
            // Cards: Team A gets 1 yellow (-1) and 1 direct red (-3) = -4
            MatchEvent(
              id: 'c-1',
              matchId: 'm-1',
              type: MatchEventType.yellowCard,
              minute: 20,
              teamId: 'team-a',
              primaryPlayerId: 'p-1',
              createdAt: baseDate,
            ),
            MatchEvent(
              id: 'c-2',
              matchId: 'm-1',
              type: MatchEventType.directRedCard,
              minute: 80,
              teamId: 'team-a',
              primaryPlayerId: 'p-2',
              createdAt: baseDate,
            ),
            // Team B gets 1 yellow (-1) -> total -1 (ranks #1 in Fair Play!)
            MatchEvent(
              id: 'c-3',
              matchId: 'm-1',
              type: MatchEventType.yellowCard,
              minute: 60,
              teamId: 'team-b',
              primaryPlayerId: 'p-3',
              createdAt: baseDate,
            ),
          ],
        );

        final bundle = calculator.calculateRankings(
          tournament: tournament,
          teams: [teamA, teamB],
          closedReports: [report],
        );

        expect(bundle.topScorers.length, 2);
        expect(bundle.topScorers[0].goals, 2);
        expect(bundle.topScorers[1].goals, 2);

        // Top Assists: Carlos Valderrama has 2 assists
        expect(bundle.topAssists.length, 1);
        expect(bundle.topAssists.first.playerId, 'p-1');
        expect(bundle.topAssists.first.assists, 2);

        // Fair Play: Team B (-1) ranks #1, Team A (-4) ranks #2
        expect(bundle.teamFairPlay.length, 2);
        expect(bundle.teamFairPlay[0].teamId, 'team-b');
        expect(bundle.teamFairPlay[0].penaltyPoints, -1);
        expect(bundle.teamFairPlay[1].teamId, 'team-a');
        expect(bundle.teamFairPlay[1].penaltyPoints, -4);
      },
    );
  });
}
