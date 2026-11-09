import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/presentation/teams/models/team_match_summary.dart';

void main() {
  group('TeamMatchSummary.fromCatalog', () {
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

    final tournament = ChampionshipTournament(
      id: 'tour-1',
      name: 'Liga de Apertura 2026',
      category: 'Primera División',
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 6, 30),
      format: TournamentFormat.league,
      status: TournamentStatus.inProgress,
      updatedAt: DateTime(2026, 3, 1),
    );

    test('returns null matches when team has no matches in catalog', () {
      final summary = TeamMatchSummary.fromCatalog(
        teamId: 'team-a',
        teams: [teamA, teamB],
        tournaments: [tournament],
        matches: [],
      );

      expect(summary.hasTeam, isTrue);
      expect(summary.team?.id, 'team-a');
      expect(summary.tournament?.name, 'Liga de Apertura 2026');
      expect(summary.hasLastPlayedMatch, isFalse);
      expect(summary.hasNextScheduledMatch, isFalse);
    });

    test('resolves last played match (completed status with latest date)', () {
      final match1 = ChampionshipMatch(
        id: 'm1',
        tournamentId: 'tour-1',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'team-a',
        awayTeamId: 'team-b',
        status: MatchStatus.completed,
        scheduledStartTime: DateTime(2026, 3, 5, 14, 0),
        homeScore: 2,
        awayScore: 1,
      );

      final match2 = ChampionshipMatch(
        id: 'm2',
        tournamentId: 'tour-1',
        roundNumber: 2,
        roundName: 'Jornada 2',
        homeTeamId: 'team-c',
        awayTeamId: 'team-a',
        status: MatchStatus.completed,
        scheduledStartTime: DateTime(2026, 3, 12, 16, 0),
        homeScore: 0,
        awayScore: 3,
      );

      final summary = TeamMatchSummary.fromCatalog(
        teamId: 'team-a',
        teams: [teamA, teamB, teamC],
        tournaments: [tournament],
        matches: [match1, match2],
      );

      expect(summary.hasLastPlayedMatch, isTrue);
      expect(summary.lastPlayedMatch?.id, 'm2');
      expect(summary.isLastMatchHome, isFalse);
      expect(summary.lastMatchOpponent?.id, 'team-c');
      expect(summary.lastPlayedMatch?.awayScore, 3);
    });

    test(
      'prioritizes inProgress over scheduled and pendingSchedule for next match',
      () {
        final inProgressMatch = ChampionshipMatch(
          id: 'm-live',
          tournamentId: 'tour-1',
          roundNumber: 3,
          roundName: 'Jornada 3',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          status: MatchStatus.inProgress,
          scheduledStartTime: DateTime(2026, 3, 19, 15, 0),
        );

        final scheduledMatch = ChampionshipMatch(
          id: 'm-sched',
          tournamentId: 'tour-1',
          roundNumber: 4,
          roundName: 'Jornada 4',
          homeTeamId: 'team-c',
          awayTeamId: 'team-a',
          status: MatchStatus.scheduled,
          scheduledStartTime: DateTime(2026, 3, 26, 16, 0),
        );

        final summary = TeamMatchSummary.fromCatalog(
          teamId: 'team-a',
          teams: [teamA, teamB, teamC],
          tournaments: [tournament],
          matches: [scheduledMatch, inProgressMatch],
        );

        expect(summary.hasNextScheduledMatch, isTrue);
        expect(summary.nextScheduledMatch?.id, 'm-live');
        expect(summary.isNextMatchHome, isTrue);
        expect(summary.nextMatchOpponent?.id, 'team-b');
      },
    );

    test('orders scheduled matches by scheduledStartTime ascending', () {
      final earlyMatch = ChampionshipMatch(
        id: 'm-early',
        tournamentId: 'tour-1',
        roundNumber: 3,
        roundName: 'Jornada 3',
        homeTeamId: 'team-a',
        awayTeamId: 'team-b',
        status: MatchStatus.scheduled,
        scheduledStartTime: DateTime(2026, 3, 20, 10, 0),
      );

      final lateMatch = ChampionshipMatch(
        id: 'm-late',
        tournamentId: 'tour-1',
        roundNumber: 4,
        roundName: 'Jornada 4',
        homeTeamId: 'team-c',
        awayTeamId: 'team-a',
        status: MatchStatus.scheduled,
        scheduledStartTime: DateTime(2026, 3, 27, 10, 0),
      );

      final summary = TeamMatchSummary.fromCatalog(
        teamId: 'team-a',
        teams: [teamA, teamB, teamC],
        tournaments: [tournament],
        matches: [lateMatch, earlyMatch],
      );

      expect(summary.nextScheduledMatch?.id, 'm-early');
    });

    test(
      'resolves pendingSchedule matches by roundNumber when no dates exist',
      () {
        final pendingRound3 = ChampionshipMatch(
          id: 'm-pend-3',
          tournamentId: 'tour-1',
          roundNumber: 3,
          roundName: 'Jornada 3',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          status: MatchStatus.pendingSchedule,
        );

        final pendingRound5 = ChampionshipMatch(
          id: 'm-pend-5',
          tournamentId: 'tour-1',
          roundNumber: 5,
          roundName: 'Jornada 5',
          homeTeamId: 'team-c',
          awayTeamId: 'team-a',
          status: MatchStatus.pendingSchedule,
        );

        final summary = TeamMatchSummary.fromCatalog(
          teamId: 'team-a',
          teams: [teamA, teamB, teamC],
          tournaments: [tournament],
          matches: [pendingRound5, pendingRound3],
        );

        expect(summary.nextScheduledMatch?.id, 'm-pend-3');
      },
    );

    test('excludes cancelled matches from upcoming match candidates', () {
      final cancelledMatch = ChampionshipMatch(
        id: 'm-canc',
        tournamentId: 'tour-1',
        roundNumber: 3,
        roundName: 'Jornada 3',
        homeTeamId: 'team-a',
        awayTeamId: 'team-b',
        status: MatchStatus.cancelled,
        scheduledStartTime: DateTime(2026, 3, 20, 10, 0),
      );

      final summary = TeamMatchSummary.fromCatalog(
        teamId: 'team-a',
        teams: [teamA, teamB],
        tournaments: [tournament],
        matches: [cancelledMatch],
      );

      expect(summary.hasNextScheduledMatch, isFalse);
    });
  });
}
