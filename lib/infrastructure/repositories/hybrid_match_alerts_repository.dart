import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import 'package:vifutbol/domain/entities/match_alert_type.dart';
import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/domain/entities/sync_outbox_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/match_alerts_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_alerts_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';

/// Remote data source contract for `match_live_alerts`.
abstract interface class MatchAlertsRemoteDataSource {
  Future<List<MatchLiveAlert>> fetchAlerts({String? tournamentId});
  Future<void> upsertAlert(MatchLiveAlert alert);
  Future<void> markAsRead(String alertId);
  Future<void> markAllAsRead({String? tournamentId});
}

/// PostgREST implementation targeting `vifutboldev.match_live_alerts`.
class PostgrestMatchAlertsRemoteDataSource
    implements MatchAlertsRemoteDataSource {
  PostgrestMatchAlertsRemoteDataSource({
    required this.client,
    required this.schema,
  });

  final SupabaseClient client;
  final String schema;

  static String _toDbAlertType(MatchAlertType type) => switch (type) {
    MatchAlertType.matchStarted => 'kickoff',
    MatchAlertType.goalScored => 'goal',
    MatchAlertType.matchEnded => 'fullTime',
    MatchAlertType.refereeMatchAssigned => 'refereeMatchAssigned',
    MatchAlertType.matchUpcoming ||
    MatchAlertType.newsPublished => 'rescheduling',
  };

  static MatchAlertType _fromDbAlertType(String? value) => switch (value) {
    'kickoff' => MatchAlertType.matchStarted,
    'goal' => MatchAlertType.goalScored,
    'fullTime' => MatchAlertType.matchEnded,
    'refereeMatchAssigned' => MatchAlertType.refereeMatchAssigned,
    'rescheduling' => MatchAlertType.matchUpcoming,
    _ => MatchAlertType.matchUpcoming,
  };

  @override
  Future<List<MatchLiveAlert>> fetchAlerts({String? tournamentId}) async {
    var query = client.schema(schema).from('match_live_alerts').select();
    if (tournamentId != null && tournamentId.isNotEmpty) {
      final safeTournamentId = HybridRepositorySupport.ensureUuid(
        tournamentId,
        'tournament',
      );
      query = query.eq('tournament_id', safeTournamentId);
    }
    final rows = await query.order('alert_timestamp', ascending: false);

    return (rows as List<dynamic>)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .map(
          (r) => MatchLiveAlert(
            id: r['id'] as String,
            matchId: r['match_id'] as String,
            tournamentId: r['tournament_id'] as String,
            type: _fromDbAlertType(r['alert_type'] as String?),
            title: r['title'] as String,
            message: r['message'] as String,
            timestamp: DateTime.parse(r['alert_timestamp'] as String).toLocal(),
            isRead: r['is_read'] as bool? ?? false,
            recipientUserId: r['recipient_user_id'] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<void> upsertAlert(MatchLiveAlert alert) async {
    final safeId = HybridRepositorySupport.ensureUuid(alert.id, 'alert');
    final safeMatchId = HybridRepositorySupport.ensureUuid(
      alert.matchId,
      'match',
    );
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      alert.tournamentId,
      'tournament',
    );
    await client.schema(schema).from('match_live_alerts').upsert({
      'id': safeId,
      'match_id': safeMatchId,
      'tournament_id': safeTournamentId,
      'alert_type': _toDbAlertType(alert.type),
      'recipient_user_id': HybridRepositorySupport.uuidOrNull(
        alert.recipientUserId,
      ),
      'title': alert.title,
      'message': alert.message,
      'alert_timestamp': alert.timestamp.toUtc().toIso8601String(),
      'is_read': alert.isRead,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'id');
  }

  @override
  Future<void> markAsRead(String alertId) async {
    final safeId = HybridRepositorySupport.ensureUuid(alertId, 'alert');
    await client
        .schema(schema)
        .from('match_live_alerts')
        .update({'is_read': true})
        .eq('id', safeId);
  }

  @override
  Future<void> markAllAsRead({String? tournamentId}) async {
    var query = client.schema(schema).from('match_live_alerts').update({
      'is_read': true,
    });
    if (tournamentId != null && tournamentId.isNotEmpty) {
      final safeTournamentId = HybridRepositorySupport.ensureUuid(
        tournamentId,
        'tournament',
      );
      query = query.eq('tournament_id', safeTournamentId);
    }
    await query;
  }
}

/// Offline-first hybrid [MatchAlertsRepository].
class HybridMatchAlertsRepository implements MatchAlertsRepository {
  HybridMatchAlertsRepository({
    required this.local,
    required this.remote,
    required this.support,
  });

  final LocalMatchAlertsRepository local;
  final MatchAlertsRemoteDataSource remote;
  final HybridRepositorySupport support;

  @override
  Future<List<MatchLiveAlert>> loadAlerts(
    String userId, {
    String? tournamentId,
  }) {
    return support.executeRead(
      remoteFetch: () => remote.fetchAlerts(tournamentId: tournamentId),
      cacheUpdate: (alerts) async {
        if (tournamentId == null) {
          await local.replaceAllCache(alerts);
        } else {
          for (final alert in alerts) {
            await local.saveAlert(alert);
          }
        }
      },
      localFallback: () => local.loadAlerts(userId, tournamentId: tournamentId),
    );
  }

  @override
  Stream<List<MatchLiveAlert>> watchAlerts(
    String userId, {
    String? tournamentId,
  }) {
    loadAlerts(userId, tournamentId: tournamentId).ignore();
    return local.watchAlerts(userId, tournamentId: tournamentId);
  }

  @override
  Future<void> saveAlert(MatchLiveAlert alert) {
    return support.executeMutation(
      localWrite: () => local.saveAlert(alert),
      remoteWrite: () => remote.upsertAlert(alert),
      entityType: SyncOutboxEntityType.matchAlert,
      entityId: alert.id,
      operation: SyncOutboxOperation.upsert,
      buildPayload: () => {'kind': 'save', 'alert': alert.toJson()},
      displayTitle: alert.title,
    );
  }

  @override
  Future<void> markAsRead(String alertId) {
    return support.executeMutation(
      localWrite: () => local.markAsRead(alertId),
      remoteWrite: () => remote.markAsRead(alertId),
      entityType: SyncOutboxEntityType.matchAlert,
      entityId: alertId,
      operation: SyncOutboxOperation.upsert,
      buildPayload: () => {'kind': 'markRead', 'alertId': alertId},
      displayTitle: alertId,
    );
  }

  @override
  Future<void> markAllAsRead(String userId, {String? tournamentId}) {
    return support.executeMutation(
      localWrite: () => local.markAllAsRead(userId, tournamentId: tournamentId),
      remoteWrite: () => remote.markAllAsRead(tournamentId: tournamentId),
      entityType: SyncOutboxEntityType.matchAlert,
      entityId: tournamentId ?? userId,
      operation: SyncOutboxOperation.replaceBatch,
      buildPayload: () => {'kind': 'markAllRead', 'tournamentId': tournamentId},
      displayTitle: tournamentId ?? 'alerts',
    );
  }

  @override
  Future<void> clearAlerts(String userId) {
    return local.clearAlerts(userId);
  }

  /// Replays a queued [SyncOutboxItem] against Supabase during FIFO flush.
  Future<void> replayOutboxItem(SyncOutboxItem item) async {
    final kind = item.payloadJson['kind'] as String?;
    switch (kind) {
      case 'markRead':
        await remote.markAsRead(item.payloadJson['alertId'] as String);
      case 'markAllRead':
        await remote.markAllAsRead(
          tournamentId: item.payloadJson['tournamentId'] as String?,
        );
      default:
        final raw = item.payloadJson['alert'];
        if (raw is Map) {
          await remote.upsertAlert(
            MatchLiveAlert.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
    }
  }
}
