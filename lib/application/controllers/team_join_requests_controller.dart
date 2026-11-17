import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/use_cases/manage_team_join_requests_use_case.dart';
import 'package:vifutbol/domain/entities/available_player_candidate.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/team_join_request.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';

/// State of the team join requests controller.
class TeamJoinRequestsState {
  final bool isLoading;
  final bool isSaving;
  final List<AvailablePlayerCandidate> candidateSearchResults;
  final List<TeamJoinRequest> teamRequests;
  final List<TeamJoinRequest> playerRequests;
  final AppFailure? lastFailure;

  const TeamJoinRequestsState({
    this.isLoading = false,
    this.isSaving = false,
    this.candidateSearchResults = const <AvailablePlayerCandidate>[],
    this.teamRequests = const <TeamJoinRequest>[],
    this.playerRequests = const <TeamJoinRequest>[],
    this.lastFailure,
  });

  TeamJoinRequestsState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<AvailablePlayerCandidate>? candidateSearchResults,
    List<TeamJoinRequest>? teamRequests,
    List<TeamJoinRequest>? playerRequests,
    AppFailure? lastFailure,
    bool clearLastFailure = false,
  }) {
    return TeamJoinRequestsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      candidateSearchResults:
          candidateSearchResults ?? this.candidateSearchResults,
      teamRequests: teamRequests ?? this.teamRequests,
      playerRequests: playerRequests ?? this.playerRequests,
      lastFailure: clearLastFailure ? null : (lastFailure ?? this.lastFailure),
    );
  }
}

/// State notifier managing candidate searches, coach join requests, and player inbox.
class TeamJoinRequestsController extends StateNotifier<TeamJoinRequestsState> {
  TeamJoinRequestsController({
    required this.manageUseCase,
  }) : super(const TeamJoinRequestsState());

  final ManageTeamJoinRequestsUseCase manageUseCase;

  /// Clears the last error.
  void clearFailure() {
    if (state.lastFailure != null) {
      state = state.copyWith(clearLastFailure: true);
    }
  }

  /// Searches registered players matching [query].
  Future<void> searchCandidates({
    required String query,
    required UserRole actorRole,
  }) async {
    state = state.copyWith(isLoading: true, clearLastFailure: true);
    try {
      final results = await manageUseCase.searchRegisteredPlayers(
        query: query,
        actorRole: actorRole,
      );
      state = state.copyWith(
        candidateSearchResults: results,
        isLoading: false,
      );
    } catch (e) {
      final failure = e is AppFailure ? e : DataLoadFailure(e.toString());
      state = state.copyWith(isLoading: false, lastFailure: failure);
    }
  }

  /// Loads join requests sent for [teamId].
  Future<void> loadRequestsForTeam(String teamId) async {
    state = state.copyWith(isLoading: true, clearLastFailure: true);
    try {
      final requests = await manageUseCase.loadRequestsForTeam(teamId);
      state = state.copyWith(
        teamRequests: requests,
        isLoading: false,
      );
    } catch (e) {
      final failure = e is AppFailure ? e : DataLoadFailure(e.toString());
      state = state.copyWith(isLoading: false, lastFailure: failure);
    }
  }

  /// Loads pending requests received by the current player.
  Future<void> loadRequestsForCurrentPlayer() async {
    state = state.copyWith(isLoading: true, clearLastFailure: true);
    try {
      final requests = await manageUseCase.loadRequestsForCurrentPlayer();
      state = state.copyWith(
        playerRequests: requests,
        isLoading: false,
      );
    } catch (e) {
      final failure = e is AppFailure ? e : DataLoadFailure(e.toString());
      state = state.copyWith(isLoading: false, lastFailure: failure);
    }
  }

  /// Sends a join request to [candidate] with single-flight protection.
  Future<bool> sendJoinRequest({
    required TournamentTeam team,
    required AvailablePlayerCandidate candidate,
    required int shirtNumber,
    required PlayerPosition position,
    required UserRole actorRole,
  }) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      final created = await manageUseCase.sendJoinRequest(
        team: team,
        candidate: candidate,
        shirtNumber: shirtNumber,
        position: position,
        actorRole: actorRole,
      );
      state = state.copyWith(
        isSaving: false,
        teamRequests: [created, ...state.teamRequests],
      );
      return true;
    } catch (e) {
      final failure = e is AppFailure ? e : DataLoadFailure(e.toString());
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }

  /// Responds to a join request (accept or reject) with single-flight protection.
  Future<bool> respondToJoinRequest({
    required String requestId,
    required bool accept,
    required UserRole actorRole,
  }) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      await manageUseCase.respondToJoinRequest(
        requestId: requestId,
        accept: accept,
        actorRole: actorRole,
      );
      final updatedPlayerRequests = state.playerRequests
          .where((r) => r.id != requestId)
          .toList();

      state = state.copyWith(
        isSaving: false,
        playerRequests: updatedPlayerRequests,
      );
      return true;
    } catch (e) {
      final failure = e is AppFailure ? e : DataLoadFailure(e.toString());
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }

  /// Cancels a join request sent by coach.
  Future<bool> cancelJoinRequest({
    required String requestId,
    required UserRole actorRole,
  }) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearLastFailure: true);

    try {
      await manageUseCase.cancelJoinRequest(
        requestId: requestId,
        actorRole: actorRole,
      );
      final updatedTeamRequests = state.teamRequests
          .where((r) => r.id != requestId)
          .toList();
      state = state.copyWith(
        isSaving: false,
        teamRequests: updatedTeamRequests,
      );
      return true;
    } catch (e) {
      final failure = e is AppFailure ? e : DataLoadFailure(e.toString());
      state = state.copyWith(isSaving: false, lastFailure: failure);
      return false;
    }
  }
}
