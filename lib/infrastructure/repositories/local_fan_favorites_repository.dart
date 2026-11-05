import 'dart:async';
import 'dart:convert';
import 'package:vifutbol/domain/entities/fan_favorite_team.dart';
import 'package:vifutbol/domain/repositories/fan_favorites_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';

class LocalFanFavoritesRepository implements FanFavoritesRepository {
  LocalFanFavoritesRepository({required this.storage});

  final LocalStorageRepository storage;
  final StreamController<List<FanFavoriteTeam>> _favoritesStreamController =
      StreamController<List<FanFavoriteTeam>>.broadcast();

  static const String favoritesStorageKey = 'vifutbol.fan_favorites.v1';

  @override
  Future<List<FanFavoriteTeam>> loadFavoriteTeams(
    String userId,
    String tournamentId,
  ) async {
    final all = await _loadAll();
    return all
        .where((f) => f.userId == userId && f.tournamentId == tournamentId)
        .toList();
  }

  @override
  Stream<List<FanFavoriteTeam>> watchFavoriteTeams(
    String userId,
    String tournamentId,
  ) async* {
    final initial = await loadFavoriteTeams(userId, tournamentId);
    yield initial;
    yield* _favoritesStreamController.stream.map(
      (all) => all
          .where((f) => f.userId == userId && f.tournamentId == tournamentId)
          .toList(),
    );
  }

  @override
  Future<void> saveFavoriteTeam(FanFavoriteTeam favorite) async {
    final all = await _loadAll();
    final updated = List<FanFavoriteTeam>.from(all);
    final index = updated.indexWhere(
      (f) =>
          f.userId == favorite.userId &&
          f.tournamentId == favorite.tournamentId &&
          f.teamId == favorite.teamId,
    );

    if (index >= 0) {
      updated[index] = favorite;
    } else {
      updated.add(favorite);
    }
    await _persist(updated);
  }

  @override
  Future<void> removeFavoriteTeam(
    String userId,
    String tournamentId,
    String teamId,
  ) async {
    final all = await _loadAll();
    final updated = all
        .where(
          (f) =>
              !(f.userId == userId &&
                  f.tournamentId == tournamentId &&
                  f.teamId == teamId),
        )
        .toList();
    await _persist(updated);
  }

  @override
  Future<bool> toggleFavoriteTeam(FanFavoriteTeam favorite) async {
    final all = await _loadAll();
    final index = all.indexWhere(
      (f) =>
          f.userId == favorite.userId &&
          f.tournamentId == favorite.tournamentId &&
          f.teamId == favorite.teamId,
    );

    if (index >= 0) {
      await removeFavoriteTeam(
        favorite.userId,
        favorite.tournamentId,
        favorite.teamId,
      );
      return false; // Removed
    } else {
      await saveFavoriteTeam(favorite);
      return true; // Added
    }
  }

  Future<List<FanFavoriteTeam>> _loadAll() async {
    try {
      final dynamic future = storage.readString(favoritesStorageKey);
      final raw = future is Future ? await future : null;
      if (raw != null && raw.trim().isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(FanFavoriteTeam.fromJson)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> _persist(List<FanFavoriteTeam> list) async {
    final jsonList = list.map((f) => f.toJson()).toList();
    await storage.writeString(favoritesStorageKey, jsonEncode(jsonList));
    if (!_favoritesStreamController.isClosed) {
      _favoritesStreamController.add(list);
    }
  }
}
