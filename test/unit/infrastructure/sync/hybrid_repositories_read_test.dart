import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/fan_favorite_team.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_alert_type.dart';
import 'package:vifutbol/domain/entities/match_lineup_convocation.dart';
import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/entities/player_internal_tracking.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/season_honor_roll.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_news_category.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_fan_favorites_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_lineups_tracking_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_match_alerts_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_match_reports_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_season_honor_roll_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_tournament_news_repository.dart';
import 'package:vifutbol/infrastructure/repositories/hybrid_tournaments_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_fan_favorites_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_lineups_tracking_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_alerts_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_reports_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_season_honor_roll_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_news_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
import 'package:vifutbol/infrastructure/sync/hive_sync_outbox_repository.dart';
import 'package:vifutbol/infrastructure/sync/hybrid_repository_support.dart';
import 'package:vifutbol/infrastructure/venues/hybrid_venues_repository.dart';
import 'package:vifutbol/infrastructure/venues/local_venues_repository.dart';

class _InMemoryLocalStorage implements LocalStorageRepository {
  final Map<String, String> store = {};

  @override
  bool get isUsingFallbackMemory => true;

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => store[key];

  @override
  Future<void> writeString(String key, String value) async {
    store[key] = value;
  }

  @override
  Future<void> clearNamespace() async => store.clear();
}

class _FakeConnectivity implements ConnectivityRepository {
  _FakeConnectivity([this._status = NetworkConnectionStatus.connected]);
  NetworkConnectionStatus _status;
  final _ctrl = StreamController<NetworkConnectionStatus>.broadcast();

  void setStatus(NetworkConnectionStatus status) => _status = status;

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async => _status;

  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged => _ctrl.stream;

  Future<void> dispose() => _ctrl.close();
}

class _MockTournamentsRemote extends Mock
    implements TournamentsRemoteDataSource {}

class _MockVenuesRemote extends Mock implements VenuesRemoteDataSource {}

class _MockTeamsRemote extends Mock implements TeamsRemoteDataSource {}

class _MockMatchesRemote extends Mock
    implements TournamentMatchesRemoteDataSource {}

class _MockLineupsRemote extends Mock
    implements LineupsTrackingRemoteDataSource {}

class _MockReportsRemote extends Mock implements MatchReportsRemoteDataSource {}

class _MockAlertsRemote extends Mock implements MatchAlertsRemoteDataSource {}

class _MockNewsRemote extends Mock implements TournamentNewsRemoteDataSource {}

class _MockHonorRollRemote extends Mock
    implements SeasonHonorRollRemoteDataSource {}

class _MockFavoritesRemote extends Mock
    implements FanFavoritesRemoteDataSource {}

