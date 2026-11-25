import 'dart:math';
import '../../domain/entities/championship_match.dart';
import '../../domain/entities/digital_match_report.dart';
import '../../domain/entities/match_enums.dart';
import '../../domain/entities/match_event.dart';
import '../../domain/entities/match_report_enums.dart';
import '../../domain/entities/player_internal_tracking.dart';
import '../../domain/entities/registered_player.dart';
import '../../domain/entities/role_permission_matrix.dart';
import '../../domain/entities/tournament_team.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/repositories/lineups_tracking_repository.dart';
import '../../domain/repositories/match_reports_repository.dart';
import '../../domain/repositories/teams_repository.dart';
import '../../domain/repositories/tournament_matches_repository.dart';
import '../../domain/repositories/tournaments_repository.dart';
import '../../domain/services/knockout_bracket_service.dart';
import '../../domain/services/referee_assigned_matches_service.dart';

/// Application use case controlling live match periods, event recording,
/// automatic double-yellow expulsions, and immutable report closure.
class ManageDigitalMatchReportUseCase {
  const ManageDigitalMatchReportUseCase({
    required this.matchReportsRepository,
    required this.tournamentMatchesRepository,
    required this.lineupsTrackingRepository,
    required this.tournamentsRepository,
    this.teamsRepository,
    this.knockoutBracketService = const KnockoutBracketService(),
  });

  final MatchReportsRepository matchReportsRepository;
  final TournamentMatchesRepository tournamentMatchesRepository;
  final LineupsTrackingRepository lineupsTrackingRepository;
  final TournamentsRepository tournamentsRepository;
  final TeamsRepository? teamsRepository;
  final KnockoutBracketService knockoutBracketService;

  /// Verifies whether [activeRole] + optional [actorUserId]/[actorRefereeId]
  /// is authorized to start and manage [match]. Only the assigned
  /// [UserRole.referee] is authorized.
  static bool isMatchAssignedToActor(
    ChampionshipMatch match, {
    required UserRole activeRole,
    String? actorUserId,
    String? actorRefereeId,
  }) {
    if (activeRole != UserRole.referee) {
      return false;
    }
    final matchRefereeId = match.refereeId?.trim();
    if (matchRefereeId == null || matchRefereeId.isEmpty) {
      return true;
    }
    final hasActorIdentity =
        (actorUserId != null && actorUserId.trim().isNotEmpty) ||
        (actorRefereeId != null && actorRefereeId.trim().isNotEmpty);
    if (!hasActorIdentity) {
      return true;
    }
    return RefereeAssignedMatchesService.isAssignedToReferee(
      match,
      userId: actorUserId,
      linkedRefereeId: actorRefereeId,
    );
  }

