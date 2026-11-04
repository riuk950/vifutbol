import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_event.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_reports_repository.dart';

class MockLocalStorageRepository implements LocalStorageRepository {
  final Map<String, dynamic> _memory = {};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async {
    return const LocalStorageStatus(
      isPersistent: true,
      storageNamespace: 'test',
    );
  }

  @override
  Future<String?> readString(String key) async => _memory[key] as String?;

  @override
  Future<void> writeString(String key, String value) async {
    _memory[key] = value;
  }

  @override
  Future<void> clearNamespace() async {
    _memory.clear();
  }

  @override
  bool get isUsingFallbackMemory => true;
}

void main() {
  group('LocalMatchReportsRepository Tests', () {
    late MockLocalStorageRepository storage;
    late EnvironmentConfig config;
    late LocalMatchReportsRepository repository;

    final dummyMatch = ChampionshipMatch(
      id: 'match-test-1',
      tournamentId: 't-1',
      roundNumber: 1,
      roundName: 'Jornada 1',
      homeTeamId: 'team-home',
      awayTeamId: 'team-away',
      status: MatchStatus.scheduled,
      updatedAt: DateTime.now(),
    );

    setUp(() {
      storage = MockLocalStorageRepository();
      config = EnvironmentConfig.development();
      repository = LocalMatchReportsRepository(
        storage: storage,
        config: config,
      );
    });

    test('creates and retrieves default initial report for match', () async {
      final report = await repository.loadOrCreateReport(dummyMatch);
      expect(report.matchId, 'match-test-1');
      expect(report.currentPeriod, MatchPeriod.notStarted);
      expect(report.events, isEmpty);
      expect(report.homeScore, 0);
      expect(report.awayScore, 0);
      expect(report.isClosed, isFalse);
    });

    test('saves and retrieves modified report', () async {
      final report = await repository.loadOrCreateReport(dummyMatch);
      final updatedReport = report.copyWith(
        currentPeriod: MatchPeriod.firstHalf,
        periodStartedAt: DateTime.now(),
        homeScore: 1,
      );

      await repository.saveReport(updatedReport);
      final loaded = await repository.loadOrCreateReport(dummyMatch);

      expect(loaded.currentPeriod, MatchPeriod.firstHalf);
      expect(loaded.homeScore, 1);
    });

    test(
      'enqueues pending events when offline and synchronizes idempotently',
      () async {
        const matchId = 'match-test-1';
        final report = await repository.loadOrCreateReport(dummyMatch);

        final event1 = MatchEvent(
          id: 'event-1',
          matchId: matchId,
          teamId: 'team-home',
          type: MatchEventType.goal,
          minute: 10,
          primaryPlayerId: 'p-1',
          secondaryPlayerId: 'p-2',
          isSynced: false,
        );

        final event2 = MatchEvent(
          id: 'event-2',
          matchId: matchId,
          teamId: 'team-away',
          type: MatchEventType.yellowCard,
          minute: 25,
          primaryPlayerId: 'p-3',
          isSynced: false,
        );

        // Save report with newly created offline events
        final updatedReport = report.copyWith(
          events: [event1, event2],
          homeScore: 1,
        );
        await repository.saveReport(
          updatedReport,
          newlyCreatedEvents: [event1, event2],
        );

        var pending = await repository.loadPendingSyncQueue(matchId);
        expect(pending.length, 2);
        expect(pending.map((e) => e.id), containsAll(['event-1', 'event-2']));

        // Idempotently save again with same events
        await repository.saveReport(
          updatedReport,
          newlyCreatedEvents: [event1],
        );
        pending = await repository.loadPendingSyncQueue(matchId);
        expect(
          pending.length,
          2,
          reason: 'Duplicate event id should not create duplicate entries',
        );

        // Synchronize pending events
        final syncedReport = await repository.synchronizePendingEvents(matchId);
        expect(syncedReport.events.length, 2);
        expect(syncedReport.events.every((e) => e.isSynced), isTrue);

        // Queue should now be empty
        final emptyQueue = await repository.loadPendingSyncQueue(matchId);
        expect(emptyQueue, isEmpty);
      },
    );
  });
}
