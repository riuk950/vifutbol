import '../entities/championship_match.dart';
import '../entities/championship_tournament.dart';
import '../entities/digital_match_report.dart';
import '../entities/match_enums.dart';
import '../entities/match_report_enums.dart';
import '../entities/standings_table.dart';
import '../entities/tournament_enums.dart';
import '../entities/tournament_team.dart';

/// Pure domain service that deterministically calculates league and group-stage
/// standings tables and resolves ties using the tournament's configured tiebreaker hierarchy.
class StandingsCalculatorService {
  const StandingsCalculatorService();

  /// Computes a deterministic [StandingsTable] for a league or specific group.
  ///
  /// Only matches with [MatchStatus.completed] and non-null scores are counted (`FR-001`).
  /// Points are awarded according to [tournament.rules] (`FR-002`).
  /// Ties in points are resolved strictly in [tournament.rules.tiebreakerOrder] (`FR-003`).
  StandingsTable calculateTable({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required List<ChampionshipMatch> matches,
    required List<DigitalMatchReport> closedReports,
    String? groupName,
  }) {
    final rules = tournament.rules;
    final teamIds = teams.map((t) => t.id).toSet();

    // Filter only completed matches belonging to this tournament, group (if specified),
    // and involving the provided teams.
    final completedMatches = matches.where((m) {
      if (m.tournamentId != tournament.id) return false;
      if (m.status != MatchStatus.completed) return false;
      if (m.homeScore == null || m.awayScore == null) return false;
      if (!teamIds.contains(m.homeTeamId) || !teamIds.contains(m.awayTeamId)) {
        return false;
      }
      if (groupName != null &&
          m.groupName != null &&
          m.groupName != groupName) {
        return false;
      }
      return true;
    }).toList();

    final completedMatchIds = completedMatches.map((m) => m.id).toSet();

    // Accumulators per team
    final stats = <String, _MutableTeamStanding>{
      for (final team in teams) team.id: _MutableTeamStanding(team: team),
    };

    for (final match in completedMatches) {
      final home = stats[match.homeTeamId];
      final away = stats[match.awayTeamId];
      if (home == null || away == null) continue;

      final hGoals = match.homeScore!;
      final aGoals = match.awayScore!;

      home.played += 1;
      away.played += 1;
      home.goalsFor += hGoals;
      home.goalsAgainst += aGoals;
      away.goalsFor += aGoals;
      away.goalsAgainst += hGoals;

      if (hGoals > aGoals) {
        home.won += 1;
        home.points += rules.pointsForWin;
        away.lost += 1;
        away.points += rules.pointsForLoss;
      } else if (hGoals < aGoals) {
        away.won += 1;
        away.points += rules.pointsForWin;
        home.lost += 1;
        home.points += rules.pointsForLoss;
      } else {
        home.drawn += 1;
        away.drawn += 1;
        home.points += rules.pointsForDraw;
        away.points += rules.pointsForDraw;
      }
    }

    // Aggregate Fair Play cards from closed match reports for these teams/matches
    for (final report in closedReports) {
      if (!report.isClosed) continue;
      if (report.tournamentId != tournament.id) continue;
      if (completedMatchIds.isNotEmpty &&
          !completedMatchIds.contains(report.matchId)) {
        // Also allow reports whose matchId is among completedMatches or teams in this group
        if (!teamIds.contains(report.homeTeamId) ||
            !teamIds.contains(report.awayTeamId)) {
          continue;
        }
      }

      // Identify yellow cards that triggered a secondYellowRedCard so we don't double-count
      // the second yellow as -1 in addition to the -3 of secondYellowRedCard.
      final linkedYellowIds = report.events
          .where(
            (e) =>
                e.type == MatchEventType.secondYellowRedCard &&
                e.linkedParentEventId != null,
          )
          .map((e) => e.linkedParentEventId!)
          .toSet();

      for (final event in report.events) {
        final teamStat = stats[event.teamId];
        if (teamStat == null) continue;

        if (event.type == MatchEventType.yellowCard &&
            !linkedYellowIds.contains(event.id)) {
          teamStat.yellowCards += 1;
        } else if (event.type == MatchEventType.secondYellowRedCard) {
          teamStat.secondYellowRedCards += 1;
        } else if (event.type == MatchEventType.directRedCard) {
          teamStat.directRedCards += 1;
        }
      }
    }

    final mutableRows = stats.values.toList();

    // Sort deterministically
    mutableRows.sort((a, b) {
      // 1. Primary criterion: Total Points (descending)
      final pointsCmp = b.points.compareTo(a.points);
      if (pointsCmp != 0) return pointsCmp;

      // 2. Configured hierarchical tiebreakers
      for (final criterion in rules.tiebreakerOrder) {
        final cmp = _compareByCriterion(
          criterion: criterion,
          a: a,
          b: b,
          completedMatches: completedMatches,
          pointsForWin: rules.pointsForWin,
          pointsForDraw: rules.pointsForDraw,
          pointsForLoss: rules.pointsForLoss,
        );
        if (cmp != 0) return cmp;
      }

      // 3. Deterministic alphabetical fallback
      return a.team.normalizedName.compareTo(b.team.normalizedName);
    });

    // Determine qualification slots:
    // - For group stage: advancingPerGroup
    // - For general league: top 4 (or top half if < 4 teams)
    final qualifyingSlots =
        tournament.format == TournamentFormat.mixedGroupsAndKnockout
        ? rules.groupStageConfig.advancingPerGroup
        : (mutableRows.length >= 4 ? 4 : (mutableRows.length >= 2 ? 1 : 0));

    final rows = <StandingsRow>[];
    for (var i = 0; i < mutableRows.length; i++) {
      final current = mutableRows[i];
      var tiedOnAll = false;

      if (i > 0) {
        final prev = mutableRows[i - 1];
        if (_areTiedOnAllConfiguredCriteria(
          a: prev,
          b: current,
          tiebreakers: rules.tiebreakerOrder,
          completedMatches: completedMatches,
          pointsForWin: rules.pointsForWin,
          pointsForDraw: rules.pointsForDraw,
          pointsForLoss: rules.pointsForLoss,
        )) {
          tiedOnAll = true;
        }
      }
      if (!tiedOnAll && i + 1 < mutableRows.length) {
        final next = mutableRows[i + 1];
        if (_areTiedOnAllConfiguredCriteria(
          a: current,
          b: next,
          tiebreakers: rules.tiebreakerOrder,
          completedMatches: completedMatches,
          pointsForWin: rules.pointsForWin,
          pointsForDraw: rules.pointsForDraw,
          pointsForLoss: rules.pointsForLoss,
        )) {
          tiedOnAll = true;
        }
      }

      rows.add(
        StandingsRow(
          position: i + 1,
          teamId: current.team.id,
          teamName: current.team.name,
          teamShortCode: current.team.shortCode,
          crestShape: current.team.crestShape,
          primaryColorHex: current.team.primaryColorHex,
          played: current.played,
          won: current.won,
          drawn: current.drawn,
          lost: current.lost,
          goalsFor: current.goalsFor,
          goalsAgainst: current.goalsAgainst,
          goalDifference: current.goalDifference,
          points: current.points,
          yellowCards: current.yellowCards,
          secondYellowRedCards: current.secondYellowRedCards,
          directRedCards: current.directRedCards,
          fairPlayPenaltyPoints: current.fairPlayPenaltyPoints,
          isQualified: (i + 1) <= qualifyingSlots,
          isTiedOnAllCriteria: tiedOnAll,
        ),
      );
    }

    return StandingsTable(
      tournamentId: tournament.id,
      groupName: groupName,
      rows: rows,
      appliedTiebreakers: rules.tiebreakerOrder,
      completedMatchesCount: completedMatches.length,
    );
  }