  void _assertAuthorizedForEvents(
    UserRole role, {
    ChampionshipMatch? match,
    String? actorUserId,
    String? actorRefereeId,
  }) {
    final hasPermission =
        role == UserRole.referee &&
        RolePermissionMatrix.hasCapability(
          role,
          RoleCapability.recordMatchEvents,
        );

    if (!hasPermission ||
        (match != null &&
            !isMatchAssignedToActor(
              match,
              activeRole: role,
              actorUserId: actorUserId,
              actorRefereeId: actorRefereeId,
            ))) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.unauthorizedRole,
        'Solo el árbitro asignado a este partido puede iniciar y gestionar el acta.',
      );
    }
  }

  void _assertAuthorizedForClose(
    UserRole role, {
    ChampionshipMatch? match,
    String? actorUserId,
    String? actorRefereeId,
  }) {
    final hasPermission =
        role == UserRole.referee &&
        RolePermissionMatrix.hasCapability(
          role,
          RoleCapability.closeMatchReport,
        );

    if (!hasPermission ||
        (match != null &&
            !isMatchAssignedToActor(
              match,
              activeRole: role,
              actorUserId: actorUserId,
              actorRefereeId: actorRefereeId,
            ))) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.unauthorizedRole,
        'Solo el árbitro asignado a este partido puede cerrar el acta oficial.',
      );
    }
  }

  Future<DigitalMatchReport> loadOrCreateReport(ChampionshipMatch match) {
    return matchReportsRepository.loadOrCreateReport(match);
  }

  Future<DigitalMatchReport> transitionMatchPeriod({
    required UserRole activeRole,
    required ChampionshipMatch match,
    required DigitalMatchReport currentReport,
    required MatchPeriod targetPeriod,
    String? actorUserId,
    String? actorRefereeId,
    bool isOffline = false,
    DateTime? now,
  }) async {
    _assertAuthorizedForEvents(
      activeRole,
      match: match,
      actorUserId: actorUserId,
      actorRefereeId: actorRefereeId,
    );

    if (currentReport.isClosed) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.reportAlreadyClosed,
        'El acta oficial ya ha sido cerrada y no puede ser modificada.',
      );
    }

    final currentTime = now ?? DateTime.now();
    int newAccumulatedSeconds = currentReport.elapsedSecondsBeforeCurrentPeriod;

    if (currentReport.currentPeriod.isRunning &&
        currentReport.periodStartedAt != null) {
      final runningDiff = max(
        0,
        currentTime.difference(currentReport.periodStartedAt!).inSeconds,
      );
      newAccumulatedSeconds += runningDiff;
    }

    final DateTime? newPeriodStartedAt = targetPeriod.isRunning
        ? currentTime
        : null;

    final transitionEvent = MatchEvent(
      id: 'evt-pt-${currentTime.millisecondsSinceEpoch}',
      matchId: match.id,
      type: MatchEventType.periodTransition,
      minute: currentReport.currentMatchMinuteAt(currentTime),
      teamId: 'match',
      description: targetPeriod.name,
      isSynced: !isOffline,
      createdAt: currentTime,
    );

    final updatedEvents = [...currentReport.events, transitionEvent];

    final updatedReport = currentReport.copyWith(
      currentPeriod: targetPeriod,
      periodStartedAt: newPeriodStartedAt,
      clearPeriodStartedAt: !targetPeriod.isRunning,
      elapsedSecondsBeforeCurrentPeriod: newAccumulatedSeconds,
      events: updatedEvents,
      updatedAt: currentTime,
    );

    // If starting game and match was scheduled, transition match to inProgress
    if (targetPeriod.isRunning && match.status != MatchStatus.inProgress) {
      final updatedMatch = match.copyWith(
        status: MatchStatus.inProgress,
        homeScore: updatedReport.homeScore,
        awayScore: updatedReport.awayScore,
        updatedAt: currentTime,
      );
      await tournamentMatchesRepository.saveMatch(updatedMatch);
    }

    return matchReportsRepository.saveReport(
      updatedReport,
      newlyCreatedEvents: [transitionEvent],
    );
  }

  Future<DigitalMatchReport> recordGoalEvent({
    required UserRole activeRole,
    required ChampionshipMatch match,
    required DigitalMatchReport currentReport,
    required String teamId,
    required RegisteredPlayer scorer,
    RegisteredPlayer? assistant,
    required int minute,
    String? notes,
    String? actorUserId,
    String? actorRefereeId,
    bool isOffline = false,
    DateTime? now,
  }) async {
    _assertAuthorizedForEvents(
      activeRole,
      match: match,
      actorUserId: actorUserId,
      actorRefereeId: actorRefereeId,
    );

    if (currentReport.isClosed) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.reportAlreadyClosed,
        'El acta oficial ya ha sido cerrada y no puede ser modificada.',
      );
    }
    if (!currentReport.currentPeriod.isOpenForEvents) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.matchNotInProgress,
        'El partido debe estar en juego para registrar incidencias.',
      );
    }
    if (minute < 1 || minute > 130) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.invalidMinute,
        'El minuto debe estar entre 1 y 130.',
      );
    }
    if (currentReport.isPlayerExpelled(scorer.id)) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.playerAlreadyExpelled,
        'El jugador anotador ya fue expulsado en el partido.',
      );
    }
    if (assistant != null) {
      if (assistant.id == scorer.id) {
        throw const MatchReportValidationFailure(
          MatchReportErrorCode.invalidAssistantPlayer,
          'El jugador asistente no puede ser el mismo anotador.',
        );
      }
      if (currentReport.isPlayerExpelled(assistant.id)) {
        throw const MatchReportValidationFailure(
          MatchReportErrorCode.playerAlreadyExpelled,
          'El jugador asistente ya fue expulsado en el partido.',
        );
      }
    }

    final currentTime = now ?? DateTime.now();
    final goalEvent = MatchEvent(
      id: 'evt-goal-${currentTime.millisecondsSinceEpoch}-${scorer.id}',
      matchId: match.id,
      type: MatchEventType.goal,
      minute: minute,
      teamId: teamId,
      primaryPlayerId: scorer.id,
      primaryPlayerName: scorer.fullName,
      primaryPlayerShirtNumber: scorer.shirtNumber,
      secondaryPlayerId: assistant?.id,
      secondaryPlayerName: assistant?.fullName,
      secondaryPlayerShirtNumber: assistant?.shirtNumber,
      description: notes,
      isSynced: !isOffline,
      createdAt: currentTime,
    );

    final updatedEvents = [...currentReport.events, goalEvent];
    final newHomeScore = updatedEvents
        .where(
          (e) =>
              e.type == MatchEventType.goal &&
              e.teamId == currentReport.homeTeamId,
        )
        .length;
    final newAwayScore = updatedEvents
        .where(
          (e) =>
              e.type == MatchEventType.goal &&
              e.teamId == currentReport.awayTeamId,
        )
        .length;

    final updatedReport = currentReport.copyWith(
      homeScore: newHomeScore,
      awayScore: newAwayScore,
      events: updatedEvents,
      updatedAt: currentTime,
    );

    // Update match score
    final updatedMatch = match.copyWith(
      homeScore: newHomeScore,
      awayScore: newAwayScore,
      updatedAt: currentTime,
    );
    await tournamentMatchesRepository.saveMatch(updatedMatch);

    return matchReportsRepository.saveReport(
      updatedReport,
      newlyCreatedEvents: [goalEvent],
    );
  }

  Future<DigitalMatchReport> recordDisciplinaryCard({
    required UserRole activeRole,
    required ChampionshipMatch match,
    required DigitalMatchReport currentReport,
    required String teamId,
    required RegisteredPlayer player,
    required bool isDirectRed,
    required int minute,
    String? notes,
    String? actorUserId,
    String? actorRefereeId,
    bool isOffline = false,
    DateTime? now,
  }) async {
    _assertAuthorizedForEvents(
      activeRole,
      match: match,
      actorUserId: actorUserId,
      actorRefereeId: actorRefereeId,
    );

    if (currentReport.isClosed) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.reportAlreadyClosed,
        'El acta oficial ya ha sido cerrada y no puede ser modificada.',
      );
    }
    if (!currentReport.currentPeriod.isOpenForEvents) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.matchNotInProgress,
        'El partido debe estar en juego para registrar incidencias.',
      );
    }
    if (minute < 1 || minute > 130) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.invalidMinute,
        'El minuto debe estar entre 1 y 130.',
      );
    }
    if (currentReport.isPlayerExpelled(player.id)) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.playerAlreadyExpelled,
        'El jugador ya fue expulsado y no puede recibir nuevas tarjetas.',
      );
    }

    final currentTime = now ?? DateTime.now();
    final newEvents = <MatchEvent>[];

    if (isDirectRed) {
      final redCardEvent = MatchEvent(
        id: 'evt-rc-${currentTime.millisecondsSinceEpoch}-${player.id}',
        matchId: match.id,
        type: MatchEventType.directRedCard,
        minute: minute,
        teamId: teamId,
        primaryPlayerId: player.id,
        primaryPlayerName: player.fullName,
        primaryPlayerShirtNumber: player.shirtNumber,
        description: notes,
        isSynced: !isOffline,
        createdAt: currentTime,
      );
      newEvents.add(redCardEvent);
    } else {
      final currentYellows = currentReport.yellowCardCountForPlayer(player.id);
      final ycId = 'evt-yc-${currentTime.millisecondsSinceEpoch}-${player.id}';
      final ycEvent = MatchEvent(
        id: ycId,
        matchId: match.id,
        type: MatchEventType.yellowCard,
        minute: minute,
        teamId: teamId,
        primaryPlayerId: player.id,
        primaryPlayerName: player.fullName,
        primaryPlayerShirtNumber: player.shirtNumber,
        description: notes,
        isSynced: !isOffline,
        createdAt: currentTime,
      );
      newEvents.add(ycEvent);

      // Regla de Doble Amarilla: segunda amarilla en el mismo partido genera expulsión automática
      if (currentYellows >= 1) {
        final expulsionEvent = MatchEvent(
          id: 'evt-syrc-${currentTime.millisecondsSinceEpoch}-${player.id}',
          matchId: match.id,
          type: MatchEventType.secondYellowRedCard,
          minute: minute,
          teamId: teamId,
          primaryPlayerId: player.id,
          primaryPlayerName: player.fullName,
          primaryPlayerShirtNumber: player.shirtNumber,
          linkedParentEventId: ycId,
          description: 'Expulsión automática por segunda tarjeta amarilla',
          isSynced: !isOffline,
          createdAt: currentTime,
        );
        newEvents.add(expulsionEvent);
      }
    }

    final updatedReport = currentReport.copyWith(
      events: [...currentReport.events, ...newEvents],
      updatedAt: currentTime,
    );

    return matchReportsRepository.saveReport(
      updatedReport,
      newlyCreatedEvents: newEvents,
    );
  }

  Future<DigitalMatchReport> recordSubstitution({
    required UserRole activeRole,
    required ChampionshipMatch match,
    required DigitalMatchReport currentReport,
    required String teamId,
    required RegisteredPlayer playerOut,
    required RegisteredPlayer playerIn,
    required int minute,
    String? notes,
    String? actorUserId,
    String? actorRefereeId,
    bool isOffline = false,
    DateTime? now,
  }) async {
    _assertAuthorizedForEvents(
      activeRole,
      match: match,
      actorUserId: actorUserId,
      actorRefereeId: actorRefereeId,
    );

    if (currentReport.isClosed) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.reportAlreadyClosed,
        'El acta oficial ya ha sido cerrada y no puede ser modificada.',
      );
    }
    if (!currentReport.currentPeriod.isOpenForEvents) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.matchNotInProgress,
        'El partido debe estar en juego para registrar incidencias.',
      );
    }
    if (minute < 1 || minute > 130) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.invalidMinute,
        'El minuto debe estar entre 1 y 130.',
      );
    }
    if (playerOut.id == playerIn.id) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.invalidSubstitutionPlayers,
        'El jugador que sale y el que entra deben ser diferentes.',
      );
    }
    if (currentReport.isPlayerExpelled(playerOut.id) ||
        currentReport.isPlayerExpelled(playerIn.id)) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.playerAlreadyExpelled,
        'Un jugador expulsado no puede formar parte de una sustitución.',
      );
    }

    final currentTime = now ?? DateTime.now();
    final subEvent = MatchEvent(
      id: 'evt-sub-${currentTime.millisecondsSinceEpoch}-${playerOut.id}',
      matchId: match.id,
      type: MatchEventType.substitution,
      minute: minute,
      teamId: teamId,
      primaryPlayerId: playerOut.id,
      primaryPlayerName: playerOut.fullName,
      primaryPlayerShirtNumber: playerOut.shirtNumber,
      secondaryPlayerId: playerIn.id,
      secondaryPlayerName: playerIn.fullName,
      secondaryPlayerShirtNumber: playerIn.shirtNumber,
      description: notes,
      isSynced: !isOffline,
      createdAt: currentTime,
    );

    final updatedReport = currentReport.copyWith(
      events: [...currentReport.events, subEvent],
      updatedAt: currentTime,
    );

    return matchReportsRepository.saveReport(
      updatedReport,
      newlyCreatedEvents: [subEvent],
    );
  }

  Future<DigitalMatchReport> removeMatchEvent({
    required UserRole activeRole,
    required ChampionshipMatch match,
    required DigitalMatchReport currentReport,
    required String eventId,
    String? actorUserId,
    String? actorRefereeId,
    DateTime? now,
  }) async {
    _assertAuthorizedForEvents(
      activeRole,
      match: match,
      actorUserId: actorUserId,
      actorRefereeId: actorRefereeId,
    );

    if (currentReport.isClosed) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.reportAlreadyClosed,
        'El acta oficial ya ha sido cerrada y no puede ser modificada.',
      );
    }

    final currentTime = now ?? DateTime.now();

    // Remove event and any automatic linked events (e.g. secondYellowRedCard triggered by this yellow card)
    final filteredEvents = currentReport.events
        .where((e) => e.id != eventId && e.linkedParentEventId != eventId)
        .toList();

    final newHomeScore = filteredEvents
        .where(
          (e) =>
              e.type == MatchEventType.goal &&
              e.teamId == currentReport.homeTeamId,
        )
        .length;
    final newAwayScore = filteredEvents
        .where(
          (e) =>
              e.type == MatchEventType.goal &&
              e.teamId == currentReport.awayTeamId,
        )
        .length;

    final updatedReport = currentReport.copyWith(
      homeScore: newHomeScore,
      awayScore: newAwayScore,
      events: filteredEvents,
      updatedAt: currentTime,
    );

    final updatedMatch = match.copyWith(
      homeScore: newHomeScore,
      awayScore: newAwayScore,
      updatedAt: currentTime,
    );
    await tournamentMatchesRepository.saveMatch(updatedMatch);

    return matchReportsRepository.saveReport(updatedReport);
  }

  Future<DigitalMatchReport> updateRefereeObservations({
    required UserRole activeRole,
    required ChampionshipMatch match,
    required DigitalMatchReport currentReport,
    required String observations,
    String? actorUserId,
    String? actorRefereeId,
    DateTime? now,
  }) async {
    _assertAuthorizedForEvents(
      activeRole,
      match: match,
      actorUserId: actorUserId,
      actorRefereeId: actorRefereeId,
    );

    if (currentReport.isClosed) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.reportAlreadyClosed,
        'El acta oficial ya ha sido cerrada y no puede ser modificada.',
      );
    }

    final trimmed = observations.trim();
    final updatedReport = currentReport.copyWith(
      refereeObservations: trimmed.isEmpty ? null : trimmed,
      clearRefereeObservations: trimmed.isEmpty,
      updatedAt: now ?? DateTime.now(),
    );

    return matchReportsRepository.saveReport(updatedReport);
  }

  Future<DigitalMatchReport> closeOfficialMatchReport({
    required UserRole activeRole,
    required String userId,
    required ChampionshipMatch match,
    required DigitalMatchReport currentReport,
    String? actorRefereeId,
    int? homePenaltyScore,
    int? awayPenaltyScore,
    bool isOffline = false,
    DateTime? now,
  }) async {
    _assertAuthorizedForClose(
      activeRole,
      match: match,
      actorUserId: userId,
      actorRefereeId: actorRefereeId,
    );

    if (currentReport.isClosed) {
      throw const MatchReportValidationFailure(
        MatchReportErrorCode.reportAlreadyClosed,
        'El acta oficial ya ha sido cerrada y no puede ser modificada.',
      );
    }

    final currentTime = now ?? DateTime.now();
    int finalElapsed = currentReport.elapsedSecondsBeforeCurrentPeriod;
    if (currentReport.currentPeriod.isRunning &&
        currentReport.periodStartedAt != null) {
      finalElapsed += max(
        0,
        currentTime.difference(currentReport.periodStartedAt!).inSeconds,
      );
    }

    final closeEvent = MatchEvent(
      id: 'evt-close-${currentTime.millisecondsSinceEpoch}',
      matchId: match.id,
      type: MatchEventType.periodTransition,
      minute: currentReport.currentMatchMinuteAt(currentTime),
      teamId: 'match',
      description: 'Cierre Definitivo de Acta Oficial',
      isSynced: !isOffline,
      createdAt: currentTime,
    );

    final closedReport = currentReport.copyWith(
      homePenaltyScore: homePenaltyScore ?? currentReport.homePenaltyScore,
      awayPenaltyScore: awayPenaltyScore ?? currentReport.awayPenaltyScore,
      currentPeriod: MatchPeriod.closed,
      clearPeriodStartedAt: true,
      elapsedSecondsBeforeCurrentPeriod: finalElapsed,
      closedAt: currentTime,
      closedByUserId: userId,
      events: [...currentReport.events, closeEvent],
      updatedAt: currentTime,
    );

    // Update match to completed
    final completedMatch = match.copyWith(
      status: MatchStatus.completed,
      homeScore: closedReport.homeScore,
      awayScore: closedReport.awayScore,
      homePenaltyScore: closedReport.homePenaltyScore,
      awayPenaltyScore: closedReport.awayPenaltyScore,
      updatedAt: currentTime,
    );
    await tournamentMatchesRepository.saveMatch(completedMatch);

    // Save closed report first so knockout bracket advancement sees it
    final savedReport = await matchReportsRepository.saveReport(
      closedReport,
      newlyCreatedEvents: [closeEvent],
    );

    // Propagate individual stats & suspensions
    await _propagatePlayerStatsAndSanctions(
      tournamentId: match.tournamentId,
      report: savedReport,
    );

    // Automatically advance knockout bracket winners if applicable (FR-006)
    await _advanceKnockoutWinnersIfApplicable(
      tournamentId: match.tournamentId,
      now: currentTime,
    );

    return savedReport;
  }

  Future<void> _advanceKnockoutWinnersIfApplicable({
    required String tournamentId,
    required DateTime now,
  }) async {
    try {
      final tournaments = await tournamentsRepository.loadTournaments();
      final tournament = tournaments
          .where((t) => t.id == tournamentId)
          .firstOrNull;
      if (tournament == null || !tournament.format.hasKnockoutBracket) {
        return;
      }

      final allMatches = await tournamentMatchesRepository
          .loadMatchesForTournament(tournamentId);
      final allReports = await matchReportsRepository.loadReportsForTournament(
        tournamentId,
      );
      final teams = teamsRepository != null
          ? await teamsRepository!.loadTeamsForTournament(tournamentId)
          : const <TournamentTeam>[];

      final nextRoundUpdates = knockoutBracketService
          .computeUpdatedMatchesWithAdvancement(
            tournament: tournament,
            teams: teams,
            currentMatches: allMatches,
            reports: allReports,
            now: now,
          );

      if (nextRoundUpdates.isNotEmpty) {
        await tournamentMatchesRepository.saveMatchesBatch(nextRoundUpdates);
      }
    } catch (_) {
      // Non-blocking fallback for bracket auto-advancement
    }
  }

  Future<void> _propagatePlayerStatsAndSanctions({
    required String tournamentId,
    required DigitalMatchReport report,
  }) async {
    try {
      final tournaments = await tournamentsRepository.loadTournaments();
      final tournament = tournaments
          .where((t) => t.id == tournamentId)
          .firstOrNull;
      final yellowThreshold = tournament?.rules.yellowCardSuspensionLimit ?? 3;

      // Collect match stats per player
      final goalsPerPlayer = <String, int>{};
      final assistsPerPlayer = <String, int>{};
      final yellowsPerPlayer = <String, int>{};
      final redsPerPlayer = <String, int>{};
      final playerTeamMap = <String, String>{};

      for (final event in report.events) {
        if (event.primaryPlayerId != null && event.teamId != 'match') {
          playerTeamMap[event.primaryPlayerId!] = event.teamId;
        }
        if (event.secondaryPlayerId != null && event.teamId != 'match') {
          playerTeamMap[event.secondaryPlayerId!] = event.teamId;
        }

        if (event.type == MatchEventType.goal &&
            event.primaryPlayerId != null) {
          goalsPerPlayer[event.primaryPlayerId!] =
              (goalsPerPlayer[event.primaryPlayerId!] ?? 0) + 1;
          if (event.secondaryPlayerId != null) {
            assistsPerPlayer[event.secondaryPlayerId!] =
                (assistsPerPlayer[event.secondaryPlayerId!] ?? 0) + 1;
          }
        } else if (event.type == MatchEventType.yellowCard &&
            event.primaryPlayerId != null) {
          yellowsPerPlayer[event.primaryPlayerId!] =
              (yellowsPerPlayer[event.primaryPlayerId!] ?? 0) + 1;
        } else if ((event.type == MatchEventType.directRedCard ||
                event.type == MatchEventType.secondYellowRedCard) &&
            event.primaryPlayerId != null) {
          redsPerPlayer[event.primaryPlayerId!] =
              (redsPerPlayer[event.primaryPlayerId!] ?? 0) + 1;
        }
      }

      final allPlayerIds = {
        ...goalsPerPlayer.keys,
        ...assistsPerPlayer.keys,
        ...yellowsPerPlayer.keys,
        ...redsPerPlayer.keys,
      };

      for (final pId in allPlayerIds) {
        final teamId = playerTeamMap[pId] ?? report.homeTeamId;
        final currentList = await lineupsTrackingRepository.loadTrackingForTeam(
          tournamentId,
          teamId,
          const [],
        );
        final current =
            currentList.where((t) => t.playerId == pId).firstOrNull ??
            PlayerInternalTracking(
              playerId: pId,
              teamId: teamId,
              tournamentId: tournamentId,
            );

        final newGoals = current.goals + (goalsPerPlayer[pId] ?? 0);
        final newAssists = current.assists + (assistsPerPlayer[pId] ?? 0);
        final newYellows = current.yellowCards + (yellowsPerPlayer[pId] ?? 0);
        final newReds = current.redCards + (redsPerPlayer[pId] ?? 0);

        int newSuspension = current.pendingSuspensionMatches;
        if ((redsPerPlayer[pId] ?? 0) > 0) {
          newSuspension += 1;
        } else if (newYellows >= yellowThreshold &&
            current.yellowCards < yellowThreshold) {
          newSuspension += 1;
        }

        final updated = current.copyWith(
          matchesPlayed: current.matchesPlayed + 1,
          goals: newGoals,
          assists: newAssists,
          yellowCards: newYellows,
          redCards: newReds,
          pendingSuspensionMatches: newSuspension,
        );
        await lineupsTrackingRepository.savePlayerTracking(updated);
      }
    } catch (_) {
      // Non-blocking fallback for stat propagation in local development
    }
  }
}
