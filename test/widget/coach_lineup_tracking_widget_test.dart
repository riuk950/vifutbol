import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/lineups_tracking_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/lineups_tracking_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/manage_lineups_tracking_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/player_internal_tracking.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_lineups_tracking_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/navigation/app_router.dart';
import 'package:vifutbol/presentation/teams/coach_lineup_tracking_screen.dart';

class _WidgetTestStorage implements LocalStorageRepository {
  _WidgetTestStorage() {
    const tournamentId = 'tournament-seed-liga-clausura';
    const teamId = 'team-seed-atletico-norte';
    final tournament = ChampionshipTournament(
      id: tournamentId,
      name: 'Liga Clausura ViFutbol 2026',
      category: 'Libre Masculino',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 12, 30),
      format: TournamentFormat.league,
      status: TournamentStatus.openRegistration,
      rules: const TournamentRulesConfig(yellowCardSuspensionLimit: 3),
      updatedAt: DateTime(2026, 4, 17),
    );
    const players = [
      RegisteredPlayer(
        id: 'p-seed-atn-1',
        fullName: 'David Ospina',
        documentId: '10100001',
        shirtNumber: 1,
        position: PlayerPosition.goalkeeper,
        isEligible: true,
      ),
      RegisteredPlayer(
        id: 'p-seed-atn-2',
        fullName: 'Yerry Mina',
        documentId: '10100002',
        shirtNumber: 4,
        position: PlayerPosition.defender,
        isEligible: true,
      ),
      RegisteredPlayer(
        id: 'p-seed-atn-3',
        fullName: 'Dávinson Sánchez',
        documentId: '10100003',
        shirtNumber: 2,
        position: PlayerPosition.defender,
        isEligible: true,
      ),
      RegisteredPlayer(
        id: 'p-seed-atn-4',
        fullName: 'Santiago Arias',
        documentId: '10100004',
        shirtNumber: 5,
        position: PlayerPosition.defender,
        isEligible: true,
      ),
      RegisteredPlayer(
        id: 'p-seed-atn-17',
        fullName: 'Johan Mojica',
        documentId: '10100017',
        shirtNumber: 3,
        position: PlayerPosition.defender,
        isEligible: true,
      ),
      RegisteredPlayer(
        id: 'p-seed-atn-8',
        fullName: 'Wilmar Barrios',
        documentId: '10100008',
        shirtNumber: 6,
        position: PlayerPosition.midfielder,
        isEligible: true,
      ),
      RegisteredPlayer(
        id: 'p-seed-atn-6',
        fullName: 'James Rodríguez',
        documentId: '10100006',
        shirtNumber: 10,
        position: PlayerPosition.midfielder,
        isEligible: true,
      ),
      RegisteredPlayer(
        id: 'p-seed-atn-11',
        fullName: 'Juan Cuadrado',
        documentId: '10100011',
        shirtNumber: 11,
        position: PlayerPosition.midfielder,
        isEligible: true,
      ),
      RegisteredPlayer(
        id: 'p-seed-atn-14',
        fullName: 'Jefferson Lerma',
        documentId: '10100014',
        shirtNumber: 14,
        position: PlayerPosition.midfielder,
        isEligible: true,
      ),
      RegisteredPlayer(
        id: 'p-seed-atn-7',
        fullName: 'Luis Díaz',
        documentId: '10100007',
        shirtNumber: 7,
        position: PlayerPosition.forward,
        isEligible: true,
      ),
      RegisteredPlayer(
        id: 'p-seed-atn-5',
        fullName: 'Falcao',
        documentId: '10100005',
        shirtNumber: 9,
        position: PlayerPosition.forward,
        isEligible: true,
      ),
      RegisteredPlayer(
        id: 'p-seed-atn-12',
        fullName: 'Camilo Vargas',
        documentId: '10100012',
        shirtNumber: 12,
        position: PlayerPosition.goalkeeper,
        isEligible: true,
      ),
      RegisteredPlayer(
        id: 'p-seed-atn-13',
        fullName: 'Carlos Cuesta',
        documentId: '10100013',
        shirtNumber: 13,
        position: PlayerPosition.defender,
        isEligible: true,
      ),
      RegisteredPlayer(
        id: 'p-seed-atn-15',
        fullName: 'Mateus Uribe',
        documentId: '10100015',
        shirtNumber: 8,
        position: PlayerPosition.midfielder,
        isEligible: true,
      ),
    ];
    final atn = TournamentTeam(
      id: teamId,
      tournamentId: tournamentId,
      name: 'Atlético Norte FC',
      shortCode: 'ATN',
      eligibilityStatus: TeamEligibilityStatus.eligible,
      players: players,
    );
    const trackings = [
      PlayerInternalTracking(
        playerId: 'p-seed-atn-8',
        teamId: teamId,
        tournamentId: tournamentId,
        matchesPlayed: 4,
        yellowCards: 2,
        redCards: 1,
        pendingSuspensionMatches: 1,
      ),
      PlayerInternalTracking(
        playerId: 'p-seed-atn-2',
        teamId: teamId,
        tournamentId: tournamentId,
        matchesPlayed: 5,
        goals: 1,
        yellowCards: 2,
      ),
    ];
    _map[LocalTournamentsRepository.catalogStorageKey] = jsonEncode([
      tournament.toJson(),
    ]);
    _map[LocalTeamsRepository.catalogStorageKey] = jsonEncode([atn.toJson()]);
    _map[LocalLineupsTrackingRepository.trackingStorageKey] = jsonEncode(
      trackings.map((t) => t.toJson()).toList(),
    );
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

