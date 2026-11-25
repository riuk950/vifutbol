import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/match_event.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/match_reports_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_reports_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';

/// Remote data source contract for `digital_match_reports` and `match_events`.
abstract interface class MatchReportsRemoteDataSource {
  Future<DigitalMatchReport?> fetchReportByMatchId(String matchId);
  Future<List<DigitalMatchReport>> fetchReportsForTournament(
    String tournamentId,
  );
  Future<DigitalMatchReport> upsertReport(DigitalMatchReport report);
  Future<void> replaceForTournament(
    String tournamentId,
    List<DigitalMatchReport> reports,
  );
}

/// PostgREST implementation targeting `vifutboldev.digital_match_reports` and `match_events`.
class PostgrestMatchReportsRemoteDataSource
    implements MatchReportsRemoteDataSource {
  PostgrestMatchReportsRemoteDataSource({
    required this.client,
    required this.schema,
    required this.support,
  });

  final SupabaseClient client;
  final String schema;
  final HybridRepositorySupport support;

  static String _toDbPeriod(MatchPeriod p) => switch (p) {
    MatchPeriod.notStarted => 'notStarted',
    MatchPeriod.firstHalf => 'firstHalf',
    MatchPeriod.halfTime => 'halftime',
    MatchPeriod.secondHalf => 'secondHalf',
    MatchPeriod.fullTime => 'extraTime',
    MatchPeriod.closed => 'closed',
  };

  static MatchPeriod _fromDbPeriod(String? value) => switch (value) {
    'notStarted' => MatchPeriod.notStarted,
    'firstHalf' => MatchPeriod.firstHalf,
    'halftime' => MatchPeriod.halfTime,
    'secondHalf' => MatchPeriod.secondHalf,
    'extraTime' || 'penalties' => MatchPeriod.fullTime,
    'closed' => MatchPeriod.closed,
    _ => MatchPeriod.notStarted,
  };

  static String _toDbEventType(MatchEventType type) => switch (type) {
    MatchEventType.goal => 'goal',
    MatchEventType.yellowCard => 'yellowCard',
    MatchEventType.secondYellowRedCard ||
    MatchEventType.directRedCard => 'redCard',
    MatchEventType.substitution => 'substitution',
    MatchEventType.periodTransition => 'assist',
  };

  static String? _encodeDescription(MatchEvent event) {
    final base = (event.description ?? '').trim();
    if (event.type == MatchEventType.secondYellowRedCard) {
      return '[2Y]${base.isEmpty ? '' : ' $base'}';
    }
    if (event.type == MatchEventType.periodTransition) {
      return '[PERIOD]${base.isEmpty ? '' : ' $base'}';
    }
    return base.isEmpty ? null : base;
  }

  static ({MatchEventType type, String? description}) _decodeEventTypeAndDesc(
    String? dbType,
    String? rawDesc,
  ) {
    final desc = rawDesc?.trim();
    if (desc != null && desc.startsWith('[2Y]')) {
      final cleaned = desc.substring(4).trim();
      return (
        type: MatchEventType.secondYellowRedCard,
        description: cleaned.isEmpty ? null : cleaned,
      );
    }
    if (desc != null && desc.startsWith('[PERIOD]')) {
      final cleaned = desc.substring(8).trim();
      return (
        type: MatchEventType.periodTransition,
        description: cleaned.isEmpty ? null : cleaned,
      );
    }
    final mapped = switch (dbType) {
      'goal' => MatchEventType.goal,
      'yellowCard' => MatchEventType.yellowCard,
      'redCard' => MatchEventType.directRedCard,
      'substitution' => MatchEventType.substitution,
      'assist' => MatchEventType.periodTransition,
      _ => MatchEventType.goal,
    };
    return (type: mapped, description: desc?.isEmpty == true ? null : desc);
  }

  String _reportUuid(String matchId) {
    return support.deterministicUuid('report|$matchId');
  }

  String _eventUuid(String rawId) {
    return HybridRepositorySupport.uuidOrNull(rawId) ??
        support.deterministicUuid('event|$rawId');
  }

  @override
  Future<DigitalMatchReport?> fetchReportByMatchId(String matchId) async {
    final safeMatchId = HybridRepositorySupport.ensureUuid(matchId, 'match');
    final row = await client
        .schema(schema)
        .from('digital_match_reports')
        .select('*, match_events(*)')
        .eq('match_id', safeMatchId)
        .maybeSingle();

    if (row == null) return null;
    return _fromRow(row);
  }

  @override
  Future<List<DigitalMatchReport>> fetchReportsForTournament(
    String tournamentId,
  ) async {
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    final rows = await client
        .schema(schema)
        .from('digital_match_reports')
        .select('*, match_events(*)')
        .eq('tournament_id', safeTournamentId);

    return (rows as List<dynamic>)
        .map((r) => _fromRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<DigitalMatchReport> upsertReport(DigitalMatchReport report) async {
    final safeMatchId = HybridRepositorySupport.ensureUuid(
      report.matchId,
      'match',
    );
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      report.tournamentId,
      'tournament',
    );
    final safeHomeTeamId = HybridRepositorySupport.ensureUuid(
      report.homeTeamId,
      'tournament_team',
    );
    final safeAwayTeamId = HybridRepositorySupport.ensureUuid(
      report.awayTeamId,
      'tournament_team',
    );
    final existing = await client
        .schema(schema)
        .from('digital_match_reports')
        .select('id')
        .eq('match_id', safeMatchId)
        .maybeSingle();
    final reportId = (existing?['id'] as String?) ?? _reportUuid(safeMatchId);
    final nowIso = report.updatedAt.toUtc().toIso8601String();

    await client.schema(schema).from('digital_match_reports').upsert({
      'id': reportId,
      'match_id': safeMatchId,
      'tournament_id': safeTournamentId,
      'home_tournament_team_id': safeHomeTeamId,
      'away_tournament_team_id': safeAwayTeamId,
      'home_score': report.homeScore,
      'away_score': report.awayScore,
      'home_penalty_score': report.homePenaltyScore,
      'away_penalty_score': report.awayPenaltyScore,
      'current_period': _toDbPeriod(report.currentPeriod),
      'period_started_at': report.periodStartedAt?.toUtc().toIso8601String(),
      'elapsed_seconds_before_current_period':
          report.elapsedSecondsBeforeCurrentPeriod,
      'referee_observations': report.refereeObservations,
      'closed_at': report.closedAt?.toUtc().toIso8601String(),
      'closed_by_user_id': HybridRepositorySupport.uuidOrNull(
        report.closedByUserId,
      ),
      'updated_at': nowIso,
    }, onConflict: 'match_id');

    if (report.events.isNotEmpty) {
      final eventRows = report.events
          .map(
            (e) => <String, dynamic>{
              'id': _eventUuid(e.id),
              'report_id': reportId,
              'match_id': safeMatchId,
              'event_type': _toDbEventType(e.type),
              'minute': e.minute,
              'tournament_team_id': (e.teamId == 'match' || e.teamId.isEmpty)
                  ? safeHomeTeamId
                  : HybridRepositorySupport.ensureUuid(
                      e.teamId,
                      'tournament_team',
                    ),
              'primary_player_id': HybridRepositorySupport.ensureUuidOrNull(
                e.primaryPlayerId,
                'player',
              ),
              'primary_player_name': e.primaryPlayerName,
              'primary_player_shirt_number': e.primaryPlayerShirtNumber,
              'secondary_player_id': HybridRepositorySupport.ensureUuidOrNull(
                e.secondaryPlayerId,
                'player',
              ),
              'secondary_player_name': e.secondaryPlayerName,
              'secondary_player_shirt_number': e.secondaryPlayerShirtNumber,
              'linked_parent_event_id': e.linkedParentEventId == null
                  ? null
                  : _eventUuid(e.linkedParentEventId!),
              'description': _encodeDescription(e),
              'is_synced': true,
              'created_at': e.createdAt.toUtc().toIso8601String(),
              'updated_at': nowIso,
            },
          )
          .toList();

      await client
          .schema(schema)
          .from('match_events')
          .upsert(eventRows, onConflict: 'id');
    }

    final syncedEvents = report.events
        .map((e) => e.isSynced ? e : e.copyWith(isSynced: true))
        .toList();
    return report.copyWith(events: syncedEvents);
  }

  @override
  Future<void> replaceForTournament(
    String tournamentId,
    List<DigitalMatchReport> reports,
  ) async {
    for (final report in reports) {
      await upsertReport(report);
    }
  }

  DigitalMatchReport _fromRow(Map<String, dynamic> row) {
    final rawEvents = (row['match_events'] as List<dynamic>?) ?? const [];
    final events =
        rawEvents.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).map(
          (e) {
            final decoded = _decodeEventTypeAndDesc(
              e['event_type'] as String?,
              e['description'] as String?,
            );
            return MatchEvent(
              id: e['id'] as String,
              matchId: e['match_id'] as String,
              type: decoded.type,
              minute: (e['minute'] as num).toInt(),
              teamId: e['tournament_team_id'] as String,
              primaryPlayerId: e['primary_player_id'] as String?,
              primaryPlayerName: e['primary_player_name'] as String?,
              primaryPlayerShirtNumber:
                  (e['primary_player_shirt_number'] as num?)?.toInt(),
              secondaryPlayerId: e['secondary_player_id'] as String?,
              secondaryPlayerName: e['secondary_player_name'] as String?,
              secondaryPlayerShirtNumber:
                  (e['secondary_player_shirt_number'] as num?)?.toInt(),
              linkedParentEventId: e['linked_parent_event_id'] as String?,
              description: decoded.description,
              isSynced: e['is_synced'] as bool? ?? true,
              createdAt: DateTime.parse(e['created_at'] as String).toLocal(),
            );
          },
        ).toList()..sort((a, b) => a.minute.compareTo(b.minute));

    final rawPeriodStarted = row['period_started_at'] as String?;
    final rawClosedAt = row['closed_at'] as String?;

    return DigitalMatchReport(
      matchId: row['match_id'] as String,
      tournamentId: row['tournament_id'] as String,
      homeTeamId: row['home_tournament_team_id'] as String,
      awayTeamId: row['away_tournament_team_id'] as String,
      homeScore: (row['home_score'] as num?)?.toInt() ?? 0,
      awayScore: (row['away_score'] as num?)?.toInt() ?? 0,
      homePenaltyScore: (row['home_penalty_score'] as num?)?.toInt(),
      awayPenaltyScore: (row['away_penalty_score'] as num?)?.toInt(),
      currentPeriod: _fromDbPeriod(row['current_period'] as String?),
      periodStartedAt: rawPeriodStarted == null
          ? null
          : DateTime.parse(rawPeriodStarted).toLocal(),
      elapsedSecondsBeforeCurrentPeriod:
          (row['elapsed_seconds_before_current_period'] as num?)?.toInt() ?? 0,
      events: events,
      refereeObservations: row['referee_observations'] as String?,
      closedAt: rawClosedAt == null
          ? null
          : DateTime.parse(rawClosedAt).toLocal(),
      closedByUserId: row['closed_by_user_id'] as String?,
      updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
    );
  }
}

