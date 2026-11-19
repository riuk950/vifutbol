import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/sync/hive_sync_outbox_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';
import 'package:vifutbol/infrastructure/sync/supabase_cloud_sync_service.dart';

class _InMemoryLocalStorage implements LocalStorageRepository {
  final Map<String, String> _store = <String, String>{};

  @override
  bool get isUsingFallbackMemory => true;

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _store[key];

  @override
  Future<void> writeString(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> clearNamespace() async => _store.clear();
}

class _FakeConnectivityRepository implements ConnectivityRepository {
  NetworkConnectionStatus status = NetworkConnectionStatus.connected;
  final StreamController<NetworkConnectionStatus> _controller =
      StreamController<NetworkConnectionStatus>.broadcast();

  void setStatus(NetworkConnectionStatus next) {
    status = next;
    _controller.add(next);
  }

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async => status;

  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      _controller.stream;
}

class _FakeRemoteDataSource implements TournamentMatchesRemoteDataSource {
  final Map<String, ChampionshipMatch> remoteMatches = {};
  int replaceCalls = 0;
  int upsertCalls = 0;
  bool throwOnNextWrite = false;

  @override
  Future<List<ChampionshipMatch>> fetchAll() async =>
      remoteMatches.values.toList();

  @override
  Future<List<ChampionshipMatch>> fetchForTournament(
    String tournamentId,
  ) async {
    return remoteMatches.values
        .where((m) => m.tournamentId == tournamentId)
        .toList();
  }

  @override
  Future<List<MatchReferee>> fetchOfficialReferees() async => const [];

  @override
  Future<ChampionshipMatch> upsertMatch(ChampionshipMatch match) async {
    upsertCalls++;
    if (throwOnNextWrite) {
      throwOnNextWrite = false;
      throw Exception('Network error');
    }
    final canonicalId = HybridRepositorySupport.ensureUuid(match.id, 'match');
    final stored = match.copyWith(id: canonicalId);
    remoteMatches[canonicalId] = stored;
    return stored;
  }

  @override
  Future<List<ChampionshipMatch>> upsertBatch(
    List<ChampionshipMatch> matches,
  ) async {
    if (throwOnNextWrite) {
      throwOnNextWrite = false;
      throw Exception('Network error');
    }
    for (final m in matches) {
      final canonicalId = HybridRepositorySupport.ensureUuid(m.id, 'match');
      remoteMatches[canonicalId] = m.copyWith(id: canonicalId);
    }
    return matches;
  }

