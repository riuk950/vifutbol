import 'package:vifutbol/domain/entities/player_performance_profile.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';

/// Presentation projection representing an enrolled player in the directory.
class PlayerDirectoryItem {
  final RegisteredPlayer player;
  final String teamId;
  final String teamName;
  final String teamShortCode;
  final String tournamentId;
  final String tournamentName;

  const PlayerDirectoryItem({
    required this.player,
    required this.teamId,
    required this.teamName,
    required this.teamShortCode,
    required this.tournamentId,
    required this.tournamentName,
  });

  /// Converts this directory item into a [PlayerPerformanceProfile] for performance modals.
  PlayerPerformanceProfile toPerformanceProfile() {
    return PlayerPerformanceProfile(
      playerId: player.id,
      tournamentId: tournamentId,
      fullName: player.fullName,
      shirtNumber: player.shirtNumber,
      position: player.position,
      teamId: teamId,
      teamName: teamName,
      teamShortCode: teamShortCode,
      isSuspended: !player.isEligible,
    );
  }
}
