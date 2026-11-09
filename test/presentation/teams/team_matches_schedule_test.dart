import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/presentation/teams/models/team_matches_schedule.dart';

void main() {
  group('TeamMatchesSchedule.fromCatalog', () {
    final teamA = TournamentTeam(
      id: 'team-a',
      tournamentId: 'tour-1',
      name: 'Atlético Norte FC',
      shortCode: 'ATN',
      crestShape: TeamCrestShape.shield,
      primaryColorHex: 0xFF00E676,
      secondaryColorHex: 0xFF0A0E17,
      eligibilityStatus: TeamEligibilityStatus.eligible,
    );

    final teamB = TournamentTeam(
      id: 'team-b',
      tournamentId: 'tour-1',
      name: 'Deportivo Sur',
      shortCode: 'DPS',
      crestShape: TeamCrestShape.circle,
      primaryColorHex: 0xFF38BDF8,
      secondaryColorHex: 0xFF0A0E17,
      eligibilityStatus: TeamEligibilityStatus.eligible,
    );

    final teamC = TournamentTeam(
      id: 'team-c',
      tournamentId: 'tour-1',
      name: 'Real Oriente',
      shortCode: 'ROF',
      crestShape: TeamCrestShape.diamond,
      primaryColorHex: 0xFFEAB308,
      secondaryColorHex: 0xFF0A0E17,
      eligibilityStatus: TeamEligibilityStatus.eligible,
    );

    final teamD = TournamentTeam(
      id: 'team-d',
      tournamentId: 'tour-1',
      name: 'Club Poniente',
      shortCode: 'CPN',
      crestShape: TeamCrestShape.hexagon,
      primaryColorHex: 0xFFEF4444,
      secondaryColorHex: 0xFF0A0E17,
      eligibilityStatus: TeamEligibilityStatus.eligible,
    );

    test('returns empty lists when team has no matches in catalog', () {
      final schedule = TeamMatchesSchedule.fromCatalog(
        teamId: 'team-a',
        teams: [teamA, teamB],
        matches: [],
      );

      expect(schedule.teamId, 'team-a');
      expect(schedule.hasAnyMatches, isFalse);
      expect(schedule.hasUpcomingMatches, isFalse);
      expect(schedule.hasCompletedMatches, isFalse);
      expect(schedule.upcomingMatches, isEmpty);
      expect(schedule.completedMatches, isEmpty);
    });

    test('filters exclusively by team and excludes matches of other teams', () {
      final matchOther = ChampionshipMatch(
        id: 'm-other',
        tournamentId: 'tour-1',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'team-c',
        awayTeamId: 'team-d',
        status: MatchStatus.completed,
        scheduledStartTime: DateTime(2026, 3, 5, 14, 0),
        homeScore: 1,
        awayScore: 0,
      );

      final matchTeamA = ChampionshipMatch(
        id: 'm-a',
        tournamentId: 'tour-1',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'team-a',
        awayTeamId: 'team-b',
        status: MatchStatus.completed,
        scheduledStartTime: DateTime(2026, 3, 5, 16, 0),
        homeScore: 2,
        awayScore: 1,
      );

      final schedule = TeamMatchesSchedule.fromCatalog(
        teamId: 'team-a',
        teams: [teamA, teamB, teamC, teamD],
        matches: [matchOther, matchTeamA],
      );

      expect(schedule.completedMatches.length, 1);
      expect(schedule.completedMatches.first.match.id, 'm-a');
      expect(schedule.upcomingMatches, isEmpty);
    });

    test('excludes cancelled matches from upcoming and completed lists', () {
      final matchCancelled = ChampionshipMatch(
        id: 'm-cancelled',
        tournamentId: 'tour-1',
        roundNumber: 2,
        roundName: 'Jornada 2',
        homeTeamId: 'team-a',
        awayTeamId: 'team-b',
        status: MatchStatus.cancelled,
        scheduledStartTime: DateTime(2026, 3, 12, 14, 0),
      );

      final schedule = TeamMatchesSchedule.fromCatalog(
        teamId: 'team-a',
        teams: [teamA, teamB],
        matches: [matchCancelled],
      );

      expect(schedule.hasAnyMatches, isFalse);
    });

    test(
      'sorts upcomingMatches chronologically: inProgress > scheduled asc > pendingSchedule asc',
      () {
        final pendingMatch = ChampionshipMatch(
          id: 'm-pending',
          tournamentId: 'tour-1',
          roundNumber: 5,
          roundName: 'Jornada 5',
          homeTeamId: 'team-a',
          awayTeamId: 'team-d',
          status: MatchStatus.pendingSchedule,
        );

        final scheduledMatchLater = ChampionshipMatch(
          id: 'm-later',
          tournamentId: 'tour-1',
          roundNumber: 4,
          roundName: 'Jornada 4',
          homeTeamId: 'team-c',
          awayTeamId: 'team-a',
          status: MatchStatus.scheduled,
          scheduledStartTime: DateTime(2026, 3, 25, 18, 0),
        );

        final scheduledMatchEarlier = ChampionshipMatch(
          id: 'm-earlier',
          tournamentId: 'tour-1',
          roundNumber: 3,
          roundName: 'Jornada 3',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          status: MatchStatus.scheduled,
          scheduledStartTime: DateTime(2026, 3, 18, 14, 0),
        );

        final inProgressMatch = ChampionshipMatch(
          id: 'm-live',
          tournamentId: 'tour-1',
          roundNumber: 2,
          roundName: 'Jornada 2',
          homeTeamId: 'team-b',
          awayTeamId: 'team-a',
          status: MatchStatus.inProgress,
          scheduledStartTime: DateTime(2026, 3, 11, 10, 0),
          homeScore: 0,
          awayScore: 0,
        );

        final schedule = TeamMatchesSchedule.fromCatalog(
          teamId: 'team-a',
          teams: [teamA, teamB, teamC, teamD],
          matches: [
            pendingMatch,
            scheduledMatchLater,
            scheduledMatchEarlier,
            inProgressMatch,
          ],
        );

        expect(schedule.upcomingMatches.length, 4);
        expect(schedule.upcomingMatches[0].match.id, 'm-live');
        expect(schedule.upcomingMatches[1].match.id, 'm-earlier');
        expect(schedule.upcomingMatches[2].match.id, 'm-later');
        expect(schedule.upcomingMatches[3].match.id, 'm-pending');
        expect(schedule.upcomingMatches[3].isHome, isTrue);
        expect(schedule.upcomingMatches[2].isHome, isFalse);
        expect(schedule.upcomingMatches[2].opponentTeam?.id, 'team-c');
      },
    );

    test(
      'sorts completedMatches descending by scheduledStartTime and computes win, draw, loss',
      () {
        // Team A as home: win 3 - 1
        final matchWinHome = ChampionshipMatch(
          id: 'm-win-home',
          tournamentId: 'tour-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          status: MatchStatus.completed,
          scheduledStartTime: DateTime(2026, 3, 1, 10, 0),
          homeScore: 3,
          awayScore: 1,
        );

        // Team A as away: loss 2 - 0 (awayScore 0 < homeScore 2)
        final matchLossAway = ChampionshipMatch(
          id: 'm-loss-away',
          tournamentId: 'tour-1',
          roundNumber: 2,
          roundName: 'Jornada 2',
          homeTeamId: 'team-c',
          awayTeamId: 'team-a',
          status: MatchStatus.completed,
          scheduledStartTime: DateTime(2026, 3, 8, 12, 0),
          homeScore: 2,
          awayScore: 0,
        );

        // Team A as home: draw 1 - 1
        final matchDrawHome = ChampionshipMatch(
          id: 'm-draw-home',
          tournamentId: 'tour-1',
          roundNumber: 3,
          roundName: 'Jornada 3',
          homeTeamId: 'team-a',
          awayTeamId: 'team-d',
          status: MatchStatus.completed,
          scheduledStartTime: DateTime(2026, 3, 15, 14, 0),
          homeScore: 1,
          awayScore: 1,
        );

        // Team A as away: win 1 - 2 (awayScore 2 > homeScore 1) - most recent
        final matchWinAway = ChampionshipMatch(
          id: 'm-win-away',
          tournamentId: 'tour-1',
          roundNumber: 4,
          roundName: 'Jornada 4',
          homeTeamId: 'team-b',
          awayTeamId: 'team-a',
          status: MatchStatus.completed,
          scheduledStartTime: DateTime(2026, 3, 22, 16, 0),
          homeScore: 1,
          awayScore: 2,
        );

        final schedule = TeamMatchesSchedule.fromCatalog(
          teamId: 'team-a',
          teams: [teamA, teamB, teamC, teamD],
          matches: [matchWinHome, matchLossAway, matchDrawHome, matchWinAway],
        );

        expect(schedule.completedMatches.length, 4);
        // Descending order: m-win-away (Mar 22) > m-draw-home (Mar 15) > m-loss-away (Mar 8) > m-win-home (Mar 1)
        expect(schedule.completedMatches[0].match.id, 'm-win-away');
        expect(schedule.completedMatches[0].outcome, TeamMatchOutcome.win);
        expect(schedule.completedMatches[0].isHome, isFalse);
        expect(schedule.completedMatches[0].opponentTeam?.id, 'team-b');

        expect(schedule.completedMatches[1].match.id, 'm-draw-home');
        expect(schedule.completedMatches[1].outcome, TeamMatchOutcome.draw);
        expect(schedule.completedMatches[1].isHome, isTrue);

        expect(schedule.completedMatches[2].match.id, 'm-loss-away');
        expect(schedule.completedMatches[2].outcome, TeamMatchOutcome.loss);
        expect(schedule.completedMatches[2].isHome, isFalse);

        expect(schedule.completedMatches[3].match.id, 'm-win-home');
        expect(schedule.completedMatches[3].outcome, TeamMatchOutcome.win);
        expect(schedule.completedMatches[3].isHome, isTrue);
      },
    );
  });
}
