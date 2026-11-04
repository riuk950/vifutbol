import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/use_cases/manage_lineups_tracking_use_case.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_lineup_convocation.dart';
import 'package:vifutbol/domain/entities/player_internal_tracking.dart';
import 'package:vifutbol/domain/entities/team_lineups_tracking_state.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/lineups_tracking_repository.dart';

/// StateNotifier controlling coach lineups, match convocations, and internal player tracking.
class LineupsTrackingController
    extends StateNotifier<TeamLineupsTrackingState> {
  final LineupsTrackingRepository repository;
  final ManageLineupsTrackingUseCase manageLineupsTrackingUseCase;

  LineupsTrackingController({
    required this.repository,
    required this.manageLineupsTrackingUseCase,
  }) : super(const TeamLineupsTrackingState());

  /// Loads the convocation and tracking records for the given team and tournament.
  Future<void> loadForTeam({
    required String tournamentId,
    required TournamentTeam team,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final convocation = await repository.loadConvocationForTeam(
        tournamentId,
        team.id,
      );
      final trackingList = await repository.loadTrackingForTeam(
        tournamentId,
        team.id,
        team.players,
      );

      final updatedConvs = Map<String, MatchLineupConvocation>.from(
        state.convocationsByTeamId,
      );
      updatedConvs[team.id] = convocation;

      final updatedTracking = Map<String, PlayerInternalTracking>.from(
        state.trackingByPlayerId,
      );
      for (final t in trackingList) {
        updatedTracking[t.playerId] = t;
      }

      state = state.copyWith(
        convocationsByTeamId: updatedConvs,
        trackingByPlayerId: updatedTracking,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  /// Toggles or sets a player's role in the draft convocation.
  Future<void> setPlayerRole({
    required UserRole activeRole,
    required ChampionshipTournament tournament,
    required TournamentTeam team,
    required String playerId,
    required bool isStarter,
    required bool isSubstitute,
  }) async {
    final currentConv =
        state.convocationForTeam(team.id) ??
        MatchLineupConvocation(
          id: 'conv-${tournament.id}-${team.id}',
          tournamentId: tournament.id,
          teamId: team.id,
        );

    final starters = List<String>.from(currentConv.starterPlayerIds);
    final substitutes = List<String>.from(currentConv.substitutePlayerIds);
    String? captain = currentConv.captainPlayerId;

    starters.remove(playerId);
    substitutes.remove(playerId);

    if (isStarter) {
      starters.add(playerId);
    } else if (isSubstitute) {
      substitutes.add(playerId);
      if (captain == playerId) {
        captain = null;
      }
    } else {
      if (captain == playerId) {
        captain = null;
      }
    }

    try {
      final updated = await manageLineupsTrackingUseCase.updateDraftSelection(
        activeRole: activeRole,
        tournament: tournament,
        team: team,
        starterPlayerIds: starters,
        substitutePlayerIds: substitutes,
        captainPlayerId: captain,
        trackingByPlayerId: state.trackingByPlayerId,
      );

      final updatedConvs = Map<String, MatchLineupConvocation>.from(
        state.convocationsByTeamId,
      );
      updatedConvs[team.id] = updated;

      state = state.copyWith(
        convocationsByTeamId: updatedConvs,
        errorMessage: () => null,
      );
    } on LineupConvocationValidationFailure catch (failure) {
      state = state.copyWith(errorMessage: () => failure.message);
      rethrow;
    }
  }

  /// Designates a starter player as team captain.
  Future<void> setCaptain({
    required UserRole activeRole,
    required ChampionshipTournament tournament,
    required TournamentTeam team,
    required String playerId,
  }) async {
    final currentConv = state.convocationForTeam(team.id);
    if (currentConv == null) return;

    try {
      final updated = await manageLineupsTrackingUseCase.updateDraftSelection(
        activeRole: activeRole,
        tournament: tournament,
        team: team,
        starterPlayerIds: currentConv.starterPlayerIds,
        substitutePlayerIds: currentConv.substitutePlayerIds,
        captainPlayerId: playerId,
        trackingByPlayerId: state.trackingByPlayerId,
      );

      final updatedConvs = Map<String, MatchLineupConvocation>.from(
        state.convocationsByTeamId,
      );
      updatedConvs[team.id] = updated;

      state = state.copyWith(
        convocationsByTeamId: updatedConvs,
        errorMessage: () => null,
      );
    } on LineupConvocationValidationFailure catch (failure) {
      state = state.copyWith(errorMessage: () => failure.message);
      rethrow;
    }
  }

  /// Confirms the official match convocation and synchronizes with referee report.
  Future<MatchLineupConvocation> confirmConvocation({
    required UserRole activeRole,
    required ChampionshipTournament tournament,
    required TournamentTeam team,
  }) async {
    final currentConv =
        state.convocationForTeam(team.id) ??
        MatchLineupConvocation(
          id: 'conv-${tournament.id}-${team.id}',
          tournamentId: tournament.id,
          teamId: team.id,
        );

    state = state.copyWith(isSaving: true, errorMessage: () => null);

    try {
      final confirmed = await manageLineupsTrackingUseCase
          .confirmOfficialConvocation(
            activeRole: activeRole,
            tournament: tournament,
            team: team,
            starterPlayerIds: currentConv.starterPlayerIds,
            substitutePlayerIds: currentConv.substitutePlayerIds,
            captainPlayerId: currentConv.captainPlayerId,
            trackingByPlayerId: state.trackingByPlayerId,
          );

      final updatedConvs = Map<String, MatchLineupConvocation>.from(
        state.convocationsByTeamId,
      );
      updatedConvs[team.id] = confirmed;

      state = state.copyWith(
        convocationsByTeamId: updatedConvs,
        isSaving: false,
        errorMessage: () => null,
      );
      return confirmed;
    } on LineupConvocationValidationFailure catch (failure) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => failure.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: () => e.toString());
      rethrow;
    }
  }

  /// Updates internal tracking metrics for a player.
  Future<void> updatePlayerMetrics({
    required UserRole activeRole,
    required ChampionshipTournament tournament,
    required TournamentTeam team,
    required PlayerInternalTracking updatedTracking,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: () => null);

    try {
      final saved = await manageLineupsTrackingUseCase
          .updatePlayerInternalTracking(
            activeRole: activeRole,
            tournament: tournament,
            team: team,
            updatedTracking: updatedTracking,
          );

      final updatedTrackingMap = Map<String, PlayerInternalTracking>.from(
        state.trackingByPlayerId,
      );
      updatedTrackingMap[saved.playerId] = saved;

      // Re-fetch convocation to account for potential cleanup of suspended player
      final freshConv = await repository.loadConvocationForTeam(
        tournament.id,
        team.id,
      );
      final updatedConvs = Map<String, MatchLineupConvocation>.from(
        state.convocationsByTeamId,
      );
      updatedConvs[team.id] = freshConv;

      state = state.copyWith(
        trackingByPlayerId: updatedTrackingMap,
        convocationsByTeamId: updatedConvs,
        isSaving: false,
        errorMessage: () => null,
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: () => e.toString());
      rethrow;
    }
  }
}
