import '../entities/championship_match.dart';
import '../entities/championship_tournament.dart';
import '../entities/digital_match_report.dart';
import '../entities/match_lineup_convocation.dart';
import '../entities/match_report_enums.dart';
import '../entities/player_internal_tracking.dart';
import '../entities/player_performance_profile.dart';
import '../entities/registered_player.dart';
import '../entities/standings_table.dart';
import '../entities/team_detailed_stats.dart';
import '../entities/tournament_team.dart';

/// Pure domain calculation service that derives `PlayerPerformanceProfile`
/// and `TeamDetailedStats` from tournament data, closed official reports,
/// lineups, and rosters.
class PlayerTeamStatsCalculatorService {
  const PlayerTeamStatsCalculatorService();

  /// Computes deterministic performance profiles for all enrolled players and
  /// detailed stats for all tournament teams.
  ({
    Map<String, PlayerPerformanceProfile> playerProfilesById,
    Map<String, TeamDetailedStats> teamStatsById,
  })
  calculateAll({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required StandingsTable mainStandingsTable,
    required List<ChampionshipMatch> matches,
    required List<DigitalMatchReport> reports,
    Map<String, MatchLineupConvocation> convocationsByTeamId =
        const <String, MatchLineupConvocation>{},
    Map<String, PlayerInternalTracking> trackingByPlayerId =
        const <String, PlayerInternalTracking>{},
  }) {
    final closedReports = reports.where((r) => r.isClosed).toList();

    // Map matches and closed reports by matchId
    final matchById = <String, ChampionshipMatch>{
      for (final m in matches) m.id: m,
    };
    final closedReportByMatchId = <String, DigitalMatchReport>{
      for (final r in closedReports) r.matchId: r,
    };

    // Index StandingsRow by teamId
    final standingsRowByTeamId = <String, StandingsRow>{
      for (final row in mainStandingsTable.rows) row.teamId: row,
    };

    // Track most recent closed match per team to evaluate red card suspension
    final mostRecentClosedReportByTeamId = <String, DigitalMatchReport>{};
    for (final report in closedReports) {
      final m = matchById[report.matchId];
      final matchDate =
          m?.scheduledStartTime ?? report.closedAt ?? DateTime.now();

      for (final tid in [report.homeTeamId, report.awayTeamId]) {
        final currentLatest = mostRecentClosedReportByTeamId[tid];
        if (currentLatest == null) {
          mostRecentClosedReportByTeamId[tid] = report;
        } else {
          final currDate =
              matchById[currentLatest.matchId]?.scheduledStartTime ??
              currentLatest.closedAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          if (matchDate.isAfter(currDate)) {
            mostRecentClosedReportByTeamId[tid] = report;
          }
        }
      }
    }

    final allPlayerProfiles = <String, PlayerPerformanceProfile>{};
    final allTeamStats = <String, TeamDetailedStats>{};

    for (final team in teams) {
      final teamSquadProfiles = <PlayerPerformanceProfile>[];

      // Matches involving this team
      final teamMatches =
          matches
              .where((m) => m.homeTeamId == team.id || m.awayTeamId == team.id)
              .toList()
            ..sort((a, b) {
              final dateA = a.scheduledStartTime ?? DateTime.now();
              final dateB = b.scheduledStartTime ?? DateTime.now();
              return dateA.compareTo(dateB);
            });

      final teamClosedReports =
          closedReports
              .where((r) => r.homeTeamId == team.id || r.awayTeamId == team.id)
              .toList()
            ..sort((a, b) {
              final dateA =
                  matchById[a.matchId]?.scheduledStartTime ??
                  a.closedAt ??
                  DateTime.now();
              final dateB =
                  matchById[b.matchId]?.scheduledStartTime ??
                  b.closedAt ??
                  DateTime.now();
              return dateA.compareTo(dateB);
            });

      // 1. Calculate each player's performance profile in this team
      for (final player in team.players) {
        final profile = _calculatePlayerProfile(
          tournament: tournament,
          team: team,
          player: player,
          teamClosedReports: teamClosedReports,
          matchById: matchById,
          convocation: convocationsByTeamId[team.id],
          tracking: trackingByPlayerId[player.id],
          mostRecentReport: mostRecentClosedReportByTeamId[team.id],
        );
        allPlayerProfiles[player.id] = profile;
        teamSquadProfiles.add(profile);
      }

      // Sort squad by shirtNumber ascending
      teamSquadProfiles.sort((a, b) => a.shirtNumber.compareTo(b.shirtNumber));

      // 2. Compute recent form, completed matches, and upcoming matches
      final completedMatches = <TeamMatchHistoryItem>[];
      final recentFormList = <TeamFormResult>[];

      for (final report in teamClosedReports) {
        final match = matchById[report.matchId];
        final isHome = report.homeTeamId == team.id;
        final teamScore = isHome ? report.homeScore : report.awayScore;
        final opponentScore = isHome ? report.awayScore : report.homeScore;
        final teamPenalties = isHome
            ? report.homePenaltyScore
            : report.awayPenaltyScore;
        final opponentPenalties = isHome
            ? report.awayPenaltyScore
            : report.homePenaltyScore;

        final opponentId = isHome ? report.awayTeamId : report.homeTeamId;
        final opponentTeam = teams.firstWhere(
          (t) => t.id == opponentId,
          orElse: () => TournamentTeam(
            id: opponentId,
            tournamentId: tournament.id,
            name: 'Rival',
            shortCode: 'RIV',
            primaryColorHex: 0xFF808080,
          ),
        );

        TeamFormResult result;
        if (teamScore > opponentScore) {
          result = TeamFormResult.win;
        } else if (teamScore < opponentScore) {
          result = TeamFormResult.loss;
        } else {
          // Check penalties if decisive
          if (teamPenalties != null && opponentPenalties != null) {
            if (teamPenalties > opponentPenalties) {
              result = TeamFormResult.win;
            } else if (teamPenalties < opponentPenalties) {
              result = TeamFormResult.loss;
            } else {
              result = TeamFormResult.draw;
            }
          } else {
            result = TeamFormResult.draw;
          }
        }

        recentFormList.add(result);

        completedMatches.add(
          TeamMatchHistoryItem(
            matchId: report.matchId,
            roundNumber: match?.roundNumber ?? 1,
            roundName: match?.roundName ?? 'Jornada ${match?.roundNumber ?? 1}',
            scheduledAt:
                match?.scheduledStartTime ?? report.closedAt ?? DateTime.now(),
            opponentTeamId: opponentTeam.id,
            opponentTeamName: opponentTeam.name,
            opponentShortCode: opponentTeam.shortCode,
            isHome: isHome,
            teamScore: teamScore,
            opponentScore: opponentScore,
            teamPenaltyScore: teamPenalties,
            opponentPenaltyScore: opponentPenalties,
            result: result,
          ),
        );
      }

      // Recent form takes up to last 5 matches
      final recentForm = recentFormList.length > 5
          ? recentFormList.sublist(recentFormList.length - 5)
          : recentFormList;

      // Completed matches sorted most recent first
      completedMatches.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

      // Upcoming matches (not closed)
      final upcomingMatches = <TeamUpcomingMatchItem>[];
      final unclosedMatches = teamMatches.where((m) {
        final r = closedReportByMatchId[m.id];
        return r == null || !r.isClosed;
      }).toList();

      for (final m in unclosedMatches) {
        final isHome = m.homeTeamId == team.id;
        final opponentId = isHome ? m.awayTeamId : m.homeTeamId;
        final opponentTeam = teams.firstWhere(
          (t) => t.id == opponentId,
          orElse: () => TournamentTeam(
            id: opponentId,
            tournamentId: tournament.id,
            name: 'Rival',
            shortCode: 'RIV',
            primaryColorHex: 0xFF808080,
          ),
        );

        upcomingMatches.add(
          TeamUpcomingMatchItem(
            matchId: m.id,
            roundNumber: m.roundNumber,
            roundName: m.roundName,
            scheduledAt: m.scheduledStartTime ?? DateTime.now(),
            opponentTeamId: opponentId,
            opponentTeamName: opponentTeam.name,
            opponentShortCode: opponentTeam.shortCode,
            isHome: isHome,
            venueName: m.venueId,
            pitchName: m.pitchName,
          ),
        );
      }
      upcomingMatches.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      final fallbackStandingsRow = StandingsRow(
        position: teams.indexOf(team) + 1,
        teamId: team.id,
        teamName: team.name,
        teamShortCode: team.shortCode,
        played: 0,
        won: 0,
        drawn: 0,
        lost: 0,
        goalsFor: 0,
        goalsAgainst: 0,
        goalDifference: 0,
        points: 0,
      );

      final teamStats = TeamDetailedStats(
        tournamentId: tournament.id,
        teamId: team.id,
        teamName: team.name,
        teamShortCode: team.shortCode,
        crestShape: team.crestShape,
        primaryColorHex: team.primaryColorHex,
        standingsRow: standingsRowByTeamId[team.id] ?? fallbackStandingsRow,
        recentForm: List.unmodifiable(recentForm),
        completedMatches: List.unmodifiable(completedMatches),
        upcomingMatches: List.unmodifiable(upcomingMatches),
        squadStats: List.unmodifiable(teamSquadProfiles),
      );

      allTeamStats[team.id] = teamStats;
    }

    return (playerProfilesById: allPlayerProfiles, teamStatsById: allTeamStats);
  }

