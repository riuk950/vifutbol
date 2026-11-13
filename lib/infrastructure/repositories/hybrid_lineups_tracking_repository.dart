import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import 'package:vifutbol/domain/entities/lineup_enums.dart';
import 'package:vifutbol/domain/entities/match_lineup_convocation.dart';
import 'package:vifutbol/domain/entities/player_internal_tracking.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/lineups_tracking_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_lineups_tracking_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';

/// Remote data source contract for `player_internal_trackings` and `match_lineup_convocations`.
abstract interface class LineupsTrackingRemoteDataSource {
  Future<List<PlayerInternalTracking>> fetchTrackingForTeam(
    String tournamentId,
    String teamId,
    List<RegisteredPlayer> roster,
  );
  Future<PlayerInternalTracking> upsertTracking(
    PlayerInternalTracking tracking,
  );
  Future<MatchLineupConvocation?> fetchConvocationForTeam(
    String tournamentId,
    String teamId,
  );
  Future<MatchLineupConvocation> upsertConvocation(
    MatchLineupConvocation convocation,
  );
}

/// PostgREST implementation targeting `vifutboldev.player_internal_trackings` and
/// `vifutboldev.match_lineup_convocations`.
class PostgrestLineupsTrackingRemoteDataSource
    implements LineupsTrackingRemoteDataSource {
  PostgrestLineupsTrackingRemoteDataSource({
    required this.client,
    required this.schema,
    required this.support,
  });

  final SupabaseClient client;
  final String schema;
  final HybridRepositorySupport support;

  String _safeConvocationUuid(MatchLineupConvocation conv) {
    return HybridRepositorySupport.uuidOrNull(conv.id) ??
        support.deterministicUuid(
          'convocation|${conv.tournamentId}|${conv.teamId}',
        );
  }

  @override
  Future<List<PlayerInternalTracking>> fetchTrackingForTeam(
    String tournamentId,
    String teamId,
    List<RegisteredPlayer> roster,
  ) async {
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    final safeTeamId = HybridRepositorySupport.ensureUuid(
      teamId,
      'tournament_team',
    );
    final rows = await client
        .schema(schema)
        .from('player_internal_trackings')
        .select()
        .eq('tournament_id', safeTournamentId)
        .eq('tournament_team_id', safeTeamId);

    final byPlayer = <String, PlayerInternalTracking>{};
    for (final raw in (rows as List<dynamic>)) {
      final r = Map<String, dynamic>.from(raw as Map);
      final playerId = r['player_id'] as String;
      byPlayer[playerId] = PlayerInternalTracking(
        playerId: playerId,
        teamId: r['tournament_team_id'] as String,
        tournamentId: r['tournament_id'] as String,
        matchesPlayed: (r['matches_played'] as num?)?.toInt() ?? 0,
        goals: (r['goals'] as num?)?.toInt() ?? 0,
        assists: (r['assists'] as num?)?.toInt() ?? 0,
        yellowCards: (r['yellow_cards'] as num?)?.toInt() ?? 0,
        redCards: (r['red_cards'] as num?)?.toInt() ?? 0,
        pendingSuspensionMatches:
            (r['pending_suspension_matches'] as num?)?.toInt() ?? 0,
      );
    }

    return roster
        .map(
          (p) =>
              byPlayer[p.id] ??
              PlayerInternalTracking(
                playerId: p.id,
                teamId: teamId,
                tournamentId: tournamentId,
              ),
        )
        .toList();
  }

  @override
  Future<PlayerInternalTracking> upsertTracking(
    PlayerInternalTracking tracking,
  ) async {
    final safePlayerId = HybridRepositorySupport.ensureUuid(
      tracking.playerId,
      'player',
    );
    final safeTeamId = HybridRepositorySupport.ensureUuid(
      tracking.teamId,
      'tournament_team',
    );
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tracking.tournamentId,
      'tournament',
    );
    await client.schema(schema).from('player_internal_trackings').upsert({
      'id': support.deterministicUuid('tracking|$safePlayerId|$safeTeamId'),
      'player_id': safePlayerId,
      'tournament_team_id': safeTeamId,
      'tournament_id': safeTournamentId,
      'matches_played': tracking.matchesPlayed,
      'goals': tracking.goals,
      'assists': tracking.assists,
      'yellow_cards': tracking.yellowCards,
      'red_cards': tracking.redCards,
      'pending_suspension_matches': tracking.pendingSuspensionMatches,
      'updated_at': support.nowUtc().toIso8601String(),
    }, onConflict: 'player_id,tournament_team_id');
    return tracking;
  }

  @override
  Future<MatchLineupConvocation?> fetchConvocationForTeam(
    String tournamentId,
    String teamId,
  ) async {
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    final safeTeamId = HybridRepositorySupport.ensureUuid(
      teamId,
      'tournament_team',
    );
    final row = await client
        .schema(schema)
        .from('match_lineup_convocations')
        .select()
        .eq('tournament_id', safeTournamentId)
        .eq('tournament_team_id', safeTeamId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;

    final rawConfirmedAt = row['confirmed_at'] as String?;
    return MatchLineupConvocation(
      id: row['id'] as String,
      tournamentId: row['tournament_id'] as String,
      teamId: row['tournament_team_id'] as String,
      matchLabel:
          row['match_label'] as String? ??
          'Jornada 1 · Próximo Partido Oficial',
      starterPlayerIds: ((row['starter_player_ids'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList(),
      substitutePlayerIds:
          ((row['substitute_player_ids'] as List<dynamic>?) ?? [])
              .map((e) => e.toString())
              .toList(),
      captainPlayerId: row['captain_player_id'] as String?,
      status: ConvocationStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => ConvocationStatus.draft,
      ),
      confirmedStarterPlayerIds:
          ((row['confirmed_starter_player_ids'] as List<dynamic>?) ?? [])
              .map((e) => e.toString())
              .toList(),
      confirmedSubstitutePlayerIds:
          ((row['confirmed_substitute_player_ids'] as List<dynamic>?) ?? [])
              .map((e) => e.toString())
              .toList(),
      confirmedCaptainPlayerId: row['confirmed_captain_player_id'] as String?,
      confirmedAt: rawConfirmedAt == null
          ? null
          : DateTime.parse(rawConfirmedAt).toLocal(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
    );
  }

  @override
  Future<MatchLineupConvocation> upsertConvocation(
    MatchLineupConvocation convocation,
  ) async {
    final safeId = _safeConvocationUuid(convocation);
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      convocation.tournamentId,
      'tournament',
    );
    final safeTeamId = HybridRepositorySupport.ensureUuid(
      convocation.teamId,
      'tournament_team',
    );
    await client.schema(schema).from('match_lineup_convocations').upsert({
      'id': safeId,
      'tournament_id': safeTournamentId,
      'tournament_team_id': safeTeamId,
      'match_label': convocation.matchLabel,
      'starter_player_ids': convocation.starterPlayerIds
          .map((id) => HybridRepositorySupport.ensureUuid(id, 'player'))
          .toList(),
      'substitute_player_ids': convocation.substitutePlayerIds
          .map((id) => HybridRepositorySupport.ensureUuid(id, 'player'))
          .toList(),
      'captain_player_id': HybridRepositorySupport.ensureUuidOrNull(
        convocation.captainPlayerId,
        'player',
      ),
      'status': convocation.status.name,
      'confirmed_starter_player_ids': convocation.confirmedStarterPlayerIds
          .map((id) => HybridRepositorySupport.ensureUuid(id, 'player'))
          .toList(),
      'confirmed_substitute_player_ids': convocation
          .confirmedSubstitutePlayerIds
          .map((id) => HybridRepositorySupport.ensureUuid(id, 'player'))
          .toList(),
      'confirmed_captain_player_id': HybridRepositorySupport.ensureUuidOrNull(
        convocation.confirmedCaptainPlayerId,
        'player',
      ),
      'confirmed_at': convocation.confirmedAt?.toUtc().toIso8601String(),
      'updated_at': convocation.updatedAt.toUtc().toIso8601String(),
    }, onConflict: 'id');
    return convocation.copyWith(id: safeId);
  }
}

/// Offline-first hybrid [LineupsTrackingRepository].
class HybridLineupsTrackingRepository implements LineupsTrackingRepository {
  HybridLineupsTrackingRepository({
    required this.local,
    required this.remote,
    required this.support,
  });

  final LocalLineupsTrackingRepository local;
  final LineupsTrackingRemoteDataSource remote;
  final HybridRepositorySupport support;

  @override
  Future<List<PlayerInternalTracking>> loadTrackingForTeam(
    String tournamentId,
    String teamId,
    List<RegisteredPlayer> roster,
  ) {
    return support.executeRead(
      remoteFetch: () =>
          remote.fetchTrackingForTeam(tournamentId, teamId, roster),
      cacheUpdate: (items) async {
        for (final item in items) {
          await local.savePlayerTracking(item);
        }
      },
      localFallback: () =>
          local.loadTrackingForTeam(tournamentId, teamId, roster),
    );
  }

  @override
  Future<PlayerInternalTracking> savePlayerTracking(
    PlayerInternalTracking tracking,
  ) {
    return support.executeMutation(
      localWrite: () => local.savePlayerTracking(tracking),
      remoteWrite: () => remote.upsertTracking(tracking),
      entityType: SyncOutboxEntityType.lineupTracking,
      entityId: 'tracking-${tracking.playerId}-${tracking.teamId}',
      operation: SyncOutboxOperation.upsert,
      buildPayload: () => {'kind': 'tracking', 'tracking': tracking.toJson()},
      displayTitle: tracking.playerId,
    );
  }

  @override
  Future<MatchLineupConvocation> loadConvocationForTeam(
    String tournamentId,
    String teamId,
  ) {
    return support.executeRead(
      remoteFetch: () async {
        final remoteConv = await remote.fetchConvocationForTeam(
          tournamentId,
          teamId,
        );
        return remoteConv ??
            await local.loadConvocationForTeam(tournamentId, teamId);
      },
      cacheUpdate: (conv) async {
        await local.saveConvocation(conv);
      },
      localFallback: () => local.loadConvocationForTeam(tournamentId, teamId),
    );
  }

  @override
  Future<MatchLineupConvocation> saveConvocation(
    MatchLineupConvocation convocation,
  ) {
    return support.executeMutation(
      localWrite: () => local.saveConvocation(convocation),
      remoteWrite: () => remote.upsertConvocation(convocation),
      entityType: SyncOutboxEntityType.lineupTracking,
      entityId: convocation.id,
      operation: SyncOutboxOperation.upsert,
      buildPayload: () => {
        'kind': 'convocation',
        'convocation': convocation.toJson(),
      },
      displayTitle: convocation.matchLabel,
    );
  }

  /// Replays a queued [SyncOutboxItem] against Supabase during FIFO flush.
  Future<void> replayOutboxItem(SyncOutboxItem item) async {
    final kind = item.payloadJson['kind'] as String?;
    if (kind == 'tracking') {
      final raw = item.payloadJson['tracking'];
      if (raw is Map) {
        await remote.upsertTracking(
          PlayerInternalTracking.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
      return;
    }

    if (kind == 'convocation') {
      final raw = item.payloadJson['convocation'];
      if (raw is Map) {
        await remote.upsertConvocation(
          MatchLineupConvocation.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
    }
  }
}
