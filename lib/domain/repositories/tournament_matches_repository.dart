import '../entities/championship_match.dart';
import '../entities/match_referee.dart';

abstract class TournamentMatchesRepository {
  /// Loads all matches associated with a tournament.
  Future<List<ChampionshipMatch>> loadMatchesForTournament(String tournamentId);

  /// Saves or updates a single championship match.
  Future<ChampionshipMatch> saveMatch(ChampionshipMatch match);

  /// Saves or updates a batch of championship matches.
  Future<List<ChampionshipMatch>> saveMatchesBatch(
    List<ChampionshipMatch> matches,
  );

  /// Loads active official referees available for match assignment.
  Future<List<MatchReferee>> loadOfficialReferees();
}
