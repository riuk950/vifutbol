import 'package:vifutbol/domain/entities/match_lineup_convocation.dart';
import 'package:vifutbol/domain/entities/player_internal_tracking.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';

/// Contract defining persistence and retrieval of player tracking and match convocations.
abstract class LineupsTrackingRepository {
  /// Loads internal tracking for all players in the team roster.
  Future<List<PlayerInternalTracking>> loadTrackingForTeam(
    String tournamentId,
    String teamId,
    List<RegisteredPlayer> roster,
  );

  /// Saves or updates the internal metrics for a single player.
  Future<PlayerInternalTracking> savePlayerTracking(
    PlayerInternalTracking tracking,
  );

  /// Loads the active match convocation (draft or confirmed) for a team.
  Future<MatchLineupConvocation> loadConvocationForTeam(
    String tournamentId,
    String teamId,
  );

  /// Saves or updates the match convocation for a team.
  Future<MatchLineupConvocation> saveConvocation(
    MatchLineupConvocation convocation,
  );
}
