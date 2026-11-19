import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/rule_audit_entry.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';

/// Remote data source contract for `tournaments` and `rule_audit_entries`.
abstract interface class TournamentsRemoteDataSource {
  Future<List<ChampionshipTournament>> fetchAll();
  Future<ChampionshipTournament> upsert(ChampionshipTournament tournament);
  Future<void> deleteById(String tournamentId);
}

/// PostgREST implementation targeting `vifutboldev.tournaments` & `rule_audit_entries`.
class PostgrestTournamentsRemoteDataSource
    implements TournamentsRemoteDataSource {
  PostgrestTournamentsRemoteDataSource({
    required this.client,
    required this.schema,
    required this.support,
  });

  final SupabaseClient client;
  final String schema;
  final HybridRepositorySupport support;

  @override
  Future<List<ChampionshipTournament>> fetchAll() async {
    final rows = await client
        .schema(schema)
        .from('tournaments')
        .select('*, rule_audit_entries(*)')
        .order('updated_at', ascending: false);

    return (rows as List<dynamic>)
        .map((r) => _fromRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<ChampionshipTournament> upsert(
    ChampionshipTournament tournament,
  ) async {
    final nowIso = tournament.updatedAt.toUtc().toIso8601String();
    final tournamentId = HybridRepositorySupport.ensureUuid(
      tournament.id,
      'tournament',
    );
    final tournamentPayload = <String, dynamic>{
      'id': tournamentId,
      'organizer_id': HybridRepositorySupport.uuidOrNull(
        tournament.organizerId,
      ),
      'name': tournament.name,
      'category': tournament.category,
      'start_date': tournament.startDate.toUtc().toIso8601String(),
      'end_date': tournament.endDate.toUtc().toIso8601String(),
      'format': tournament.format.name,
      'status': tournament.status.name,
      'rules_config': tournament.rules.toJson(),
      'venue_ids': tournament.venueIds
          .map((v) => HybridRepositorySupport.ensureUuid(v, 'venue'))
          .toList(),
      'updated_at': nowIso,
    };

    await client
        .schema(schema)
        .from('tournaments')
        .upsert(tournamentPayload, onConflict: 'id');

    if (tournament.auditTrail.isNotEmpty) {
      final auditRows = tournament.auditTrail.map((entry) {
        final recordedIso = entry.recordedAt.toUtc().toIso8601String();
        return <String, dynamic>{
          'id': support.deterministicUuid(
            'audit|$tournamentId|$recordedIso|${entry.summary}',
          ),
          'tournament_id': tournamentId,
          'recorded_at': recordedIso,
          'summary': entry.summary,
          'reason': entry.reason,
          'recalculation_confirmed': entry.recalculationConfirmed,
          'updated_at': nowIso,
        };
      }).toList();

      await client
          .schema(schema)
          .from('rule_audit_entries')
          .upsert(auditRows, onConflict: 'id');
    }

    return tournament;
  }

  @override
  Future<void> deleteById(String tournamentId) async {
    final targetId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    await client.schema(schema).from('tournaments').delete().eq('id', targetId);
  }

  ChampionshipTournament _fromRow(Map<String, dynamic> row) {
    final rawAudit = (row['rule_audit_entries'] as List<dynamic>?) ?? const [];
    final auditTrail =
        rawAudit
            .whereType<Map>()
            .map((a) => Map<String, dynamic>.from(a))
            .map(
              (a) => RuleAuditEntry(
                recordedAt: DateTime.parse(a['recorded_at'] as String).toUtc(),
                summary: (a['summary'] as String? ?? '').trim(),
                reason: (a['reason'] as String? ?? '').trim(),
                recalculationConfirmed:
                    a['recalculation_confirmed'] as bool? ?? true,
              ),
            )
            .toList()
          ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final rawRules = row['rules_config'];
    final rules = rawRules is Map
        ? TournamentRulesConfig.fromJson(Map<String, dynamic>.from(rawRules))
        : const TournamentRulesConfig();

    final rawVenues = (row['venue_ids'] as List<dynamic>?) ?? const [];

    return ChampionshipTournament(
      id: row['id'] as String,
      organizerId: row['organizer_id'] as String?,
      name: row['name'] as String,
      category: row['category'] as String,
      startDate: DateTime.parse(row['start_date'] as String).toLocal(),
      endDate: DateTime.parse(row['end_date'] as String).toLocal(),
      format: TournamentFormat.values.firstWhere(
        (e) => e.name == row['format'],
        orElse: () => TournamentFormat.league,
      ),
      status: TournamentStatus.values.firstWhere(
        (e) => e.name == row['status'],
        orElse: () => TournamentStatus.openRegistration,
      ),
      rules: rules,
      auditTrail: auditTrail,
      venueIds: rawVenues.map((e) => e.toString()).toList(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
    );
  }
}

/// Offline-first hybrid [TournamentsRepository] coordinating local Hive cache,
/// Supabase DEV tables, and FIFO outbox queue. Local creation drafts stay offline-only.
class HybridTournamentsRepository implements TournamentsRepository {
  HybridTournamentsRepository({
    required this.local,
    required this.remote,
    required this.support,
  });

  final LocalTournamentsRepository local;
  final TournamentsRemoteDataSource remote;
  final HybridRepositorySupport support;

  ChampionshipTournament _normalizeTournament(
    ChampionshipTournament tournament,
  ) {
    final normalizedId = HybridRepositorySupport.ensureUuid(
      tournament.id,
      'tournament',
    );
    final normalizedVenueIds = tournament.venueIds
        .map((v) => HybridRepositorySupport.ensureUuid(v, 'venue'))
        .toList();
    return tournament.copyWith(
      id: normalizedId,
      venueIds: normalizedVenueIds,
    );
  }

  @override
  Future<List<ChampionshipTournament>> loadTournaments() {
    return support.executeRead(
      remoteFetch: remote.fetchAll,
      cacheUpdate: local.replaceAllCache,
      localFallback: local.loadTournaments,
    );
  }

  @override
  Future<ChampionshipTournament> saveTournament(
    ChampionshipTournament tournament,
  ) {
    final normalized = _normalizeTournament(tournament);
    return support.executeMutation(
      localWrite: () => local.saveTournament(normalized),
      remoteWrite: () => remote.upsert(normalized),
      entityType: SyncOutboxEntityType.tournament,
      entityId: normalized.id,
      operation: SyncOutboxOperation.upsert,
      buildPayload: () => {'tournament': normalized.toJson()},
      displayTitle: normalized.name,
    );
  }

  @override
  Future<void> deleteTournament(String tournamentId) {
    final normalizedId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    return support.executeMutation(
      localWrite: () => local.deleteTournament(normalizedId),
      remoteWrite: () => remote.deleteById(normalizedId),
      entityType: SyncOutboxEntityType.tournament,
      entityId: normalizedId,
      operation: SyncOutboxOperation.delete,
      buildPayload: () => {'tournamentId': normalizedId},
      displayTitle: normalizedId,
    );
  }

  /// Replays a queued [SyncOutboxItem] against Supabase during FIFO flush.
  Future<void> replayOutboxItem(SyncOutboxItem item) async {
    if (item.operation == SyncOutboxOperation.delete) {
      await remote.deleteById(item.entityId);
      return;
    }
    final raw = item.payloadJson['tournament'];
    if (raw is Map) {
      final tournament = ChampionshipTournament.fromJson(
        Map<String, dynamic>.from(raw),
      );
      await remote.upsert(tournament);
    }
  }

  @override
  Future<TournamentDraft?> loadDraft() => local.loadDraft();

  @override
  Future<void> saveDraft(TournamentDraft draft) => local.saveDraft(draft);

  @override
  Future<void> clearDraft() => local.clearDraft();
}
