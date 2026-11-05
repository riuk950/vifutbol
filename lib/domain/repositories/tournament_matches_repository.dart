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

  /// Streams matches for a tournament, emitting immediately upon subscription
  /// and whenever matches in the tournament are created, modified, or updated in status/score.
  Stream<List<ChampionshipMatch>> watchMatchesForTournament(
    String tournamentId,
  );

  /// Replaces all matches belonging to [tournamentId] with [matches],
  /// preserving matches from other tournaments.
  Future<void> replaceMatchesForTournament(
    String tournamentId,
    List<ChampionshipMatch> matches,
  );
}
