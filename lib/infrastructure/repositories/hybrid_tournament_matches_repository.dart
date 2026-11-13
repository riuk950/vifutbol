import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';

/// Remote data source contract for `matches` and `match_referees`.
abstract interface class TournamentMatchesRemoteDataSource {
  Future<List<ChampionshipMatch>> fetchAll();
  Future<List<ChampionshipMatch>> fetchForTournament(String tournamentId);
  Future<ChampionshipMatch> upsertMatch(ChampionshipMatch match);
  Future<List<ChampionshipMatch>> upsertBatch(List<ChampionshipMatch> matches);
  Future<List<MatchReferee>> fetchOfficialReferees();
}

/// PostgREST implementation targeting `vifutboldev.matches` & `match_referees`.
class PostgrestTournamentMatchesRemoteDataSource
    implements TournamentMatchesRemoteDataSource {
  PostgrestTournamentMatchesRemoteDataSource({
    required this.client,
    required this.schema,
  });

  final SupabaseClient client;
  final String schema;

  static Map<String, dynamic> _toRow(ChampionshipMatch m) {
    return <String, dynamic>{
      'id': HybridRepositorySupport.ensureUuid(m.id, 'match'),
      'tournament_id': HybridRepositorySupport.ensureUuid(
        m.tournamentId,
        'tournament',
      ),
      'round_number': m.roundNumber,
      'round_name': m.roundName,
      'home_tournament_team_id': HybridRepositorySupport.ensureUuid(
        m.homeTeamId,
        'tournament_team',
      ),
      'away_tournament_team_id': HybridRepositorySupport.ensureUuid(
        m.awayTeamId,
        'tournament_team',
      ),
      'scheduled_at': m.scheduledStartTime?.toUtc().toIso8601String(),
      'scheduled_end_at': m.scheduledEndTime?.toUtc().toIso8601String(),
      'venue_id': HybridRepositorySupport.ensureUuidOrNull(m.venueId, 'venue'),
      'pitch_id': HybridRepositorySupport.ensureUuidOrNull(m.pitchId, 'pitch'),
      'pitch_name': m.pitchName,
      'referee_id': HybridRepositorySupport.uuidOrNull(m.refereeId),
      'referee_name': m.refereeName,
      'status': m.status.code,
      'home_score': m.homeScore,
      'away_score': m.awayScore,
      'home_penalty_score': m.homePenaltyScore,
      'away_penalty_score': m.awayPenaltyScore,
      'group_name': m.groupName,
      'updated_at': m.updatedAt.toUtc().toIso8601String(),
    };
  }

  static ChampionshipMatch _fromRow(Map<String, dynamic> row) {
    final rawStart = row['scheduled_at'] as String?;
    final rawEnd = row['scheduled_end_at'] as String?;
    return ChampionshipMatch(
      id: row['id'] as String,
      tournamentId: row['tournament_id'] as String,
      roundNumber: (row['round_number'] as num).toInt(),
      roundName: row['round_name'] as String,
      homeTeamId: row['home_tournament_team_id'] as String,
      awayTeamId: row['away_tournament_team_id'] as String,
      scheduledStartTime: rawStart == null
          ? null
          : DateTime.parse(rawStart).toLocal(),
      scheduledEndTime: rawEnd == null
          ? null
          : DateTime.parse(rawEnd).toLocal(),
      venueId: row['venue_id'] as String?,
      pitchId: row['pitch_id'] as String?,
      pitchName: row['pitch_name'] as String?,
      refereeId: row['referee_id'] as String?,
      refereeName: row['referee_name'] as String?,
      status: MatchStatus.fromCode(row['status'] as String?),
      homeScore: (row['home_score'] as num?)?.toInt(),
      awayScore: (row['away_score'] as num?)?.toInt(),
      homePenaltyScore: (row['home_penalty_score'] as num?)?.toInt(),
      awayPenaltyScore: (row['away_penalty_score'] as num?)?.toInt(),
      groupName: row['group_name'] as String?,
      updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
    );
  }

  @override
  Future<List<ChampionshipMatch>> fetchAll() async {
    final rows = await client
        .schema(schema)
        .from('matches')
        .select()
        .order('round_number', ascending: true);
    return (rows as List<dynamic>)
        .map((r) => _fromRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<List<ChampionshipMatch>> fetchForTournament(
    String tournamentId,
  ) async {
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    final rows = await client
        .schema(schema)
        .from('matches')
        .select()
        .eq('tournament_id', safeTournamentId)
        .order('round_number', ascending: true);
    return (rows as List<dynamic>)
        .map((r) => _fromRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<ChampionshipMatch> upsertMatch(ChampionshipMatch match) async {
    await client
        .schema(schema)
        .from('matches')
        .upsert(_toRow(match), onConflict: 'id');
    return match;
  }

  @override
  Future<List<ChampionshipMatch>> upsertBatch(
    List<ChampionshipMatch> matches,
  ) async {
    if (matches.isEmpty) return const [];
    await client
        .schema(schema)
        .from('matches')
        .upsert(matches.map(_toRow).toList(), onConflict: 'id');
    return matches;
  }

  @override
  Future<List<MatchReferee>> fetchOfficialReferees() async {
    final rows = await client
        .schema(schema)
        .from('match_referees')
        .select()
        .eq('is_active', true)
        .order('full_name', ascending: true);

    return (rows as List<dynamic>)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .map(
          (r) => MatchReferee(
            id: r['id'] as String,
            fullName: r['full_name'] as String,
            certificationLevel:
                r['certification_level'] as String? ?? 'Nacional',
            isActive: r['is_active'] as bool? ?? true,
          ),
        )
        .toList();
  }
}

/// Offline-first hybrid [TournamentMatchesRepository].
class HybridTournamentMatchesRepository implements TournamentMatchesRepository {
  HybridTournamentMatchesRepository({
    required this.local,
    required this.remote,
    required this.support,
  });

  final LocalTournamentMatchesRepository local;
  final TournamentMatchesRemoteDataSource remote;
  final HybridRepositorySupport support;

  @override
  Future<List<ChampionshipMatch>> loadMatchesForTournament(
    String tournamentId,
  ) {
    return support.executeRead(
      remoteFetch: () => remote.fetchForTournament(tournamentId),
      cacheUpdate: (matches) =>
          local.replaceMatchesForTournament(tournamentId, matches),
      localFallback: () => local.loadMatchesForTournament(tournamentId),
    );
  }

  @override
  Future<List<ChampionshipMatch>> loadAllMatches() {
    return support.executeRead(
      remoteFetch: remote.fetchAll,
      cacheUpdate: local.replaceAllMatchesCache,
      localFallback: local.loadAllMatches,
    );
  }

  @override
  Future<List<MatchReferee>> loadOfficialReferees() {
    return support.executeRead(
      remoteFetch: remote.fetchOfficialReferees,
      cacheUpdate: local.replaceOfficialRefereesCache,
      localFallback: local.loadOfficialReferees,
    );
  }

  @override
  Stream<List<ChampionshipMatch>> watchMatchesForTournament(
    String tournamentId,
  ) {
    // Trigger background remote hydration and expose the live local stream.
    loadMatchesForTournament(tournamentId).ignore();
    return local.watchMatchesForTournament(tournamentId);
  }

  @override
  Future<ChampionshipMatch> saveMatch(ChampionshipMatch match) {
    return support.executeMutation(
      localWrite: () => local.saveMatch(match),
      remoteWrite: () => remote.upsertMatch(match),
      entityType: SyncOutboxEntityType.match,
      entityId: match.id,
      operation: SyncOutboxOperation.upsert,
      buildPayload: () => {'match': match.toJson()},
      displayTitle: match.roundName,
    );
  }

  @override
  Future<List<ChampionshipMatch>> saveMatchesBatch(
    List<ChampionshipMatch> matches,
  ) {
    if (matches.isEmpty) return Future.value(const []);
    final batchScopeId = matches.first.tournamentId;
    return support.executeMutation(
      localWrite: () => local.saveMatchesBatch(matches),
      remoteWrite: () => remote.upsertBatch(matches),
      entityType: SyncOutboxEntityType.match,
      entityId: batchScopeId,
      operation: SyncOutboxOperation.replaceBatch,
      buildPayload: () => {
        'tournamentId': batchScopeId,
        'matches': matches.map((m) => m.toJson()).toList(),
      },
      displayTitle: batchScopeId,
    );
  }

  @override
  Future<void> replaceMatchesForTournament(
    String tournamentId,
    List<ChampionshipMatch> matches,
  ) {
    return support.executeMutation(
      localWrite: () =>
          local.replaceMatchesForTournament(tournamentId, matches),
      remoteWrite: () => remote.upsertBatch(matches),
      entityType: SyncOutboxEntityType.match,
      entityId: tournamentId,
      operation: SyncOutboxOperation.replaceBatch,
      buildPayload: () => {
        'tournamentId': tournamentId,
        'matches': matches.map((m) => m.toJson()).toList(),
      },
      displayTitle: tournamentId,
    );
  }

  /// Replays a queued [SyncOutboxItem] against Supabase during FIFO flush.
  Future<void> replayOutboxItem(SyncOutboxItem item) async {
    if (item.operation == SyncOutboxOperation.upsert) {
      final raw = item.payloadJson['match'];
      if (raw is Map) {
        await remote.upsertMatch(
          ChampionshipMatch.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
      return;
    }

    if (item.operation == SyncOutboxOperation.replaceBatch) {
      final rawList = (item.payloadJson['matches'] as List<dynamic>?) ?? [];
      final matches = rawList
          .whereType<Map>()
          .map((m) => ChampionshipMatch.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      await remote.upsertBatch(matches);
    }
  }
}
