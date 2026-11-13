import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_directory_item.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/sync_outbox_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';

class _MockLocalStorageRepository extends Mock
    implements LocalStorageRepository {}

class _MockConnectivityRepository extends Mock
    implements ConnectivityRepository {}

class _MockSyncOutboxRepository extends Mock implements SyncOutboxRepository {}

class _MockTeamsRemoteDataSource extends Mock
    implements TeamsRemoteDataSource {}

void main() {
  late _MockLocalStorageRepository storage;
  late _MockConnectivityRepository connectivity;
  late _MockSyncOutboxRepository outbox;
  late _MockTeamsRemoteDataSource remote;
  late LocalTeamsRepository local;
  late HybridRepositorySupport support;
  late HybridTeamsRepository hybrid;

  final clubAlpha = TeamDirectoryItem(
    id: 'c0000000-0000-4000-8000-000000000001',
    name: 'Atlético Nacional',
    shortCode: 'ATN',
    crestShape: TeamCrestShape.shield,
    primaryColorHex: 0xFF008000,
    secondaryColorHex: 0xFFFFFFFF,
    categoryLabel: null,
    tournamentCount: 0,
    playerCount: 0,
    eligibilityStatus: TeamEligibilityStatus.pendingVerification,
    coachId: 'coach-1',
    updatedAt: DateTime(2026, 11, 13),
  );

  final clubBeta = TeamDirectoryItem(
    id: 'c0000000-0000-4000-8000-000000000002',
    name: 'Barcelona SC',
    shortCode: 'BSC',
    crestShape: TeamCrestShape.circle,
    primaryColorHex: 0xFFFFD700,
    secondaryColorHex: 0xFF000000,
    categoryLabel: 'Libre',
    tournamentCount: 1,
    playerCount: 18,
    eligibilityStatus: TeamEligibilityStatus.eligible,
    coachId: 'coach-2',
    updatedAt: DateTime(2026, 11, 13),
  );

  final clubZeta = TeamDirectoryItem(
    id: 'c0000000-0000-4000-8000-000000000003',
    name: 'Zulia FC',
    shortCode: 'ZUL',
    crestShape: TeamCrestShape.diamond,
    primaryColorHex: 0xFF0000FF,
    secondaryColorHex: 0xFFFFFFFF,
    categoryLabel: null,
    tournamentCount: 2,
    playerCount: 34,
    eligibilityStatus: TeamEligibilityStatus.eligible,
    coachId: 'coach-3',
    updatedAt: DateTime(2026, 11, 13),
  );

  setUp(() {
    storage = _MockLocalStorageRepository();
    connectivity = _MockConnectivityRepository();
    outbox = _MockSyncOutboxRepository();
    remote = _MockTeamsRemoteDataSource();

    local = LocalTeamsRepository(
      storage: storage,
      config: EnvironmentConfig.development(),
    );

    support = HybridRepositorySupport(
      connectivity: connectivity,
      outbox: outbox,
      userContextReader: () => (userId: 'user-1', isGuest: false),
    );

    hybrid = HybridTeamsRepository(
      local: local,
      remote: remote,
      support: support,
    );

    when(() => storage.readString(any())).thenAnswer((_) async => null);
    when(() => storage.writeString(any(), any())).thenAnswer((_) async => true);
  });

  group('HybridTeamsRepository.loadAllTeams()', () {
    test(
      'fetches unique clubs from remote when connected and hydrates Hive cache',
      () async {
        when(
          () => connectivity.checkConnectivity(),
        ).thenAnswer((_) async => NetworkConnectionStatus.connected);
        when(
          () => remote.fetchAllTeams(),
        ).thenAnswer((_) async => [clubAlpha, clubBeta, clubZeta]);

        final result = await hybrid.loadAllTeams();

        expect(result.length, 3);
        expect(result.first.name, 'Atlético Nacional');
        expect(result.first.tournamentCount, 0);
        expect(result.last.tournamentCount, 2);
        expect(result.last.playerCount, 34);

        verify(() => remote.fetchAllTeams()).called(1);
        verify(
          () => storage.writeString(
            LocalTeamsRepository.directoryStorageKey,
            any(),
          ),
        ).called(1);
      },
    );

    test('falls back to cached directory items when offline', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => NetworkConnectionStatus.disconnected);
      when(
        () => storage.readString(LocalTeamsRepository.directoryStorageKey),
      ).thenAnswer(
        (_) async => jsonEncode([clubZeta.toJson(), clubAlpha.toJson()]),
      );

      final result = await hybrid.loadAllTeams();

      expect(result.length, 2);
      expect(result.first.name, 'Atlético Nacional');
      expect(result.last.name, 'Zulia FC');
      verifyNever(() => remote.fetchAllTeams());
    });

    test(
      'falls back to local cache when remote fetch throws an exception',
      () async {
        when(
          () => connectivity.checkConnectivity(),
        ).thenAnswer((_) async => NetworkConnectionStatus.connected);
        when(
          () => remote.fetchAllTeams(),
        ).thenThrow(Exception('PostgREST timeout'));
        when(
          () => storage.readString(LocalTeamsRepository.directoryStorageKey),
        ).thenAnswer((_) async => jsonEncode([clubBeta.toJson()]));

        final result = await hybrid.loadAllTeams();

        expect(result.length, 1);
        expect(result.first.name, 'Barcelona SC');
      },
    );

    test(
      'LocalTeamsRepository.loadAllTeams() deduplicates legacy catalog and sorts A-Z',
      () async {
        final legacyT1 = TournamentTeam(
          id: 'e1',
          tournamentId: 't1',
          name: 'Zebra FC',
          shortCode: 'ZEB',
          players: [
            RegisteredPlayer(
              id: 'p1',
              fullName: 'Jugador 1',
              documentId: '1',
              shirtNumber: 9,
              position: PlayerPosition.forward,
            ),
          ],
          eligibilityStatus: TeamEligibilityStatus.eligible,
          updatedAt: DateTime(2026, 11, 1),
        );
        final legacyT2 = TournamentTeam(
          id: 'e2',
          tournamentId: 't2',
          name: 'Zebra FC',
          shortCode: 'ZEB',
          players: [
            RegisteredPlayer(
              id: 'p2',
              fullName: 'Jugador 2',
              documentId: '2',
              shirtNumber: 10,
              position: PlayerPosition.midfielder,
            ),
          ],
          eligibilityStatus: TeamEligibilityStatus.pendingVerification,
          updatedAt: DateTime(2026, 11, 2),
        );
        final legacyA = TournamentTeam(
          id: 'e3',
          tournamentId: '',
          name: 'Alianza Lima',
          shortCode: 'ALI',
          updatedAt: DateTime(2026, 11, 3),
        );

        when(
          () => storage.readString(LocalTeamsRepository.catalogStorageKey),
        ).thenAnswer(
          (_) async => jsonEncode([
            legacyT1.toJson(),
            legacyT2.toJson(),
            legacyA.toJson(),
          ]),
        );

        final result = await local.loadAllTeams();

        expect(result.length, 2);
        expect(result.first.name, 'Alianza Lima');
        expect(result.first.tournamentCount, 0);
        expect(result.last.name, 'Zebra FC');
        expect(result.last.tournamentCount, 2);
        expect(result.last.playerCount, 2);
        expect(result.last.eligibilityStatus, TeamEligibilityStatus.eligible);
      },
    );
  });
}
