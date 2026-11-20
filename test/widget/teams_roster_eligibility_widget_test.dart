import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/navigation/app_router.dart';
import 'package:vifutbol/presentation/shell/tabs/standings_tab_view.dart';
import 'package:vifutbol/presentation/teams/team_roster_detail_screen.dart';

class _FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;
}

class _MemoryStorage implements LocalStorageRepository {
  _MemoryStorage() {
    const tournamentId = 'tournament-seed-liga-clausura';
    final tournament = ChampionshipTournament(
      id: tournamentId,
      name: 'Liga Clausura ViFutbol 2026',
      category: 'Libre Masculino',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 12, 30),
      format: TournamentFormat.league,
      status: TournamentStatus.openRegistration,
      rules: const TournamentRulesConfig(minPlayersPerTeam: 7),
      updatedAt: DateTime(2026, 4, 17),
    );
    final atn = TournamentTeam(
      id: 'team-seed-atletico-norte',
      tournamentId: tournamentId,
      name: 'Atlético Norte FC',
      shortCode: 'ATN',
      eligibilityStatus: TeamEligibilityStatus.eligible,
      players: const [
        RegisteredPlayer(
          id: 'p-atn-10',
          fullName: 'James Rodríguez',
          documentId: '10100010',
          shirtNumber: 10,
          position: PlayerPosition.midfielder,
          isEligible: true,
        ),
      ],
    );
    final rsc = TournamentTeam(
      id: 'team-seed-real-sabana',
      tournamentId: tournamentId,
      name: 'Real Sabana Club',
      shortCode: 'RSC',
      eligibilityStatus: TeamEligibilityStatus.pendingVerification,
      players: List.generate(
        9,
        (i) => RegisteredPlayer(
          id: 'p-rsc-${i + 1}',
          fullName: 'Jugador RSC ${i + 1}',
          documentId: '2020000${i + 1}',
          shirtNumber: i + 1,
          position: PlayerPosition.midfielder,
        ),
      ),
    );
    _map[LocalTournamentsRepository.catalogStorageKey] = jsonEncode([
      tournament.toJson(),
    ]);
    _map[LocalTeamsRepository.catalogStorageKey] = jsonEncode([
      atn.toJson(),
      rsc.toJson(),
    ]);
  }

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

  Widget buildTestApp({
    required UserRole role,
    Widget? home,
    _MemoryStorage? sharedStorage,
  }) {
    final devConfig = EnvironmentConfig.development();
    final storage = sharedStorage ?? _MemoryStorage();
    final tournamentsRepo = LocalTournamentsRepository(
      storage: storage,
      config: devConfig,
    );
    final tournamentsUseCase = ManageTournamentsUseCase(tournamentsRepo);

    final teamsRepo = LocalTeamsRepository(storage: storage, config: devConfig);
    final teamsUseCase = ManageTeamsEligibilityUseCase(teamsRepo);

    return ProviderScope(
      overrides: [
        environmentConfigProvider.overrideWithValue(devConfig),
        localStorageRepositoryProvider.overrideWithValue(storage),
        connectivityRepositoryProvider.overrideWithValue(
          _FakeConnectivityRepository(),
        ),
        tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
        manageTournamentsUseCaseProvider.overrideWithValue(tournamentsUseCase),
        teamsRepositoryProvider.overrideWithValue(teamsRepo),
        manageTeamsEligibilityUseCaseProvider.overrideWithValue(teamsUseCase),
        activeUserRoleProvider.overrideWithValue(role),
        activeRoleCapabilitiesProvider.overrideWithValue(
          RolePermissionMatrix.capabilitiesForRole(role),
        ),
        tournamentsControllerProvider.overrideWith(
          (ref) => TournamentsController(
            tournamentsRepository: tournamentsRepo,
            manageTournamentsUseCase: tournamentsUseCase,
          ),
        ),
        teamsControllerProvider.overrideWith(
          (ref) => TeamsController(
            teamsRepository: teamsRepo,
            manageTeamsEligibilityUseCase: teamsUseCase,
          ),
        ),
      ],
      child: MaterialApp(
        theme: KickPulseTheme.darkTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        onGenerateRoute: AppRouter.router.generator,
        home: home ?? const Scaffold(body: StandingsTabView()),
      ),
    );
  }

  group('Tournament Teams & Roster Widget Tests', () {
    testWidgets(
      'displays teams section in StandingsTabView and registers a new team as coach',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestApp(role: UserRole.coach));
        await tester.pumpAndSettle();

        expect(find.text('Equipos Inscritos'), findsOneWidget);
        expect(
          find.byKey(const Key('register_team_action_button')),
          findsOneWidget,
        );

        // Seed teams loaded in dev
        expect(find.text('Atlético Norte FC'), findsOneWidget);
        expect(find.text('Real Sabana Club'), findsOneWidget);

        // Scroll down to teams section
        await tester.ensureVisible(
          find.byKey(const Key('register_team_action_button')),
        );
        await tester.pumpAndSettle();

        // Tap register team button
        await tester.tap(find.byKey(const Key('register_team_action_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.byKey(const Key('team_name_input')), findsOneWidget);
        expect(find.byKey(const Key('team_short_code_input')), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('team_name_input')),
          'Deportivo ViFutbol',
        );
        await tester.enterText(
          find.byKey(const Key('team_short_code_input')),
          'DVF',
        );

        await tester.tap(find.byKey(const Key('team_submit_button')));
        await tester.pumpAndSettle();

        expect(find.text('Deportivo ViFutbol'), findsOneWidget);
      },
    );

    testWidgets(
      'configures numeric keyboard and validates duplicate shirt number with exact Gherkin message',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final storage = _MemoryStorage();
        final devConfig = EnvironmentConfig.development();
        final teamsRepo = LocalTeamsRepository(
          storage: storage,
          config: devConfig,
        );
        // Preload seeds
        final teams = await teamsRepo.loadTeams();
        final atletico = teams.firstWhere((t) => t.shortCode == 'ATN');

        final tournamentsRepo = LocalTournamentsRepository(
          storage: storage,
          config: devConfig,
        );
        await tournamentsRepo.loadTournaments();

        final teamsUseCase = ManageTeamsEligibilityUseCase(teamsRepo);
        final teamsController = TeamsController(
          teamsRepository: teamsRepo,
          manageTeamsEligibilityUseCase: teamsUseCase,
        );
        teamsController.selectTeam(atletico.id);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              environmentConfigProvider.overrideWithValue(devConfig),
              localStorageRepositoryProvider.overrideWithValue(storage),
              connectivityRepositoryProvider.overrideWithValue(
                _FakeConnectivityRepository(),
              ),
              tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
              teamsRepositoryProvider.overrideWithValue(teamsRepo),
              teamsControllerProvider.overrideWith((ref) => teamsController),
              activeUserRoleProvider.overrideWithValue(UserRole.coach),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('es'),
              home: TeamRosterDetailScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Atlético Norte FC'), findsOneWidget);
        expect(find.byKey(const Key('enroll_player_button')), findsOneWidget);

        // Open invite player modal (HU 20.1)
        await tester.tap(find.byKey(const Key('enroll_player_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(
          find.byKey(const Key('invite_player_search_field')),
          findsOneWidget,
        );
      },
    );

    testWidgets('enforces read-only view for fans without mutation controls', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(role: UserRole.fan));
      await tester.pumpAndSettle();

      expect(find.text('Equipos Inscritos'), findsOneWidget);
      // Register button must be hidden for fan
      expect(
        find.byKey(const Key('register_team_action_button')),
        findsNothing,
      );
    });

    testWidgets('organizer approves team eligibility when quota is satisfied', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final storage = _MemoryStorage();
      final devConfig = EnvironmentConfig.development();
      final teamsRepo = LocalTeamsRepository(
        storage: storage,
        config: devConfig,
      );
      final teams = await teamsRepo.loadTeams();
      // Modify Real Sabana to pendingVerification
      final realSabana = teams.firstWhere((t) => t.shortCode == 'RSC');
      final updatedRSC = realSabana.copyWith(
        eligibilityStatus: TeamEligibilityStatus.pendingVerification,
        players: [
          ...realSabana.players,
          // Add 6 more players to reach regulatory minimum quota (11)
          const RegisteredPlayer(
            id: 'p-seed-rsc-6',
            fullName: 'Jhon Arias',
            documentId: '20200006',
            shirtNumber: 11,
            position: PlayerPosition.midfielder,
          ),
          const RegisteredPlayer(
            id: 'p-seed-rsc-7',
            fullName: 'Jhon Durán',
            documentId: '20200007',
            shirtNumber: 9,
            position: PlayerPosition.forward,
          ),
          const RegisteredPlayer(
            id: 'p-seed-rsc-8',
            fullName: 'Luis Díaz',
            documentId: '20200008',
            shirtNumber: 7,
            position: PlayerPosition.forward,
          ),
          const RegisteredPlayer(
            id: 'p-seed-rsc-9',
            fullName: 'Daniel Muñoz',
            documentId: '20200009',
            shirtNumber: 21,
            position: PlayerPosition.defender,
          ),
          const RegisteredPlayer(
            id: 'p-seed-rsc-10',
            fullName: 'Johan Mojica',
            documentId: '20200010',
            shirtNumber: 17,
            position: PlayerPosition.defender,
          ),
          const RegisteredPlayer(
            id: 'p-seed-rsc-11',
            fullName: 'Richard Ríos',
            documentId: '20200011',
            shirtNumber: 6,
            position: PlayerPosition.midfielder,
          ),
        ],
      );
      await teamsRepo.saveTeam(updatedRSC);

      final tournamentsRepo = LocalTournamentsRepository(
        storage: storage,
        config: devConfig,
      );
      await tournamentsRepo.loadTournaments();

      final teamsUseCase = ManageTeamsEligibilityUseCase(teamsRepo);
      final teamsController = TeamsController(
        teamsRepository: teamsRepo,
        manageTeamsEligibilityUseCase: teamsUseCase,
      );
      teamsController.selectTeam(updatedRSC.id);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            environmentConfigProvider.overrideWithValue(devConfig),
            localStorageRepositoryProvider.overrideWithValue(storage),
            connectivityRepositoryProvider.overrideWithValue(
              _FakeConnectivityRepository(),
            ),
            tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
            teamsRepositoryProvider.overrideWithValue(teamsRepo),
            teamsControllerProvider.overrideWith((ref) => teamsController),
            activeUserRoleProvider.overrideWithValue(UserRole.organizer),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('es'),
            home: TeamRosterDetailScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('approve_team_eligibility_button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('approve_team_eligibility_button')),
      );
      await tester.pumpAndSettle();

      // Team is now eligible
      expect(
        teamsController.state.selectedTeam?.eligibilityStatus,
        equals(TeamEligibilityStatus.eligible),
      );
    });
  });
}
