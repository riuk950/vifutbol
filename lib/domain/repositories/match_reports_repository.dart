import '../entities/championship_match.dart';
import '../entities/digital_match_report.dart';
import '../entities/match_event.dart';

/// Contract for managing digital match reports and offline synchronization queue.
abstract class MatchReportsRepository {
  /// Loads the digital match report for [match.id], or creates an initial report
  /// linked to the given [match] if none exists yet.
  Future<DigitalMatchReport> loadOrCreateReport(ChampionshipMatch match);

  /// Saves the updated [DigitalMatchReport] to local storage.
  /// If [newlyCreatedEvents] are provided, also appends unsynced events to the sync queue.
  Future<DigitalMatchReport> saveReport(
    DigitalMatchReport report, {
    List<MatchEvent> newlyCreatedEvents = const [],
  });

  /// Loads all events currently queued in offline storage for [matchId].
  Future<List<MatchEvent>> loadPendingSyncQueue(String matchId);

  /// Idempotently synchronizes pending offline events for [matchId],
  /// marking all events in the report as synced and clearing the queue.
  Future<DigitalMatchReport> synchronizePendingEvents(String matchId);
}