  PlayerPerformanceProfile _calculatePlayerProfile({
    required ChampionshipTournament tournament,
    required TournamentTeam team,
    required RegisteredPlayer player,
    required List<DigitalMatchReport> teamClosedReports,
    required Map<String, ChampionshipMatch> matchById,
    required MatchLineupConvocation? convocation,
    required PlayerInternalTracking? tracking,
    required DigitalMatchReport? mostRecentReport,
  }) {
    var matchesPlayed = 0;
    var startsCount = 0;
    var goals = 0;
    var assists = 0;
    var yellowCards = 0;
    var redCards = 0;
    final participations = <PlayerMatchParticipation>[];

    for (final report in teamClosedReports) {
      final match = matchById[report.matchId];
      final isHome = report.homeTeamId == team.id;
      final teamScore = isHome ? report.homeScore : report.awayScore;
      final opponentScore = isHome ? report.awayScore : report.homeScore;
      final opponentId = isHome ? report.awayTeamId : report.homeTeamId;

      // Gather player match events
      var matchGoals = 0;
      var matchAssists = 0;
      var matchYellowCards = 0;
      var matchRedCards = 0;
      var enteredAsSub = false;
      var exitedAsStarter = false;

      for (final event in report.events) {
        if (event.type == MatchEventType.goal) {
          if (event.primaryPlayerId == player.id) matchGoals++;
          if (event.secondaryPlayerId == player.id) matchAssists++;
        } else if (event.type == MatchEventType.yellowCard) {
          if (event.primaryPlayerId == player.id) matchYellowCards++;
        } else if (event.type == MatchEventType.secondYellowRedCard ||
            event.type == MatchEventType.directRedCard) {
          if (event.primaryPlayerId == player.id) matchRedCards++;
        } else if (event.type == MatchEventType.substitution) {
          if (event.primaryPlayerId == player.id) {
            enteredAsSub = true;
          }
          if (event.secondaryPlayerId == player.id) {
            exitedAsStarter = true;
          }
        }
      }

      // Starter determination:
      bool wasStarter;
      if (convocation != null && convocation.starterPlayerIds.isNotEmpty) {
        wasStarter =
            convocation.isStarter(player.id) ||
            convocation.confirmedStarterPlayerIds.contains(player.id);
      } else {
        wasStarter =
            exitedAsStarter ||
            ((matchGoals > 0 ||
                    matchAssists > 0 ||
                    matchYellowCards > 0 ||
                    matchRedCards > 0) &&
                !enteredAsSub);
      }

      final participated =
          wasStarter ||
          enteredAsSub ||
          matchGoals > 0 ||
          matchAssists > 0 ||
          matchYellowCards > 0 ||
          matchRedCards > 0;

      if (participated) {
        matchesPlayed++;
        if (wasStarter) {
          startsCount++;
        }

        goals += matchGoals;
        assists += matchAssists;
        yellowCards += matchYellowCards;
        redCards += matchRedCards;

        participations.add(
          PlayerMatchParticipation(
            matchId: report.matchId,
            roundNumber: match?.roundNumber ?? 1,
            roundName: match?.roundName ?? 'Jornada ${match?.roundNumber ?? 1}',
            scheduledAt:
                match?.scheduledStartTime ?? report.closedAt ?? DateTime.now(),
            opponentTeamId: opponentId,
            opponentTeamName: 'Rival',
            opponentShortCode: 'RIV',
            isHome: isHome,
            teamScore: teamScore,
            opponentScore: opponentScore,
            wasStarter: wasStarter,
            goals: matchGoals,
            assists: matchAssists,
            yellowCards: matchYellowCards,
            redCards: matchRedCards,
          ),
        );
      }
    }

    // Sort participations chronologically descending (most recent first)
    participations.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    // Incorporate tracking baseline if tracking reports higher numbers (e.g. historical data)
    if (tracking != null) {
      if (tracking.matchesPlayed > matchesPlayed) {
        matchesPlayed = tracking.matchesPlayed;
      }
      if (tracking.goals > goals) goals = tracking.goals;
      if (tracking.assists > assists) assists = tracking.assists;
      if (tracking.yellowCards > yellowCards) {
        yellowCards = tracking.yellowCards;
      }
      if (tracking.redCards > redCards) redCards = tracking.redCards;
    }

    // Disciplinary status evaluation per FR-001:
    final expelledInLatest =
        mostRecentReport != null &&
        mostRecentReport.isPlayerExpelled(player.id);

    final limit = tournament.rules.yellowCardSuspensionLimit;
    final yellowLimitReached =
        limit > 0 && yellowCards > 0 && (yellowCards % limit == 0);

    final hasPendingSuspension =
        tracking != null &&
        (tracking.pendingSuspensionMatches > 0 || tracking.isSuspended(limit));

    final isSuspended =
        !player.isEligible ||
        hasPendingSuspension ||
        expelledInLatest ||
        yellowLimitReached;

    return PlayerPerformanceProfile(
      playerId: player.id,
      tournamentId: tournament.id,
      fullName: player.fullName,
      shirtNumber: player.shirtNumber,
      position: player.position,
      teamId: team.id,
      teamName: team.name,
      teamShortCode: team.shortCode,
      matchesPlayed: matchesPlayed,
      startsCount: startsCount,
      goals: goals,
      assists: assists,
      yellowCards: yellowCards,
      redCards: redCards,
      isSuspended: isSuspended,
      matchParticipations: List.unmodifiable(participations),
    );
  }
}
