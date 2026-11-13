import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import 'package:vifutbol/domain/entities/fan_favorite_team.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/fan_favorites_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_fan_favorites_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';

/// Remote data source contract for `fan_favorite_teams`.
abstract interface class FanFavoritesRemoteDataSource {
  Future<List<FanFavoriteTeam>> fetchFavorites(
    String userId,
    String tournamentId,
  );
  Future<void> upsertFavorite(FanFavoriteTeam favorite);
  Future<void> removeFavorite(
    String userId,
    String tournamentId,
    String teamId,
  );
}

/// PostgREST implementation targeting `vifutboldev.fan_favorite_teams`.
class PostgrestFanFavoritesRemoteDataSource
    implements FanFavoritesRemoteDataSource {
  PostgrestFanFavoritesRemoteDataSource({
    required this.client,
    required this.schema,
    required this.support,
  });

  final SupabaseClient client;
  final String schema;
  final HybridRepositorySupport support;

  Future<String> _resolveMasterTeamId(String enrollmentOrTeamId) async {
    final safeEnrollmentId = HybridRepositorySupport.ensureUuid(
      enrollmentOrTeamId,
      'tournament_team',
    );
    final row = await client
        .schema(schema)
        .from('tournament_teams')
        .select('team_id')
        .eq('id', safeEnrollmentId)
        .maybeSingle();
    return (row?['team_id'] as String?) ??
        HybridRepositorySupport.ensureUuid(enrollmentOrTeamId, 'team');
  }

  @override
  Future<List<FanFavoriteTeam>> fetchFavorites(
    String userId,
    String tournamentId,
  ) async {
    final safeUserId = HybridRepositorySupport.ensureUuid(userId, 'user');
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    final rows = await client
        .schema(schema)
        .from('fan_favorite_teams')
        .select()
        .eq('user_id', safeUserId)
        .eq('tournament_id', safeTournamentId);

    return (rows as List<dynamic>)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .map(
          (r) => FanFavoriteTeam(
            userId: r['user_id'] as String,
            tournamentId: r['tournament_id'] as String,
            teamId: r['team_id'] as String,
            teamName: r['team_name'] as String,
            notificationsEnabled: r['notifications_enabled'] as bool? ?? true,
            createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
          ),
        )
        .toList();
  }

  @override
  Future<void> upsertFavorite(FanFavoriteTeam favorite) async {
    final safeUserId = HybridRepositorySupport.ensureUuid(
      favorite.userId,
      'user',
    );
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      favorite.tournamentId,
      'tournament',
    );
    final masterTeamId = await _resolveMasterTeamId(favorite.teamId);
    await client.schema(schema).from('fan_favorite_teams').upsert({
      'id': support.deterministicUuid(
        'fav|$safeUserId|$safeTournamentId|$masterTeamId',
      ),
      'user_id': safeUserId,
      'tournament_id': safeTournamentId,
      'team_id': masterTeamId,
      'team_name': favorite.teamName,
      'notifications_enabled': favorite.notificationsEnabled,
      'created_at': favorite.createdAt.toUtc().toIso8601String(),
      'updated_at': support.nowUtc().toIso8601String(),
    }, onConflict: 'user_id,tournament_id,team_id');
  }

  @override
  Future<void> removeFavorite(
    String userId,
    String tournamentId,
    String teamId,
  ) async {
    final safeUserId = HybridRepositorySupport.ensureUuid(userId, 'user');
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    final masterTeamId = await _resolveMasterTeamId(teamId);
    await client
        .schema(schema)
        .from('fan_favorite_teams')
        .delete()
        .eq('user_id', safeUserId)
        .eq('tournament_id', safeTournamentId)
        .eq('team_id', masterTeamId);
  }
}

/// Offline-first hybrid [FanFavoritesRepository]. Guest fan favorites remain 100% local (`FR-009`).
class HybridFanFavoritesRepository implements FanFavoritesRepository {
  HybridFanFavoritesRepository({
    required this.local,
    required this.remote,
    required this.support,
  });

  final LocalFanFavoritesRepository local;
  final FanFavoritesRemoteDataSource remote;
  final HybridRepositorySupport support;

  @override
  Future<List<FanFavoriteTeam>> loadFavoriteTeams(
    String userId,
    String tournamentId,
  ) {
    return support.executeRead(
      allowRemoteForGuest: false,
      remoteFetch: () => remote.fetchFavorites(userId, tournamentId),
      cacheUpdate: (items) =>
          local.replaceFavoritesForTournament(userId, tournamentId, items),
      localFallback: () => local.loadFavoriteTeams(userId, tournamentId),
    );
  }

  @override
  Stream<List<FanFavoriteTeam>> watchFavoriteTeams(
    String userId,
    String tournamentId,
  ) {
    loadFavoriteTeams(userId, tournamentId).ignore();
    return local.watchFavoriteTeams(userId, tournamentId);
  }

  @override
  Future<void> saveFavoriteTeam(FanFavoriteTeam favorite) {
    return support.executeMutation(
      localWrite: () => local.saveFavoriteTeam(favorite),
      remoteWrite: () => remote.upsertFavorite(favorite),
      entityType: SyncOutboxEntityType.fanFavorite,
      entityId:
          '${favorite.userId}|${favorite.tournamentId}|${favorite.teamId}',
      operation: SyncOutboxOperation.upsert,
      buildPayload: () => {'favorite': favorite.toJson()},
      displayTitle: favorite.teamName,
    );
  }

  @override
  Future<void> removeFavoriteTeam(
    String userId,
    String tournamentId,
    String teamId,
  ) {
    return support.executeMutation(
      localWrite: () => local.removeFavoriteTeam(userId, tournamentId, teamId),
      remoteWrite: () => remote.removeFavorite(userId, tournamentId, teamId),
      entityType: SyncOutboxEntityType.fanFavorite,
      entityId: '$userId|$tournamentId|$teamId',
      operation: SyncOutboxOperation.delete,
      buildPayload: () => {
        'userId': userId,
        'tournamentId': tournamentId,
        'teamId': teamId,
      },
      displayTitle: teamId,
    );
  }

  @override
  Future<bool> toggleFavoriteTeam(FanFavoriteTeam favorite) async {
    final existing = await local.loadFavoriteTeams(
      favorite.userId,
      favorite.tournamentId,
    );
    final isCurrentlyFavorite = existing.any(
      (f) => f.teamId == favorite.teamId,
    );
    if (isCurrentlyFavorite) {
      await removeFavoriteTeam(
        favorite.userId,
        favorite.tournamentId,
        favorite.teamId,
      );
      return false;
    }
    await saveFavoriteTeam(favorite);
    return true;
  }

  /// Replays a queued [SyncOutboxItem] against Supabase during FIFO flush.
  Future<void> replayOutboxItem(SyncOutboxItem item) async {
    if (item.operation == SyncOutboxOperation.delete) {
      await remote.removeFavorite(
        item.payloadJson['userId'] as String,
        item.payloadJson['tournamentId'] as String,
        item.payloadJson['teamId'] as String,
      );
      return;
    }
    final raw = item.payloadJson['favorite'];
    if (raw is Map) {
      await remote.upsertFavorite(
        FanFavoriteTeam.fromJson(Map<String, dynamic>.from(raw)),
      );
    }
  }
}
