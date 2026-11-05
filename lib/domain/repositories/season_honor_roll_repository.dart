import 'package:vifutbol/domain/entities/season_honor_roll.dart';

/// Repository contract for managing official tournament season honor rolls.
abstract interface class SeasonHonorRollRepository {
  /// Loads the persisted official honor roll for [tournamentId], if the season was closed.
  Future<SeasonHonorRoll?> loadHonorRollForTournament(String tournamentId);

  /// Persists or updates the official [SeasonHonorRoll] for its tournament.
  Future<SeasonHonorRoll> saveHonorRoll(SeasonHonorRoll honorRoll);

  /// Removes any honor roll associated with [tournamentId].
  Future<void> deleteHonorRollForTournament(String tournamentId);
}
