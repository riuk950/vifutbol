import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/fan_favorite_team.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_alert_type.dart';
import 'package:vifutbol/domain/entities/match_event.dart';
import 'package:vifutbol/domain/entities/match_lineup_convocation.dart';
import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';
import 'package:vifutbol/domain/entities/player_internal_tracking.dart';
import 'package:vifutbol/domain/entities/season_honor_roll.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/sync_status.dart';
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
import 'package:vifutbol/infrastructure/sync/supabase_cloud_sync_service.dart';
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
  _FakeConnectivity([this._status = NetworkConnectionStatus.disconnected]);
  NetworkConnectionStatus _status;
  final _ctrl = StreamController<NetworkConnectionStatus>.broadcast();

  void setStatus(NetworkConnectionStatus status) {
    _status = status;
    _ctrl.add(status);
  }

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
  setUpAll(() {
    registerFallbackValue(
      ChampionshipTournament(
        id: 'fb-t',
        name: 'Fallback',
        category: 'Libre',
        startDate: DateTime.utc(2026),
        endDate: DateTime.utc(2026),
        format: TournamentFormat.league,
        updatedAt: DateTime.utc(2026),
      ),
    );
    registerFallbackValue(
      SportsVenue(
        id: 'fb-v',
        name: 'Sede Fallback',
        address: 'Calle 123',
        urbanReference: '',
        coordinate: GeoCoordinate.defaultCityCenter,
        pitches: const [
          VenuePitch(
            id: 'p1',
            name: 'P1',
            surfaceType: PitchSurfaceType.syntheticGrass,
            format: PitchFormat.football7,
            capacity: 0,
            hasLighting: false,
            status: VenueOperationalStatus.active,
          ),
        ],
        status: VenueOperationalStatus.active,
        updatedAt: DateTime.utc(2026),
      ),
    );
    registerFallbackValue(
      TournamentTeam(id: 'fb-team', name: 'Fallback FC', shortCode: 'FBK'),
    );
    registerFallbackValue(
      ChampionshipMatch(
        id: 'fb-m',
        tournamentId: 'fb-t',
        roundNumber: 1,
        roundName: 'J1',
        homeTeamId: 'a',
        awayTeamId: 'b',
      ),
    );
    registerFallbackValue(
      const PlayerInternalTracking(
        playerId: 'fb-p',
        teamId: 'fb-team',
        tournamentId: 'fb-t',
      ),
    );
    registerFallbackValue(
      MatchLineupConvocation(
        id: 'fb-c',
        tournamentId: 'fb-t',
        teamId: 'fb-team',
      ),
    );
    registerFallbackValue(
      DigitalMatchReport(
        matchId: 'fb-m',
        tournamentId: 'fb-t',
        homeTeamId: 'a',
        awayTeamId: 'b',
      ),
    );
    registerFallbackValue(
      MatchLiveAlert(
        id: 'fb-a',
        matchId: 'fb-m',
        tournamentId: 'fb-t',
        type: MatchAlertType.goalScored,
        title: 'Goal',
        message: 'Goal scored',
        timestamp: DateTime.utc(2026),
      ),
    );
    registerFallbackValue(
      TournamentNewsItem(
        id: 'fb-n',
        tournamentId: 'fb-t',
        title: 'Noticia',
        body: 'Contenido oficial',
        category: TournamentNewsCategory.general,
        publishedAt: DateTime.utc(2026),
        authorUserId: 'u1',
        authorName: 'Org',
      ),
    );
    registerFallbackValue(
      SeasonHonorRoll(
        tournamentId: 'fb-t',
        tournamentName: 'T',
        closedAt: DateTime.utc(2026),
        championTeamId: 'a',
        championTeamName: 'Team A',
        championShortCode: 'TMA',
        runnerUpTeamId: 'b',
        runnerUpTeamName: 'Team B',
        runnerUpShortCode: 'TMB',
        bestDefenseTeamId: 'a',
        bestDefenseTeamName: 'Team A',
        bestDefenseShortCode: 'TMA',
        bestDefenseGoalsAgainst: 1,
      ),
    );
    registerFallbackValue(
      FanFavoriteTeam(
        userId: 'u1',
        tournamentId: 'fb-t',
        teamId: 'fb-team',
        teamName: 'Fallback FC',
        createdAt: DateTime.utc(2026),
      ),
    );
  });

  final config = EnvironmentConfig.development(
    supabase: const SupabaseConfig.empty(),
  );

  group(
    'Offline-first hybrid writes, Q1 remote-first, FIFO replay, and guest bypass (US2)',
    () {
      test(
        'online remote-first write updates local cache immediately without enqueueing outbox items (Q1)',
        () async {
          final storage = _InMemoryLocalStorage();
          final outbox = HiveSyncOutboxRepository(storage: storage);
          final connectivity = _FakeConnectivity(
            NetworkConnectionStatus.connected,
          );
          final now = DateTime.utc(2026, 11, 11, 16, 0);
          final support = HybridRepositorySupport(
            connectivity: connectivity,
            outbox: outbox,
            userContextReader: () => (userId: 'org-1', isGuest: false),
            clock: Clock.fixed(now),
          );

          final tRemote = _MockTournamentsRemote();
          final localT = LocalTournamentsRepository(
            storage: storage,
            config: config,
          );
          final tRepo = HybridTournamentsRepository(
            local: localT,
            remote: tRemote,
            support: support,
          );

          final tournament = ChampionshipTournament(
            id: 't-online',
            name: 'Copa Directa',
            category: 'Libre',
            startDate: now,
            endDate: now.add(const Duration(days: 10)),
            format: TournamentFormat.league,
            updatedAt: now,
          );

          when(() => tRemote.upsert(any())).thenAnswer((_) async => tournament);
          await tRepo.saveTournament(tournament);

          verify(() => tRemote.upsert(tournament)).called(1);
          expect((await localT.loadTournaments()).first.id, 't-online');
          expect(await outbox.loadItemsForUser('org-1'), isEmpty);

          await connectivity.dispose();
        },
      );

      test(
        'offline writes across all 10 repositories enqueue FIFO items and replay cleanly in order upon reconnect',
        () async {
          final storage = _InMemoryLocalStorage();
          final connectivity = _FakeConnectivity(
            NetworkConnectionStatus.disconnected,
          );
          var currentNow = DateTime.utc(2026, 11, 11, 17, 0);
          var isGuest = false;
          final outbox = HiveSyncOutboxRepository(storage: storage);
          final support = HybridRepositorySupport(
            connectivity: connectivity,
            outbox: outbox,
            userContextReader: () => (userId: 'org-1', isGuest: isGuest),
            clock: Clock(() {
              currentNow = currentNow.add(const Duration(seconds: 1));
              return currentNow;
            }),
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
            local: LocalMatchReportsRepository(
              storage: storage,
              config: config,
            ),
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

          // Execute offline mutations across all 10 modules
          final tournament = ChampionshipTournament(
            id: 't1',
            name: 'Copa Offline',
            category: 'Libre',
            startDate: currentNow,
            endDate: currentNow.add(const Duration(days: 5)),
            format: TournamentFormat.league,
            updatedAt: currentNow,
          );
          await tRepo.saveTournament(tournament);
          await vRepo.saveVenue(
            SportsVenue(
              id: 'v1',
              name: 'Sede Norte',
              address: 'Av 19 # 100',
              urbanReference: '',
              coordinate: GeoCoordinate.defaultCityCenter,
              pitches: const [
                VenuePitch(
                  id: 'p1',
                  name: 'Cancha A',
                  surfaceType: PitchSurfaceType.syntheticGrass,
                  format: PitchFormat.football7,
                  capacity: 0,
                  hasLighting: false,
                  status: VenueOperationalStatus.active,
                ),
              ],
              status: VenueOperationalStatus.active,
              updatedAt: currentNow,
            ),
          );
          await teamRepo.saveTeam(
            TournamentTeam(
              id: 'team1',
              tournamentId: 't1',
              name: 'Tigres FC',
              shortCode: 'TIG',
            ),
          );
          await mRepo.saveMatch(
            ChampionshipMatch(
              id: 'm1',
              tournamentId: 't1',
              roundNumber: 1,
              roundName: 'Fecha 1',
              homeTeamId: 'team1',
              awayTeamId: 'team2',
            ),
          );
          await lRepo.saveConvocation(
            MatchLineupConvocation(
              id: 'c1',
              tournamentId: 't1',
              teamId: 'team1',
            ),
          );
          await rRepo.saveReport(
            DigitalMatchReport(
              matchId: 'm1',
              tournamentId: 't1',
              homeTeamId: 'team1',
              awayTeamId: 'team2',
              events: [
                MatchEvent(
                  id: 'ev1',
                  matchId: 'm1',
                  type: MatchEventType.goal,
                  minute: 12,
                  teamId: 'team1',
                  isSynced: false,
                ),
              ],
            ),
          );
          await aRepo.saveAlert(
            MatchLiveAlert(
              id: 'a1',
              matchId: 'm1',
              tournamentId: 't1',
              type: MatchAlertType.goalScored,
              title: 'Gol',
              message: 'Gol Tigres',
              timestamp: currentNow,
            ),
          );
          await nRepo.saveNewsItem(
            TournamentNewsItem(
              id: 'n1',
              tournamentId: 't1',
              title: 'Boletín 1',
              body: 'Comunicado oficial de programación',
              category: TournamentNewsCategory.general,
              publishedAt: currentNow,
              authorUserId: 'org-1',
              authorName: 'Org',
            ),
          );
          await hRepo.saveHonorRoll(
            SeasonHonorRoll(
              tournamentId: 't1',
              tournamentName: 'Copa Offline',
              closedAt: currentNow,
              championTeamId: 'team1',
              championTeamName: 'Tigres FC',
              championShortCode: 'TIG',
              runnerUpTeamId: 'team2',
              runnerUpTeamName: 'Leones',
              runnerUpShortCode: 'LEO',
              bestDefenseTeamId: 'team1',
              bestDefenseTeamName: 'Tigres FC',
              bestDefenseShortCode: 'TIG',
              bestDefenseGoalsAgainst: 0,
            ),
          );
          await fRepo.saveFavoriteTeam(
            FanFavoriteTeam(
              userId: 'org-1',
              tournamentId: 't1',
              teamId: 'team1',
              teamName: 'Tigres FC',
              createdAt: currentNow,
            ),
          );

          // Guest mutation stays purely local with 0 cloud enqueue
          isGuest = true;
          await fRepo.saveFavoriteTeam(
            FanFavoriteTeam(
              userId: 'guest-1',
              tournamentId: 't1',
              teamId: 'team2',
              teamName: 'Leones',
              createdAt: currentNow,
            ),
          );
          isGuest = false;

          // Cold restart simulation reading from same storage
          final restartedOutbox = HiveSyncOutboxRepository(storage: storage);
          final queuedItems = await restartedOutbox.loadItemsForUser('org-1');
          expect(queuedItems.length, 10);
          expect(await restartedOutbox.loadItemsForUser('guest-1'), isEmpty);

          // Wire replay stubs and record execution order
          final order = <SyncOutboxEntityType>[];
          when(() => tRemote.upsert(any())).thenAnswer((i) async {
            order.add(SyncOutboxEntityType.tournament);
            return i.positionalArguments.first as ChampionshipTournament;
          });
          when(() => vRemote.upsert(any())).thenAnswer((_) async {
            order.add(SyncOutboxEntityType.venue);
          });
          when(() => teamRemote.upsert(any())).thenAnswer((i) async {
            order.add(SyncOutboxEntityType.team);
            return i.positionalArguments.first as TournamentTeam;
          });
          when(() => mRemote.upsertMatch(any())).thenAnswer((i) async {
            order.add(SyncOutboxEntityType.match);
            return i.positionalArguments.first as ChampionshipMatch;
          });
          when(() => lRemote.upsertConvocation(any())).thenAnswer((i) async {
            order.add(SyncOutboxEntityType.lineupTracking);
            return i.positionalArguments.first as MatchLineupConvocation;
          });
          when(() => rRemote.upsertReport(any())).thenAnswer((i) async {
            order.add(SyncOutboxEntityType.matchReport);
            return (i.positionalArguments.first as DigitalMatchReport);
          });
          when(() => aRemote.upsertAlert(any())).thenAnswer((_) async {
            order.add(SyncOutboxEntityType.matchAlert);
          });
          when(() => nRemote.upsertNewsItem(any())).thenAnswer((i) async {
            order.add(SyncOutboxEntityType.tournamentNews);
            return i.positionalArguments.first as TournamentNewsItem;
          });
          when(() => hRemote.upsertHonorRoll(any())).thenAnswer((i) async {
            order.add(SyncOutboxEntityType.seasonHonorRoll);
            return i.positionalArguments.first as SeasonHonorRoll;
          });
          when(() => fRemote.upsertFavorite(any())).thenAnswer((_) async {
            order.add(SyncOutboxEntityType.fanFavorite);
          });

          final syncService = SupabaseCloudSyncService(
            outboxRepository: restartedOutbox,
            connectivityRepository: connectivity,
          );
          syncService.registerHandler(
            SyncOutboxEntityType.tournament,
            tRepo.replayOutboxItem,
          );
          syncService.registerHandler(
            SyncOutboxEntityType.venue,
            vRepo.replayOutboxItem,
          );
          syncService.registerHandler(
            SyncOutboxEntityType.team,
            teamRepo.replayOutboxItem,
          );
          syncService.registerHandler(
            SyncOutboxEntityType.match,
            mRepo.replayOutboxItem,
          );
          syncService.registerHandler(
            SyncOutboxEntityType.lineupTracking,
            lRepo.replayOutboxItem,
          );
          syncService.registerHandler(
            SyncOutboxEntityType.matchReport,
            rRepo.replayOutboxItem,
          );
          syncService.registerHandler(
            SyncOutboxEntityType.matchAlert,
            aRepo.replayOutboxItem,
          );
          syncService.registerHandler(
            SyncOutboxEntityType.tournamentNews,
            nRepo.replayOutboxItem,
          );
          syncService.registerHandler(
            SyncOutboxEntityType.seasonHonorRoll,
            hRepo.replayOutboxItem,
          );
          syncService.registerHandler(
            SyncOutboxEntityType.fanFavorite,
            fRepo.replayOutboxItem,
          );

          syncService.setActiveUser('org-1');
          connectivity.setStatus(NetworkConnectionStatus.connected);
          await Future<void>.delayed(const Duration(milliseconds: 80));

          expect(order, [
            SyncOutboxEntityType.tournament,
            SyncOutboxEntityType.venue,
            SyncOutboxEntityType.team,
            SyncOutboxEntityType.match,
            SyncOutboxEntityType.lineupTracking,
            SyncOutboxEntityType.matchReport,
            SyncOutboxEntityType.matchAlert,
            SyncOutboxEntityType.tournamentNews,
            SyncOutboxEntityType.seasonHonorRoll,
            SyncOutboxEntityType.fanFavorite,
          ]);
          expect(await restartedOutbox.loadItemsForUser('org-1'), isEmpty);

          // Also test online transient SocketException fallback enqueues cleanly
          when(
            () => tRemote.upsert(any()),
          ).thenThrow(const SocketException('Drop mid-flight'));
          await tRepo.saveTournament(tournament);
          expect((await restartedOutbox.loadItemsForUser('org-1')).length, 1);

          await syncService.dispose();
          await connectivity.dispose();
        },
      );
    },
  );
}