/// Offline-first hybrid [MatchReportsRepository] integrating digital match reports and
/// live match events directly with the global FIFO [SyncOutboxRepository].
class HybridMatchReportsRepository implements MatchReportsRepository {
  HybridMatchReportsRepository({
    required this.local,
    required this.remote,
    required this.support,
  });

  final LocalMatchReportsRepository local;
  final MatchReportsRemoteDataSource remote;
  final HybridRepositorySupport support;

  @override
  Future<DigitalMatchReport> loadOrCreateReport(ChampionshipMatch match) {
    return support.executeRead(
      remoteFetch: () async {
        final fetched = await remote.fetchReportByMatchId(match.id);
        return fetched ?? await local.loadOrCreateReport(match);
      },
      cacheUpdate: (report) => local.saveReport(report),
      localFallback: () => local.loadOrCreateReport(match),
    );
  }

  @override
  Future<List<DigitalMatchReport>> loadReportsForTournament(
    String tournamentId,
  ) {
    return support.executeRead(
      remoteFetch: () => remote.fetchReportsForTournament(tournamentId),
      cacheUpdate: (reports) =>
          local.replaceReportsForTournament(tournamentId, reports),
      localFallback: () => local.loadReportsForTournament(tournamentId),
    );
  }

  @override
  Future<DigitalMatchReport> saveReport(
    DigitalMatchReport report, {
    List<MatchEvent> newlyCreatedEvents = const [],
  }) {
    final syncedEvents = report.events
        .map((e) => e.isSynced ? e : e.copyWith(isSynced: true))
        .toList();
    final reportMarkedSynced = report.copyWith(events: syncedEvents);

    return support.executeMutation(
      localWrite: () =>
          local.saveReport(report, newlyCreatedEvents: newlyCreatedEvents),
      remoteWrite: () async {
        final remoteSaved = await remote.upsertReport(reportMarkedSynced);
        await local.saveReport(remoteSaved);
        return remoteSaved;
      },
      entityType: SyncOutboxEntityType.matchReport,
      entityId: report.matchId,
      operation: SyncOutboxOperation.upsert,
      buildPayload: () => {'report': report.toJson()},
      displayTitle: '${report.homeScore}-${report.awayScore}',
    );
  }

