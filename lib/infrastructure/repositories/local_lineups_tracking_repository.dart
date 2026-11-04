import 'dart:convert';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/match_lineup_convocation.dart';
import 'package:vifutbol/domain/entities/player_internal_tracking.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/lineups_tracking_repository.dart';

/// Implementation of [LineupsTrackingRepository] utilizing [LocalStorageRepository],
/// preloading seed tracking metrics and a suspended player in development.
class LocalLineupsTrackingRepository implements LineupsTrackingRepository {
  final LocalStorageRepository storage;
  final EnvironmentConfig config;

  LocalLineupsTrackingRepository({required this.storage, required this.config});

  static const String trackingStorageKey = 'vifutbol.lineups.tracking.v1';
  static const String convocationsStorageKey =
      'vifutbol.lineups.convocations.v1';

  @override
  Future<List<PlayerInternalTracking>> loadTrackingForTeam(
    String tournamentId,
    String teamId,
    List<RegisteredPlayer> roster,
  ) async {
    final raw = await storage.readString(trackingStorageKey);
    Map<String, PlayerInternalTracking> trackingMap = {};

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final t = PlayerInternalTracking.fromJson(item);
            trackingMap[t.playerId] = t;
          }
        }
      } catch (_) {}
    } else if (config.environment == AppEnvironment.development) {
      trackingMap = _buildDevSeedTracking();
      await _persistTracking(trackingMap.values.toList());
    }

    final results = <PlayerInternalTracking>[];
    for (final player in roster) {
      final existing = trackingMap[player.id];
      if (existing != null) {
        results.add(existing);
      } else {
        // Fallback default metrics for any enrolled player
        final fallback = PlayerInternalTracking(
          playerId: player.id,
          teamId: teamId,
          tournamentId: tournamentId,
        );
        results.add(fallback);
      }
    }
    return results;
  }

  @override
  Future<PlayerInternalTracking> savePlayerTracking(
    PlayerInternalTracking tracking,
  ) async {
    final raw = await storage.readString(trackingStorageKey);
    final List<PlayerInternalTracking> allTracking = [];

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            allTracking.add(PlayerInternalTracking.fromJson(item));
          }
        }
      } catch (_) {}
    }

    final index = allTracking.indexWhere(
      (t) => t.playerId == tracking.playerId,
    );
    if (index >= 0) {
      allTracking[index] = tracking;
    } else {
      allTracking.add(tracking);
    }

    await _persistTracking(allTracking);
    return tracking;
  }

  @override
  Future<MatchLineupConvocation> loadConvocationForTeam(
    String tournamentId,
    String teamId,
  ) async {
    final raw = await storage.readString(convocationsStorageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final conv = MatchLineupConvocation.fromJson(item);
            if (conv.teamId == teamId && conv.tournamentId == tournamentId) {
              return conv;
            }
          }
        }
      } catch (_) {}
    }

    // Default empty draft convocation
    return MatchLineupConvocation(
      id: 'conv-$tournamentId-$teamId',
      tournamentId: tournamentId,
      teamId: teamId,
      matchLabel: 'Jornada 1 · Próximo Partido Oficial',
    );
  }

  @override
  Future<MatchLineupConvocation> saveConvocation(
    MatchLineupConvocation convocation,
  ) async {
    final raw = await storage.readString(convocationsStorageKey);
    final List<MatchLineupConvocation> all = [];

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            all.add(MatchLineupConvocation.fromJson(item));
          }
        }
      } catch (_) {}
    }

    final index = all.indexWhere((c) => c.id == convocation.id);
    if (index >= 0) {
      all[index] = convocation;
    } else {
      all.add(convocation);
    }

    final serialized = jsonEncode(all.map((c) => c.toJson()).toList());
    await storage.writeString(convocationsStorageKey, serialized);
    return convocation;
  }

  Future<void> _persistTracking(List<PlayerInternalTracking> list) async {
    final serialized = jsonEncode(list.map((t) => t.toJson()).toList());
    await storage.writeString(trackingStorageKey, serialized);
  }

  Map<String, PlayerInternalTracking> _buildDevSeedTracking() {
    return {
      // Wilmar Barrios: Active red card suspension (1 match pending)
      'p-seed-atn-8': const PlayerInternalTracking(
        playerId: 'p-seed-atn-8',
        teamId: 'team-seed-atletico-norte',
        tournamentId: 'tournament-seed-liga-clausura',
        matchesPlayed: 4,
        goals: 0,
        assists: 1,
        yellowCards: 2,
        redCards: 1,
        pendingSuspensionMatches: 1,
      ),
      // Yerry Mina: Yellow card warning threshold (2 yellow cards, limit is 3)
      'p-seed-atn-2': const PlayerInternalTracking(
        playerId: 'p-seed-atn-2',
        teamId: 'team-seed-atletico-norte',
        tournamentId: 'tournament-seed-liga-clausura',
        matchesPlayed: 5,
        goals: 1,
        assists: 0,
        yellowCards: 2,
        redCards: 0,
        pendingSuspensionMatches: 0,
      ),
      // Falcao: Top scorer
      'p-seed-atn-5': const PlayerInternalTracking(
        playerId: 'p-seed-atn-5',
        teamId: 'team-seed-atletico-norte',
        tournamentId: 'tournament-seed-liga-clausura',
        matchesPlayed: 5,
        goals: 4,
        assists: 1,
        yellowCards: 0,
        redCards: 0,
        pendingSuspensionMatches: 0,
      ),
      // James Rodríguez: Top playmaker
      'p-seed-atn-6': const PlayerInternalTracking(
        playerId: 'p-seed-atn-6',
        teamId: 'team-seed-atletico-norte',
        tournamentId: 'tournament-seed-liga-clausura',
        matchesPlayed: 5,
        goals: 2,
        assists: 5,
        yellowCards: 1,
        redCards: 0,
        pendingSuspensionMatches: 0,
      ),
      // Luis Díaz: Key forward
      'p-seed-atn-7': const PlayerInternalTracking(
        playerId: 'p-seed-atn-7',
        teamId: 'team-seed-atletico-norte',
        tournamentId: 'tournament-seed-liga-clausura',
        matchesPlayed: 5,
        goals: 3,
        assists: 2,
        yellowCards: 0,
        redCards: 0,
        pendingSuspensionMatches: 0,
      ),
      // David Ospina: Goalkeeper
      'p-seed-atn-1': const PlayerInternalTracking(
        playerId: 'p-seed-atn-1',
        teamId: 'team-seed-atletico-norte',
        tournamentId: 'tournament-seed-liga-clausura',
        matchesPlayed: 5,
        goals: 0,
        assists: 0,
        yellowCards: 0,
        redCards: 0,
        pendingSuspensionMatches: 0,
      ),
    };
  }
}
