import 'match_lineup_convocation.dart';
import 'player_internal_tracking.dart';

/// Immutable container state for match convocations and squad internal tracking.
class TeamLineupsTrackingState {
  final Map<String, MatchLineupConvocation> convocationsByTeamId;
  final Map<String, PlayerInternalTracking> trackingByPlayerId;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const TeamLineupsTrackingState({
    this.convocationsByTeamId = const {},
    this.trackingByPlayerId = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  /// Convenience getter for a specific team's convocation.
  MatchLineupConvocation? convocationForTeam(String teamId) =>
      convocationsByTeamId[teamId];

  /// Convenience getter for a specific player's internal tracking.
  PlayerInternalTracking? trackingForPlayer(String playerId) =>
      trackingByPlayerId[playerId];

  TeamLineupsTrackingState copyWith({
    Map<String, MatchLineupConvocation>? convocationsByTeamId,
    Map<String, PlayerInternalTracking>? trackingByPlayerId,
    bool? isLoading,
    bool? isSaving,
    String? Function()? errorMessage,
  }) {
    return TeamLineupsTrackingState(
      convocationsByTeamId: convocationsByTeamId ?? this.convocationsByTeamId,
      trackingByPlayerId: trackingByPlayerId ?? this.trackingByPlayerId,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}