  @override
  Future<List<MatchEvent>> loadPendingSyncQueue(String matchId) {
    return local.loadPendingSyncQueue(matchId);
  }

  @override
  Future<DigitalMatchReport> synchronizePendingEvents(String matchId) async {
    final localQueue = await local.loadPendingSyncQueue(matchId);
    final updated = await local.synchronizePendingEvents(matchId);
    if (localQueue.isNotEmpty) {
      await remote.upsertReport(updated);
    }
    return updated;
  }

  @override
  Future<void> replaceReportsForTournament(
    String tournamentId,
    List<DigitalMatchReport> reports,
  ) {
    return support.executeMutation(
      localWrite: () =>
          local.replaceReportsForTournament(tournamentId, reports),
      remoteWrite: () => remote.replaceForTournament(tournamentId, reports),
      entityType: SyncOutboxEntityType.matchReport,
      entityId: tournamentId,
      operation: SyncOutboxOperation.replaceBatch,
      buildPayload: () => {
        'tournamentId': tournamentId,
        'reports': reports.map((r) => r.toJson()).toList(),
      },
      displayTitle: tournamentId,
    );
  }

  /// Replays a queued [SyncOutboxItem] against Supabase during FIFO flush.
  Future<void> replayOutboxItem(SyncOutboxItem item) async {
    if (item.operation == SyncOutboxOperation.replaceBatch) {
      final tournamentId = item.payloadJson['tournamentId'] as String? ?? '';
      final rawReports = (item.payloadJson['reports'] as List<dynamic>?) ?? [];
      final reports = rawReports
          .whereType<Map>()
          .map((m) => DigitalMatchReport.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      await remote.replaceForTournament(tournamentId, reports);
      return;
    }

    final raw = item.payloadJson['report'];
    if (raw is Map) {
      final report = DigitalMatchReport.fromJson(
        Map<String, dynamic>.from(raw),
      );
      final synced = await remote.upsertReport(report);
      await local.saveReport(synced);
    }
  }
}
