import 'dart:convert';
import '../../domain/entities/app_environment.dart';
import '../../domain/entities/championship_match.dart';
import '../../domain/entities/digital_match_report.dart';
import '../../domain/entities/match_enums.dart';
import '../../domain/entities/match_event.dart';
import '../../domain/entities/match_report_enums.dart';
import '../../domain/repositories/local_storage_repository.dart';
import '../../domain/repositories/match_reports_repository.dart';

/// Offline-first implementation of [MatchReportsRepository] backed by [LocalStorageRepository].
class LocalMatchReportsRepository implements MatchReportsRepository {
  LocalMatchReportsRepository({
    required this.storage,
    required this.config,
    this.reportsStorageKey = 'vifutbol.match_reports.v1',
    this.syncQueueStorageKey = 'vifutbol.match_events_sync_queue.v1',
  });

  final LocalStorageRepository storage;
  final EnvironmentConfig config;
  final String reportsStorageKey;
  final String syncQueueStorageKey;

  @override
  Future<DigitalMatchReport> loadOrCreateReport(ChampionshipMatch match) async {
    final reports = await _loadAllReports();
    final existingIndex = reports.indexWhere((r) => r.matchId == match.id);

    if (existingIndex >= 0) {
      return reports[existingIndex];
    }

    final initialReport = DigitalMatchReport(
      matchId: match.id,
      tournamentId: match.tournamentId,
      homeTeamId: match.homeTeamId,
      awayTeamId: match.awayTeamId,
      homeScore: match.homeScore ?? 0,
      awayScore: match.awayScore ?? 0,
      currentPeriod: match.status == MatchStatus.inProgress
          ? MatchPeriod.firstHalf
          : (match.status == MatchStatus.completed
                ? MatchPeriod.closed
                : MatchPeriod.notStarted),
    );

    final updated = List<DigitalMatchReport>.from(reports)..add(initialReport);
    await _persistReports(updated);
    return initialReport;
  }

  @override
  Future<List<DigitalMatchReport>> loadReportsForTournament(
    String tournamentId,
  ) async {
    final reports = await _loadAllReports();
    return reports.where((r) => r.tournamentId == tournamentId).toList();
  }

  @override
  Future<DigitalMatchReport> saveReport(
    DigitalMatchReport report, {
    List<MatchEvent> newlyCreatedEvents = const [],
  }) async {
    final reports = await _loadAllReports();
    final index = reports.indexWhere((r) => r.matchId == report.idOrMatchId);

    final updatedList = List<DigitalMatchReport>.from(reports);
    if (index >= 0) {
      updatedList[index] = report;
    } else {
      updatedList.add(report);
    }

    await _persistReports(updatedList);

    // Queue unsynced events if provided
    final unsyncedEvents = newlyCreatedEvents
        .where((e) => !e.isSynced)
        .toList();
    if (unsyncedEvents.isNotEmpty) {
      await _enqueueOfflineEvents(unsyncedEvents);
    }

    return report;
  }

  @override
  Future<List<MatchEvent>> loadPendingSyncQueue(String matchId) async {
    final allQueued = await _loadSyncQueue();
    return allQueued.where((e) => e.matchId == matchId).toList();
  }

  @override
  Future<DigitalMatchReport> synchronizePendingEvents(String matchId) async {
    final reports = await _loadAllReports();
    final index = reports.indexWhere((r) => r.matchId == matchId);

    final allQueued = await _loadSyncQueue();
    // Remove queued events for this match
    final remainingQueue = allQueued
        .where((e) => e.matchId != matchId)
        .toList();
    await _persistSyncQueue(remainingQueue);

    if (index < 0) {
      throw StateError(
        'Cannot synchronize report: Match report not found for $matchId',
      );
    }

    final current = reports[index];
    final synchronizedEvents = current.events.map((e) {
      return e.isSynced ? e : e.copyWith(isSynced: true);
    }).toList();

    final updatedReport = current.copyWith(
      events: synchronizedEvents,
      updatedAt: DateTime.now(),
    );

    reports[index] = updatedReport;
    await _persistReports(reports);

    return updatedReport;
  }

  Future<List<DigitalMatchReport>> _loadAllReports() async {
    final raw = await storage.readString(reportsStorageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(DigitalMatchReport.fromJson)
            .toList();
      } catch (_) {}
    }

    return const <DigitalMatchReport>[];
  }

  Future<void> _persistReports(List<DigitalMatchReport> reports) async {
    final jsonList = reports.map((r) => r.toJson()).toList();
    await storage.writeString(reportsStorageKey, jsonEncode(jsonList));
  }

  Future<List<MatchEvent>> _loadSyncQueue() async {
    final raw = await storage.readString(syncQueueStorageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(MatchEvent.fromJson)
            .toList();
      } catch (_) {}
    }
    return const <MatchEvent>[];
  }

  Future<void> _persistSyncQueue(List<MatchEvent> queue) async {
    final jsonList = queue.map((e) => e.toJson()).toList();
    await storage.writeString(syncQueueStorageKey, jsonEncode(jsonList));
  }

  Future<void> _enqueueOfflineEvents(List<MatchEvent> newEvents) async {
    final existingQueue = await _loadSyncQueue();
    final existingIds = existingQueue.map((e) => e.id).toSet();

    final deduplicated = List<MatchEvent>.from(existingQueue);
    for (final event in newEvents) {
      if (!existingIds.contains(event.id)) {
        deduplicated.add(event);
        existingIds.add(event.id);
      }
    }

    await _persistSyncQueue(deduplicated);
  }
}

extension _DigitalMatchReportX on DigitalMatchReport {
  String get idOrMatchId => matchId;
}
