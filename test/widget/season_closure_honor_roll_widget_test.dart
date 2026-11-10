import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/backup_and_season_closure_providers.dart';
import 'package:vifutbol/application/providers/digital_match_report_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournament_news_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_event.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';
import 'package:vifutbol/domain/entities/season_honor_roll.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_reports_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_season_honor_roll_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_news_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/news/tournament_news_feed_view.dart';
import 'package:vifutbol/presentation/shell/tabs/standings_tab_view.dart';
import 'package:vifutbol/presentation/standings/widgets/season_honor_roll_card.dart';
import 'package:vifutbol/presentation/tournaments/widgets/season_closure_confirmation_dialog.dart';

class _MockStorage implements LocalStorageRepository {
  final Map<String, String> _data = {};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _data[key];

  @override
  Future<void> writeString(String key, String value) async =>
      _data[key] = value;

  Future<void> remove(String key) async => _data.remove(key);

  Future<void> clearAll() async => _data.clear();

  @override
  Future<void> clearNamespace() async => _data.clear();

  @override
  bool get isUsingFallbackMemory => false;
}

class _FakeTournamentsRepo implements TournamentsRepository {
  final Map<String, ChampionshipTournament> tournaments = {};

  @override
  Future<List<ChampionshipTournament>> loadTournaments() async =>
      tournaments.values.toList();

  @override
  Future<ChampionshipTournament> saveTournament(
    ChampionshipTournament tournament,
  ) async {
    tournaments[tournament.id] = tournament;
    return tournament;
  }

  @override
  Future<void> deleteTournament(String tournamentId) async {
    tournaments.remove(tournamentId);
  }

  @override
  Future<TournamentDraft?> loadDraft() async => null;

  @override
  Future<void> saveDraft(TournamentDraft draft) async {}

  @override
  Future<void> clearDraft() async {}
}

