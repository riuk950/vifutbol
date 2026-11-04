import 'dart:math';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/lineup_enums.dart';
import 'package:vifutbol/domain/entities/match_lineup_convocation.dart';
import 'package:vifutbol/domain/entities/player_internal_tracking.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/lineups_tracking_repository.dart';

/// Use case handling coach match convocations, referee roster synchronization,
/// and internal squad performance tracking.
class ManageLineupsTrackingUseCase {
  final LineupsTrackingRepository repository;

  ManageLineupsTrackingUseCase(this.repository);

  /// Calculates the required starters on the pitch according to tournament rules (max 11).
  int requiredStartersForTournament(ChampionshipTournament tournament) {
    final minPlayers = tournament.rules.minPlayersPerTeam;
    return min(minPlayers > 0 ? minPlayers : 7, 11);
  }

  /// Updates the draft convocation selection, ensuring immediate local persistence.
  Future<MatchLineupConvocation> updateDraftSelection({
    required UserRole activeRole,
    required ChampionshipTournament tournament,
    required TournamentTeam team,
    required List<String> starterPlayerIds,
    required List<String> substitutePlayerIds,
    required String? captainPlayerId,
    required Map<String, PlayerInternalTracking> trackingByPlayerId,
  }) async {
    _ensureCoachOrOrganizer(activeRole);

    final yellowLimit = tournament.rules.yellowCardSuspensionLimit;

    // Disallow drafting suspended players
    for (final playerId in starterPlayerIds) {
      final tracking = trackingByPlayerId[playerId];
      if (tracking != null && tracking.isSuspended(yellowLimit)) {
        final player = team.players.firstWhere((p) => p.id == playerId);
        throw LineupConvocationValidationFailure(
          LineupConvocationErrorCode.suspendedPlayerSelected,
          'No puedes convocar al jugador ${player.fullName} porque se encuentra suspendido',
          player.fullName,
        );
      }
    }

    for (final playerId in substitutePlayerIds) {
      final tracking = trackingByPlayerId[playerId];
      if (tracking != null && tracking.isSuspended(yellowLimit)) {
        final player = team.players.firstWhere((p) => p.id == playerId);
        throw LineupConvocationValidationFailure(
          LineupConvocationErrorCode.suspendedPlayerSelected,
          'No puedes convocar al jugador ${player.fullName} porque se encuentra suspendido',
          player.fullName,
        );
      }
    }

    // Captain must be among starters; clean if not
    final verifiedCaptain =
        (captainPlayerId != null && starterPlayerIds.contains(captainPlayerId))
        ? captainPlayerId
        : null;

    final existing = await repository.loadConvocationForTeam(
      tournament.id,
      team.id,
    );

    final updated = existing.copyWith(
      starterPlayerIds: starterPlayerIds,
      substitutePlayerIds: substitutePlayerIds,
      captainPlayerId: () => verifiedCaptain,
      status: ConvocationStatus.draft,
      updatedAt: DateTime.now(),
    );

    return repository.saveConvocation(updated);
  }

