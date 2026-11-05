import 'package:vifutbol/application/use_cases/calculate_tournament_standings_and_rankings_use_case.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/season_honor_roll.dart';
import 'package:vifutbol/domain/entities/standings_table.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/match_reports_repository.dart';
import 'package:vifutbol/domain/repositories/season_honor_roll_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';

/// Use case that previews and executes the official season closure of a championship tournament,
/// calculating the deterministic SeasonHonorRoll and locking the tournament into permanent historical read-only mode.
class CloseTournamentSeasonUseCase {
  const CloseTournamentSeasonUseCase({
    required this.tournamentsRepository,
    required this.teamsRepository,
    required this.matchesRepository,
    required this.reportsRepository,
    required this.honorRollRepository,
    required this.calculateStandingsUseCase,
  });

  final TournamentsRepository tournamentsRepository;
  final TeamsRepository teamsRepository;
  final TournamentMatchesRepository matchesRepository;
  final MatchReportsRepository reportsRepository;
  final SeasonHonorRollRepository honorRollRepository;
  final CalculateTournamentStandingsAndRankingsUseCase
  calculateStandingsUseCase;

  static const String pendingMatchesMessage =
      'Todos los partidos obligatorios deben estar finalizados antes de cerrar el campeonato.';

  Future<SeasonHonorRoll> previewHonorRoll({
    required ChampionshipTournament tournament,
    required UserRole actorRole,
  }) async {
    _ensureOrganizer(actorRole);

    final teams = await teamsRepository.loadTeamsForTournament(tournament.id);
    if (teams.length < 2) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.pendingMandatoryMatchesForSeasonClosure,
        'Se requieren al menos 2 equipos para determinar el cuadro de honor.',
      );
    }

    final matches = await matchesRepository.loadMatchesForTournament(
      tournament.id,
    );
    if (matches.isEmpty) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.pendingMandatoryMatchesForSeasonClosure,
        pendingMatchesMessage,
      );
    }

    _validateMandatoryMatchesCompleted(tournament, matches);

    final compResult = await calculateStandingsUseCase.execute(tournament.id);

    // 1. Determine Champion & Runner-Up
    final teamsMap = {for (final t in teams) t.id: t};
    String championTeamId = '';
    String runnerUpTeamId = '';

    // Check if knockout final match exists
    final finalMatch = _findFinalMatch(matches);
    if (finalMatch != null && finalMatch.status == MatchStatus.completed) {
      final homeScore =
          (finalMatch.homeScore ?? 0) + (finalMatch.homePenaltyScore ?? 0);
      final awayScore =
          (finalMatch.awayScore ?? 0) + (finalMatch.awayPenaltyScore ?? 0);
      if (homeScore >= awayScore) {
        championTeamId = finalMatch.homeTeamId;
        runnerUpTeamId = finalMatch.awayTeamId;
      } else {
        championTeamId = finalMatch.awayTeamId;
        runnerUpTeamId = finalMatch.homeTeamId;
      }
    } else {
      // Determined by standings table
      final rows = compResult.mainStandingsTable.rows;
      if (rows.length >= 2) {
        championTeamId = rows[0].teamId;
        runnerUpTeamId = rows[1].teamId;
      } else {
        championTeamId = teams[0].id;
        runnerUpTeamId = teams[1].id;
      }
    }

    final champTeam = teamsMap[championTeamId] ?? teams[0];
    final runnerTeam = teamsMap[runnerUpTeamId] ?? teams[1];

    // 2. Determine Top Scorer
    final topScorers = compResult.rankings.topScorers;
    String? topScorerId;
    String? topScorerName;
    String? topScorerTeam;
    int topScorerGoals = 0;

    if (topScorers.isNotEmpty && topScorers.first.goals > 0) {
      final best = topScorers.first;
      topScorerId = best.playerId;
      topScorerName = best.playerName;
      topScorerTeam = best.teamName;
      topScorerGoals = best.goals;
    }

    // 3. Determine Best Defense (Valla Menos Vencida)
    final candidateRows = compResult.mainStandingsTable.rows
        .where((r) => r.played >= 1)
        .toList();
    StandingsRow? bestDefenseRow;
    if (candidateRows.isNotEmpty) {
      candidateRows.sort((a, b) {
        final gaCmp = a.goalsAgainst.compareTo(b.goalsAgainst);
        if (gaCmp != 0) return gaCmp;
        final pjCmp = b.played.compareTo(a.played);
        if (pjCmp != 0) return pjCmp;
        final dgCmp = b.goalDifference.compareTo(a.goalDifference);
        if (dgCmp != 0) return dgCmp;
        return a.teamName.compareTo(b.teamName);
      });
      bestDefenseRow = candidateRows.first;
    }

    final bestDefTeam = bestDefenseRow != null
        ? teamsMap[bestDefenseRow.teamId] ?? champTeam
        : champTeam;
    final bestDefGoalsAgainst = bestDefenseRow?.goalsAgainst ?? 0;

    return SeasonHonorRoll(
      tournamentId: tournament.id,
      tournamentName: tournament.name,
      closedAt: DateTime.now().toUtc(),
      championTeamId: champTeam.id,
      championTeamName: champTeam.name,
      championShortCode: champTeam.shortCode,
      runnerUpTeamId: runnerTeam.id,
      runnerUpTeamName: runnerTeam.name,
      runnerUpShortCode: runnerTeam.shortCode,
      topScorerPlayerId: topScorerId,
      topScorerPlayerName: topScorerName,
      topScorerTeamName: topScorerTeam,
      topScorerGoals: topScorerGoals,
      bestDefenseTeamId: bestDefTeam.id,
      bestDefenseTeamName: bestDefTeam.name,
      bestDefenseShortCode: bestDefTeam.shortCode,
      bestDefenseGoalsAgainst: bestDefGoalsAgainst,
    );
  }

  Future<SeasonHonorRoll> closeSeason({
    required ChampionshipTournament tournament,
    required UserRole actorRole,
    required bool isTwoStepConfirmed,
  }) async {
    _ensureOrganizer(actorRole);

    if (!isTwoStepConfirmed) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.missingTwoStepConfirmation,
        'Se requiere confirmación explícita para cerrar oficialmente la temporada',
      );
    }

    if (tournament.status == TournamentStatus.finished) {
      throw const TournamentValidationFailure(
        TournamentValidationErrorCode.tournamentAlreadyFinished,
        'El campeonato ya se encuentra finalizado',
      );
    }

    final honorRoll = await previewHonorRoll(
      tournament: tournament,
      actorRole: actorRole,
    );

    // Transition status to finished
    final closedTournament = tournament.copyWith(
      status: TournamentStatus.finished,
      updatedAt: DateTime.now().toUtc(),
    );

    await tournamentsRepository.saveTournament(closedTournament);
    await honorRollRepository.saveHonorRoll(honorRoll);

    return honorRoll;
  }

  void _validateMandatoryMatchesCompleted(
    ChampionshipTournament tournament,
    List<ChampionshipMatch> matches,
  ) {
    if (tournament.format == TournamentFormat.league) {
      final hasPending = matches.any((m) => m.status != MatchStatus.completed);
      if (hasPending) {
        throw const TournamentValidationFailure(
          TournamentValidationErrorCode.pendingMandatoryMatchesForSeasonClosure,
          pendingMatchesMessage,
        );
      }
    } else {
      // Knockout or mixed
      final finalMatch = _findFinalMatch(matches);
      if (finalMatch == null || finalMatch.status != MatchStatus.completed) {
        throw const TournamentValidationFailure(
          TournamentValidationErrorCode.pendingMandatoryMatchesForSeasonClosure,
          pendingMatchesMessage,
        );
      }
      final anyInProgress = matches.any(
        (m) => m.status == MatchStatus.inProgress,
      );
      if (anyInProgress) {
        throw const TournamentValidationFailure(
          TournamentValidationErrorCode.pendingMandatoryMatchesForSeasonClosure,
          pendingMatchesMessage,
        );
      }
    }
  }

  ChampionshipMatch? _findFinalMatch(List<ChampionshipMatch> matches) {
    for (final m in matches) {
      final name = m.roundName.toLowerCase();
      if (name == 'final' ||
          name.contains('gran final') ||
          name.startsWith('final')) {
        return m;
      }
    }
    return null;
  }

  void _ensureOrganizer(UserRole actorRole) {
    if (!RolePermissionMatrix.hasCapability(
      actorRole,
      RoleCapability.manageTournaments,
    )) {
      throw const UnauthorizedRoleFailure();
    }
  }
}