  /// Computes independent per-group [StandingsTable] instances for
  /// [TournamentFormat.mixedGroupsAndKnockout] (`FR-004`).
  List<StandingsTable> calculateGroupStageTables({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required List<ChampionshipMatch> matches,
    required List<DigitalMatchReport> closedReports,
  }) {
    final groupCount = tournament.rules.groupStageConfig.groupCount.clamp(2, 8);
    final sortedTeams = List<TournamentTeam>.from(teams)
      ..sort((a, b) => a.id.compareTo(b.id));

    final buckets = List<List<TournamentTeam>>.generate(
      groupCount,
      (_) => <TournamentTeam>[],
    );
    for (var i = 0; i < sortedTeams.length; i++) {
      buckets[i % groupCount].add(sortedTeams[i]);
    }

    final tables = <StandingsTable>[];
    for (var g = 0; g < groupCount; g++) {
      final groupLetter = String.fromCharCode('A'.codeUnitAt(0) + g);
      final groupName = 'Grupo $groupLetter';
      final groupTeams = buckets[g];
      if (groupTeams.isEmpty) continue;

      tables.add(
        calculateTable(
          tournament: tournament,
          teams: groupTeams,
          matches: matches,
          closedReports: closedReports,
          groupName: groupName,
        ),
      );
    }

    return tables;
  }