  /// Validates and confirms the official match convocation, creating a snapshot
  /// immediately visible in the referee's digital match report.
  Future<MatchLineupConvocation> confirmOfficialConvocation({
    required UserRole activeRole,
    required ChampionshipTournament tournament,
    required TournamentTeam team,
    required List<String> starterPlayerIds,
    required List<String> substitutePlayerIds,
    required String? captainPlayerId,
    required Map<String, PlayerInternalTracking> trackingByPlayerId,
  }) async {
    _ensureCoachOrOrganizer(activeRole);

    if (team.eligibilityStatus != TeamEligibilityStatus.eligible) {
      throw const LineupConvocationValidationFailure(
        LineupConvocationErrorCode.teamNotEligible,
        'El equipo debe estar oficialmente Habilitado para confirmar una alineación oficial.',
      );
    }

    final yellowLimit = tournament.rules.yellowCardSuspensionLimit;
    final requiredStarters = requiredStartersForTournament(tournament);

    if (starterPlayerIds.length != requiredStarters) {
      throw LineupConvocationValidationFailure(
        LineupConvocationErrorCode.invalidStartersCount,
        'Debes seleccionar exactamente $requiredStarters titulares (actual: ${starterPlayerIds.length}).',
        '${starterPlayerIds.length}/$requiredStarters',
      );
    }

    if (captainPlayerId == null ||
        !starterPlayerIds.contains(captainPlayerId)) {
      throw const LineupConvocationValidationFailure(
        LineupConvocationErrorCode.missingCaptain,
        'Debes designar un capitán dentro de los jugadores titulares.',
      );
    }

    // Verify no suspended players
    for (final playerId in starterPlayerIds) {
      final tracking = trackingByPlayerId[playerId];
      if (tracking != null && tracking.isSuspended(yellowLimit)) {
        final player = team.players.firstWhere((p) => p.id == playerId);
        throw LineupConvocationValidationFailure(
          LineupConvocationErrorCode.suspendedPlayerSelected,
          'No puedes convocar al jugador ${player.fullName} porque se encuentra suspendido',
          player.fullName,
        );
      }
    }

    for (final playerId in substitutePlayerIds) {
      final tracking = trackingByPlayerId[playerId];
      if (tracking != null && tracking.isSuspended(yellowLimit)) {
        final player = team.players.firstWhere((p) => p.id == playerId);
        throw LineupConvocationValidationFailure(
          LineupConvocationErrorCode.suspendedPlayerSelected,
          'No puedes convocar al jugador ${player.fullName} porque se encuentra suspendido',
          player.fullName,
        );
      }
    }

    final existing = await repository.loadConvocationForTeam(
      tournament.id,
      team.id,
    );

    final confirmed = existing.copyWith(
      starterPlayerIds: starterPlayerIds,
      substitutePlayerIds: substitutePlayerIds,
      captainPlayerId: () => captainPlayerId,
      status: ConvocationStatus.confirmed,
      confirmedStarterPlayerIds: starterPlayerIds,
      confirmedSubstitutePlayerIds: substitutePlayerIds,
      confirmedCaptainPlayerId: () => captainPlayerId,
      confirmedAt: () => DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return repository.saveConvocation(confirmed);
  }

  /// Updates a player's internal tracking metrics and cleans them from active drafts if suspended.
  Future<PlayerInternalTracking> updatePlayerInternalTracking({
    required UserRole activeRole,
    required ChampionshipTournament tournament,
    required TournamentTeam team,
    required PlayerInternalTracking updatedTracking,
  }) async {
    _ensureCoachOrOrganizer(activeRole);

    final saved = await repository.savePlayerTracking(updatedTracking);

    // If newly suspended, clean from current draft convocation
    if (saved.isSuspended(tournament.rules.yellowCardSuspensionLimit)) {
      final currentConv = await repository.loadConvocationForTeam(
        tournament.id,
        team.id,
      );

      final hasStarters = currentConv.starterPlayerIds.contains(saved.playerId);
      final hasSubstitutes = currentConv.substitutePlayerIds.contains(
        saved.playerId,
      );

      if (hasStarters || hasSubstitutes) {
        final newStarters = currentConv.starterPlayerIds
            .where((id) => id != saved.playerId)
            .toList();
        final newSubstitutes = currentConv.substitutePlayerIds
            .where((id) => id != saved.playerId)
            .toList();
        final newCaptain = (currentConv.captainPlayerId == saved.playerId)
            ? null
            : currentConv.captainPlayerId;

        final cleanedConv = currentConv.copyWith(
          starterPlayerIds: newStarters,
          substitutePlayerIds: newSubstitutes,
          captainPlayerId: () => newCaptain,
          status: ConvocationStatus.draft,
          updatedAt: DateTime.now(),
        );

        await repository.saveConvocation(cleanedConv);
      }
    }

    return saved;
  }

  void _ensureCoachOrOrganizer(UserRole role) {
    final canManageLineups = RolePermissionMatrix.hasCapability(
      role,
      RoleCapability.manageLineups,
    );
    final canManageTournaments = RolePermissionMatrix.hasCapability(
      role,
      RoleCapability.manageTournaments,
    );

    if (!canManageLineups && !canManageTournaments) {
      throw const LineupConvocationValidationFailure(
        LineupConvocationErrorCode.unauthorizedRole,
        'No tienes permisos para gestionar la convocatoria o seguimiento de este equipo.',
      );
    }
  }
}
