import 'dart:async';
import 'dart:convert';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';

class LocalTournamentMatchesRepository implements TournamentMatchesRepository {
  LocalTournamentMatchesRepository({
    required this.storage,
    required this.config,
  });

  final LocalStorageRepository storage;
  final EnvironmentConfig config;

  final StreamController<List<ChampionshipMatch>> _matchesStreamController =
      StreamController<List<ChampionshipMatch>>.broadcast();

  static const String matchesStorageKey = 'vifutbol.matches.v1';
  static const String refereesStorageKey = 'vifutbol.referees.v1';

  @override
  Future<List<ChampionshipMatch>> loadMatchesForTournament(
    String tournamentId,
  ) async {
    final allMatches = await _loadAllMatches();
    return allMatches.where((m) => m.tournamentId == tournamentId).toList();
  }

  @override
  Future<List<ChampionshipMatch>> loadAllMatches() async {
    return _loadAllMatches();
  }

  @override
  Stream<List<ChampionshipMatch>> watchMatchesForTournament(
    String tournamentId,
  ) async* {
    final initial = await loadMatchesForTournament(tournamentId);
    yield initial;
    yield* _matchesStreamController.stream.map(
      (matches) =>
          matches.where((m) => m.tournamentId == tournamentId).toList(),
    );
  }

  @override
  Future<ChampionshipMatch> saveMatch(ChampionshipMatch match) async {
    final allMatches = await _loadAllMatches();
    final updatedList = List<ChampionshipMatch>.from(allMatches);
    final index = updatedList.indexWhere((m) => m.id == match.id);
    if (index >= 0) {
      updatedList[index] = match;
    } else {
      updatedList.add(match);
    }
    await _persistMatches(updatedList);
    return match;
  }

  @override
  Future<List<ChampionshipMatch>> saveMatchesBatch(
    List<ChampionshipMatch> matches,
  ) async {
    if (matches.isEmpty) return const [];
    final allMatches = await _loadAllMatches();
    final updatedList = List<ChampionshipMatch>.from(allMatches);

    for (final match in matches) {
      final index = updatedList.indexWhere((m) => m.id == match.id);
      if (index >= 0) {
        updatedList[index] = match;
      } else {
        updatedList.add(match);
      }
    }

    await _persistMatches(updatedList);
    return matches;
  }

  @override
  Future<void> replaceMatchesForTournament(
    String tournamentId,
    List<ChampionshipMatch> matches,
  ) async {
    final allMatches = await _loadAllMatches();
    final otherMatches = allMatches
        .where((m) => m.tournamentId != tournamentId)
        .toList();
    final updatedList = [...otherMatches, ...matches];
    await _persistMatches(updatedList);
  }

  @override
  Future<List<MatchReferee>> loadOfficialReferees() async {
    final raw = await storage.readString(refereesStorageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(MatchReferee.fromJson)
            .toList();
      } catch (_) {}
    }

    return const <MatchReferee>[];
  }

  Future<List<ChampionshipMatch>> _loadAllMatches() async {
    final raw = await storage.readString(matchesStorageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(ChampionshipMatch.fromJson)
            .toList();
      } catch (_) {}
    }

    return const <ChampionshipMatch>[];
  }

  /// Replaces the full local matches cache with fresh remote data and notifies listeners.
  Future<void> replaceAllMatchesCache(List<ChampionshipMatch> matches) {
    return _persistMatches(matches);
  }

  /// Replaces cached official referees with fresh remote data.
  Future<void> replaceOfficialRefereesCache(List<MatchReferee> referees) async {
    final serialized = jsonEncode(referees.map((r) => r.toJson()).toList());
    await storage.writeString(refereesStorageKey, serialized);
  }

  Future<void> _persistMatches(List<ChampionshipMatch> matches) async {
    final jsonList = matches.map((m) => m.toJson()).toList();
    await storage.writeString(matchesStorageKey, jsonEncode(jsonList));
    if (!_matchesStreamController.isClosed) {
      _matchesStreamController.add(matches);
    }
  }
}
