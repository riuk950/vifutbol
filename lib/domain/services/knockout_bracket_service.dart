import '../entities/championship_match.dart';
import '../entities/championship_tournament.dart';
import '../entities/digital_match_report.dart';
import '../entities/knockout_bracket.dart';
import '../entities/match_enums.dart';
import '../entities/tournament_enums.dart';
import '../entities/tournament_team.dart';

/// Pure domain service that builds chronological knockout bracket trees (`FR-005`)
/// and propagates winners automatically across rounds (`FR-006`).
class KnockoutBracketService {
  const KnockoutBracketService();

  static const String tbdTeamLabel = 'Por definir';

  /// Builds the full chronological [KnockoutBracket] tree from the tournament's
  /// starting round through [KnockoutRound.finalMatch].
  ///
  /// Automatically propagates winners of completed ties into the next round's
  /// corresponding slot (`tieIndex ~/ 2`, even -> home, odd -> away).
  KnockoutBracket buildBracket({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required List<ChampionshipMatch> matches,
    required List<DigitalMatchReport> reports,
  }) {
    final roundsSequence = tournament.rules.knockoutConfig.activeRoundsSequence;
    final teamMap = <String, TournamentTeam>{for (final t in teams) t.id: t};
    final reportByMatchId = <String, DigitalMatchReport>{
      for (final r in reports) r.matchId: r,
    };

    final tournamentMatches = matches
        .where((m) => m.tournamentId == tournament.id)
        .toList();

    // Map (round, tieIndex) -> resolved node
    final resolvedNodesByRound = <KnockoutRound, List<KnockoutMatchTieNode>>{};

    for (var rIdx = 0; rIdx < roundsSequence.length; rIdx++) {
      final round = roundsSequence[rIdx];
      final nextRound = (rIdx + 1 < roundsSequence.length)
          ? roundsSequence[rIdx + 1]
          : null;
      final roundMatches = _findMatchesForRound(
        tournamentId: tournament.id,
        round: round,
        roundSequenceIndex: rIdx,
        allTournamentMatches: tournamentMatches,
      );

      final previousRound = rIdx > 0 ? roundsSequence[rIdx - 1] : null;
      final prevNodes = previousRound != null
          ? resolvedNodesByRound[previousRound]
          : null;

      final ties = <KnockoutMatchTieNode>[];
      for (var tieIdx = 0; tieIdx < round.tieCount; tieIdx++) {
        final existingMatch = tieIdx < roundMatches.length
            ? roundMatches[tieIdx]
            : null;
        final report = existingMatch != null
            ? reportByMatchId[existingMatch.id]
            : null;

        // Determine home & away team IDs:
        // 1. From existing match if present
        // 2. Or propagated from previous round winners (feeder ties tieIdx*2 and tieIdx*2+1)
        // 3. Or seeded from initial teams list if first round and no match created yet
        String? homeTeamId = existingMatch?.homeTeamId;
        String? awayTeamId = existingMatch?.awayTeamId;

        if (prevNodes != null) {
          final feederHomeIdx = tieIdx * 2;
          final feederAwayIdx = tieIdx * 2 + 1;
          final promotedHome = feederHomeIdx < prevNodes.length
              ? prevNodes[feederHomeIdx].winnerTeamId
              : null;
          final promotedAway = feederAwayIdx < prevNodes.length
              ? prevNodes[feederAwayIdx].winnerTeamId
              : null;

          if (promotedHome != null && promotedHome.isNotEmpty) {
            homeTeamId ??= promotedHome;
          }
          if (promotedAway != null && promotedAway.isNotEmpty) {
            awayTeamId ??= promotedAway;
          }
        } else if (rIdx == 0 && existingMatch == null) {
          final hSeedIdx = tieIdx * 2;
          final aSeedIdx = tieIdx * 2 + 1;
          if (hSeedIdx < teams.length) {
            homeTeamId = teams[hSeedIdx].id;
          }
          if (aSeedIdx < teams.length) {
            awayTeamId = teams[aSeedIdx].id;
          }
        }

        final homeTeam = homeTeamId != null ? teamMap[homeTeamId] : null;
        final awayTeam = awayTeamId != null ? teamMap[awayTeamId] : null;

        final homeScore =
            existingMatch?.homeScore ??
            (report != null && report.isClosed ? report.homeScore : null);
        final awayScore =
            existingMatch?.awayScore ??
            (report != null && report.isClosed ? report.awayScore : null);
        final homePen =
            existingMatch?.homePenaltyScore ?? report?.homePenaltyScore;
        final awayPen =
            existingMatch?.awayPenaltyScore ?? report?.awayPenaltyScore;

        final isCompleted =
            existingMatch?.status == MatchStatus.completed ||
            (report != null && report.isClosed);
        final status = isCompleted
            ? MatchStatus.completed
            : (existingMatch?.status ?? MatchStatus.pendingSchedule);

        final winnerId = isCompleted
            ? resolveWinnerTeamId(
                homeTeamId: homeTeamId,
                awayTeamId: awayTeamId,
                homeScore: homeScore,
                awayScore: awayScore,
                homePenaltyScore: homePen,
                awayPenaltyScore: awayPen,
              )
            : null;
        final winnerTeam = winnerId != null ? teamMap[winnerId] : null;

        final nextNodeId = nextRound != null
            ? 'ko-${nextRound.name}-${tieIdx ~/ 2}'
            : null;

        ties.add(
          KnockoutMatchTieNode(
            nodeId: 'ko-${round.name}-$tieIdx',
            round: round,
            tieIndex: tieIdx,
            matchId: existingMatch?.id,
            homeTeamId: homeTeamId,
            homeTeamName: homeTeam?.name ?? tbdTeamLabel,
            homeTeamShortCode: homeTeam?.shortCode,
            awayTeamId: awayTeamId,
            awayTeamName: awayTeam?.name ?? tbdTeamLabel,
            awayTeamShortCode: awayTeam?.shortCode,
            homeScore: homeScore,
            awayScore: awayScore,
            homePenaltyScore: homePen,
            awayPenaltyScore: awayPen,
            status: status,
            winnerTeamId: winnerId,
            winnerTeamName: winnerTeam?.name,
            nextRoundNodeId: nextNodeId,
          ),
        );
      }

      resolvedNodesByRound[round] = ties;
    }

    final rounds = <KnockoutBracketRound>[
      for (final round in roundsSequence)
        KnockoutBracketRound(
          round: round,
          roundTitle: formatRoundTitle(round),
          ties: resolvedNodesByRound[round] ?? const <KnockoutMatchTieNode>[],
        ),
    ];

    final finalNodes = resolvedNodesByRound[KnockoutRound.finalMatch];
    final finalWinnerId = (finalNodes != null && finalNodes.isNotEmpty)
        ? finalNodes.first.winnerTeamId
        : null;
    final championName = finalWinnerId != null
        ? teamMap[finalWinnerId]?.name
        : null;

    return KnockoutBracket(
      tournamentId: tournament.id,
      rounds: rounds,
      championTeamId: finalWinnerId,
      championTeamName: championName,
    );
  }