  group('Coach Lineups, Tracking & Disciplinary Widget Tests', () {
    testWidgets(
      'displays suspended player with disabled controls and warning for yellow card accumulation',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final storage = _WidgetTestStorage();
        final devConfig = EnvironmentConfig.development();
        final tournamentsRepo = LocalTournamentsRepository(
          storage: storage,
          config: devConfig,
        );
        await tournamentsRepo.loadTournaments();

        final teamsRepo = LocalTeamsRepository(
          storage: storage,
          config: devConfig,
        );
        final teams = await teamsRepo.loadTeams();
        final atletico = teams.firstWhere((t) => t.shortCode == 'ATN');

        final lineupsRepo = LocalLineupsTrackingRepository(
          storage: storage,
          config: devConfig,
        );
        await lineupsRepo.loadTrackingForTeam(
          atletico.tournamentId,
          atletico.id,
          atletico.players,
        );

        final teamsUseCase = ManageTeamsEligibilityUseCase(teamsRepo);
        final teamsController = TeamsController(
          teamsRepository: teamsRepo,
          manageTeamsEligibilityUseCase: teamsUseCase,
        );
        teamsController.selectTeam(atletico.id);

        final lineupsUseCase = ManageLineupsTrackingUseCase(lineupsRepo);
        final lineupsController = LineupsTrackingController(
          repository: lineupsRepo,
          manageLineupsTrackingUseCase: lineupsUseCase,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              environmentConfigProvider.overrideWithValue(devConfig),
              localStorageRepositoryProvider.overrideWithValue(storage),
              tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
              teamsRepositoryProvider.overrideWithValue(teamsRepo),
              teamsControllerProvider.overrideWith((ref) => teamsController),
              lineupsTrackingRepositoryProvider.overrideWithValue(lineupsRepo),
              manageLineupsTrackingUseCaseProvider.overrideWithValue(
                lineupsUseCase,
              ),
              lineupsTrackingControllerProvider.overrideWith(
                (ref) => lineupsController,
              ),
              activeUserRoleProvider.overrideWithValue(UserRole.coach),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('es'),
              home: CoachLineupTrackingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Wilmar Barrios (dorsal 6) has pending suspension of 1 match
        expect(find.text('Wilmar Barrios'), findsOneWidget);
        expect(find.text('Suspendido (1 fecha)'), findsOneWidget);

        // Selection controls for Wilmar Barrios must be disabled
        final starterChoiceChip = tester.widget<ChoiceChip>(
          find.byKey(const Key('role_starter_6')),
        );
        expect(starterChoiceChip.onSelected, isNull);

        // Yerry Mina (dorsal 4) has 2 yellow cards (limit 3) -> warning "En capilla"
        expect(find.text('Yerry Mina'), findsOneWidget);
        expect(find.text('En capilla (2 TA)'), findsOneWidget);
      },
    );

    testWidgets(
      'coach confirms official lineup and referee views synchronized roster in referee tab',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final storage = _WidgetTestStorage();
        final devConfig = EnvironmentConfig.development();

        final tournamentsRepo = LocalTournamentsRepository(
          storage: storage,
          config: devConfig,
        );
        await tournamentsRepo.loadTournaments();

        final teamsRepo = LocalTeamsRepository(
          storage: storage,
          config: devConfig,
        );
        final teams = await teamsRepo.loadTeams();
        final atletico = teams.firstWhere((t) => t.shortCode == 'ATN');

        final lineupsRepo = LocalLineupsTrackingRepository(
          storage: storage,
          config: devConfig,
        );
        await lineupsRepo.loadTrackingForTeam(
          atletico.tournamentId,
          atletico.id,
          atletico.players,
        );

        final teamsUseCase = ManageTeamsEligibilityUseCase(teamsRepo);
        final teamsController = TeamsController(
          teamsRepository: teamsRepo,
          manageTeamsEligibilityUseCase: teamsUseCase,
        );
        teamsController.selectTeam(atletico.id);

        final lineupsUseCase = ManageLineupsTrackingUseCase(lineupsRepo);
        final lineupsController = LineupsTrackingController(
          repository: lineupsRepo,
          manageLineupsTrackingUseCase: lineupsUseCase,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              environmentConfigProvider.overrideWithValue(devConfig),
              localStorageRepositoryProvider.overrideWithValue(storage),
              tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
              teamsRepositoryProvider.overrideWithValue(teamsRepo),
              teamsControllerProvider.overrideWith((ref) => teamsController),
              lineupsTrackingRepositoryProvider.overrideWithValue(lineupsRepo),
              manageLineupsTrackingUseCaseProvider.overrideWithValue(
                lineupsUseCase,
              ),
              lineupsTrackingControllerProvider.overrideWith(
                (ref) => lineupsController,
              ),
              activeUserRoleProvider.overrideWithValue(UserRole.coach),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('es'),
              home: CoachLineupTrackingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select 7 eligible starters: 1 (Ospina), 4 (Mina), 5 (Sánchez), 8 (Uribe), 9 (Falcao), 10 (James), 11 (Díaz)
        final starterDorsals = [1, 4, 5, 8, 9, 10, 11];
        for (final dorsal in starterDorsals) {
          await tester.ensureVisible(find.byKey(Key('role_starter_$dorsal')));
          await tester.tap(find.byKey(Key('role_starter_$dorsal')));
          await tester.pumpAndSettle();
        }

        // Set James (dorsal 10) as Captain
        await tester.ensureVisible(find.byKey(const Key('captain_action_10')));
        await tester.tap(find.byKey(const Key('captain_action_10')));
        await tester.pumpAndSettle();

        // Select substitute: dorsal 3 (Mojica)
        await tester.ensureVisible(find.byKey(const Key('role_substitute_3')));
        await tester.tap(find.byKey(const Key('role_substitute_3')));
        await tester.pumpAndSettle();

        // Confirm official convocation
        await tester.ensureVisible(
          find.byKey(const Key('confirm_convocation_action_button')),
        );
        await tester.tap(
          find.byKey(const Key('confirm_convocation_action_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Alineación oficial confirmada y sincronizada con el acta arbitral',
          ),
          findsOneWidget,
        );

        // Switch to Referee tab (Acta Arbitral)
        await tester.tap(find.text('Acta Arbitral'));
        await tester.pumpAndSettle();

        expect(
          find.text('Nómina Oficial Sincronizada (Acta Arbitral)'),
          findsOneWidget,
        );
        expect(find.text('James Rodríguez'), findsWidgets);
        expect(find.text('Capitán'), findsOneWidget);
        expect(find.text('Johan Mojica'), findsOneWidget);
      },
    );

    testWidgets(
      'preserves partial selection across mobile background lifecycle transition',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final storage = _WidgetTestStorage();
        final devConfig = EnvironmentConfig.development();

        final tournamentsRepo = LocalTournamentsRepository(
          storage: storage,
          config: devConfig,
        );
        await tournamentsRepo.loadTournaments();

        final teamsRepo = LocalTeamsRepository(
          storage: storage,
          config: devConfig,
        );
        final teams = await teamsRepo.loadTeams();
        final atletico = teams.firstWhere((t) => t.shortCode == 'ATN');

        final lineupsRepo = LocalLineupsTrackingRepository(
          storage: storage,
          config: devConfig,
        );
        await lineupsRepo.loadTrackingForTeam(
          atletico.tournamentId,
          atletico.id,
          atletico.players,
        );

        final teamsUseCase = ManageTeamsEligibilityUseCase(teamsRepo);
        final teamsController = TeamsController(
          teamsRepository: teamsRepo,
          manageTeamsEligibilityUseCase: teamsUseCase,
        );
        teamsController.selectTeam(atletico.id);

        final lineupsUseCase = ManageLineupsTrackingUseCase(lineupsRepo);
        final lineupsController = LineupsTrackingController(
          repository: lineupsRepo,
          manageLineupsTrackingUseCase: lineupsUseCase,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              environmentConfigProvider.overrideWithValue(devConfig),
              localStorageRepositoryProvider.overrideWithValue(storage),
              tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
              teamsRepositoryProvider.overrideWithValue(teamsRepo),
              teamsControllerProvider.overrideWith((ref) => teamsController),
              lineupsTrackingRepositoryProvider.overrideWithValue(lineupsRepo),
              manageLineupsTrackingUseCaseProvider.overrideWithValue(
                lineupsUseCase,
              ),
              lineupsTrackingControllerProvider.overrideWith(
                (ref) => lineupsController,
              ),
              activeUserRoleProvider.overrideWithValue(UserRole.coach),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('es'),
              home: CoachLineupTrackingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select Falcao (dorsal 9) as starter
        await tester.ensureVisible(find.byKey(const Key('role_starter_9')));
        await tester.tap(find.byKey(const Key('role_starter_9')));
        await tester.pumpAndSettle();

        // Simulate mobile background lifecycle transition
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();

        // Starter 9 remains selected
        final falcaoChip = tester.widget<ChoiceChip>(
          find.byKey(const Key('role_starter_9')),
        );
        expect(falcaoChip.selected, isTrue);
      },
    );
  });
}
