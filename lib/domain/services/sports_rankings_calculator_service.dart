import '../entities/championship_tournament.dart';
import '../entities/digital_match_report.dart';
import '../entities/match_report_enums.dart';
import '../entities/registered_player.dart';
import '../entities/tournament_rankings.dart';
import '../entities/tournament_team.dart';

/// Pure domain service that deterministically calculates individual player rankings
/// (`topScorers` `FR-007`, `topAssists` `FR-008`) and collective team Fair Play
/// standings (`teamFairPlay` `FR-009`: -1 yellow, -3 second-yellow/red, -3 direct red)
/// exclusively from closed official match reports.
class SportsRankingsCalculatorService {
  const SportsRankingsCalculatorService();

  TournamentRankingsBundle calculateRankings({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required List<DigitalMatchReport> closedReports,
  }) {
    final teamMap = <String, TournamentTeam>{for (final t in teams) t.id: t};
    final rosterPlayerMap = <String, _EnrolledPlayerMeta>{};

    for (final team in teams) {
      for (final player in team.players) {
        rosterPlayerMap[player.id] = _EnrolledPlayerMeta(
          player: player,
          team: team,
        );
      }
    }

    final playerAccumulators = <String, _MutablePlayerStats>{};
    final teamCardAccumulators = <String, _MutableTeamFairPlay>{
      for (final team in teams) team.id: _MutableTeamFairPlay(team: team),
    };

    final validReports = closedReports.where(
      (r) => r.isClosed && r.tournamentId == tournament.id,
    );

    for (final report in validReports) {
      // Track which players participated in events in this match
      final matchParticipants = <String>{};

      // Identify yellow cards that triggered a secondYellowRedCard so we don't double-count
      final linkedYellowIds = report.events
          .where(
            (e) =>
                e.type == MatchEventType.secondYellowRedCard &&
                e.linkedParentEventId != null,
          )
          .map((e) => e.linkedParentEventId!)
          .toSet();

      for (final event in report.events) {
        if (event.teamId == 'match') continue;

        final team = teamMap[event.teamId];
        final teamName = team?.name ?? event.teamId;
        final teamCode = team?.shortCode ?? 'EQP';

        if (event.type == MatchEventType.goal) {
          final scorerId = event.primaryPlayerId;
          if (scorerId != null && scorerId.isNotEmpty) {
            final meta = rosterPlayerMap[scorerId];
            final acc = playerAccumulators.putIfAbsent(
              scorerId,
              () => _MutablePlayerStats(
                playerId: scorerId,
                playerName:
                    meta?.player.fullName ??
                    event.primaryPlayerName ??
                    scorerId,
                shirtNumber:
                    meta?.player.shirtNumber ??
                    event.primaryPlayerShirtNumber ??
                    0,
                teamId: meta?.team.id ?? event.teamId,
                teamName: meta?.team.name ?? teamName,
                teamShortCode: meta?.team.shortCode ?? teamCode,
              ),
            );
            acc.goals += 1;
            matchParticipants.add(scorerId);
          }

          final assistantId = event.secondaryPlayerId;
          if (assistantId != null && assistantId.isNotEmpty) {
            final meta = rosterPlayerMap[assistantId];
            final acc = playerAccumulators.putIfAbsent(
              assistantId,
              () => _MutablePlayerStats(
                playerId: assistantId,
                playerName:
                    meta?.player.fullName ??
                    event.secondaryPlayerName ??
                    assistantId,
                shirtNumber:
                    meta?.player.shirtNumber ??
                    event.secondaryPlayerShirtNumber ??
                    0,
                teamId: meta?.team.id ?? event.teamId,
                teamName: meta?.team.name ?? teamName,
                teamShortCode: meta?.team.shortCode ?? teamCode,
              ),
            );
            acc.assists += 1;
            matchParticipants.add(assistantId);
          }
        } else if (event.type == MatchEventType.yellowCard) {
          final pId = event.primaryPlayerId;
          if (pId != null && pId.isNotEmpty) {
            final meta = rosterPlayerMap[pId];
            final acc = playerAccumulators.putIfAbsent(
              pId,
              () => _MutablePlayerStats(
                playerId: pId,
                playerName:
                    meta?.player.fullName ?? event.primaryPlayerName ?? pId,
                shirtNumber:
                    meta?.player.shirtNumber ??
                    event.primaryPlayerShirtNumber ??
                    0,
                teamId: meta?.team.id ?? event.teamId,
                teamName: meta?.team.name ?? teamName,
                teamShortCode: meta?.team.shortCode ?? teamCode,
              ),
            );
            if (!linkedYellowIds.contains(event.id)) {
              acc.yellowCards += 1;
            }
            matchParticipants.add(pId);
          }

          if (!linkedYellowIds.contains(event.id)) {
            teamCardAccumulators[event.teamId]?.yellowCards += 1;
          }
        } else if (event.type == MatchEventType.secondYellowRedCard) {
          final pId = event.primaryPlayerId;
          if (pId != null && pId.isNotEmpty) {
            final meta = rosterPlayerMap[pId];
            final acc = playerAccumulators.putIfAbsent(
              pId,
              () => _MutablePlayerStats(
                playerId: pId,
                playerName:
                    meta?.player.fullName ?? event.primaryPlayerName ?? pId,
                shirtNumber:
                    meta?.player.shirtNumber ??
                    event.primaryPlayerShirtNumber ??
                    0,
                teamId: meta?.team.id ?? event.teamId,
                teamName: meta?.team.name ?? teamName,
                teamShortCode: meta?.team.shortCode ?? teamCode,
              ),
            );
            acc.redCards += 1;
            matchParticipants.add(pId);
          }

          teamCardAccumulators[event.teamId]?.secondYellowRedCards += 1;
        } else if (event.type == MatchEventType.directRedCard) {
          final pId = event.primaryPlayerId;
          if (pId != null && pId.isNotEmpty) {
            final meta = rosterPlayerMap[pId];
            final acc = playerAccumulators.putIfAbsent(
              pId,
              () => _MutablePlayerStats(
                playerId: pId,
                playerName:
                    meta?.player.fullName ?? event.primaryPlayerName ?? pId,
                shirtNumber:
                    meta?.player.shirtNumber ??
                    event.primaryPlayerShirtNumber ??
                    0,
                teamId: meta?.team.id ?? event.teamId,
                teamName: meta?.team.name ?? teamName,
                teamShortCode: meta?.team.shortCode ?? teamCode,
              ),
            );
            acc.redCards += 1;
            matchParticipants.add(pId);
          }

          teamCardAccumulators[event.teamId]?.directRedCards += 1;
        }
      }

      for (final pId in matchParticipants) {
        final acc = playerAccumulators[pId];
        if (acc != null) {
          acc.matchesPlayed += 1;
        }
      }
    }

    // 1. Top Scorers (FR-007): goals > 0, sorted by goals desc, assists desc, matchesPlayed asc, playerName asc
    final scorerCandidates =
        playerAccumulators.values.where((p) => p.goals > 0).toList()
          ..sort((a, b) {
            final gCmp = b.goals.compareTo(a.goals);
            if (gCmp != 0) return gCmp;
            final aCmp = b.assists.compareTo(a.assists);
            if (aCmp != 0) return aCmp;
            final mCmp = a.matchesPlayed.compareTo(b.matchesPlayed);
            if (mCmp != 0) return mCmp;
            return a.playerName.toLowerCase().compareTo(
              b.playerName.toLowerCase(),
            );
          });

    final topScorers = <PlayerRankingEntry>[
      for (var i = 0; i < scorerCandidates.length; i++)
        scorerCandidates[i].toEntry(rank: i + 1),
    ];

    // 2. Top Assists (FR-008): assists > 0, sorted by assists desc, goals desc, matchesPlayed asc, playerName asc
    final assistCandidates =
        playerAccumulators.values.where((p) => p.assists > 0).toList()
          ..sort((a, b) {
            final aCmp = b.assists.compareTo(a.assists);
            if (aCmp != 0) return aCmp;
            final gCmp = b.goals.compareTo(a.goals);
            if (gCmp != 0) return gCmp;
            final mCmp = a.matchesPlayed.compareTo(b.matchesPlayed);
            if (mCmp != 0) return mCmp;
            return a.playerName.toLowerCase().compareTo(
              b.playerName.toLowerCase(),
            );
          });

    final topAssists = <PlayerRankingEntry>[
      for (var i = 0; i < assistCandidates.length; i++)
        assistCandidates[i].toEntry(rank: i + 1),
    ];

    // 3. Team Fair Play (FR-009): -1 per yellow, -3 per secondYellowRed, -3 per directRed; closest to 0 first
    final fairPlayCandidates = teamCardAccumulators.values.toList()
      ..sort((a, b) {
        final penCmp = b.penaltyPoints.compareTo(a.penaltyPoints);
        if (penCmp != 0) return penCmp;
        final drCmp = a.directRedCards.compareTo(b.directRedCards);
        if (drCmp != 0) return drCmp;
        final syrCmp = a.secondYellowRedCards.compareTo(b.secondYellowRedCards);
        if (syrCmp != 0) return syrCmp;
        final ycCmp = a.yellowCards.compareTo(b.yellowCards);
        if (ycCmp != 0) return ycCmp;
        return a.team.normalizedName.compareTo(b.team.normalizedName);
      });

    final teamFairPlay = <TeamFairPlayRow>[
      for (var i = 0; i < fairPlayCandidates.length; i++)
        fairPlayCandidates[i].toRow(rank: i + 1),
    ];

    return TournamentRankingsBundle(
      tournamentId: tournament.id,
      topScorers: topScorers,
      topAssists: topAssists,
      teamFairPlay: teamFairPlay,
    );
  }
}