  /// Evaluates the bracket and generates or updates next-round [ChampionshipMatch]
  /// records whenever two feeder ties in round $r$ have determined winners, or updates
  /// an existing next-round match (`FR-006`).
  List<ChampionshipMatch> computeUpdatedMatchesWithAdvancement({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required List<ChampionshipMatch> currentMatches,
    required List<DigitalMatchReport> reports,
    DateTime? now,
  }) {
    if (!tournament.format.hasKnockoutBracket) {
      return const <ChampionshipMatch>[];
    }

    final bracket = buildBracket(
      tournament: tournament,
      teams: teams,
      matches: currentMatches,
      reports: reports,
    );

    final existingById = <String, ChampionshipMatch>{
      for (final m in currentMatches) m.id: m,
    };
    final updatedOrCreated = <ChampionshipMatch>[];
    final timestamp = now ?? DateTime.now();

    for (var rIdx = 1; rIdx < bracket.rounds.length; rIdx++) {
      final roundObj = bracket.rounds[rIdx];
      final round = roundObj.round;
      for (final tie in roundObj.ties) {
        if (!tie.hasBothTeamsAssigned) continue;
        if (tie.homeTeamId == tie.awayTeamId) continue;

        final canonicalId =
            tie.matchId ??
            'match-${tournament.id}-ko-${round.name}-${tie.tieIndex + 1}';
        final existing = existingById[canonicalId];

        if (existing == null) {
          final created = ChampionshipMatch(
            id: canonicalId,
            tournamentId: tournament.id,
            roundNumber: rIdx + 1,
            roundName: formatRoundTitle(round),
            homeTeamId: tie.homeTeamId!,
            awayTeamId: tie.awayTeamId!,
            status: MatchStatus.pendingSchedule,
            updatedAt: timestamp,
          );
          updatedOrCreated.add(created);
        } else if (existing.homeTeamId != tie.homeTeamId ||
            existing.awayTeamId != tie.awayTeamId) {
          final updated = existing.copyWith(
            homeTeamId: tie.homeTeamId,
            awayTeamId: tie.awayTeamId,
            updatedAt: timestamp,
          );
          updatedOrCreated.add(updated);
        }
      }
    }

    return updatedOrCreated;
  }

