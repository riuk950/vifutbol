import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/player_directory_item.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
import 'package:vifutbol/domain/entities/team_directory_item.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
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

class _FakeTeamsRemoteDataSource implements TeamsRemoteDataSource {
  final Map<String, TournamentTeam> remoteTeams = {};
  int replaceCalls = 0;

  @override
  Future<List<TournamentTeam>> fetchAll() async => remoteTeams.values.toList();

  @override
  Future<List<PlayerDirectoryItem>> fetchAllPlayers() async => const [];

  @override
  Future<List<TeamDirectoryItem>> fetchAllTeams() async => const [];

  @override
  Future<List<TournamentTeam>> fetchForTournament(String tournamentId) async {
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    return remoteTeams.values
        .where((t) => t.tournamentId == safeTournamentId)
        .toList();
  }

  @override
  Future<TournamentTeam> upsert(TournamentTeam team) async {
    final safeId = HybridRepositorySupport.ensureUuid(
      team.id,
      'tournament_team',
    );
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      team.tournamentId,
      'tournament',
    );
    final stored = team.copyWith(id: safeId, tournamentId: safeTournamentId);
    remoteTeams[safeId] = stored;
    return stored;
  }

  @override
  Future<void> replaceForTournament(
    String tournamentId,
    List<TournamentTeam> teams,
  ) async {
    replaceCalls++;
    final safeTournamentId = HybridRepositorySupport.ensureUuid(
      tournamentId,
      'tournament',
    );
    final keepIds = teams
        .map((t) => HybridRepositorySupport.ensureUuid(t.id, 'tournament_team'))
        .toSet();
    remoteTeams.removeWhere(
      (id, t) => t.tournamentId == safeTournamentId && !keepIds.contains(id),
    );
    for (final team in teams) {
      await upsert(team);
    }
  }

  @override
  Future<void> deleteById(String teamId) async {
    final safeId = HybridRepositorySupport.ensureUuid(
      teamId,
      'tournament_team',
    );
    remoteTeams.remove(safeId);
  }
}

void main() {
  group('HybridTeamsRepository', () {
    late _InMemoryLocalStorage storage;
    late _FakeConnectivityRepository connectivity;
    late HiveSyncOutboxRepository outbox;
    late SupabaseCloudSyncService syncService;
    late HybridRepositorySupport support;
    late LocalTeamsRepository local;
    late _FakeTeamsRemoteDataSource remote;
    late HybridTeamsRepository repo;

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
      local = LocalTeamsRepository(
        storage: storage,
        config: EnvironmentConfig.development(),
      );
      remote = _FakeTeamsRemoteDataSource();
      repo = HybridTeamsRepository(
        local: local,
        remote: remote,
        support: support,
      );
      syncService.registerHandler(
        SyncOutboxEntityType.team,
        repo.replayOutboxItem,
      );
    });

    test(
      'normalizes team id and tournamentId and syncs group/eligibility updates',
      () async {
        final team = TournamentTeam(
          id: 'team-alpha',
          tournamentId: 'liga-1',
          name: 'Atlético Alpha',
          shortCode: 'ALP',
          groupName: 'Grupo A',
          eligibilityStatus: TeamEligibilityStatus.pendingVerification,
        );

        final saved = await repo.saveTeam(team);
        final expectedTeamId = HybridRepositorySupport.ensureUuid(
          'team-alpha',
          'tournament_team',
        );
        final expectedTournamentId = HybridRepositorySupport.ensureUuid(
          'liga-1',
          'tournament',
        );

        expect(saved.id, expectedTeamId);
        expect(saved.tournamentId, expectedTournamentId);

        final updated = saved.copyWith(
          groupName: 'Grupo B',
          eligibilityStatus: TeamEligibilityStatus.eligible,
        );
        await repo.saveTeam(updated);

        final remoteLoaded = await repo.loadTeamsForTournament('liga-1');
        expect(remoteLoaded, hasLength(1));
        expect(remoteLoaded.first.groupName, 'Grupo B');
        expect(
          remoteLoaded.first.eligibilityStatus,
          TeamEligibilityStatus.eligible,
        );
      },
    );

    test(
      'replaceTeamsForTournament prunes withdrawn enrollments locally and remotely',
      () async {
        final teamA = TournamentTeam(
          id: 'team-a',
          tournamentId: 'liga-1',
          name: 'Equipo A',
          shortCode: 'EQA',
        );
        final teamB = TournamentTeam(
          id: 'team-b',
          tournamentId: 'liga-1',
          name: 'Equipo B',
          shortCode: 'EQB',
        );
        await repo.saveTeam(teamA);
        await repo.saveTeam(teamB);
        expect(remote.remoteTeams, hasLength(2));

        // Withdraw teamB by replacing tournament enrollments with only teamA
        await repo.replaceTeamsForTournament('liga-1', [teamA]);

        final afterRemote = await remote.fetchForTournament('liga-1');
        expect(afterRemote, hasLength(1));
        expect(afterRemote.first.name, 'Equipo A');

        final afterLocal = await local.loadTeamsForTournament(
          HybridRepositorySupport.ensureUuid('liga-1', 'tournament'),
        );
        expect(afterLocal, hasLength(1));
      },
    );

    test(
      'queues offline eligibility mutation and replays on reconnect',
      () async {
        connectivity.setStatus(NetworkConnectionStatus.disconnected);
        final team = TournamentTeam(
          id: 'team-offline',
          tournamentId: 'liga-1',
          name: 'Offline FC',
          shortCode: 'OFF',
          eligibilityStatus: TeamEligibilityStatus.eligible,
        );

        await repo.saveTeam(team);
        expect(remote.remoteTeams, isEmpty);
        expect(await outbox.loadItemsForUser('org-1'), hasLength(1));

        connectivity.setStatus(NetworkConnectionStatus.connected);
        final flushResult = await syncService.flushOutbox(userId: 'org-1');
        expect(flushResult.syncedCount, 1);
        expect(remote.remoteTeams, hasLength(1));
      },
    );
  });
}
