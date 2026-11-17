import 'package:vifutbol/domain/entities/available_player_candidate.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/team_join_request.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';

/// Repository interface for searching registered players and managing team join requests.
abstract interface class TeamJoinRequestsRepository {
  /// Searches registered users with the 'player' role matching [query] by name or document ID.
  Future<List<AvailablePlayerCandidate>> searchRegisteredPlayers({
    String query = '',
  });

  /// Loads all join requests sent on behalf of [teamId].
  Future<List<TeamJoinRequest>> loadRequestsForTeam(String teamId);

  /// Loads all pending join requests sent to the currently authenticated player.
  Future<List<TeamJoinRequest>> loadRequestsForCurrentPlayer();

  /// Sends a new join request to [candidate] with a proposed [shirtNumber] and [position].
  Future<TeamJoinRequest> sendJoinRequest({
    required TournamentTeam team,
    required AvailablePlayerCandidate candidate,
    required int shirtNumber,
    required PlayerPosition position,
  });

  /// Accepts or rejects a pending join request by [requestId].
  Future<TeamJoinRequest> respondToJoinRequest({
    required String requestId,
    required bool accept,
  });

  /// Cancels a pending join request by [requestId].
  Future<void> cancelJoinRequest(String requestId);
}