  int _compareByCriterion({
    required TiebreakerCriterion criterion,
    required _MutableTeamStanding a,
    required _MutableTeamStanding b,
    required List<ChampionshipMatch> completedMatches,
    required int pointsForWin,
    required int pointsForDraw,
    required int pointsForLoss,
  }) {
    switch (criterion) {
      case TiebreakerCriterion.goalDifference:
        return b.goalDifference.compareTo(a.goalDifference);
      case TiebreakerCriterion.goalsFor:
        return b.goalsFor.compareTo(a.goalsFor);
      case TiebreakerCriterion.headToHead:
        return _compareHeadToHead(
          aId: a.team.id,
          bId: b.team.id,
          completedMatches: completedMatches,
          pointsForWin: pointsForWin,
          pointsForDraw: pointsForDraw,
          pointsForLoss: pointsForLoss,
        );
      case TiebreakerCriterion.fairPlay:
        // fairPlayPenaltyPoints is <= 0 (e.g. -1 vs -4). Higher (closer to 0) is better.
        return b.fairPlayPenaltyPoints.compareTo(a.fairPlayPenaltyPoints);
    }
  }

  /// Evaluates direct mutual completed matches between [aId] and [bId].
  /// If they haven't played each other yet or their mutual record is drawn,
  /// returns 0 immediately so the next hierarchical tiebreaker is evaluated (`FR-003`).
  int _compareHeadToHead({
    required String aId,
    required String bId,
    required List<ChampionshipMatch> completedMatches,
    required int pointsForWin,
    required int pointsForDraw,
    required int pointsForLoss,
  }) {
    final mutualMatches = completedMatches.where((m) {
      return (m.homeTeamId == aId && m.awayTeamId == bId) ||
          (m.homeTeamId == bId && m.awayTeamId == aId);
    }).toList();

    if (mutualMatches.isEmpty) {
      return 0;
    }

    var aPoints = 0;
    var bPoints = 0;
    var aGoals = 0;
    var bGoals = 0;

    for (final m in mutualMatches) {
      final hScore = m.homeScore!;
      final aScore = m.awayScore!;
      final isAHome = m.homeTeamId == aId;
      final goalsByA = isAHome ? hScore : aScore;
      final goalsByB = isAHome ? aScore : hScore;

      aGoals += goalsByA;
      bGoals += goalsByB;

      if (goalsByA > goalsByB) {
        aPoints += pointsForWin;
        bPoints += pointsForLoss;
      } else if (goalsByB > goalsByA) {
        bPoints += pointsForWin;
        aPoints += pointsForLoss;
      } else {
        aPoints += pointsForDraw;
        bPoints += pointsForDraw;
      }
    }

    final ptsCmp = bPoints.compareTo(aPoints);
    if (ptsCmp != 0) return ptsCmp;

    final gdA = aGoals - bGoals;
    final gdB = bGoals - aGoals;
    return gdB.compareTo(gdA);
  }

  bool _areTiedOnAllConfiguredCriteria({
    required _MutableTeamStanding a,
    required _MutableTeamStanding b,
    required List<TiebreakerCriterion> tiebreakers,
    required List<ChampionshipMatch> completedMatches,
    required int pointsForWin,
    required int pointsForDraw,
    required int pointsForLoss,
  }) {
    if (a.points != b.points) return false;
    for (final criterion in tiebreakers) {
      final cmp = _compareByCriterion(
        criterion: criterion,
        a: a,
        b: b,
        completedMatches: completedMatches,
        pointsForWin: pointsForWin,
        pointsForDraw: pointsForDraw,
        pointsForLoss: pointsForLoss,
      );
      if (cmp != 0) return false;
    }
    return true;
  }
}

class _MutableTeamStanding {
  _MutableTeamStanding({required this.team});

  final TournamentTeam team;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  int points = 0;
  int yellowCards = 0;
  int secondYellowRedCards = 0;
  int directRedCards = 0;

  int get goalDifference => goalsFor - goalsAgainst;

  /// Fair Play penalty weighting (`FR-009`):
  /// -1 per yellowCard, -3 per secondYellowRedCard, -3 per directRedCard.
  int get fairPlayPenaltyPoints =>
      -(yellowCards * 1 + secondYellowRedCards * 3 + directRedCards * 3);
}
