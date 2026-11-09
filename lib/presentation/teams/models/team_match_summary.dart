import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';

/// Immutable presentation projection containing resolved tournament, opponent,
/// and match details for a specific team.
class TeamMatchSummary {
  final TournamentTeam? team;
  final ChampionshipTournament? tournament;
  final ChampionshipMatch? lastPlayedMatch;
  final TournamentTeam? lastMatchOpponent;
  final bool isLastMatchHome;
  final ChampionshipMatch? nextScheduledMatch;
  final TournamentTeam? nextMatchOpponent;
  final bool isNextMatchHome;

  const TeamMatchSummary({
    required this.team,
    required this.tournament,
    this.lastPlayedMatch,
    this.lastMatchOpponent,
    this.isLastMatchHome = true,
    this.nextScheduledMatch,
    this.nextMatchOpponent,
    this.isNextMatchHome = true,
  });

  bool get hasTeam => team != null;
  bool get hasLastPlayedMatch => lastPlayedMatch != null;
  bool get hasNextScheduledMatch => nextScheduledMatch != null;

  /// Pure deterministic factory computing the last played match and next scheduled match
  /// from the catalog of teams, tournaments, and matches.
  factory TeamMatchSummary.fromCatalog({
    required String teamId,
    required List<TournamentTeam> teams,
    required List<ChampionshipTournament> tournaments,
    required List<ChampionshipMatch> matches,
  }) {
    final teamsMap = {for (final t in teams) t.id: t};
    final targetTeam = teamsMap[teamId];

    final targetTournament = targetTeam != null
        ? tournaments.where((t) => t.id == targetTeam.tournamentId).firstOrNull
        : null;

    final teamMatches = matches
        .where((m) => m.homeTeamId == teamId || m.awayTeamId == teamId)
        .toList();

    // 1. Last Played Match: completed status, sorted by scheduledStartTime desc, then roundNumber desc
    final completedMatches =
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

    final lastMatch = completedMatches.firstOrNull;
    final isLastHome = lastMatch?.homeTeamId == teamId;
    final lastOpponent = lastMatch != null
        ? teamsMap[isLastHome ? lastMatch.awayTeamId : lastMatch.homeTeamId]
        : null;

    // 2. Next Scheduled Match: inProgress, scheduled, pendingSchedule (exclude cancelled & completed)
    final upcomingCandidates =
        teamMatches.where((m) {
          return m.status == MatchStatus.inProgress ||
              m.status == MatchStatus.scheduled ||
              m.status == MatchStatus.pendingSchedule;
        }).toList()..sort((a, b) {
          // Priority 1: inProgress
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

    final nextMatch = upcomingCandidates.firstOrNull;
    final isNextHome = nextMatch?.homeTeamId == teamId;
    final nextOpponent = nextMatch != null
        ? teamsMap[isNextHome ? nextMatch.awayTeamId : nextMatch.homeTeamId]
        : null;

    return TeamMatchSummary(
      team: targetTeam,
      tournament: targetTournament,
      lastPlayedMatch: lastMatch,
      lastMatchOpponent: lastOpponent,
      isLastMatchHome: isLastHome,
      nextScheduledMatch: nextMatch,
      nextMatchOpponent: nextOpponent,
      isNextMatchHome: isNextHome,
    );
  }
}