  /// Determines the winning team ID of a knockout tie from regulation or penalty scores.
  String? resolveWinnerTeamId({
    required String? homeTeamId,
    required String? awayTeamId,
    required int? homeScore,
    required int? awayScore,
    int? homePenaltyScore,
    int? awayPenaltyScore,
  }) {
    if (homeTeamId == null ||
        awayTeamId == null ||
        homeScore == null ||
        awayScore == null) {
      return null;
    }
    if (homeScore > awayScore) return homeTeamId;
    if (awayScore > homeScore) return awayTeamId;

    if (homePenaltyScore != null && awayPenaltyScore != null) {
      if (homePenaltyScore > awayPenaltyScore) return homeTeamId;
      if (awayPenaltyScore > homePenaltyScore) return awayTeamId;
    }
    return null;
  }

  static String formatRoundTitle(KnockoutRound round) {
    return switch (round) {
      KnockoutRound.roundOf16 => 'Octavos de Final',
      KnockoutRound.quarterFinals => 'Cuartos de Final',
      KnockoutRound.semiFinals => 'Semifinales',
      KnockoutRound.finalMatch => 'Gran Final',
    };
  }

  List<ChampionshipMatch> _findMatchesForRound({
    required String tournamentId,
    required KnockoutRound round,
    required int roundSequenceIndex,
    required List<ChampionshipMatch> allTournamentMatches,
  }) {
    final prefix = 'match-$tournamentId-ko-${round.name}-';
    final byIdPrefix = allTournamentMatches
        .where((m) => m.id.startsWith(prefix))
        .toList();
    if (byIdPrefix.isNotEmpty) {
      byIdPrefix.sort((a, b) => a.id.compareTo(b.id));
      return byIdPrefix;
    }

    final expectedTitle = formatRoundTitle(round).toLowerCase();
    final byRoundName = allTournamentMatches.where((m) {
      final rn = m.roundName.toLowerCase();
      if (rn == expectedTitle) return true;
      return switch (round) {
        KnockoutRound.roundOf16 => rn.contains('octavos'),
        KnockoutRound.quarterFinals => rn.contains('cuartos'),
        KnockoutRound.semiFinals => rn.contains('semifinal'),
        KnockoutRound.finalMatch =>
          rn == 'final' ||
              rn == 'gran final' ||
              (rn.contains('final') &&
                  !rn.contains('octavos') &&
                  !rn.contains('cuartos') &&
                  !rn.contains('semifinal')),
      };
    }).toList();

    if (byRoundName.isNotEmpty) {
      byRoundName.sort((a, b) => a.id.compareTo(b.id));
      return byRoundName;
    }

    return const <ChampionshipMatch>[];
  }
}
