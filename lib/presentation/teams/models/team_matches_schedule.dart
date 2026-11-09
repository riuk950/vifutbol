import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';

/// Semantic outcome of a completed match evaluated from the perspective of a specific team.
enum TeamMatchOutcome { win, draw, loss }

/// Enriched schedule match item containing the match and resolved team entities.
class TeamScheduledMatchItem {
  final ChampionshipMatch match;
  final TournamentTeam? homeTeam;
  final TournamentTeam? awayTeam;
  final bool isHome;
  final TeamMatchOutcome? outcome;

  const TeamScheduledMatchItem({
    required this.match,
    required this.homeTeam,
    required this.awayTeam,
    required this.isHome,
    this.outcome,
  });

  TournamentTeam? get opponentTeam => isHome ? awayTeam : homeTeam;
  bool get isCompleted => match.status == MatchStatus.completed;
}

/// Immutable presentation model for the team matches tab schedule.
class TeamMatchesSchedule {
  final String teamId;
  final List<TeamScheduledMatchItem> upcomingMatches;
  final List<TeamScheduledMatchItem> completedMatches;

  const TeamMatchesSchedule({
    required this.teamId,
    required this.upcomingMatches,
    required this.completedMatches,
  });

  bool get hasAnyMatches =>
      upcomingMatches.isNotEmpty || completedMatches.isNotEmpty;
  bool get hasUpcomingMatches => upcomingMatches.isNotEmpty;
  bool get hasCompletedMatches => completedMatches.isNotEmpty;

  /// Pure deterministic factory computing the schedule from the catalogs.
  factory TeamMatchesSchedule.fromCatalog({
    required String teamId,
    required List<TournamentTeam> teams,
    required List<ChampionshipMatch> matches,
  }) {
    final teamsMap = {for (final t in teams) t.id: t};

    final teamMatches = matches
        .where(
          (m) =>
              (m.homeTeamId == teamId || m.awayTeamId == teamId) &&
              m.status != MatchStatus.cancelled,
        )
        .toList();

    // 1. Upcoming matches: inProgress, scheduled, pendingSchedule
    final upcomingCandidates =
        teamMatches.where((m) {
          return m.status == MatchStatus.inProgress ||
              m.status == MatchStatus.scheduled ||
              m.status == MatchStatus.pendingSchedule;
        }).toList()..sort((a, b) {
          // Priority 1: inProgress first
          if (a.status == MatchStatus.inProgress &&
              b.status != MatchStatus.inProgress) {
            return -1;
          }
          if (b.status == MatchStatus.inProgress &&
              a.status != MatchStatus.inProgress) {
            return 1;
          }

          // Priority 2: scheduled with startTime asc
          if (a.status == MatchStatus.scheduled &&
              b.status == MatchStatus.scheduled) {
            if (a.scheduledStartTime != null && b.scheduledStartTime != null) {
              final comp = a.scheduledStartTime!.compareTo(
                b.scheduledStartTime!,
              );
              if (comp != 0) return comp;
            } else if (a.scheduledStartTime != null) {
              return -1;
            } else if (b.scheduledStartTime != null) {
              return 1;
            }
          } else if (a.status == MatchStatus.scheduled &&
              b.status == MatchStatus.pendingSchedule) {
            return -1;
          } else if (b.status == MatchStatus.scheduled &&
              a.status == MatchStatus.pendingSchedule) {
            return 1;
          }

          // Priority 3: roundNumber asc
          final roundComp = a.roundNumber.compareTo(b.roundNumber);
          if (roundComp != 0) return roundComp;

          return a.id.compareTo(b.id);
        });

    final upcomingItems = upcomingCandidates.map((m) {
      final isHome = m.homeTeamId == teamId;
      return TeamScheduledMatchItem(
        match: m,
        homeTeam: teamsMap[m.homeTeamId],
        awayTeam: teamsMap[m.awayTeamId],
        isHome: isHome,
        outcome: null,
      );
    }).toList();

    // 2. Completed matches: completed status, sorted desc by scheduledStartTime then roundNumber
    final completedCandidates =
        teamMatches.where((m) => m.status == MatchStatus.completed).toList()
          ..sort((a, b) {
            if (a.scheduledStartTime != null && b.scheduledStartTime != null) {
              final comp = b.scheduledStartTime!.compareTo(
                a.scheduledStartTime!,
              );
              if (comp != 0) return comp;
            } else if (a.scheduledStartTime != null) {
              return -1;
            } else if (b.scheduledStartTime != null) {
              return 1;
            }

            final roundComp = b.roundNumber.compareTo(a.roundNumber);
            if (roundComp != 0) return roundComp;

            return b.id.compareTo(a.id);
          });

    final completedItems = completedCandidates.map((m) {
      final isHome = m.homeTeamId == teamId;
      final teamGoals = isHome ? (m.homeScore ?? 0) : (m.awayScore ?? 0);
      final oppGoals = isHome ? (m.awayScore ?? 0) : (m.homeScore ?? 0);

      final TeamMatchOutcome outcome;
      if (teamGoals > oppGoals) {
        outcome = TeamMatchOutcome.win;
      } else if (teamGoals == oppGoals) {
        outcome = TeamMatchOutcome.draw;
      } else {
        outcome = TeamMatchOutcome.loss;
      }

      return TeamScheduledMatchItem(
        match: m,
        homeTeam: teamsMap[m.homeTeamId],
        awayTeam: teamsMap[m.awayTeamId],
        isHome: isHome,
        outcome: outcome,
      );
    }).toList();

    return TeamMatchesSchedule(
      teamId: teamId,
      upcomingMatches: List.unmodifiable(upcomingItems),
      completedMatches: List.unmodifiable(completedItems),
    );
  }
}