class _EnrolledPlayerMeta {
  const _EnrolledPlayerMeta({required this.player, required this.team});
  final RegisteredPlayer player;
  final TournamentTeam team;
}

class _MutablePlayerStats {
  _MutablePlayerStats({
    required this.playerId,
    required this.playerName,
    required this.shirtNumber,
    required this.teamId,
    required this.teamName,
    required this.teamShortCode,
  });

  final String playerId;
  final String playerName;
  final int shirtNumber;
  final String teamId;
  final String teamName;
  final String teamShortCode;
  int goals = 0;
  int assists = 0;
  int matchesPlayed = 0;
  int yellowCards = 0;
  int redCards = 0;

  PlayerRankingEntry toEntry({required int rank}) {
    return PlayerRankingEntry(
      rank: rank,
      playerId: playerId,
      playerName: playerName,
      shirtNumber: shirtNumber,
      teamId: teamId,
      teamName: teamName,
      teamShortCode: teamShortCode,
      goals: goals,
      assists: assists,
      matchesPlayed: matchesPlayed,
      yellowCards: yellowCards,
      redCards: redCards,
    );
  }
}

class _MutableTeamFairPlay {
  _MutableTeamFairPlay({required this.team});

  final TournamentTeam team;
  int yellowCards = 0;
  int secondYellowRedCards = 0;
  int directRedCards = 0;

  int get penaltyPoints =>
      -(yellowCards * 1 + secondYellowRedCards * 3 + directRedCards * 3);

  TeamFairPlayRow toRow({required int rank}) {
    return TeamFairPlayRow(
      rank: rank,
      teamId: team.id,
      teamName: team.name,
      teamShortCode: team.shortCode,
      yellowCards: yellowCards,
      secondYellowRedCards: secondYellowRedCards,
      directRedCards: directRedCards,
      penaltyPoints: penaltyPoints,
    );
  }
}
