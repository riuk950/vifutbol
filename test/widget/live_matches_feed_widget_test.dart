import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:vifutbol/application/use_cases/fixture_scheduling_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/matches/widgets/match_card.dart';
import 'package:vifutbol/presentation/shell/tabs/matchday_tab_view.dart';

class _MockStorage implements LocalStorageRepository {
  final Map<String, String> _data = {};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _data[key];

  @override
  Future<void> writeString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> clearNamespace() async => _data.clear();

  @override
  bool get isUsingFallbackMemory => true;
}

void main() {
  testWidgets(
    'Live matches feed highlights inProgress match with EN VIVO badge and tabular scores',
    (tester) async {
      final storage = _MockStorage();
      final config = EnvironmentConfig.production();
      final matchesRepo = LocalTournamentMatchesRepository(
        storage: storage,
        config: config,
      );
      final tournamentsRepo = LocalTournamentsRepository(
        storage: storage,
        config: config,
      );
      final teamsRepo = LocalTeamsRepository(storage: storage, config: config);

      final tournament = ChampionshipTournament(
        id: 'tour-live-1',
        name: 'Torneo Clausura 2026',
        category: 'Libre',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 11, 30),
        format: TournamentFormat.league,
        status: TournamentStatus.inProgress,
        rules: const TournamentRulesConfig(
          pointsForWin: 3,
          pointsForDraw: 1,
          pointsForLoss: 0,
          yellowCardSuspensionLimit: 3,
          minPlayersPerTeam: 7,
          maxPlayersPerTeam: 18,
          halfDurationMinutes: 45,
          leagueRounds: 1,
        ),
        updatedAt: DateTime.now(),
      );
      await tournamentsRepo.saveTournament(tournament);

      final homeTeam = TournamentTeam(
        id: 'team-h',
        tournamentId: 'tour-live-1',
        name: 'Halcones FC',
        shortCode: 'HAL',
        primaryColorHex: 0xFFEF4444,
        secondaryColorHex: 0xFF000000,
      );
      final awayTeam = TournamentTeam(
        id: 'team-a',
        tournamentId: 'tour-live-1',
        name: 'Águilas Doradas',
        shortCode: 'AGU',
        primaryColorHex: 0xFFFFD700,
        secondaryColorHex: 0xFF000000,
      );
      await teamsRepo.saveTeam(homeTeam);
      await teamsRepo.saveTeam(awayTeam);

      final liveMatch = ChampionshipMatch(
        id: 'match-live-1',
        tournamentId: 'tour-live-1',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'team-h',
        awayTeamId: 'team-a',
        status: MatchStatus.inProgress,
        homeScore: 2,
        awayScore: 1,
      );
      await matchesRepo.saveMatch(liveMatch);

      final tournamentsUseCase = ManageTournamentsUseCase(tournamentsRepo);
      final teamsUseCase = ManageTeamsEligibilityUseCase(teamsRepo);
      final fixtureUseCase = FixtureSchedulingUseCase(
        matchesRepository: matchesRepo,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageRepositoryProvider.overrideWithValue(storage),
            environmentConfigProvider.overrideWithValue(config),
            activeUserRoleProvider.overrideWith((ref) => UserRole.fan),
            tournamentMatchesRepositoryProvider.overrideWithValue(matchesRepo),
            tournamentsControllerProvider.overrideWith(
              (ref) => TournamentsController(
                tournamentsRepository: tournamentsRepo,
                manageTournamentsUseCase: tournamentsUseCase,
              )..loadCatalog(),
            ),
            teamsControllerProvider.overrideWith(
              (ref) => TeamsController(
                teamsRepository: teamsRepo,
                manageTeamsEligibilityUseCase: teamsUseCase,
              )..loadTeams(),
            ),
            matchesCatalogControllerProvider.overrideWith(
              (ref) => MatchesCatalogController(
                matchesRepository: matchesRepo,
                fixtureSchedulingUseCase: fixtureUseCase,
              ),
            ),
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
            home: Scaffold(body: MatchdayTabView()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Live Section Header is present
      expect(find.byKey(const Key('live_matches_section')), findsOneWidget);
      expect(find.text('Partidos en Juego'), findsOneWidget);

      // Verify EN VIVO badge is displayed
      expect(find.text('EN VIVO'), findsWidgets);

      // Verify Score is displayed
      expect(find.text('2 - 1'), findsWidgets);

      // Verify MatchCard widget exists
      final matchCardFinder = find.byType(MatchCard).first;
      expect(matchCardFinder, findsOneWidget);
    },
  );
}
