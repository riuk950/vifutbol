import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/rule_audit_entry.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_tournaments_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
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

class _FakeTournamentsRemoteDataSource implements TournamentsRemoteDataSource {
  final Map<String, ChampionshipTournament> remoteTournaments = {};
  int upsertCalls = 0;

  @override
  Future<List<ChampionshipTournament>> fetchAll() async =>
      remoteTournaments.values.toList();

  @override
  Future<ChampionshipTournament> upsert(
    ChampionshipTournament tournament,
  ) async {
    upsertCalls++;
    final canonicalId = HybridRepositorySupport.ensureUuid(
      tournament.id,
      'tournament',
    );
    final stored = tournament.copyWith(id: canonicalId);
    remoteTournaments[canonicalId] = stored;
    return stored;
  }

  @override
  Future<void> deleteById(String tournamentId) async {
    final canonicalId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    remoteTournaments.remove(canonicalId);
  }
}

void main() {
  group('HybridTournamentsRepository', () {
    late _InMemoryLocalStorage storage;
    late _FakeConnectivityRepository connectivity;
    late HiveSyncOutboxRepository outbox;
    late SupabaseCloudSyncService syncService;
    late HybridRepositorySupport support;
    late LocalTournamentsRepository local;
    late _FakeTournamentsRemoteDataSource remote;
    late HybridTournamentsRepository repo;

    setUp(() {
      storage = _InMemoryLocalStorage();
      connectivity = _FakeConnectivityRepository();
      outbox = HiveSyncOutboxRepository(storage: storage);
      syncService = SupabaseCloudSyncService(
        outboxRepository: outbox,
        connectivityRepository: connectivity,
      );
      syncService.setActiveUser('org-1');
      support = HybridRepositorySupport(
        connectivity: connectivity,
        outbox: outbox,
        userContextReader: () => (userId: 'org-1', isGuest: false),
      );
      local = LocalTournamentsRepository(
        storage: storage,
        config: EnvironmentConfig.development(),
      );
      remote = _FakeTournamentsRemoteDataSource();
      repo = HybridTournamentsRepository(
        local: local,
        remote: remote,
        support: support,
      );
      syncService.registerHandler(
        SyncOutboxEntityType.tournament,
        repo.replayOutboxItem,
      );
    });

    test(
      'normalizes tournament id and venueIds to deterministic UUIDv5 before local and remote writes',
      () async {
        final tournament = ChampionshipTournament(
          id: 'liga-local-1',
          name: 'Liga Apertura 2026',
          category: 'Libre',
          format: TournamentFormat.mixedGroupsAndKnockout,
          status: TournamentStatus.inProgress,
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 6, 30),
          venueIds: const ['sede-norte', 'sede-sur'],
          rules: const TournamentRulesConfig(
            pointsForWin: 3,
            pointsForDraw: 1,
            pointsForLoss: 0,
            tiebreakerOrder: [
              TiebreakerCriterion.headToHead,
              TiebreakerCriterion.goalDifference,
              TiebreakerCriterion.goalsFor,
            ],
            groupStageConfig: GroupStageConfig(
              groupCount: 4,
              advancingPerGroup: 2,
            ),
          ),
          auditTrail: [
            RuleAuditEntry(
              recordedAt: DateTime.utc(2026, 3, 2, 12, 0),
              summary: 'Ajuste de desempate a enfrentamiento directo',
              reason: 'Acuerdo técnico',
              recalculationConfirmed: true,
            ),
          ],
          updatedAt: DateTime(2026, 3, 2),
        );

        final saved = await repo.saveTournament(tournament);
        final expectedId = HybridRepositorySupport.ensureUuid(
          'liga-local-1',
          'tournament',
        );
        final expectedVenue1 = HybridRepositorySupport.ensureUuid(
          'sede-norte',
          'venue',
        );
        final expectedVenue2 = HybridRepositorySupport.ensureUuid(
          'sede-sur',
          'venue',
        );

        expect(saved.id, expectedId);
        expect(saved.venueIds, [expectedVenue1, expectedVenue2]);

        final localList = await local.loadTournaments();
        expect(localList, hasLength(1));
        expect(localList.first.id, expectedId);
        expect(localList.first.venueIds, [expectedVenue1, expectedVenue2]);
        expect(localList.first.rules, tournament.rules);
        expect(localList.first.auditTrail, hasLength(1));

        expect(remote.remoteTournaments.containsKey(expectedId), isTrue);
        expect(
          remote.remoteTournaments[expectedId]!.rules.tiebreakerOrder,
          tournament.rules.tiebreakerOrder,
        );
      },
    );

    test(
      'TournamentRulesConfig.fromJson applies safe backward-compatible defaults on partial JSON',
      () {
        final partial = TournamentRulesConfig.fromJson(const {
          'pointsForWin': 4,
          'tiebreakerOrder': ['goalDifference', 'unknownCriterion', 'goalsFor'],
        });

        expect(partial.pointsForWin, 4);
        expect(partial.pointsForDraw, 1);
        expect(partial.pointsForLoss, 0);
        expect(partial.tiebreakerOrder, const [
          TiebreakerCriterion.goalDifference,
          TiebreakerCriterion.goalsFor,
        ]);
        expect(partial.groupStageConfig.groupCount, 4);
        expect(partial.halfDurationMinutes, 45);
      },
    );

    test(
      'queues offline saveTournament and replays into remote on reconnect',
      () async {
        connectivity.setStatus(NetworkConnectionStatus.disconnected);
        final tournament = ChampionshipTournament(
          id: 'offline-cup',
          name: 'Copa Offline',
          category: 'Sub-20',
          format: TournamentFormat.knockoutCup,
          status: TournamentStatus.openRegistration,
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2026, 4, 20),
          updatedAt: DateTime(2026, 4, 1),
        );

        await repo.saveTournament(tournament);
        expect(remote.remoteTournaments, isEmpty);
        final pending = await outbox.loadItemsForUser('org-1');
        expect(pending, hasLength(1));

        connectivity.setStatus(NetworkConnectionStatus.connected);
        final flushResult = await syncService.flushOutbox(userId: 'org-1');
        expect(flushResult.syncedCount, 1);

        final expectedId = HybridRepositorySupport.ensureUuid(
          'offline-cup',
          'tournament',
        );
        expect(remote.remoteTournaments.containsKey(expectedId), isTrue);
      },
    );
  });
}
