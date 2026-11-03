import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';

/// Repository contract for loading and persisting championship tournaments
/// and temporary local creation drafts.
abstract interface class TournamentsRepository {
  /// Loads all persisted championship tournaments ordered by most recent update.
  Future<List<ChampionshipTournament>> loadTournaments();

  /// Creates or updates a championship tournament in persistent storage.
  Future<ChampionshipTournament> saveTournament(
    ChampionshipTournament tournament,
  );

  /// Loads the temporary local creation draft if one exists.
  Future<TournamentDraft?> loadDraft();

  /// Saves a temporary local creation draft.
  Future<void> saveDraft(TournamentDraft draft);

  /// Clears any temporary local creation draft.
  Future<void> clearDraft();
}
