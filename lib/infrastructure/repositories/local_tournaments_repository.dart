import 'dart:convert';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';

/// Local repository persisting championship tournaments and temporary creation
/// drafts to [LocalStorageRepository].
class LocalTournamentsRepository implements TournamentsRepository {
  LocalTournamentsRepository({required this.storage, required this.config});

  final LocalStorageRepository storage;
  final EnvironmentConfig config;

  static const String catalogStorageKey = 'vifutbol.tournaments.catalog.v1';
  static const String draftStorageKey =
      'vifutbol.tournaments.creation_draft.v1';

  @override
  Future<List<ChampionshipTournament>> loadTournaments() async {
    final raw = await storage.readString(catalogStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <ChampionshipTournament>[];
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChampionshipTournament.fromJson)
          .toList();
    } catch (_) {
      return <ChampionshipTournament>[];
    }
  }

  @override
  Future<ChampionshipTournament> saveTournament(
    ChampionshipTournament tournament,
  ) async {
    final existing = await loadTournaments();
    final updated = List<ChampionshipTournament>.from(existing);
    final index = updated.indexWhere((t) => t.id == tournament.id);
    if (index >= 0) {
      updated[index] = tournament;
    } else {
      updated.insert(0, tournament);
    }

    await _persistTournaments(updated);
    return tournament;
  }

  @override
  Future<void> deleteTournament(String tournamentId) async {
    final existing = await loadTournaments();
    final updated = existing.where((t) => t.id != tournamentId).toList();
    await _persistTournaments(updated);
  }

  @override
  Future<TournamentDraft?> loadDraft() async {
    final raw = await storage.readString(draftStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      return TournamentDraft.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDraft(TournamentDraft draft) async {
    await storage.writeString(draftStorageKey, jsonEncode(draft.toJson()));
  }

  @override
  Future<void> clearDraft() async {
    await storage.writeString(draftStorageKey, '');
  }

  /// Replaces the full local tournaments cache with fresh remote data.
  Future<void> replaceAllCache(List<ChampionshipTournament> tournaments) {
    return _persistTournaments(tournaments);
  }

  Future<void> _persistTournaments(
    List<ChampionshipTournament> tournaments,
  ) async {
    final jsonList = tournaments.map((t) => t.toJson()).toList();
    await storage.writeString(catalogStorageKey, jsonEncode(jsonList));
  }
}
