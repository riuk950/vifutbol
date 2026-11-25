import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/championship_match.dart';
import '../../domain/entities/digital_match_report_state.dart';
import '../../domain/entities/match_enums.dart';
import '../../domain/entities/match_report_enums.dart';
import '../../domain/entities/registered_player.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/repositories/lineups_tracking_repository.dart';
import '../../domain/repositories/match_reports_repository.dart';
import '../../domain/repositories/teams_repository.dart';
import '../../domain/repositories/tournament_matches_repository.dart';
import '../use_cases/manage_digital_match_report_use_case.dart';

class DigitalMatchReportController
    extends StateNotifier<DigitalMatchReportState> {
  DigitalMatchReportController({
    required this.useCase,
    required this.teamsRepository,
    required this.lineupsTrackingRepository,
    required this.matchReportsRepository,
    required this.matchesRepository,
  }) : super(const DigitalMatchReportState());

  final ManageDigitalMatchReportUseCase useCase;
  final TeamsRepository teamsRepository;
  final LineupsTrackingRepository lineupsTrackingRepository;
  final MatchReportsRepository matchReportsRepository;
  final TournamentMatchesRepository matchesRepository;

  Future<void> loadReportForMatch(
    ChampionshipMatch match, {
    UserRole activeRole = UserRole.referee,
  }) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final report = await useCase.loadOrCreateReport(match);

      final teams = await teamsRepository.loadTeamsForTournament(
        match.tournamentId,
      );

      final homeTeam = teams.firstWhere(
        (t) => t.id == match.homeTeamId,
        orElse: () => teams.isNotEmpty
            ? teams.first
            : throw StateError('Home team not found'),
      );
      final awayTeam = teams.firstWhere(
        (t) => t.id == match.awayTeamId,
        orElse: () => teams.length > 1
            ? teams[1]
            : throw StateError('Away team not found'),
      );

      // Attempt to load official convocation rosters (HU 5.2), fallback to eligible roster players (HU 5.1)
      final homeConvocation = await lineupsTrackingRepository
          .loadConvocationForTeam(match.tournamentId, homeTeam.id);
      final awayConvocation = await lineupsTrackingRepository
          .loadConvocationForTeam(match.tournamentId, awayTeam.id);

      final homePlayers = _resolveRosterPlayers(
        homeTeam.players,
        homeConvocation.allPlayerIds,
      );
      final awayPlayers = _resolveRosterPlayers(
        awayTeam.players,
        awayConvocation.allPlayerIds,
      );

      final pendingSync = await matchReportsRepository.loadPendingSyncQueue(
        match.id,
      );

      state = state.copyWith(
        match: match,
        report: report,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeEligiblePlayers: homePlayers,
        awayEligiblePlayers: awayPlayers,
        homeConvocationConfirmed: homeConvocation.allPlayerIds.isNotEmpty,
        awayConvocationConfirmed: awayConvocation.allPlayerIds.isNotEmpty,
        pendingSyncEventsCount: pendingSync.length,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is AppFailure ? e.message : e.toString(),
      );
    }
  }

  List<RegisteredPlayer> _resolveRosterPlayers(
    List<RegisteredPlayer> allPlayers,
    List<String>? convocationIds,
  ) {
    if (convocationIds != null && convocationIds.isNotEmpty) {
      final idSet = convocationIds.toSet();
      final convPlayers = allPlayers
          .where((p) => idSet.contains(p.id))
          .toList();
      if (convPlayers.isNotEmpty) return convPlayers;
    }
    // Fallback: all eligible players from roster, or all if none explicitly eligible
    final eligible = allPlayers.where((p) => p.isEligible).toList();
    return eligible.isNotEmpty ? eligible : allPlayers;
  }

  void setOfflineMode(bool isOffline) {
    state = state.copyWith(isOfflineMode: isOffline);
  }

  Future<bool> transitionPeriod(
    MatchPeriod targetPeriod, {
    required UserRole activeRole,
    String? actorUserId,
    String? actorRefereeId,
  }) async {
    if (state.isSubmitting) return false;
    final currentReport = state.report;
    final currentMatch = state.match;
    if (currentReport == null || currentMatch == null) return false;

    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);
    try {
      final updatedReport = await useCase.transitionMatchPeriod(
        activeRole: activeRole,
        match: currentMatch,
        currentReport: currentReport,
        targetPeriod: targetPeriod,
        actorUserId: actorUserId,
        actorRefereeId: actorRefereeId,
        isOffline: state.isOfflineMode,
      );

      final updatedMatch = currentMatch.copyWith(
        status: targetPeriod.isRunning
            ? MatchStatus.inProgress
            : (targetPeriod == MatchPeriod.closed
                  ? MatchStatus.completed
                  : currentMatch.status),
      );

      final queue = await matchReportsRepository.loadPendingSyncQueue(
        currentMatch.id,
      );

      state = state.copyWith(
        match: updatedMatch,
        report: updatedReport,
        pendingSyncEventsCount: queue.length,
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e is AppFailure ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<bool> recordGoal({
    required UserRole activeRole,
    required String teamId,
    required RegisteredPlayer scorer,
    RegisteredPlayer? assistant,
    required int minute,
    String? notes,
    String? actorUserId,
    String? actorRefereeId,
  }) async {
    if (state.isSubmitting) return false;
    final currentReport = state.report;
    final currentMatch = state.match;
    if (currentReport == null || currentMatch == null) return false;

    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);
    try {
      final updatedReport = await useCase.recordGoalEvent(
        activeRole: activeRole,
        match: currentMatch,
        currentReport: currentReport,
        teamId: teamId,
        scorer: scorer,
        assistant: assistant,
        minute: minute,
        notes: notes,
        actorUserId: actorUserId,
        actorRefereeId: actorRefereeId,
        isOffline: state.isOfflineMode,
      );

      final updatedMatch = currentMatch.copyWith(
        homeScore: updatedReport.homeScore,
        awayScore: updatedReport.awayScore,
      );

      final queue = await matchReportsRepository.loadPendingSyncQueue(
        currentMatch.id,
      );

      state = state.copyWith(
        match: updatedMatch,
        report: updatedReport,
        pendingSyncEventsCount: queue.length,
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e is AppFailure ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<bool> recordCard({
    required UserRole activeRole,
    required String teamId,
    required RegisteredPlayer player,
    required bool isDirectRed,
    required int minute,
    String? notes,
    String? actorUserId,
    String? actorRefereeId,
  }) async {
    if (state.isSubmitting) return false;
    final currentReport = state.report;
    final currentMatch = state.match;
    if (currentReport == null || currentMatch == null) return false;

    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);
    try {
      final updatedReport = await useCase.recordDisciplinaryCard(
        activeRole: activeRole,
        match: currentMatch,
        currentReport: currentReport,
        teamId: teamId,
        player: player,
        isDirectRed: isDirectRed,
        minute: minute,
        notes: notes,
        actorUserId: actorUserId,
        actorRefereeId: actorRefereeId,
        isOffline: state.isOfflineMode,
      );

      final queue = await matchReportsRepository.loadPendingSyncQueue(
        currentMatch.id,
      );

      state = state.copyWith(
        report: updatedReport,
        pendingSyncEventsCount: queue.length,
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e is AppFailure ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<bool> recordSubstitution({
    required UserRole activeRole,
    required String teamId,
    required RegisteredPlayer playerOut,
    required RegisteredPlayer playerIn,
    required int minute,
    String? notes,
    String? actorUserId,
    String? actorRefereeId,
  }) async {
    if (state.isSubmitting) return false;
    final currentReport = state.report;
    final currentMatch = state.match;
    if (currentReport == null || currentMatch == null) return false;

    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);
    try {
      final updatedReport = await useCase.recordSubstitution(
        activeRole: activeRole,
        match: currentMatch,
        currentReport: currentReport,
        teamId: teamId,
        playerOut: playerOut,
        playerIn: playerIn,
        minute: minute,
        notes: notes,
        actorUserId: actorUserId,
        actorRefereeId: actorRefereeId,
        isOffline: state.isOfflineMode,
      );

      final queue = await matchReportsRepository.loadPendingSyncQueue(
        currentMatch.id,
      );

      state = state.copyWith(
        report: updatedReport,
        pendingSyncEventsCount: queue.length,
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e is AppFailure ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<bool> removeEvent(
    String eventId, {
    required UserRole activeRole,
    String? actorUserId,
    String? actorRefereeId,
  }) async {
    if (state.isSubmitting) return false;
    final currentReport = state.report;
    final currentMatch = state.match;
    if (currentReport == null || currentMatch == null) return false;

    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);
    try {
      final updatedReport = await useCase.removeMatchEvent(
        activeRole: activeRole,
        match: currentMatch,
        currentReport: currentReport,
        eventId: eventId,
        actorUserId: actorUserId,
        actorRefereeId: actorRefereeId,
      );

      final updatedMatch = currentMatch.copyWith(
        homeScore: updatedReport.homeScore,
        awayScore: updatedReport.awayScore,
      );

      final queue = await matchReportsRepository.loadPendingSyncQueue(
        currentMatch.id,
      );

      state = state.copyWith(
        match: updatedMatch,
        report: updatedReport,
        pendingSyncEventsCount: queue.length,
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e is AppFailure ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateObservations({
    required UserRole activeRole,
    required String observations,
    String? actorUserId,
    String? actorRefereeId,
  }) async {
    if (state.isSubmitting) return false;
    final currentReport = state.report;
    final currentMatch = state.match;
    if (currentReport == null || currentMatch == null) return false;

    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);
    try {
      final updatedReport = await useCase.updateRefereeObservations(
        activeRole: activeRole,
        match: currentMatch,
        currentReport: currentReport,
        observations: observations,
        actorUserId: actorUserId,
        actorRefereeId: actorRefereeId,
      );

      state = state.copyWith(
        report: updatedReport,
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e is AppFailure ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<bool> synchronizeOfflineQueue() async {
    if (state.isSubmitting) return false;
    final currentMatch = state.match;
    if (currentMatch == null) return false;

    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);
    try {
      final updatedReport = await matchReportsRepository
          .synchronizePendingEvents(currentMatch.id);

      state = state.copyWith(
        report: updatedReport,
        pendingSyncEventsCount: 0,
        isOfflineMode: false,
        isSubmitting: false,
        lastActionFeedback: 'Todos los eventos sincronizados exitosamente',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e is AppFailure ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<bool> closeReport({
    required UserRole activeRole,
    required String userId,
    String? actorRefereeId,
    int? homePenaltyScore,
    int? awayPenaltyScore,
  }) async {
    if (state.isSubmitting) return false;
    final currentReport = state.report;
    final currentMatch = state.match;
    if (currentReport == null || currentMatch == null) return false;

    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);
    try {
      final updatedReport = await useCase.closeOfficialMatchReport(
        activeRole: activeRole,
        userId: userId,
        match: currentMatch,
        currentReport: currentReport,
        actorRefereeId: actorRefereeId,
        homePenaltyScore: homePenaltyScore,
        awayPenaltyScore: awayPenaltyScore,
        isOffline: state.isOfflineMode,
      );

      final updatedMatch = currentMatch.copyWith(
        status: MatchStatus.completed,
        homeScore: updatedReport.homeScore,
        awayScore: updatedReport.awayScore,
        homePenaltyScore: updatedReport.homePenaltyScore,
        awayPenaltyScore: updatedReport.awayPenaltyScore,
      );

      state = state.copyWith(
        match: updatedMatch,
        report: updatedReport,
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e is AppFailure ? e.message : e.toString(),
      );
      return false;
    }
  }
}
