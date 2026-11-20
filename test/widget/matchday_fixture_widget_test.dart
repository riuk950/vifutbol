import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/providers/venues_providers.dart';
import 'package:vifutbol/application/use_cases/fixture_scheduling_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_referee.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/domain/entities/venue_pitch.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
import 'package:vifutbol/infrastructure/venues/local_venues_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/matches/widgets/schedule_match_dialog.dart';
import 'package:vifutbol/presentation/navigation/app_router.dart';
import 'package:vifutbol/presentation/shell/tabs/matchday_tab_view.dart';

class _WidgetTestStorage implements LocalStorageRepository {
  final Map<String, String> _map = <String, String>{};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _map[key];

  @override
  Future<void> writeString(String key, String value) async {
    _map[key] = value;
  }

  @override
  Future<void> clearNamespace() async => _map.clear();

  @override
  bool get isUsingFallbackMemory => false;
}

void main() {
  setUpAll(() {
    AppRouter.setupRouter();
  });

  group('Matchday Tab & Fixture Scheduling Widget Tests', () {
    late _WidgetTestStorage storage;
    late EnvironmentConfig devConfig;
    late LocalTournamentsRepository tournamentsRepo;
    late LocalTeamsRepository teamsRepo;
    late LocalTournamentMatchesRepository matchesRepo;
    late LocalVenuesRepository venuesRepo;
    late ChampionshipTournament testTournament;
    late List<TournamentTeam> testTeams;

    setUp(() async {
      storage = _WidgetTestStorage();
      devConfig = EnvironmentConfig.development();

      tournamentsRepo = LocalTournamentsRepository(
        storage: storage,
        config: devConfig,
      );
      testTournament = ChampionshipTournament(
        id: 'tournament-seed-liga-clausura',
        name: 'Liga Clausura ViFutbol 2026',
        category: 'Libre Masculino',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 9, 30),
        format: TournamentFormat.league,
        status: TournamentStatus.openRegistration,
        rules: const TournamentRulesConfig(
          halfDurationMinutes: 45,
          leagueRounds: 1,
        ),
        updatedAt: DateTime(2026, 4, 1),
      );
      await tournamentsRepo.saveTournament(testTournament);

      teamsRepo = LocalTeamsRepository(storage: storage, config: devConfig);
      testTeams = [
        TournamentTeam(
          id: 'team-seed-atletico-norte',
          tournamentId: testTournament.id,
          name: 'Atlético Norte FC',
          shortCode: 'ATN',
          eligibilityStatus: TeamEligibilityStatus.eligible,
        ),
        TournamentTeam(
          id: 'team-seed-real-sabana',
          tournamentId: testTournament.id,
          name: 'Real Sabana Club',
          shortCode: 'RSC',
          eligibilityStatus: TeamEligibilityStatus.eligible,
        ),
      ];
      await teamsRepo.saveTeam(testTeams[0]);
      await teamsRepo.saveTeam(testTeams[1]);

      matchesRepo = LocalTournamentMatchesRepository(
        storage: storage,
        config: devConfig,
      );
      await storage.writeString(
        LocalTournamentMatchesRepository.refereesStorageKey,
        jsonEncode([
          const MatchReferee(
            id: 'ref-test-1',
            fullName: 'Wilmar Roldán',
            certificationLevel: 'FIFA',
            isActive: true,
          ).toJson(),
        ]),
      );
      await matchesRepo.loadOfficialReferees();

      venuesRepo = LocalVenuesRepository(storage: storage, config: devConfig);
      await venuesRepo.saveVenue(
        SportsVenue(
          id: 'venue-test-1',
          name: 'Sede Principal El Campín',
          address: 'Carrera 30 con 57',
          urbanReference: 'Estadio',
          coordinate: const GeoCoordinate(latitude: 4.64, longitude: -74.07),
          pitches: const [
            VenuePitch(
              id: 'pitch-campin-1',
              name: 'Cancha 1 (F11)',
              surfaceType: PitchSurfaceType.naturalGrass,
              format: PitchFormat.football11,
              capacity: 500,
              hasLighting: true,
              status: VenueOperationalStatus.active,
            ),
            VenuePitch(
              id: 'pitch-campin-2',
              name: 'Cancha 2 (F8)',
              surfaceType: PitchSurfaceType.syntheticGrass,
              format: PitchFormat.football8,
              capacity: 200,
              hasLighting: false,
              status: VenueOperationalStatus.active,
            ),
          ],
          status: VenueOperationalStatus.active,
          updatedAt: DateTime.now(),
        ),
      );
    });

    testWidgets(
      'Scenario 1: MatchdayTabView does not render fixture generation button for Organizer (HU 15.2)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final tournamentsUseCase = ManageTournamentsUseCase(tournamentsRepo);
        final tournamentsController = TournamentsController(
          tournamentsRepository: tournamentsRepo,
          manageTournamentsUseCase: tournamentsUseCase,
        );

        final teamsUseCase = ManageTeamsEligibilityUseCase(teamsRepo);
        final teamsController = TeamsController(
          teamsRepository: teamsRepo,
          manageTeamsEligibilityUseCase: teamsUseCase,
        );

        final fixtureUseCase = FixtureSchedulingUseCase(
          matchesRepository: matchesRepo,
        );
        final matchesController = MatchesCatalogController(
          matchesRepository: matchesRepo,
          fixtureSchedulingUseCase: fixtureUseCase,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              environmentConfigProvider.overrideWithValue(devConfig),
              localStorageRepositoryProvider.overrideWithValue(storage),
              tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
              tournamentsControllerProvider.overrideWith(
                (ref) => tournamentsController,
              ),
              teamsRepositoryProvider.overrideWithValue(teamsRepo),
              teamsControllerProvider.overrideWith((ref) => teamsController),
              venuesRepositoryProvider.overrideWithValue(venuesRepo),
              tournamentMatchesRepositoryProvider.overrideWithValue(
                matchesRepo,
              ),
              fixtureSchedulingUseCaseProvider.overrideWithValue(
                fixtureUseCase,
              ),
              matchesCatalogControllerProvider.overrideWith(
                (ref) => matchesController,
              ),
              activeUserRoleProvider.overrideWithValue(UserRole.organizer),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: MatchdayTabView()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify "Generar Fixture" button and banner are NOT present for Organizer in MatchdayTabView
        expect(find.byKey(const Key('generate_fixture_button')), findsNothing);
        expect(
          find.byKey(const Key('organizer_generate_fixture_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('organizer_pending_matches_banner')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Scenario 2: Successful match scheduling assigns pitch, referee and transitions to Programado',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final fixtureUseCase = FixtureSchedulingUseCase(
          matchesRepository: matchesRepo,
        );
        final matchesController = MatchesCatalogController(
          matchesRepository: matchesRepo,
          fixtureSchedulingUseCase: fixtureUseCase,
        );

        // Preload matches
        await matchesController.generateFixture(
          tournament: testTournament,
          teams: testTeams,
          userRole: UserRole.organizer,
        );

        final pendingMatch = matchesController.state.matches.first;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              environmentConfigProvider.overrideWithValue(devConfig),
              localStorageRepositoryProvider.overrideWithValue(storage),
              venuesRepositoryProvider.overrideWithValue(venuesRepo),
              tournamentMatchesRepositoryProvider.overrideWithValue(
                matchesRepo,
              ),
              fixtureSchedulingUseCaseProvider.overrideWithValue(
                fixtureUseCase,
              ),
              matchesCatalogControllerProvider.overrideWith(
                (ref) => matchesController,
              ),
              activeUserRoleProvider.overrideWithValue(UserRole.organizer),
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    key: const Key('open_schedule_dialog_test'),
                    onPressed: () {
                      ScheduleMatchDialog.show(
                        context: context,
                        match: pendingMatch.copyWith(
                          scheduledStartTime: DateTime(2026, 11, 20, 10, 0),
                        ),
                        tournament: testTournament,
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Open Dialog
        await tester.tap(find.byKey(const Key('open_schedule_dialog_test')));
        await tester.pumpAndSettle();

        expect(find.text('Programar Partido'), findsOneWidget);

        // Confirm scheduling with default selected venue, pitch and referee
        final confirmScheduleBtn = find.byKey(
          const Key('confirm_schedule_match_button'),
        );
        expect(confirmScheduleBtn, findsOneWidget);
        await tester.tap(confirmScheduleBtn);
        await tester.pumpAndSettle();

        // Dialog should be dismissed
        expect(find.text('Programar Partido'), findsNothing);

        // Verify match status in controller is scheduled
        final updated = matchesController.state.matches.firstWhere(
          (m) => m.id == pendingMatch.id,
        );
        expect(updated.status, MatchStatus.scheduled);
        expect(updated.pitchName, isNotNull);
        expect(updated.refereeName, isNotNull);
      },
    );

    testWidgets(
      'Scenario 3: Schedule collision blocking warning is displayed on conflict',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final fixtureUseCase = FixtureSchedulingUseCase(
          matchesRepository: matchesRepo,
        );
        final matchesController = MatchesCatalogController(
          matchesRepository: matchesRepo,
          fixtureSchedulingUseCase: fixtureUseCase,
        );

        // Preload matches
        await matchesController.generateFixture(
          tournament: testTournament,
          teams: testTeams,
          userRole: UserRole.organizer,
        );

        final matches = matchesController.state.matches;
        final matchA = matches[0];

        final venues = await venuesRepo.loadVenues();
        final venue = venues.first;
        final pitch = venue.pitches.first;
        final referees = await matchesRepo.loadOfficialReferees();
        final referee = referees.first;

        // Schedule Match A on Pitch 1 from 14:00 (future date)
        final now = DateTime.now();
        final scheduledTime = DateTime(now.year + 1, 6, 1, 14, 0);
        await fixtureUseCase.scheduleMatch(
          matchId: matchA.id,
          tournament: testTournament,
          scheduledStartTime: scheduledTime,
          venue: venue,
          pitch: pitch,
          referee: referee,
          userRole: UserRole.organizer,
        );

        // Create a different match B
        final matchB = ChampionshipMatch(
          id: 'match-collision-candidate',
          tournamentId: testTournament.id,
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-other-1',
          awayTeamId: 'team-other-2',
        );
        await matchesRepo.saveMatch(matchB);
        await matchesController.loadTournamentMatches(testTournament.id);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              environmentConfigProvider.overrideWithValue(devConfig),
              localStorageRepositoryProvider.overrideWithValue(storage),
              venuesRepositoryProvider.overrideWithValue(venuesRepo),
              tournamentMatchesRepositoryProvider.overrideWithValue(
                matchesRepo,
              ),
              fixtureSchedulingUseCaseProvider.overrideWithValue(
                fixtureUseCase,
              ),
              matchesCatalogControllerProvider.overrideWith(
                (ref) => matchesController,
              ),
              activeUserRoleProvider.overrideWithValue(UserRole.organizer),
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    key: const Key('open_collision_dialog_test'),
                    onPressed: () {
                      ScheduleMatchDialog.show(
                        context: context,
                        match: matchB.copyWith(
                          scheduledStartTime: scheduledTime, // same time!
                        ),
                        tournament: testTournament,
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Open Dialog
        await tester.tap(find.byKey(const Key('open_collision_dialog_test')));
        await tester.pumpAndSettle();

        // Tap confirm scheduling
        final confirmScheduleBtn = find.byKey(
          const Key('confirm_schedule_match_button'),
        );
        await tester.tap(confirmScheduleBtn);
        await tester.pumpAndSettle();

        // Collision error message should be displayed on screen!
        expect(find.byKey(const Key('schedule_error_message')), findsOneWidget);
        expect(
          find.text(
            'La cancha ya se encuentra ocupada en ese intervalo de horario.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Scenario 4: Calendar date filtering, removed segmented button, and Organizer-only unscheduled section',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final fixtureUseCase = FixtureSchedulingUseCase(
          matchesRepository: matchesRepo,
        );
        final matchesController = MatchesCatalogController(
          matchesRepository: matchesRepo,
          fixtureSchedulingUseCase: fixtureUseCase,
        );

        // Preload matches - fixture generates 2 pendingSchedule matches
        await matchesController.generateFixture(
          tournament: testTournament,
          teams: testTeams,
          userRole: UserRole.organizer,
        );

        // 1. Mount for Fan:
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              environmentConfigProvider.overrideWithValue(devConfig),
              localStorageRepositoryProvider.overrideWithValue(storage),
              venuesRepositoryProvider.overrideWithValue(venuesRepo),
              tournamentMatchesRepositoryProvider.overrideWithValue(
                matchesRepo,
              ),
              fixtureSchedulingUseCaseProvider.overrideWithValue(
                fixtureUseCase,
              ),
              matchesCatalogControllerProvider.overrideWith(
                (ref) => matchesController,
              ),
              activeUserRoleProvider.overrideWithValue(UserRole.fan),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: MatchdayTabView()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify DailyMatchesTabBar is present and segment button was removed
        expect(find.byKey(const Key('daily_matches_tab_bar')), findsOneWidget);
        expect(
          find.byKey(const Key('matchday_segmented_button')),
          findsNothing,
        );

        // Verify Fan does NOT see "Por programar (N)" or organizer banner
        expect(
          find.byKey(const Key('unscheduled_matches_section')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('organizer_pending_matches_banner')),
          findsNothing,
        );

        // 2. Mount for Organizer:
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              environmentConfigProvider.overrideWithValue(devConfig),
              localStorageRepositoryProvider.overrideWithValue(storage),
              venuesRepositoryProvider.overrideWithValue(venuesRepo),
              tournamentMatchesRepositoryProvider.overrideWithValue(
                matchesRepo,
              ),
              fixtureSchedulingUseCaseProvider.overrideWithValue(
                fixtureUseCase,
              ),
              matchesCatalogControllerProvider.overrideWith(
                (ref) => matchesController,
              ),
              activeUserRoleProvider.overrideWithValue(UserRole.organizer),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: MatchdayTabView()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // In HU 15.2, MatchdayTabView has no organizer banner or fixture buttons
        expect(
          find.byKey(const Key('organizer_pending_matches_banner')),
          findsNothing,
        );
        expect(find.byKey(const Key('generate_fixture_button')), findsNothing);

        // Verify daily matches tab bar exists for temporal navigation
        expect(find.byKey(const Key('daily_matches_tab_bar')), findsOneWidget);
      },
    );
  });
}
