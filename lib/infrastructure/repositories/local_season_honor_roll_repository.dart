import 'dart:convert';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/season_honor_roll.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/season_honor_roll_repository.dart';

class LocalSeasonHonorRollRepository implements SeasonHonorRollRepository {
  LocalSeasonHonorRollRepository({required this.storage, required this.config});

  final LocalStorageRepository storage;
  final EnvironmentConfig config;

  static const String honorRollStorageKey = 'vifutbol.season_honor_rolls.v1';

  @override
  Future<SeasonHonorRoll?> loadHonorRollForTournament(
    String tournamentId,
  ) async {
    final all = await _loadAll();
    return all[tournamentId];
  }

  @override
  Future<SeasonHonorRoll> saveHonorRoll(SeasonHonorRoll honorRoll) async {
    final all = await _loadAll();
    final updated = Map<String, SeasonHonorRoll>.from(all);
    updated[honorRoll.tournamentId] = honorRoll;
    await _persist(updated);
    return honorRoll;
  }

  @override
  Future<void> deleteHonorRollForTournament(String tournamentId) async {
    final all = await _loadAll();
    if (all.containsKey(tournamentId)) {
      final updated = Map<String, SeasonHonorRoll>.from(all)
        ..remove(tournamentId);
      await _persist(updated);
    }
  }

  Future<Map<String, SeasonHonorRoll>> _loadAll() async {
    try {
      final dynamic futureOrStr = storage.readString(honorRollStorageKey);
      final raw = futureOrStr is Future
          ? await futureOrStr
          : (futureOrStr as String?);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};

      final result = <String, SeasonHonorRoll>{};
      decoded.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          try {
            result[key] = SeasonHonorRoll.fromJson(value);
          } catch (_) {}
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> _persist(Map<String, SeasonHonorRoll> map) async {
    final serialized = map.map((key, value) => MapEntry(key, value.toJson()));
    await storage.writeString(honorRollStorageKey, jsonEncode(serialized));
  }
}
