import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/calculate_tournament_standings_and_rankings_use_case.dart';
import 'package:vifutbol/application/use_cases/close_tournament_season_use_case.dart';
import 'package:vifutbol/application/use_cases/fixture_scheduling_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_tournament_news_use_cases.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_event.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_news_category.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_reports_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_season_honor_roll_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_news_repository.dart';

class _FakeTournamentsRepository implements TournamentsRepository {
  final Map<String, ChampionshipTournament> _tournaments = {};

  @override
  Future<List<ChampionshipTournament>> loadTournaments() async =>
      _tournaments.values.toList();

  @override
  Future<ChampionshipTournament> saveTournament(
    ChampionshipTournament tournament,
  ) async {
    _tournaments[tournament.id] = tournament;
    return tournament;
  }

  @override
  Future<TournamentDraft?> loadDraft() async => null;

  @override
  Future<void> saveDraft(TournamentDraft draft) async {}

  @override
  Future<void> clearDraft() async {}
}

class _InMemoryStorage implements LocalStorageRepository {
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

void main() {
  final env = EnvironmentConfig.development();

  late _InMemoryStorage storage;
  late _FakeTournamentsRepository tournamentsRepo;
  late LocalTeamsRepository teamsRepo;
  late LocalTournamentMatchesRepository matchesRepo;
  late LocalMatchReportsRepository reportsRepo;
  late LocalSeasonHonorRollRepository honorRollRepo;
  late CalculateTournamentStandingsAndRankingsUseCase calculateStandingsUseCase;
  late CloseTournamentSeasonUseCase closeSeasonUseCase;

  final sampleTournament = ChampionshipTournament(
    id: 'tourn-league-1',
    name: 'Liga de Primera',
    category: 'Libre',
    startDate: DateTime(2026, 2, 1),
    endDate: DateTime(2026, 6, 1),
    format: TournamentFormat.league,
    status: TournamentStatus.inProgress,
    updatedAt: DateTime(2026, 2, 1),
  );

  final playerA = const RegisteredPlayer(
    id: 'p-1',
    fullName: 'Goleador Estrella',
    documentId: '12345678',
    shirtNumber: 9,
    position: PlayerPosition.forward,
    isEligible: true,
  );

  final teamA = TournamentTeam(
    id: 'team-1',
    tournamentId: 'tourn-league-1',
    name: 'Leones Dorados',
    shortCode: 'LEO',
    players: [playerA],
  );

  final teamB = TournamentTeam(
    id: 'team-2',
    tournamentId: 'tourn-league-1',
    name: 'Tigres Azules',
    shortCode: 'TIG',
  );

  setUp(() async {
    storage = _InMemoryStorage();
    tournamentsRepo = _FakeTournamentsRepository();
    teamsRepo = LocalTeamsRepository(storage: storage, config: env);
    matchesRepo = LocalTournamentMatchesRepository(
      storage: storage,
      config: env,
    );
    reportsRepo = LocalMatchReportsRepository(storage: storage, config: env);
    honorRollRepo = LocalSeasonHonorRollRepository(
      storage: storage,
      config: env,
    );

    calculateStandingsUseCase = CalculateTournamentStandingsAndRankingsUseCase(
      tournamentsRepository: tournamentsRepo,
      teamsRepository: teamsRepo,
      tournamentMatchesRepository: matchesRepo,
      matchReportsRepository: reportsRepo,
    );

    closeSeasonUseCase = CloseTournamentSeasonUseCase(
      tournamentsRepository: tournamentsRepo,
      teamsRepository: teamsRepo,
      matchesRepository: matchesRepo,
      reportsRepository: reportsRepo,
      honorRollRepository: honorRollRepo,
      calculateStandingsUseCase: calculateStandingsUseCase,
    );

    await tournamentsRepo.saveTournament(sampleTournament);
    await teamsRepo.saveTeam(teamA);
    await teamsRepo.saveTeam(teamB);
  });

  group('CloseTournamentSeasonUseCase', () {
    test(
      'throws UnauthorizedRoleFailure when actor is not organizer',
      () async {
        expect(
          () => closeSeasonUseCase.previewHonorRoll(
            tournament: sampleTournament,
            actorRole: UserRole.player,
          ),
          throwsA(isA<UnauthorizedRoleFailure>()),
        );
      },
    );

    test(
      'throws TournamentValidationFailure when league tournament has pending matches',
      () async {
        final pendingMatch = ChampionshipMatch(
          id: 'm-pending',
          tournamentId: 'tourn-league-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          status: MatchStatus.pendingSchedule,
        );
        await matchesRepo.saveMatch(pendingMatch);

        expect(
          () => closeSeasonUseCase.previewHonorRoll(
            tournament: sampleTournament,
            actorRole: UserRole.organizer,
          ),
          throwsA(
            predicate(
              (e) =>
                  e is TournamentValidationFailure &&
                  e.message ==
                      CloseTournamentSeasonUseCase.pendingMatchesMessage,
            ),
          ),
        );
      },
    );

    test(
      'throws TournamentValidationFailure when closeSeason is called without two-step confirmation',
      () async {
        expect(
          () => closeSeasonUseCase.closeSeason(
            tournament: sampleTournament,
            actorRole: UserRole.organizer,
            isTwoStepConfirmed: false,
          ),
          throwsA(
            predicate(
              (e) =>
                  e is TournamentValidationFailure &&
                  e.code ==
                      TournamentValidationErrorCode.missingTwoStepConfirmation,
            ),
          ),
        );
      },
    );

    test(
      'calculates deterministic honor roll and closes league season successfully',
      () async {
        // Match completed: Leones (3) - Tigres (1), Goleador Estrella scored 3
        final completedMatch = ChampionshipMatch(
          id: 'm-1',
          tournamentId: 'tourn-league-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          status: MatchStatus.completed,
          homeScore: 3,
          awayScore: 1,
        );
        await matchesRepo.saveMatch(completedMatch);

        final goalEvent = MatchEvent(
          id: 'event-goal-1',
          matchId: 'm-1',
          type: MatchEventType.goal,
          minute: 15,
          teamId: 'team-1',
          primaryPlayerId: 'p-1',
          primaryPlayerName: 'Player One',
          primaryPlayerShirtNumber: 9,
        );

        final report = DigitalMatchReport(
          matchId: 'm-1',
          tournamentId: 'tourn-league-1',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          homeScore: 3,
          awayScore: 1,
          currentPeriod: MatchPeriod.closed,
          events: [goalEvent],
        );
        await reportsRepo.saveReport(report);

        // Preview honor roll
        final preview = await closeSeasonUseCase.previewHonorRoll(
          tournament: sampleTournament,
          actorRole: UserRole.organizer,
        );

        expect(preview.championTeamId, equals('team-1'));
        expect(preview.championTeamName, equals('Leones Dorados'));
        expect(preview.runnerUpTeamId, equals('team-2'));
        expect(preview.runnerUpTeamName, equals('Tigres Azules'));
        expect(preview.topScorerPlayerId, equals('p-1'));
        expect(preview.topScorerGoals, equals(1));
        expect(preview.bestDefenseTeamId, equals('team-1'));
        expect(preview.bestDefenseGoalsAgainst, equals(1));

        // Execute closure
        final honorRoll = await closeSeasonUseCase.closeSeason(
          tournament: sampleTournament,
          actorRole: UserRole.organizer,
          isTwoStepConfirmed: true,
        );

        expect(honorRoll.championTeamId, equals('team-1'));

        // Verify tournament status is transitioned to finished
        final updatedTournaments = await tournamentsRepo.loadTournaments();
        final updated = updatedTournaments.firstWhere(
          (t) => t.id == 'tourn-league-1',
        );
        expect(updated.status, equals(TournamentStatus.finished));

        // Verify honor roll is persisted in repository
        final persisted = await honorRollRepo.loadHonorRollForTournament(
          'tourn-league-1',
        );
        expect(persisted, isNotNull);
        expect(persisted!.championTeamName, equals('Leones Dorados'));
      },
    );

    test(
      'calculates knockout final winner as Champion and loser as Runner-Up',
      () async {
        final knockoutTournament = ChampionshipTournament(
          id: 'tourn-ko-1',
          name: 'Copa Eliminatoria',
          category: 'Libre',
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 30),
          format: TournamentFormat.knockoutCup,
          status: TournamentStatus.inProgress,
          updatedAt: DateTime(2026, 5, 1),
        );
        await tournamentsRepo.saveTournament(knockoutTournament);

        final teamC = TournamentTeam(
          id: 'team-c',
          tournamentId: 'tourn-ko-1',
          name: 'Cóndores',
          shortCode: 'CND',
        );
        final teamD = TournamentTeam(
          id: 'team-d',
          tournamentId: 'tourn-ko-1',
          name: 'Delfines',
          shortCode: 'DLF',
        );
        await teamsRepo.saveTeam(teamC);
        await teamsRepo.saveTeam(teamD);

        final finalMatch = ChampionshipMatch(
          id: 'match-final',
          tournamentId: 'tourn-ko-1',
          roundNumber: 4,
          roundName: 'Gran Final',
          homeTeamId: 'team-c',
          awayTeamId: 'team-d',
          status: MatchStatus.completed,
          homeScore: 1,
          awayScore: 2, // Delfines wins away
        );
        await matchesRepo.saveMatch(finalMatch);

        final report = DigitalMatchReport(
          matchId: 'match-final',
          tournamentId: 'tourn-ko-1',
          homeTeamId: 'team-c',
          awayTeamId: 'team-d',
          homeScore: 1,
          awayScore: 2,
          currentPeriod: MatchPeriod.closed,
        );
        await reportsRepo.saveReport(report);

        final honorRoll = await closeSeasonUseCase.closeSeason(
          tournament: knockoutTournament,
          actorRole: UserRole.organizer,
          isTwoStepConfirmed: true,
        );

        expect(honorRoll.championTeamId, equals('team-d'));
        expect(honorRoll.championTeamName, equals('Delfines'));
        expect(honorRoll.runnerUpTeamId, equals('team-c'));
        expect(honorRoll.runnerUpTeamName, equals('Cóndores'));
      },
    );

    test(
      'historical read-only mode rejects team registration on finished tournament',
      () async {
        final finishedTournament = sampleTournament.copyWith(
          status: TournamentStatus.finished,
        );
        final manageTeamsUseCase = ManageTeamsEligibilityUseCase(teamsRepo);

        expect(
          () => manageTeamsUseCase.registerOrUpdateTeam(
            team: TournamentTeam(
              id: 'team-new',
              tournamentId: finishedTournament.id,
              name: 'Nuevo Equipo',
              shortCode: 'NEW',
            ),
            tournament: finishedTournament,
            actorRole: UserRole.organizer,
          ),
          throwsA(isA<TeamEligibilityValidationFailure>()),
        );

        expect(
          () => manageTeamsUseCase.approveTeamEligibility(
            teamId: 'team-1',
            tournament: finishedTournament,
            actorRole: UserRole.organizer,
          ),
          throwsA(isA<TeamEligibilityValidationFailure>()),
        );
      },
    );

    test(
      'historical read-only mode rejects fixture operations on finished tournament',
      () async {
        final finishedTournament = sampleTournament.copyWith(
          status: TournamentStatus.finished,
        );
        final fixtureUseCase = FixtureSchedulingUseCase(
          matchesRepository: matchesRepo,
        );

        expect(
          () => fixtureUseCase.generateRoundRobinFixture(
            tournament: finishedTournament,
            teams: [
              TournamentTeam(
                id: 't-1',
                tournamentId: finishedTournament.id,
                name: 'Team 1',
                shortCode: 'T1',
                eligibilityStatus: TeamEligibilityStatus.eligible,
              ),
              TournamentTeam(
                id: 't-2',
                tournamentId: finishedTournament.id,
                name: 'Team 2',
                shortCode: 'T2',
                eligibilityStatus: TeamEligibilityStatus.eligible,
              ),
            ],
            userRole: UserRole.organizer,
          ),
          throwsA(isA<FixtureScheduleValidationFailure>()),
        );
      },
    );

    test(
      'historical read-only mode rejects publishing news on finished tournament',
      () async {
        final finishedTournament = sampleTournament.copyWith(
          status: TournamentStatus.finished,
        );
        await tournamentsRepo.saveTournament(finishedTournament);
        final newsRepo = LocalTournamentNewsRepository(
          storage: storage,
          config: env,
        );
        final publishNewsUseCase = PublishTournamentNewsUseCase(
          newsRepository: newsRepo,
          tournamentsRepository: tournamentsRepo,
        );

        expect(
          () => publishNewsUseCase.execute(
            newsItem: TournamentNewsItem(
              id: 'news-1',
              tournamentId: finishedTournament.id,
              title: 'Noticia Prohibida',
              body: 'No se debe publicar en torneo finalizado',
              authorUserId: 'org-1',
              authorName: 'Organizador',
              category: TournamentNewsCategory.general,
              publishedAt: DateTime.now(),
            ),
            userRole: UserRole.organizer,
            tournament: finishedTournament,
          ),
          throwsA(isA<TournamentValidationFailure>()),
        );
      },
    );
  });
}
