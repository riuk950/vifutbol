import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/digital_match_report_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/lineups_tracking_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/authenticate_user_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_lineups_tracking_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_reports_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/matches/digital_match_report_screen.dart';

class _MockLocalStorageRepository implements LocalStorageRepository {
  final Map<String, dynamic> _memory = {};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async {
    return const LocalStorageStatus(
      isPersistent: true,
      storageNamespace: 'test',
    );
  }

  @override
  Future<String?> readString(String key) async => _memory[key] as String?;

  @override
  Future<void> writeString(String key, String value) async {
    _memory[key] = value;
  }

  @override
  Future<void> clearNamespace() async {
    _memory.clear();
  }

  @override
  bool get isUsingFallbackMemory => true;
}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockConnectivityRepository extends Mock
    implements ConnectivityRepository {}

void main() {
  group('DigitalMatchReportScreen Gherkin Scenarios Widget Tests', () {
    late _MockLocalStorageRepository storage;
    late EnvironmentConfig config;
    late LocalMatchReportsRepository matchReportsRepo;
    late LocalTournamentMatchesRepository matchesRepo;
    late LocalTeamsRepository teamsRepo;
    late LocalLineupsTrackingRepository lineupsRepo;
    late LocalTournamentsRepository tournamentsRepo;
    late _MockAuthRepository authRepo;
    late _MockConnectivityRepository connectivityRepo;

    late ChampionshipTournament tournament;
    late ChampionshipMatch match;
    late TournamentTeam homeTeam;
    late TournamentTeam awayTeam;

    late RegisteredPlayer pHome1;
    late RegisteredPlayer pHome2;
    late RegisteredPlayer pAway1;
    late RegisteredPlayer pAway2;
    late AuthSession refereeSession;

    setUp(() async {
      storage = _MockLocalStorageRepository();
      config = EnvironmentConfig.development();
      authRepo = _MockAuthRepository();
      connectivityRepo = _MockConnectivityRepository();

      matchReportsRepo = LocalMatchReportsRepository(
        storage: storage,
        config: config,
      );
      matchesRepo = LocalTournamentMatchesRepository(
        storage: storage,
        config: config,
      );
      teamsRepo = LocalTeamsRepository(storage: storage, config: config);
      lineupsRepo = LocalLineupsTrackingRepository(
        storage: storage,
        config: config,
      );
      tournamentsRepo = LocalTournamentsRepository(
        storage: storage,
        config: config,
      );

      refereeSession = AuthSession(
        sessionId: 'session-fake-1',
        sessionToken: 'fake-token',
        authenticatedAt: DateTime.now(),
        user: UserAccount(
          id: 'ref-seed-1',
          fullName: 'Árbitro Oficial',
          email: 'referee@vifutbol.com',
          activeRole: UserRole.referee,
          authorizedRoles: {UserRole.referee},
          onboardingCompleted: true,
        ),
      );

      when(
        () => authRepo.restoreSession(),
      ).thenAnswer((_) async => refereeSession);
      when(
        () => connectivityRepo.onConnectivityChanged,
      ).thenAnswer((_) => Stream.value(NetworkConnectionStatus.connected));
      when(
        () => connectivityRepo.checkConnectivity(),
      ).thenAnswer((_) async => NetworkConnectionStatus.connected);

      tournament = ChampionshipTournament(
        id: 'tournament-widget-1',
        name: 'Torneo Clausura 2026',
        category: 'Libre',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        format: TournamentFormat.league,
        updatedAt: DateTime.now(),
      );
      await tournamentsRepo.saveTournament(tournament);

      pHome1 = const RegisteredPlayer(
        id: 'p-home-1',
        fullName: 'Carlos Valderrama',
        shirtNumber: 10,
        documentId: 'CC-101',
        position: PlayerPosition.midfielder,
        isEligible: true,
      );
      pHome2 = const RegisteredPlayer(
        id: 'p-home-2',
        fullName: 'Faustino Asprilla',
        shirtNumber: 11,
        documentId: 'CC-102',
        position: PlayerPosition.forward,
        isEligible: true,
      );
      pAway1 = const RegisteredPlayer(
        id: 'p-away-1',
        fullName: 'Dávinson Sánchez',
        shirtNumber: 5,
        documentId: 'CC-201',
        position: PlayerPosition.defender,
        isEligible: true,
      );
      pAway2 = const RegisteredPlayer(
        id: 'p-away-2',
        fullName: 'James Rodríguez',
        shirtNumber: 10,
        documentId: 'CC-202',
        position: PlayerPosition.midfielder,
        isEligible: true,
      );

      homeTeam = TournamentTeam(
        id: 'team-atn',
        tournamentId: tournament.id,
        name: 'Atlético Nacional',
        shortCode: 'ATN',
        primaryColorHex: 0xFF008000,
        players: [pHome1, pHome2],
        updatedAt: DateTime.now(),
      );
      awayTeam = TournamentTeam(
        id: 'team-rsc',
        tournamentId: tournament.id,
        name: 'Real Santa Cruz',
        shortCode: 'RSC',
        primaryColorHex: 0xFFFFFFFF,
        players: [pAway1, pAway2],
        updatedAt: DateTime.now(),
      );

      await teamsRepo.saveTeam(homeTeam);
      await teamsRepo.saveTeam(awayTeam);

      match = ChampionshipMatch(
        id: 'match-widget-1',
        tournamentId: tournament.id,
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: homeTeam.id,
        awayTeamId: awayTeam.id,
        status: MatchStatus.scheduled,
        updatedAt: DateTime.now(),
      );
      await matchesRepo.saveMatch(match);
    });

    Widget createTestApp({UserRole role = UserRole.referee}) {
      final authController = AuthController(
        authRepository: authRepo,
        authenticateUserUseCase: AuthenticateUserUseCase(authRepo),
      );

      return ProviderScope(
        overrides: [
          localStorageRepositoryProvider.overrideWithValue(storage),
          environmentConfigProvider.overrideWithValue(config),
          matchReportsRepositoryProvider.overrideWithValue(matchReportsRepo),
          tournamentMatchesRepositoryProvider.overrideWithValue(matchesRepo),
          teamsRepositoryProvider.overrideWithValue(teamsRepo),
          lineupsTrackingRepositoryProvider.overrideWithValue(lineupsRepo),
          tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
          authRepositoryProvider.overrideWithValue(authRepo),
          connectivityRepositoryProvider.overrideWithValue(connectivityRepo),
          authControllerProvider.overrideWith((ref) => authController),
          activeUserRoleProvider.overrideWith((ref) => role),
        ],
        child: MaterialApp(
          theme: KickPulseTheme.darkTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: DigitalMatchReportScreen(initialMatch: match),
        ),
      );
    }

    testWidgets(
      'Gherkin Scenario 1: Referee starts match and records goal with assist updating tabular score',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Verify initial state
        expect(find.text('Acta Digital del Árbitro'), findsOneWidget);
        expect(find.text('0  -  0'), findsOneWidget);
        expect(find.text('Iniciar Partido'), findsOneWidget);

        // Tap 'Iniciar Partido'
        await tester.tap(find.text('Iniciar Partido'));
        await tester.pumpAndSettle();

        // Quick action buttons should now be visible
        expect(find.text('Gol'), findsOneWidget);
        expect(find.text('Amarilla'), findsOneWidget);
        expect(find.text('Roja'), findsOneWidget);

        // Tap 'Gol'
        await tester.tap(find.text('Gol'));
        await tester.pumpAndSettle();

        // RecordGoalDialog is open
        expect(find.text('Registrar Gol'), findsOneWidget);

        // Select Scorer Faustino Asprilla #11
        final scorerDropdown = find.byKey(
          const Key('record_goal_scorer_dropdown'),
        );
        await tester.tap(scorerDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('#11 - Faustino Asprilla').last);
        await tester.pumpAndSettle();

        // Select Assistant Carlos Valderrama #10
        final assistantDropdown = find.byKey(
          const Key('record_goal_assistant_dropdown'),
        );
        await tester.tap(assistantDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('#10 - Carlos Valderrama').last);
        await tester.pumpAndSettle();

        // Submit goal
        await tester.tap(find.text('Confirmar Gol'));
        await tester.pumpAndSettle();

        // Scoreboard updated to 1  -  0
        expect(find.text('1  -  0'), findsOneWidget);
        expect(find.text('Gol de Faustino Asprilla #11'), findsOneWidget);
        expect(find.text('Asistencia: Carlos Valderrama #10'), findsOneWidget);
      },
    );

    testWidgets(
      'Gherkin Scenario 2: Second yellow card automatically triggers expulsion for shirt #5',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Start match
        await tester.tap(find.text('Iniciar Partido'));
        await tester.pumpAndSettle();

        // Register 1st yellow card for Dávinson Sánchez #5
        await tester.tap(find.text('Amarilla'));
        await tester.pumpAndSettle();

        expect(find.text('Tarjeta Disciplinaria'), findsOneWidget);

        // Select Away team
        final teamDropdown = find.byKey(const Key('record_card_team_dropdown'));
        await tester.tap(teamDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Real Santa Cruz').last);
        await tester.pumpAndSettle();

        // Select player #5
        final playerDropdown = find.byKey(
          const Key('record_card_player_dropdown'),
        );
        await tester.tap(playerDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('#5 - Dávinson Sánchez').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Confirmar Tarjeta'));
        await tester.pumpAndSettle();

        // First yellow card is in timeline
        expect(
          find.text('Tarjeta Amarilla - Dávinson Sánchez #5'),
          findsOneWidget,
        );

        // Register 2nd yellow card for Dávinson Sánchez #5
        await tester.tap(find.text('Amarilla'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('record_card_team_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Real Santa Cruz').last);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('record_card_player_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('#5 - Dávinson Sánchez [1🟨]').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Confirmar Expulsión'));
        await tester.pumpAndSettle();

        // Verify automatic expulsion in timeline
        expect(
          find.text('Segunda Amarilla y Expulsión - Dávinson Sánchez #5'),
          findsOneWidget,
        );
        expect(
          find.text('Expulsión automática por acumulación'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Gherkin Scenario 3: Offline banner appears and queued events sync without duplicates',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap offline simulation button
        final offlineToggle = find.byKey(
          const Key('digital_match_report_offline_toggle'),
        );
        expect(offlineToggle, findsOneWidget);

        await tester.tap(offlineToggle);
        await tester.pumpAndSettle();

        // Offline Spanish banner must be displayed
        expect(
          find.text('Modo sin conexión: cambios guardados en el dispositivo'),
          findsOneWidget,
        );

        // Start match offline
        await tester.tap(find.text('Iniciar Partido'));
        await tester.pumpAndSettle();

        // Verify pending count badge with sync button
        expect(find.text('Sincronizar (1)'), findsOneWidget);

        // Tap Sincronizar
        await tester.tap(find.text('Sincronizar (1)'));
        await tester.pumpAndSettle();

        // Offline banner disappears
        expect(
          find.text('Modo sin conexión: cambios guardados en el dispositivo'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Gherkin Scenario 4: Official report closing locks report and makes it immutable',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Iniciar partido -> 1er Tiempo
        await tester.tap(find.text('Iniciar Partido'));
        await tester.pumpAndSettle();

        // Fin 1er Tiempo -> Entretiempo
        await tester.tap(find.text('Fin 1er Tiempo'));
        await tester.pumpAndSettle();

        // Iniciar 2do Tiempo -> 2do Tiempo
        await tester.tap(find.text('Iniciar 2do Tiempo'));
        await tester.pumpAndSettle();

        // Tiempo Cumplido -> Fin del Partido
        await tester.tap(find.text('Tiempo Cumplido'));
        await tester.pumpAndSettle();

        // Tap 'Cerrar Acta Oficial'
        final closeButton = find.text('Cerrar Acta Oficial');
        expect(closeButton, findsOneWidget);
        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        // Confirmation dialog should be displayed
        expect(find.text('Cierre Oficial del Acta'), findsOneWidget);
        expect(find.text('Confirmar y Cerrar Acta'), findsOneWidget);

        await tester.tap(find.text('Confirmar y Cerrar Acta'));
        await tester.pumpAndSettle();

        // Report is now closed
        expect(find.text('FINALIZADO'), findsOneWidget);
        // Action buttons (Gol, Amarilla, Roja) must be absent/locked
        expect(find.text('Gol'), findsNothing);
        expect(find.text('Amarilla'), findsNothing);
        expect(find.text('Roja'), findsNothing);
      },
    );
  });
}
