import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/player_directory_item.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
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

  final playerA = RegisteredPlayer(
    id: 'a0000000-0000-4000-8000-000000000001',
    fullName: 'Andrés Iniesta',
    documentId: '1001',
    shirtNumber: 8,
    position: PlayerPosition.midfielder,
    isEligible: true,
  );

  final playerZ = RegisteredPlayer(
    id: 'a0000000-0000-4000-8000-000000000002',
    fullName: 'Zinedine Zidane',
    documentId: '1002',
    shirtNumber: 10,
    position: PlayerPosition.midfielder,
    isEligible: true,
  );

  final team1 = TournamentTeam(
    id: 't0000000-0000-4000-8000-000000000001',
    tournamentId: 'tour-1',
    name: 'Real Madrid',
    shortCode: 'RMA',
    crestShape: TeamCrestShape.shield,
    primaryColorHex: 0xFFFFFFFF,
    secondaryColorHex: 0xFF000000,
    eligibilityStatus: TeamEligibilityStatus.eligible,
    players: [playerZ, playerA], // Z before A
    updatedAt: DateTime(2026, 11, 1),
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

  group('HybridTeamsRepository.loadAllPlayers()', () {
    test(
      'fetches from remote when connected and updates local cache',
      () async {
        when(
          () => connectivity.checkConnectivity(),
        ).thenAnswer((_) async => NetworkConnectionStatus.connected);
        when(() => remote.fetchAll()).thenAnswer((_) async => [team1]);
        when(() => remote.fetchAllPlayers()).thenAnswer(
          (_) async => [
            PlayerDirectoryItem(
              player: playerA,
              teamId: team1.id,
              teamName: team1.name,
              teamShortCode: team1.shortCode,
              tournamentId: team1.tournamentId,
              tournamentName: 'Liga Premier',
            ),
            PlayerDirectoryItem(
              player: playerZ,
              teamId: team1.id,
              teamName: team1.name,
              teamShortCode: team1.shortCode,
              tournamentId: team1.tournamentId,
              tournamentName: 'Liga Premier',
            ),
          ],
        );

        final result = await hybrid.loadAllPlayers();

        expect(result.length, equals(2));
        expect(result[0].player.fullName, equals('Andrés Iniesta'));
        expect(result[1].player.fullName, equals('Zinedine Zidane'));
        expect(result[0].tournamentName, equals('Liga Premier'));

        verify(() => remote.fetchAll()).called(1);
        verify(() => remote.fetchAllPlayers()).called(1);
        verify(() => storage.writeString(any(), any())).called(1);
      },
    );

    test(
      'falls back to LocalTeamsRepository when disconnected without calling remote',
      () async {
        when(
          () => connectivity.checkConnectivity(),
        ).thenAnswer((_) async => NetworkConnectionStatus.disconnected);

        final result = await hybrid.loadAllPlayers();

        expect(result, isEmpty);
        verifyNever(() => remote.fetchAllPlayers());
        verifyNever(() => remote.fetchAll());
      },
    );

    test(
      'falls back to LocalTeamsRepository when remote throws exception',
      () async {
        when(
          () => connectivity.checkConnectivity(),
        ).thenAnswer((_) async => NetworkConnectionStatus.connected);
        when(() => remote.fetchAll()).thenThrow(Exception('Supabase offline'));

        final result = await hybrid.loadAllPlayers();

        expect(result, isEmpty);
      },
    );

    test(
      'LocalTeamsRepository.loadAllPlayers() sorts players alphabetically A-Z',
      () async {
        final jsonRaw = '[${team1.toJsonString()}]';
        when(
          () => storage.readString(LocalTeamsRepository.catalogStorageKey),
        ).thenAnswer((_) async => jsonRaw);

        final localPlayers = await local.loadAllPlayers();

        expect(localPlayers.length, equals(2));
        // Andrés (A) must come before Zinedine (Z) despite insertion order in team.players
        expect(localPlayers[0].player.fullName, equals('Andrés Iniesta'));
        expect(localPlayers[1].player.fullName, equals('Zinedine Zidane'));
      },
    );
  });
}

extension on TournamentTeam {
  String toJsonString() {
    return '{"id":"$id","tournamentId":"$tournamentId","name":"$name","shortCode":"$shortCode","crestShape":"shield","primaryColorHex":$primaryColorHex,"secondaryColorHex":$secondaryColorHex,"eligibilityStatus":"approved","players":[{"id":"${players[0].id}","fullName":"${players[0].fullName}","documentId":"${players[0].documentId}","shirtNumber":${players[0].shirtNumber},"position":"midfielder","isEligible":true},{"id":"${players[1].id}","fullName":"${players[1].fullName}","documentId":"${players[1].documentId}","shirtNumber":${players[1].shirtNumber},"position":"midfielder","isEligible":true}],"updatedAt":"2026-11-01T00:00:00.000"}';
  }
}
