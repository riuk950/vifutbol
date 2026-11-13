import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import 'package:vifutbol/domain/entities/season_honor_roll.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/season_honor_roll_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_season_honor_roll_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';

/// Remote data source contract for `season_honor_rolls`.
abstract interface class SeasonHonorRollRemoteDataSource {
  Future<SeasonHonorRoll?> fetchForTournament(String tournamentId);
  Future<SeasonHonorRoll> upsertHonorRoll(SeasonHonorRoll honorRoll);
  Future<void> deleteForTournament(String tournamentId);
}

/// PostgREST implementation targeting `vifutboldev.season_honor_rolls`.
class PostgrestSeasonHonorRollRemoteDataSource
    implements SeasonHonorRollRemoteDataSource {
  PostgrestSeasonHonorRollRemoteDataSource({
    required this.client,
    required this.schema,
    required this.support,
  });

  final SupabaseClient client;
  final String schema;
  final HybridRepositorySupport support;

  @override
  Future<SeasonHonorRoll?> fetchForTournament(String tournamentId) async {
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    final row = await client
        .schema(schema)
        .from('season_honor_rolls')
        .select()
        .eq('tournament_id', safeTournamentId)
        .maybeSingle();

    if (row == null) return null;
    return SeasonHonorRoll(
      tournamentId: row['tournament_id'] as String,
      tournamentName: row['tournament_name'] as String,
      closedAt: DateTime.parse(row['closed_at'] as String).toLocal(),
      championTeamId: row['champion_team_id'] as String,
      championTeamName: row['champion_team_name'] as String,
      championShortCode: row['champion_short_code'] as String,
      runnerUpTeamId: row['runner_up_team_id'] as String,
      runnerUpTeamName: row['runner_up_team_name'] as String,
      runnerUpShortCode: row['runner_up_short_code'] as String,
      topScorerPlayerId: row['top_scorer_player_id'] as String?,
      topScorerPlayerName: row['top_scorer_player_name'] as String?,
      topScorerTeamName: row['top_scorer_team_name'] as String?,
      topScorerGoals: (row['top_scorer_goals'] as num?)?.toInt() ?? 0,
      bestDefenseTeamId: row['best_defense_team_id'] as String,
      bestDefenseTeamName: row['best_defense_team_name'] as String,
      bestDefenseShortCode: row['best_defense_short_code'] as String,
      bestDefenseGoalsAgainst:
          (row['best_defense_goals_against'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<SeasonHonorRoll> upsertHonorRoll(SeasonHonorRoll honorRoll) async {
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      honorRoll.tournamentId,
      'tournament',
    );
    final safeChampionTeamId = HybridRepositorySupport.ensureUuid(
      honorRoll.championTeamId,
      'tournament_team',
    );
    final safeRunnerUpTeamId = HybridRepositorySupport.ensureUuid(
      honorRoll.runnerUpTeamId,
      'tournament_team',
    );
    final safeBestDefenseTeamId = HybridRepositorySupport.ensureUuid(
      honorRoll.bestDefenseTeamId,
      'tournament_team',
    );
    final safeTopScorerId = HybridRepositorySupport.ensureUuidOrNull(
      honorRoll.topScorerPlayerId,
      'player',
    );

    await client.schema(schema).from('season_honor_rolls').upsert({
      'id': support.deterministicUuid('honor-roll|$safeTournamentId'),
      'tournament_id': safeTournamentId,
      'tournament_name': honorRoll.tournamentName,
      'closed_at': honorRoll.closedAt.toUtc().toIso8601String(),
      'champion_team_id': safeChampionTeamId,
      'champion_team_name': honorRoll.championTeamName,
      'champion_short_code': honorRoll.championShortCode,
      'runner_up_team_id': safeRunnerUpTeamId,
      'runner_up_team_name': honorRoll.runnerUpTeamName,
      'runner_up_short_code': honorRoll.runnerUpShortCode,
      'top_scorer_player_id': safeTopScorerId,
      'top_scorer_player_name': honorRoll.topScorerPlayerName,
      'top_scorer_team_name': honorRoll.topScorerTeamName,
      'top_scorer_goals': honorRoll.topScorerGoals,
      'best_defense_team_id': safeBestDefenseTeamId,
      'best_defense_team_name': honorRoll.bestDefenseTeamName,
      'best_defense_short_code': honorRoll.bestDefenseShortCode,
      'best_defense_goals_against': honorRoll.bestDefenseGoalsAgainst,
      'updated_at': support.nowUtc().toIso8601String(),
    }, onConflict: 'tournament_id');
    return honorRoll;
  }

  @override
  Future<void> deleteForTournament(String tournamentId) async {
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    await client
        .schema(schema)
        .from('season_honor_rolls')
        .delete()
        .eq('tournament_id', safeTournamentId);
  }
}

/// Offline-first hybrid [SeasonHonorRollRepository].
class HybridSeasonHonorRollRepository implements SeasonHonorRollRepository {
  HybridSeasonHonorRollRepository({
    required this.local,
    required this.remote,
    required this.support,
  });

  final LocalSeasonHonorRollRepository local;
  final SeasonHonorRollRemoteDataSource remote;
  final HybridRepositorySupport support;

  @override
  Future<SeasonHonorRoll?> loadHonorRollForTournament(String tournamentId) {
    return support.executeRead(
      remoteFetch: () => remote.fetchForTournament(tournamentId),
      cacheUpdate: (honorRoll) async {
        if (honorRoll != null) {
          await local.saveHonorRoll(honorRoll);
        }
      },
      localFallback: () => local.loadHonorRollForTournament(tournamentId),
    );
  }

  @override
  Future<SeasonHonorRoll> saveHonorRoll(SeasonHonorRoll honorRoll) {
    return support.executeMutation(
      localWrite: () => local.saveHonorRoll(honorRoll),
      remoteWrite: () => remote.upsertHonorRoll(honorRoll),
      entityType: SyncOutboxEntityType.seasonHonorRoll,
      entityId: honorRoll.tournamentId,
      operation: SyncOutboxOperation.upsert,
      buildPayload: () => {'honorRoll': honorRoll.toJson()},
      displayTitle: honorRoll.tournamentName,
    );
  }

  @override
  Future<void> deleteHonorRollForTournament(String tournamentId) {
    return support.executeMutation(
      localWrite: () => local.deleteHonorRollForTournament(tournamentId),
      remoteWrite: () => remote.deleteForTournament(tournamentId),
      entityType: SyncOutboxEntityType.seasonHonorRoll,
      entityId: tournamentId,
      operation: SyncOutboxOperation.delete,
      buildPayload: () => {'tournamentId': tournamentId},
      displayTitle: tournamentId,
    );
  }

  /// Replays a queued [SyncOutboxItem] against Supabase during FIFO flush.
  Future<void> replayOutboxItem(SyncOutboxItem item) async {
    if (item.operation == SyncOutboxOperation.delete) {
      await remote.deleteForTournament(item.entityId);
      return;
    }
    final raw = item.payloadJson['honorRoll'];
    if (raw is Map) {
      await remote.upsertHonorRoll(
        SeasonHonorRoll.fromJson(Map<String, dynamic>.from(raw)),
      );
    }
  }
}