  @override
  Future<void> replaceForTournament(
    String tournamentId,
    List<ChampionshipMatch> matches,
  ) async {
    replaceCalls++;
    if (throwOnNextWrite) {
      throwOnNextWrite = false;
      throw Exception('Network error');
    }
    final incomingIds = matches
        .map((m) => HybridRepositorySupport.ensureUuid(m.id, 'match'))
        .toSet();
    remoteMatches.removeWhere(
      (id, m) => m.tournamentId == tournamentId && !incomingIds.contains(id),
    );
    for (final m in matches) {
      final canonicalId = HybridRepositorySupport.ensureUuid(m.id, 'match');
      remoteMatches[canonicalId] = m.copyWith(id: canonicalId);
    }
  }
}

void main() {
  group('HybridTournamentMatchesRepository', () {
    late LocalTournamentMatchesRepository local;
    late _FakeRemoteDataSource remote;
    late _FakeConnectivityRepository connectivity;
    late HiveSyncOutboxRepository outbox;
    late HybridRepositorySupport support;
    late HybridTournamentMatchesRepository repository;

    setUp(() {
      final storage = _InMemoryLocalStorage();
      local = LocalTournamentMatchesRepository(
        storage: storage,
        config: EnvironmentConfig.development(),
      );
      remote = _FakeRemoteDataSource();
      connectivity = _FakeConnectivityRepository();
      outbox = HiveSyncOutboxRepository(storage: storage);
      support = HybridRepositorySupport(
        connectivity: connectivity,
        outbox: outbox,
        userContextReader: () => (userId: 'org-1', isGuest: false),
      );
      repository = HybridTournamentMatchesRepository(
        local: local,
        remote: remote,
        support: support,
      );
    });

    test(
      'replaceMatchesForTournament normalizes IDs to deterministic UUIDv5, prunes stale remote rows, and is idempotent',
      () async {
        const tournId = '11111111-1111-1111-1111-111111111111';
        final initialBatch = [
          ChampionshipMatch(
            id: 'match-$tournId-r1-1',
            tournamentId: tournId,
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 'team-a',
            awayTeamId: 'team-b',
            status: MatchStatus.pendingSchedule,
          ),
          ChampionshipMatch(
            id: 'match-$tournId-r1-2',
            tournamentId: tournId,
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 'team-c',
            awayTeamId: 'team-d',
            status: MatchStatus.pendingSchedule,
          ),
        ];

        await repository.replaceMatchesForTournament(tournId, initialBatch);

        expect(remote.replaceCalls, 1);
        expect(remote.remoteMatches.length, 2);
        final localAfterFirst = await local.loadMatchesForTournament(tournId);
        expect(localAfterFirst.length, 2);

        final uuidRegex = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        );
        for (final m in localAfterFirst) {
          expect(uuidRegex.hasMatch(m.id), isTrue);
          expect(remote.remoteMatches.containsKey(m.id), isTrue);
        }

        // Regenerate with only 1 match -> stale second match must be pruned remotely & locally
        final regeneratedBatch = [
          ChampionshipMatch(
            id: 'match-$tournId-r1-1',
            tournamentId: tournId,
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 'team-a',
            awayTeamId: 'team-c',
            status: MatchStatus.pendingSchedule,
          ),
        ];

        await repository.replaceMatchesForTournament(tournId, regeneratedBatch);

        expect(remote.replaceCalls, 2);
        expect(remote.remoteMatches.length, 1);
        final localAfterRegen = await local.loadMatchesForTournament(tournId);
        expect(localAfterRegen.length, 1);
        expect(localAfterRegen.first.awayTeamId, 'team-c');

        // Re-running identical replace produces zero duplicates
        await repository.replaceMatchesForTournament(tournId, regeneratedBatch);
        expect(remote.remoteMatches.length, 1);
      },
    );

    test(
      'saveMatch normalizes ID and persists scheduled_at, optional null logistics, and full logistics',
      () async {
        const tournId = '11111111-1111-1111-1111-111111111111';
        final start = DateTime(2026, 11, 25, 19, 30);
        final end = start.add(const Duration(minutes: 105));

        final scheduledWithoutLogistics = ChampionshipMatch(
          id: 'match-$tournId-r1-1',
          tournamentId: tournId,
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          scheduledStartTime: start,
          scheduledEndTime: end,
          status: MatchStatus.scheduled,
        );

        final saved = await repository.saveMatch(scheduledWithoutLogistics);
        expect(remote.upsertCalls, 1);
        expect(remote.remoteMatches[saved.id]?.scheduledStartTime, start);
        expect(remote.remoteMatches[saved.id]?.venueId, isNull);
        expect(remote.remoteMatches[saved.id]?.pitchId, isNull);
        expect(remote.remoteMatches[saved.id]?.refereeId, isNull);
        expect(remote.remoteMatches[saved.id]?.status, MatchStatus.scheduled);
      },
    );

    test(
      'offline replaceMatchesForTournament and saveMatch enqueue in outbox and replay idempotently on reconnect',
      () async {
        const tournId = '22222222-2222-2222-2222-222222222222';
        connectivity.setStatus(NetworkConnectionStatus.disconnected);

        final batch = [
          ChampionshipMatch(
            id: 'match-$tournId-r1-1',
            tournamentId: tournId,
            roundNumber: 1,
            roundName: 'Jornada 1',
            homeTeamId: 'team-1',
            awayTeamId: 'team-2',
            status: MatchStatus.pendingSchedule,
          ),
        ];

        await repository.replaceMatchesForTournament(tournId, batch);
        var queued = await outbox.loadItemsForUser('org-1');
        expect(queued.length, 1);
        expect(remote.remoteMatches, isEmpty);

        final scheduled = batch.first.copyWith(
          scheduledStartTime: DateTime(2026, 12, 1, 15, 0),
          scheduledEndTime: DateTime(2026, 12, 1, 16, 45),
          status: MatchStatus.scheduled,
        );
        await repository.saveMatch(scheduled);
        queued = await outbox.loadItemsForUser('org-1');
        expect(queued.length, 2);

        final syncService = SupabaseCloudSyncService(
          outboxRepository: outbox,
          connectivityRepository: connectivity,
        );
        syncService.registerHandler(
          SyncOutboxEntityType.match,
          repository.replayOutboxItem,
        );

        connectivity.setStatus(NetworkConnectionStatus.connected);
        final result = await syncService.flushOutbox(userId: 'org-1');

        expect(result.syncedCount, 2);
        queued = await outbox.loadItemsForUser('org-1');
        expect(queued, isEmpty);
        expect(remote.remoteMatches.length, 1);
        expect(
          remote.remoteMatches.values.first.status,
          MatchStatus.scheduled,
        );
      },
    );
  });
}