void main() {
  final config = EnvironmentConfig.development(
    supabase: const SupabaseConfig.empty(),
  );
  final now = DateTime.utc(2026, 11, 11, 15, 0);

  group('Hybrid repositories read-through and offline cache fallback (US1)', () {
    test(
      'all 10 hybrid repositories fetch remote data online, warm cache, and serve cached data offline',
      () async {
        final storage = _InMemoryLocalStorage();
        final outbox = HiveSyncOutboxRepository(storage: storage);
        final connectivity = _FakeConnectivity(
          NetworkConnectionStatus.connected,
        );
        var isGuest = false;
        final support = HybridRepositorySupport(
          connectivity: connectivity,
          outbox: outbox,
          userContextReader: () => (userId: 'user-1', isGuest: isGuest),
        );

        final tRemote = _MockTournamentsRemote();
        final vRemote = _MockVenuesRemote();
        final teamRemote = _MockTeamsRemote();
        final mRemote = _MockMatchesRemote();
        final lRemote = _MockLineupsRemote();
        final rRemote = _MockReportsRemote();
        final aRemote = _MockAlertsRemote();
        final nRemote = _MockNewsRemote();
        final hRemote = _MockHonorRollRemote();
        final fRemote = _MockFavoritesRemote();

        final tRepo = HybridTournamentsRepository(
          local: LocalTournamentsRepository(storage: storage, config: config),
          remote: tRemote,
          support: support,
        );
        final vRepo = HybridVenuesRepository(
          local: LocalVenuesRepository(storage: storage, config: config),
          remote: vRemote,
          support: support,
        );
        final teamRepo = HybridTeamsRepository(
          local: LocalTeamsRepository(storage: storage, config: config),
          remote: teamRemote,
          support: support,
        );
        final mRepo = HybridTournamentMatchesRepository(
          local: LocalTournamentMatchesRepository(
            storage: storage,
            config: config,
          ),
          remote: mRemote,
          support: support,
        );
        final lRepo = HybridLineupsTrackingRepository(
          local: LocalLineupsTrackingRepository(
            storage: storage,
            config: config,
          ),
          remote: lRemote,
          support: support,
        );
        final rRepo = HybridMatchReportsRepository(
          local: LocalMatchReportsRepository(storage: storage, config: config),
          remote: rRemote,
          support: support,
        );
        final aRepo = HybridMatchAlertsRepository(
          local: LocalMatchAlertsRepository(storage: storage),
          remote: aRemote,
          support: support,
        );
        final nRepo = HybridTournamentNewsRepository(
          local: LocalTournamentNewsRepository(
            storage: storage,
            config: config,
          ),
          remote: nRemote,
          support: support,
        );
        final hRepo = HybridSeasonHonorRollRepository(
          local: LocalSeasonHonorRollRepository(
            storage: storage,
            config: config,
          ),
          remote: hRemote,
          support: support,
        );
        final fRepo = HybridFanFavoritesRepository(
          local: LocalFanFavoritesRepository(storage: storage),
          remote: fRemote,
          support: support,
        );

        final sampleTournament = ChampionshipTournament(
          id: 't1',
          name: 'Copa Cloud',
          category: 'Libre',
          startDate: now,
          endDate: now.add(const Duration(days: 30)),
          format: TournamentFormat.league,
          updatedAt: now,
        );
        final sampleVenue = SportsVenue(
          id: 'v1',
          name: 'Estadio Central',
          address: 'Calle 100 # 10-20',
          urbanReference: 'Norte',
          coordinate: GeoCoordinate.defaultCityCenter,
          pitches: const [
            VenuePitch(
              id: 'p1',
              name: 'Cancha 1',
              surfaceType: PitchSurfaceType.syntheticGrass,
              format: PitchFormat.football7,
              capacity: 100,
              hasLighting: true,
              status: VenueOperationalStatus.active,
            ),
          ],
          status: VenueOperationalStatus.active,
          updatedAt: now,
        );
        final samplePlayer = const RegisteredPlayer(
          id: 'pl1',
          fullName: 'Carlos Ruiz',
          documentId: 'CC123456',
          shirtNumber: 10,
          position: PlayerPosition.forward,
        );
        final sampleTeam = TournamentTeam(
          id: 'team1',
          tournamentId: 't1',
          name: 'Atlético Cloud',
          shortCode: 'ATC',
          players: [samplePlayer],
          updatedAt: now,
        );
        final sampleMatch = ChampionshipMatch(
          id: 'm1',
          tournamentId: 't1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team1',
          awayTeamId: 'team2',
          updatedAt: now,
        );
        final sampleTracking = const PlayerInternalTracking(
          playerId: 'pl1',
          teamId: 'team1',
          tournamentId: 't1',
          goals: 3,
        );
        final sampleConv = MatchLineupConvocation(
          id: 'c1',
          tournamentId: 't1',
          teamId: 'team1',
        );
        final sampleReport = DigitalMatchReport(
          matchId: 'm1',
          tournamentId: 't1',
          homeTeamId: 'team1',
          awayTeamId: 'team2',
          homeScore: 2,
          awayScore: 1,
        );
        final sampleAlert = MatchLiveAlert(
          id: 'a1',
          matchId: 'm1',
          tournamentId: 't1',
          type: MatchAlertType.goalScored,
          title: 'Gol!',
          message: 'Gol en el minuto 15',
          timestamp: now,
        );
        final sampleNews = TournamentNewsItem(
          id: 'n1',
          tournamentId: 't1',
          title: 'Inicio oficial',
          body: 'Arranca la temporada en sede norte.',
          category: TournamentNewsCategory.general,
          publishedAt: now,
          authorUserId: 'user-1',
          authorName: 'Org',
        );
        final sampleHonor = SeasonHonorRoll(
          tournamentId: 't1',
          tournamentName: 'Copa Cloud',
          closedAt: now,
          championTeamId: 'team1',
          championTeamName: 'Atlético Cloud',
          championShortCode: 'ATC',
          runnerUpTeamId: 'team2',
          runnerUpTeamName: 'Deportivo Sol',
          runnerUpShortCode: 'SOL',
          bestDefenseTeamId: 'team1',
          bestDefenseTeamName: 'Atlético Cloud',
          bestDefenseShortCode: 'ATC',
          bestDefenseGoalsAgainst: 4,
        );
        final sampleFav = FanFavoriteTeam(
          userId: 'user-1',
          tournamentId: 't1',
          teamId: 'team1',
          teamName: 'Atlético Cloud',
          createdAt: now,
        );

        when(
          () => tRemote.fetchAll(),
        ).thenAnswer((_) async => [sampleTournament]);
        when(() => vRemote.fetchAll()).thenAnswer((_) async => [sampleVenue]);
        when(
          () => teamRemote.fetchForTournament('t1'),
        ).thenAnswer((_) async => [sampleTeam]);
        when(
          () => mRemote.fetchForTournament('t1'),
        ).thenAnswer((_) async => [sampleMatch]);
        when(() => mRemote.fetchOfficialReferees()).thenAnswer(
          (_) async => [
            const MatchReferee(
              id: 'ref1',
              fullName: 'Juan Pérez',
              certificationLevel: 'FIFA',
            ),
          ],
        );
        when(
          () => lRemote.fetchTrackingForTeam('t1', 'team1', [samplePlayer]),
        ).thenAnswer((_) async => [sampleTracking]);
        when(
          () => lRemote.fetchConvocationForTeam('t1', 'team1'),
        ).thenAnswer((_) async => sampleConv);
        when(
          () => rRemote.fetchReportsForTournament('t1'),
        ).thenAnswer((_) async => [sampleReport]);
        when(
          () => aRemote.fetchAlerts(tournamentId: 't1'),
        ).thenAnswer((_) async => [sampleAlert]);
        when(
          () => nRemote.fetchForTournament('t1'),
        ).thenAnswer((_) async => [sampleNews]);
        when(
          () => hRemote.fetchForTournament('t1'),
        ).thenAnswer((_) async => sampleHonor);
        when(
          () => fRemote.fetchFavorites('user-1', 't1'),
        ).thenAnswer((_) async => [sampleFav]);

        // 1. Online reads hydrate cache from remote
        expect((await tRepo.loadTournaments()).first.name, 'Copa Cloud');
        expect((await vRepo.loadVenues()).first.name, 'Estadio Central');
        expect(
          (await teamRepo.loadTeamsForTournament('t1')).first.name,
          'Atlético Cloud',
        );
        expect((await mRepo.loadMatchesForTournament('t1')).length, 1);
        expect((await mRepo.loadOfficialReferees()).length, 1);
        expect(
          (await lRepo.loadTrackingForTeam('t1', 'team1', [
            samplePlayer,
          ])).first.goals,
          3,
        );
        expect((await lRepo.loadConvocationForTeam('t1', 'team1')).id, 'c1');
        expect((await rRepo.loadReportsForTournament('t1')).first.homeScore, 2);
        expect(
          (await aRepo.loadAlerts('user-1', tournamentId: 't1')).length,
          1,
        );
        expect((await nRepo.loadNewsForTournament('t1')).length, 1);
        expect(
          (await hRepo.loadHonorRollForTournament('t1'))?.championTeamName,
          'Atlético Cloud',
        );
        expect((await fRepo.loadFavoriteTeams('user-1', 't1')).length, 1);

        // 2. Switch offline -> fallback serves exact cached data without hitting remote
        connectivity.setStatus(NetworkConnectionStatus.disconnected);
        expect((await tRepo.loadTournaments()).first.name, 'Copa Cloud');
        expect((await vRepo.loadVenues()).first.name, 'Estadio Central');
        expect(
          (await teamRepo.loadTeamsForTournament('t1')).first.name,
          'Atlético Cloud',
        );
        expect((await mRepo.loadMatchesForTournament('t1')).length, 1);
        expect(
          (await lRepo.loadTrackingForTeam('t1', 'team1', [
            samplePlayer,
          ])).first.goals,
          3,
        );
        expect((await rRepo.loadReportsForTournament('t1')).first.homeScore, 2);
        expect(
          (await aRepo.loadAlerts('user-1', tournamentId: 't1')).length,
          1,
        );
        expect((await nRepo.loadNewsForTournament('t1')).length, 1);
        expect(
          (await hRepo.loadHonorRollForTournament('t1'))?.championShortCode,
          'ATC',
        );
        expect((await fRepo.loadFavoriteTeams('user-1', 't1')).length, 1);

        // 3. Reconnect with transient network exception -> transparent cache fallback
        connectivity.setStatus(NetworkConnectionStatus.connected);
        when(
          () => tRemote.fetchAll(),
        ).thenThrow(const SocketException('Temporary timeout'));
        expect((await tRepo.loadTournaments()).first.name, 'Copa Cloud');

        // 4. Guest fan bypasses remote favorite fetches
        isGuest = true;
        expect(await fRepo.loadFavoriteTeams('guest', 't1'), isEmpty);
        verifyNever(() => fRemote.fetchFavorites('guest', 't1'));

        await connectivity.dispose();
      },
    );

    test(
      'returns empty lists cleanly on unseeded offline first-run without fake seeds',
      () async {
        final storage = _InMemoryLocalStorage();
        final outbox = HiveSyncOutboxRepository(storage: storage);
        final connectivity = _FakeConnectivity(
          NetworkConnectionStatus.disconnected,
        );
        final support = HybridRepositorySupport(
          connectivity: connectivity,
          outbox: outbox,
          userContextReader: () => (userId: 'user-1', isGuest: false),
        );

        final tRepo = HybridTournamentsRepository(
          local: LocalTournamentsRepository(storage: storage, config: config),
          remote: _MockTournamentsRemote(),
          support: support,
        );
        expect(await tRepo.loadTournaments(), isEmpty);

        // Provider conditional fallback stays on LocalTournamentsRepository when Supabase unconfigured.
        final container = ProviderContainer(
          overrides: [
            environmentConfigProvider.overrideWithValue(config),
            localStorageRepositoryProvider.overrideWithValue(storage),
            connectivityRepositoryProvider.overrideWithValue(connectivity),
          ],
        );
        expect(
          container.read(tournamentsRepositoryProvider),
          isA<LocalTournamentsRepository>(),
        );
        container.dispose();
        await connectivity.dispose();
      },
    );
  });
}
