import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/digital_match_report_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_event.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_reports_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/shell/tabs/standings_tab_view.dart';

class _TestMemoryStorage implements LocalStorageRepository {
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
  bool get isUsingFallbackMemory => true;
}

void main() {
  group('HU 8.1 Standings, Knockout Brackets & Sports Rankings Widget Tests', () {
    late _TestMemoryStorage storage;
    late EnvironmentConfig prodConfig;
    late LocalTournamentsRepository tournamentsRepo;
    late LocalTeamsRepository teamsRepo;
    late LocalTournamentMatchesRepository matchesRepo;
    late LocalMatchReportsRepository reportsRepo;
    final baseDate = DateTime(2026, 11, 4, 16, 0);

    setUp(() {
      storage = _TestMemoryStorage();
      prodConfig = EnvironmentConfig.production();
      tournamentsRepo = LocalTournamentsRepository(
        storage: storage,
        config: prodConfig,
      );
      teamsRepo = LocalTeamsRepository(storage: storage, config: prodConfig);
      matchesRepo = LocalTournamentMatchesRepository(
        storage: storage,
        config: prodConfig,
      );
      reportsRepo = LocalMatchReportsRepository(
        storage: storage,
        config: prodConfig,
      );
    });

    Widget buildTestHarness({
      UserRole role = UserRole.fan,
      double textScaleFactor = 1.0,
    }) {
      final tournamentsUseCase = ManageTournamentsUseCase(tournamentsRepo);
      final teamsUseCase = ManageTeamsEligibilityUseCase(teamsRepo);

      return ProviderScope(
        overrides: [
          environmentConfigProvider.overrideWithValue(prodConfig),
          localStorageRepositoryProvider.overrideWithValue(storage),
          tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
          manageTournamentsUseCaseProvider.overrideWithValue(
            tournamentsUseCase,
          ),
          teamsRepositoryProvider.overrideWithValue(teamsRepo),
          manageTeamsEligibilityUseCaseProvider.overrideWithValue(teamsUseCase),
          tournamentMatchesRepositoryProvider.overrideWithValue(matchesRepo),
          matchReportsRepositoryProvider.overrideWithValue(reportsRepo),
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
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
              child: child!,
            );
          },
          home: const Scaffold(body: StandingsTabView()),
        ),
      );
    }

    testWidgets(
      'US1 & US3 & SC-004: Renders deterministic League Standings Table with tabular-nums and switches to Scorers, Assists & Fair Play rankings without overflow at 130% text scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final league = ChampionshipTournament(
          id: 't-league-gherkin',
          name: 'Liga Gherkin 2026',
          category: 'Libre',
          startDate: baseDate,
          endDate: baseDate.add(const Duration(days: 30)),
          format: TournamentFormat.league,
          status: TournamentStatus.inProgress,
          updatedAt: baseDate,
        );
        await tournamentsRepo.saveTournament(league);

        final homeTeam = TournamentTeam(
          id: 'team-local',
          tournamentId: league.id,
          name: 'Equipo Local',
          shortCode: 'LOC',
          eligibilityStatus: TeamEligibilityStatus.eligible,
          players: const [
            RegisteredPlayer(
              id: 'pl-1',
              fullName: 'Mateo Goleador',
              documentId: '9001',
              shirtNumber: 9,
              position: PlayerPosition.forward,
              isEligible: true,
            ),
            RegisteredPlayer(
              id: 'pl-2',
              fullName: 'Lucas Asistente',
              documentId: '9002',
              shirtNumber: 10,
              position: PlayerPosition.midfielder,
              isEligible: true,
            ),
          ],
        );
        final awayTeam = TournamentTeam(
          id: 'team-visitante',
          tournamentId: league.id,
          name: 'Equipo Visitante',
          shortCode: 'VIS',
          eligibilityStatus: TeamEligibilityStatus.eligible,
          players: const [
            RegisteredPlayer(
              id: 'pl-3',
              fullName: 'Pedro Visitante',
              documentId: '9003',
              shirtNumber: 8,
              position: PlayerPosition.midfielder,
              isEligible: true,
            ),
          ],
        );
        await teamsRepo.saveTeam(homeTeam);
        await teamsRepo.saveTeam(awayTeam);

        final match = ChampionshipMatch(
          id: 'm-league-1',
          tournamentId: league.id,
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: homeTeam.id,
          awayTeamId: awayTeam.id,
          status: MatchStatus.completed,
          homeScore: 2,
          awayScore: 1,
        );
        await matchesRepo.saveMatch(match);

        final closedReport = DigitalMatchReport(
          matchId: match.id,
          tournamentId: league.id,
          homeTeamId: homeTeam.id,
          awayTeamId: awayTeam.id,
          homeScore: 2,
          awayScore: 1,
          currentPeriod: MatchPeriod.closed,
          closedAt: baseDate,
          events: [
            MatchEvent(
              id: 'ev-g1',
              matchId: match.id,
              type: MatchEventType.goal,
              minute: 10,
              teamId: homeTeam.id,
              primaryPlayerId: 'pl-1',
              primaryPlayerName: 'Mateo Goleador',
              primaryPlayerShirtNumber: 9,
              secondaryPlayerId: 'pl-2',
              secondaryPlayerName: 'Lucas Asistente',
              secondaryPlayerShirtNumber: 10,
              createdAt: baseDate,
            ),
            MatchEvent(
              id: 'ev-g2',
              matchId: match.id,
              type: MatchEventType.goal,
              minute: 55,
              teamId: homeTeam.id,
              primaryPlayerId: 'pl-1',
              primaryPlayerName: 'Mateo Goleador',
              primaryPlayerShirtNumber: 9,
              createdAt: baseDate,
            ),
            MatchEvent(
              id: 'ev-g3',
              matchId: match.id,
              type: MatchEventType.goal,
              minute: 70,
              teamId: awayTeam.id,
              primaryPlayerId: 'pl-3',
              primaryPlayerName: 'Pedro Visitante',
              primaryPlayerShirtNumber: 8,
              createdAt: baseDate,
            ),
            MatchEvent(
              id: 'ev-rc1',
              matchId: match.id,
              type: MatchEventType.directRedCard,
              minute: 82,
              teamId: awayTeam.id,
              primaryPlayerId: 'pl-3',
              primaryPlayerName: 'Pedro Visitante',
              primaryPlayerShirtNumber: 8,
              createdAt: baseDate,
            ),
          ],
        );
        await reportsRepo.saveReport(closedReport);

        // Render at 130% text scale to verify SC-004 (0 RenderFlex overflows)
        await tester.pumpWidget(buildTestHarness(textScaleFactor: 1.3));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('standings_table_card')), findsOneWidget);
        expect(
          find.byKey(const Key('standings_row_team-local')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('standings_row_team-visitante')),
          findsOneWidget,
        );
        expect(find.text('Equipo Local (LOC)'), findsOneWidget);
        expect(find.text('+1'), findsOneWidget);

        // Switch to Rankings view (US3)
        final rankingsChip = find.byKey(
          const Key('competitive_view_selector_rankings'),
        );
        await tester.scrollUntilVisible(
          rankingsChip,
          250,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(rankingsChip);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('rankings_section_card')), findsOneWidget);
        expect(find.byKey(const Key('scorer_row_pl-1')), findsOneWidget);
        expect(find.text('Mateo Goleador (#9)'), findsOneWidget);
        expect(find.text('2 goles'), findsOneWidget);

        // Switch to Asistencias
        await tester.tap(find.byKey(const Key('rankings_category_assists')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('assist_row_pl-2')), findsOneWidget);
        expect(find.text('Lucas Asistente (#10)'), findsOneWidget);

        // Switch to Fair Play
        await tester.tap(find.byKey(const Key('rankings_category_fair_play')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('fair_play_row_team-local')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('fair_play_row_team-visitante')),
          findsOneWidget,
        );
        expect(find.text('-3 pts FP'), findsOneWidget);
      },
    );

    testWidgets(
      'US2: Renders Knockout Bracket rounds, penalty shootout badges, automatic winner advancement, and 2D panoramic viewer',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 915));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final cup = ChampionshipTournament(
          id: 't-cup-gherkin',
          name: 'Copa Eliminatoria Gherkin',
          category: 'Libre',
          startDate: baseDate,
          endDate: baseDate.add(const Duration(days: 20)),
          format: TournamentFormat.knockoutCup,
          status: TournamentStatus.inProgress,
          rules: const TournamentRulesConfig(
            knockoutConfig: KnockoutStageConfig(
              startingRound: KnockoutRound.quarterFinals,
              directPenaltyShootoutOnDraw: true,
            ),
          ),
          updatedAt: baseDate,
        );
        await tournamentsRepo.saveTournament(cup);

        final teams = List<TournamentTeam>.generate(8, (i) {
          final idx = i + 1;
          return TournamentTeam(
            id: 'cup-team-$idx',
            tournamentId: cup.id,
            name: 'Club Copa $idx',
            shortCode: 'CC$idx',
            eligibilityStatus: TeamEligibilityStatus.eligible,
          );
        });
        for (final t in teams) {
          await teamsRepo.saveTeam(t);
        }

        // Quarter-Final 1 won 3-1 by Club Copa 1; Quarter-Final 2 drawn 1-1 and won 5-4 on penalties by Club Copa 4
        final qf1 = ChampionshipMatch(
          id: 'match-${cup.id}-ko-quarterFinals-1',
          tournamentId: cup.id,
          roundNumber: 1,
          roundName: 'Cuartos de Final',
          homeTeamId: 'cup-team-1',
          awayTeamId: 'cup-team-2',
          status: MatchStatus.completed,
          homeScore: 3,
          awayScore: 1,
        );
        final qf2 = ChampionshipMatch(
          id: 'match-${cup.id}-ko-quarterFinals-2',
          tournamentId: cup.id,
          roundNumber: 1,
          roundName: 'Cuartos de Final',
          homeTeamId: 'cup-team-3',
          awayTeamId: 'cup-team-4',
          status: MatchStatus.completed,
          homeScore: 1,
          awayScore: 1,
          homePenaltyScore: 4,
          awayPenaltyScore: 5,
        );
        await matchesRepo.saveMatchesBatch([qf1, qf2]);

        await tester.pumpWidget(buildTestHarness());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('knockout_bracket_card')), findsOneWidget);
        expect(
          find.byKey(const Key('bracket_tie_node_ko-quarterFinals-0')),
          findsOneWidget,
        );
        expect(find.text('Penales: 4 - 5'), findsOneWidget);
        expect(find.text('Clasifica: Club Copa 1'), findsOneWidget);
        expect(find.text('Clasifica: Club Copa 4'), findsOneWidget);

        // Tap Semifinales round chip to verify automatic advancement of Club Copa 1 and Club Copa 4
        final sfChip = find.byKey(const Key('bracket_round_chip_semiFinals'));
        await tester.scrollUntilVisible(
          sfChip,
          250,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(sfChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('bracket_tie_node_ko-semiFinals-0')),
          findsOneWidget,
        );
        expect(find.text('Club Copa 1 (CC1)'), findsOneWidget);
        expect(find.text('Club Copa 4 (CC4)'), findsOneWidget);

        // Switch to 2D Panoramic Viewer mode
        final panoramicChip = find.byKey(
          const Key('bracket_mode_panoramic_chip'),
        );
        await tester.tap(panoramicChip);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('knockout_panoramic_2d_viewer')),
          findsOneWidget,
        );
      },
    );
  });
}
