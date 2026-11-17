import 'package:vifutbol/domain/entities/available_player_candidate.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/team_join_request.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/team_join_requests_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';

/// Orchestrates sending team join invitations, searching registered players,
/// canceling invitations, and player responses (accept / reject).
class ManageTeamJoinRequestsUseCase {
  const ManageTeamJoinRequestsUseCase({
    required this.repository,
    this.teamsRepository,
  });

  final TeamJoinRequestsRepository repository;
  final TeamsRepository? teamsRepository;

  /// Searches registered users with the 'player' role matching [query].
  Future<List<AvailablePlayerCandidate>> searchRegisteredPlayers({
    String query = '',
    required UserRole actorRole,
  }) async {
    if (actorRole != UserRole.coach && actorRole != UserRole.organizer) {
      throw const UnauthorizedRoleFailure(
        'Solo los entrenadores y organizadores pueden buscar jugadores para invitar.',
      );
    }
    return repository.searchRegisteredPlayers(query: query);
  }

  /// Loads sent requests for the specified [teamId].
  Future<List<TeamJoinRequest>> loadRequestsForTeam(String teamId) {
    return repository.loadRequestsForTeam(teamId);
  }

  /// Loads pending requests received by the currently authenticated player.
  Future<List<TeamJoinRequest>> loadRequestsForCurrentPlayer() {
    return repository.loadRequestsForCurrentPlayer();
  }

  /// Sends a join request invitation to [candidate] for [team].
  Future<TeamJoinRequest> sendJoinRequest({
    required TournamentTeam team,
    required AvailablePlayerCandidate candidate,
    required int shirtNumber,
    required PlayerPosition position,
    required UserRole actorRole,
  }) async {
    if (actorRole != UserRole.coach && actorRole != UserRole.organizer) {
      throw const UnauthorizedRoleFailure(
        'Solo los entrenadores pueden enviar invitaciones de equipo.',
      );
    }

    if (shirtNumber < 1 || shirtNumber > 99) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.invalidShirtNumber,
        'El dorsal debe estar comprendido entre 1 y 99.',
      );
    }

    // Check roster conflict
    if (team.players.any((p) => p.shirtNumber == shirtNumber)) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.duplicateShirtNumberInTeam,
        'El dorsal propuesto ya se encuentra asignado a un jugador del equipo.',
      );
    }

    // Check candidate document in roster
    if (team.players.any(
      (p) =>
          p.normalizedDocumentId == candidate.normalizedDocumentId ||
          p.id == candidate.userAccountId,
    )) {
      throw const TeamEligibilityValidationFailure(
        TeamEligibilityErrorCode.playerAlreadyRegisteredInTournament,
        'El jugador ya se encuentra inscrito en la planilla de este equipo.',
      );
    }

    return repository.sendJoinRequest(
      team: team,
      candidate: candidate,
      shirtNumber: shirtNumber,
      position: position,
    );
  }

  /// Responds to a team join request (accept or reject) on behalf of a player.
  Future<TeamJoinRequest> respondToJoinRequest({
    required String requestId,
    required bool accept,
    required UserRole actorRole,
  }) async {
    if (actorRole != UserRole.player) {
      throw const UnauthorizedRoleFailure(
        'Solo los jugadores pueden aceptar o rechazar solicitudes de incorporación.',
      );
    }

    final updatedRequest = await repository.respondToJoinRequest(
      requestId: requestId,
      accept: accept,
    );

    // If accepted and teams repository is present, synchronize the local roster if needed
    if (accept && teamsRepository != null) {
      try {
        final allTeams = await teamsRepository!.loadTeams();
        final teamIndex = allTeams.indexWhere(
          (t) => t.id == updatedRequest.teamId,
        );
        if (teamIndex >= 0) {
          final team = allTeams[teamIndex];
          final alreadyInRoster = team.players.any(
            (p) =>
                p.id == updatedRequest.playerAccountId ||
                p.normalizedDocumentId ==
                    updatedRequest.playerDocumentId.trim().toUpperCase(),
          );

          if (!alreadyInRoster) {
            final newPlayer = RegisteredPlayer(
              id: updatedRequest.playerAccountId,
              fullName: updatedRequest.playerName,
              documentId: updatedRequest.playerDocumentId,
              shirtNumber: updatedRequest.shirtNumber,
              position: updatedRequest.position,
              isEligible: false,
            );
            final updatedTeam = team.copyWith(
              players: [...team.players, newPlayer],
              updatedAt: DateTime.now(),
            );
            await teamsRepository!.saveTeam(updatedTeam);
          }
        }
      } catch (_) {
        // Suppress local sync failure; remote RPC handles database consistency
      }
    }

    return updatedRequest;
  }

  /// Cancels a pending join request.
  Future<void> cancelJoinRequest({
    required String requestId,
    required UserRole actorRole,
  }) async {
    if (actorRole != UserRole.coach && actorRole != UserRole.organizer) {
      throw const UnauthorizedRoleFailure(
        'Solo los entrenadores u organizadores pueden cancelar invitaciones enviadas.',
      );
    }

    return repository.cancelJoinRequest(requestId);
  }
}