void main() {
  final config = EnvironmentConfig.development();
  late _MockStorage storage;
  late _FakeTournamentsRepo tournamentsRepo;
  late LocalTeamsRepository teamsRepo;
  late LocalTournamentMatchesRepository matchesRepo;
  late LocalMatchReportsRepository reportsRepo;
  late LocalSeasonHonorRollRepository honorRollRepo;
  late LocalTournamentNewsRepository newsRepo;

  final sampleTournament = ChampionshipTournament(
    id: 't-test-1',
    name: 'Copa Primavera 2026',
    format: TournamentFormat.league,
    category: 'Libre',
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 6, 1),
    status: TournamentStatus.inProgress,
    rules: const TournamentRulesConfig(),
    updatedAt: DateTime(2026, 1, 1),
  );

  final sampleHonorRoll = SeasonHonorRoll(
    tournamentId: 't-test-1',
    tournamentName: 'Copa Primavera 2026',
    closedAt: DateTime(2026, 6, 2),
    championTeamId: 'team-1',
    championTeamName: 'Los Rayos',
    championShortCode: 'RAY',
    runnerUpTeamId: 'team-2',
    runnerUpTeamName: 'Halcones',
    runnerUpShortCode: 'HAL',
    topScorerPlayerId: 'p-1',
    topScorerPlayerName: 'Carlos Ruiz',
    topScorerTeamName: 'Los Rayos',
    topScorerGoals: 12,
    bestDefenseTeamId: 'team-1',
    bestDefenseTeamName: 'Los Rayos',
    bestDefenseShortCode: 'RAY',
    bestDefenseGoalsAgainst: 4,
  );

  setUp(() async {
    storage = _MockStorage();
    tournamentsRepo = _FakeTournamentsRepo();
    teamsRepo = LocalTeamsRepository(storage: storage, config: config);
    matchesRepo = LocalTournamentMatchesRepository(
      storage: storage,
      config: config,
    );
    reportsRepo = LocalMatchReportsRepository(storage: storage, config: config);
    honorRollRepo = LocalSeasonHonorRollRepository(
      storage: storage,
      config: config,
    );
    newsRepo = LocalTournamentNewsRepository(storage: storage, config: config);

    await tournamentsRepo.saveTournament(sampleTournament);
    await teamsRepo.replaceTeamsForTournament('t-test-1', [
      TournamentTeam(
        id: 'team-1',
        tournamentId: 't-test-1',
        name: 'Los Rayos',
        shortCode: 'RAY',
        primaryColorHex: 0xFFFF0000,
        secondaryColorHex: 0xFF000000,
      ),
      TournamentTeam(
        id: 'team-2',
        tournamentId: 't-test-1',
        name: 'Halcones',
        shortCode: 'HAL',
        primaryColorHex: 0xFF00FF00,
        secondaryColorHex: 0xFFFFFFFF,
      ),
    ]);
  });

  Widget buildTestApp({
    required Widget child,
    UserRole role = UserRole.organizer,
    double textScaleFactor = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        localStorageRepositoryProvider.overrideWithValue(storage),
        environmentConfigProvider.overrideWithValue(config),
        tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
        teamsRepositoryProvider.overrideWithValue(teamsRepo),
        tournamentMatchesRepositoryProvider.overrideWithValue(matchesRepo),
        matchReportsRepositoryProvider.overrideWithValue(reportsRepo),
        seasonHonorRollRepositoryProvider.overrideWithValue(honorRollRepo),
        tournamentNewsRepositoryProvider.overrideWithValue(newsRepo),
        activeUserRoleProvider.overrideWith((ref) => role),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScaleFactor),
            size: const Size(400, 800),
          ),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('SeasonHonorRollCard', () {
    testWidgets('renders all four honors with correct details', (tester) async {
      await tester.pumpWidget(
        buildTestApp(child: SeasonHonorRollCard(honorRoll: sampleHonorRoll)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('season_honor_roll_card')), findsOneWidget);
      expect(find.text('Cuadro de Honor Oficial'), findsOneWidget);
      expect(
        find.text('Temporada Finalizada · Consulta Histórica'),
        findsOneWidget,
      );
      expect(
        find.text('Los Rayos (RAY)'),
        findsNWidgets(2),
      ); // Champion & Best Defense
      expect(find.text('Halcones (HAL)'), findsOneWidget); // Runner-Up
      expect(
        find.text('Carlos Ruiz (Los Rayos)'),
        findsOneWidget,
      ); // Top Scorer
      expect(find.text('12 goles'), findsOneWidget);
      expect(find.text('4 goles recibidos'), findsOneWidget);
    });

    testWidgets('renders "Sin goles registrados" when topScorerGoals is 0', (
      tester,
    ) async {
      final zeroGoalsHonorRoll = sampleHonorRoll.copyWith(
        topScorerGoals: 0,
        topScorerPlayerName: null,
      );

      await tester.pumpWidget(
        buildTestApp(child: SeasonHonorRollCard(honorRoll: zeroGoalsHonorRoll)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin goles registrados'), findsOneWidget);
    });

    testWidgets(
      'T029: zero RenderFlex overflows at 320px width and 130% text scaling',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildTestApp(
            textScaleFactor: 1.3,
            child: SingleChildScrollView(
              child: SeasonHonorRollCard(honorRoll: sampleHonorRoll),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('season_honor_roll_card')), findsOneWidget);
      },
    );
  });

  group('SeasonClosureConfirmationDialog', () {
    testWidgets('displays pending matches error when matches are not completed', (
      tester,
    ) async {
      // Add pending match
      final match = ChampionshipMatch(
        id: 'm-pending',
        tournamentId: 't-test-1',
        roundNumber: 1,
        roundName: 'Fecha 1',
        homeTeamId: 'team-1',
        awayTeamId: 'team-2',
        status: MatchStatus.pendingSchedule,
      );
      await matchesRepo.saveMatch(match);

      await tester.pumpWidget(
        buildTestApp(
          child: SeasonClosureConfirmationDialog(
            tournament: sampleTournament,
            actorRole: UserRole.organizer,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('season_closure_error_notice')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Todos los partidos obligatorios deben estar finalizados antes de cerrar el campeonato.',
        ),
        findsOneWidget,
      );
      // Confirm button is disabled
      final confirmBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('season_closure_confirm_button')),
      );
      expect(confirmBtn.onPressed, isNull);
    });

    testWidgets(
      'previews honor roll and enables confirm button only upon checkbox check',
      (tester) async {
        // Add completed match
        final match = ChampionshipMatch(
          id: 'm-completed',
          tournamentId: 't-test-1',
          roundNumber: 1,
          roundName: 'Fecha 1',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          status: MatchStatus.completed,
          homeScore: 2,
          awayScore: 0,
        );
        await matchesRepo.saveMatch(match);

        final report = DigitalMatchReport(
          matchId: 'm-completed',
          tournamentId: 't-test-1',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          homeScore: 2,
          awayScore: 0,
          currentPeriod: MatchPeriod.closed,
          events: [
            MatchEvent(
              id: 'e-1',
              matchId: 'm-completed',
              type: MatchEventType.goal,
              minute: 10,
              teamId: 'team-1',
              primaryPlayerId: 'p-1',
              primaryPlayerName: 'Player One',
            ),
          ],
        );
        await reportsRepo.saveReport(report);

        await tester.pumpWidget(
          buildTestApp(
            child: SeasonClosureConfirmationDialog(
              tournament: sampleTournament,
              actorRole: UserRole.organizer,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify preview
        expect(
          find.byKey(const Key('season_closure_honor_roll_preview')),
          findsOneWidget,
        );
        expect(find.text('Los Rayos (RAY)'), findsOneWidget); // Champ
        expect(
          find.textContaining('0 goles recibidos'),
          findsOneWidget,
        ); // best def

        // Confirm button disabled initially
        var confirmBtn = tester.widget<ElevatedButton>(
          find.byKey(const Key('season_closure_confirm_button')),
        );
        expect(confirmBtn.onPressed, isNull);

        // Tap checkbox
        await tester.tap(
          find.byKey(const Key('season_closure_confirm_checkbox')),
        );
        await tester.pumpAndSettle();

        // Confirm button enabled
        confirmBtn = tester.widget<ElevatedButton>(
          find.byKey(const Key('season_closure_confirm_button')),
        );
        expect(confirmBtn.onPressed, isNotNull);

        // Tap confirm button
        await tester.tap(
          find.byKey(const Key('season_closure_confirm_button')),
        );
        await tester.pumpAndSettle();

        // Verify tournament was closed and saved in repository
        final savedTournaments = await tournamentsRepo.loadTournaments();
        expect(savedTournaments.first.status, TournamentStatus.finished);

        // Verify honor roll was saved
        final savedHonorRoll = await honorRollRepo.loadHonorRollForTournament(
          't-test-1',
        );
        expect(savedHonorRoll, isNotNull);
        expect(savedHonorRoll!.championTeamName, 'Los Rayos');
      },
    );

    testWidgets(
      'T029: dialog zero overflows at 320px width and 130% text scaling',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildTestApp(
            textScaleFactor: 1.3,
            child: SeasonClosureConfirmationDialog(
              tournament: sampleTournament,
              actorRole: UserRole.organizer,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('StandingsTabView integration with SeasonHonorRollCard', () {
    testWidgets(
      'shows SeasonHonorRollCard when tournament is finished across roles',
      (tester) async {
        final finishedTournament = sampleTournament.copyWith(
          status: TournamentStatus.finished,
        );
        await tournamentsRepo.saveTournament(finishedTournament);
        await honorRollRepo.saveHonorRoll(sampleHonorRoll);

        for (final role in [UserRole.organizer, UserRole.coach, UserRole.fan]) {
          await tester.pumpWidget(
            buildTestApp(role: role, child: const StandingsTabView()),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('season_honor_roll_card')),
            findsOneWidget,
            reason: 'SeasonHonorRollCard should be visible for role $role',
          );
        }
      },
    );

    testWidgets(
      'T028: finished tournament enforces read-only in UI while keeping backup enabled',
      (tester) async {
        final finishedTournament = sampleTournament.copyWith(
          status: TournamentStatus.finished,
        );
        await tournamentsRepo.saveTournament(finishedTournament);
        await honorRollRepo.saveHonorRoll(sampleHonorRoll);

        await tester.pumpWidget(
          buildTestApp(
            role: UserRole.organizer,
            child: const StandingsTabView(),
          ),
        );
        await tester.pumpAndSettle();

        // Rules card hides write actions
        expect(
          find.byKey(const Key('edit_tournament_rules_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('start_tournament_status_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('finish_tournament_status_button')),
          findsNothing,
        );

        // Rules card keeps backup action enabled for organizer
        expect(
          find.byKey(const Key('tournament_backup_action_button')),
          findsOneWidget,
        );

        // Rules card shows historical notice banner
        expect(
          find.byKey(const Key('season_readonly_notice_banner')),
          findsOneWidget,
        );

        // Teams section hides register team button
        expect(
          find.byKey(const Key('register_team_action_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'T028: TournamentNewsFeedView displays readonly badge and hides create button when finished',
      (tester) async {
        final finishedTournament = sampleTournament.copyWith(
          status: TournamentStatus.finished,
        );
        await tournamentsRepo.saveTournament(finishedTournament);

        await tester.pumpWidget(
          buildTestApp(
            role: UserRole.organizer,
            child: SingleChildScrollView(
              child: TournamentNewsFeedView(
                tournamentId: finishedTournament.id,
                isHistoricalReadOnly: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('news_readonly_badge')), findsOneWidget);
        expect(find.byKey(const Key('create_news_button')), findsNothing);
      },
    );
  });
}
