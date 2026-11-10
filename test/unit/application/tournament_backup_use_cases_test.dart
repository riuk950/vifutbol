import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/tournament_backup_use_cases.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/digital_match_report.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_report_enums.dart';
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
  Future<void> deleteTournament(String tournamentId) async {
    _tournaments.remove(tournamentId);
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
  Future<void> writeString(String key, String value) async {
    _data[key] = value;
  }

  Future<void> remove(String key) async {
    _data.remove(key);
  }

  Future<void> clearAll() async {
    _data.clear();
  }

  @override
  Future<void> clearNamespace() async {
    _data.clear();
  }

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
  late LocalTournamentNewsRepository newsRepo;
  late LocalSeasonHonorRollRepository honorRollRepo;

  late ValidateTournamentBackupUseCase validateUseCase;
  late ExportTournamentBackupUseCase exportUseCase;
  late ImportTournamentBackupUseCase importUseCase;

  final sampleTournament = ChampionshipTournament(
    id: 't-test-1',
    name: 'Copa Primavera',
    category: 'Libre',
    startDate: DateTime(2026, 4, 1),
    endDate: DateTime(2026, 6, 30),
    format: TournamentFormat.league,
    status: TournamentStatus.inProgress,
    updatedAt: DateTime(2026, 4, 1),
  );

  final sampleTeamA = TournamentTeam(
    id: 'team-a',
    tournamentId: 't-test-1',
    name: 'Equipo Alfa',
    shortCode: 'ALF',
  );

  final sampleTeamB = TournamentTeam(
    id: 'team-b',
    tournamentId: 't-test-1',
    name: 'Equipo Beta',
    shortCode: 'BET',
  );

  final sampleMatch = ChampionshipMatch(
    id: 'match-1',
    tournamentId: 't-test-1',
    roundNumber: 1,
    roundName: 'Jornada 1',
    homeTeamId: 'team-a',
    awayTeamId: 'team-b',
    scheduledStartTime: DateTime(2026, 4, 10, 10, 0),
    scheduledEndTime: DateTime(2026, 4, 10, 11, 30),
    status: MatchStatus.completed,
    homeScore: 2,
    awayScore: 1,
  );

  final sampleReport = DigitalMatchReport(
    matchId: 'match-1',
    tournamentId: 't-test-1',
    homeTeamId: 'team-a',
    awayTeamId: 'team-b',
    homeScore: 2,
    awayScore: 1,
    currentPeriod: MatchPeriod.closed,
  );

  final sampleNews = TournamentNewsItem(
    id: 'news-1',
    tournamentId: 't-test-1',
    title: 'Inicio de Torneo',
    body: 'Bienvenidos a la Copa Primavera 2026',
    category: TournamentNewsCategory.general,
    authorUserId: 'org-1',
    authorName: 'Comité Organizador',
    publishedAt: DateTime(2026, 4, 1),
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
    newsRepo = LocalTournamentNewsRepository(storage: storage, config: env);
    honorRollRepo = LocalSeasonHonorRollRepository(
      storage: storage,
      config: env,
    );

    validateUseCase = const ValidateTournamentBackupUseCase();
    exportUseCase = ExportTournamentBackupUseCase(
      tournamentsRepository: tournamentsRepo,
      teamsRepository: teamsRepo,
      matchesRepository: matchesRepo,
      reportsRepository: reportsRepo,
      newsRepository: newsRepo,
      honorRollRepository: honorRollRepo,
    );
    importUseCase = ImportTournamentBackupUseCase(
      tournamentsRepository: tournamentsRepo,
      teamsRepository: teamsRepo,
      matchesRepository: matchesRepo,
      reportsRepository: reportsRepo,
      newsRepository: newsRepo,
      honorRollRepository: honorRollRepo,
      validationUseCase: validateUseCase,
    );

    await tournamentsRepo.saveTournament(sampleTournament);
    await teamsRepo.saveTeam(sampleTeamA);
    await teamsRepo.saveTeam(sampleTeamB);
    await matchesRepo.saveMatch(sampleMatch);
    await reportsRepo.saveReport(sampleReport);
    await newsRepo.saveNewsItem(sampleNews);
  });

  group('ValidateTournamentBackupUseCase', () {
    test(
      'returns invalid when JSON is corrupt, empty, or missing formatSignature',
      () {
        expect(validateUseCase.execute('').isValid, isFalse);
        expect(validateUseCase.execute('not a json').isValid, isFalse);
        expect(validateUseCase.execute('{"other": 123}').isValid, isFalse);
        expect(
          validateUseCase.execute('').errorMessage,
          equals(ValidateTournamentBackupUseCase.invalidBackupMessage),
        );
      },
    );

    test(
      'returns invalid when a match references an orphan team that does not exist in package',
      () {
        final invalidPackageJson = jsonEncode({
          'formatSignature': 'vifutbol.tournament_backup',
          'schemaVersion': 1,
          'exportedAt': DateTime.now().toIso8601String(),
          'tournament': sampleTournament.toJson(),
          'teams': [sampleTeamA.toJson()], // only team-a exists
          'matches': [sampleMatch.toJson()], // references team-b (orphan!)
          'matchReports': [],
          'newsItems': [],
        });

        final result = validateUseCase.execute(invalidPackageJson);
        expect(result.isValid, isFalse);
        expect(
          result.errorMessage,
          equals(ValidateTournamentBackupUseCase.invalidBackupMessage),
        );
      },
    );

    test('returns valid when package is self-consistent and well-formed', () {
      final validPackageJson = jsonEncode({
        'formatSignature': 'vifutbol.tournament_backup',
        'schemaVersion': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'tournament': sampleTournament.toJson(),
        'teams': [sampleTeamA.toJson(), sampleTeamB.toJson()],
        'matches': [sampleMatch.toJson()],
        'matchReports': [sampleReport.toJson()],
        'newsItems': [sampleNews.toJson()],
      });

      final result = validateUseCase.execute(validPackageJson);
      expect(result.isValid, isTrue);
      expect(result.package, isNotNull);
      expect(result.package!.tournament.id, equals('t-test-1'));
    });
  });

  group('ExportTournamentBackupUseCase', () {
    test(
      'throws UnauthorizedRoleFailure when actor is not organizer',
      () async {
        expect(
          () => exportUseCase.execute(
            tournamentId: 't-test-1',
            actorRole: UserRole.fan,
          ),
          throwsA(isA<UnauthorizedRoleFailure>()),
        );
      },
    );

    test(
      'organizer exports complete package with all nested entities',
      () async {
        final package = await exportUseCase.execute(
          tournamentId: 't-test-1',
          actorRole: UserRole.organizer,
        );

        expect(package.formatSignature, equals('vifutbol.tournament_backup'));
        expect(package.schemaVersion, equals(1));
        expect(package.tournament.id, equals('t-test-1'));
        expect(package.teams.length, equals(2));
        expect(package.matches.length, equals(1));
        expect(package.matchReports.length, equals(1));
        expect(package.newsItems.length, equals(1));
      },
    );
  });

  group('ImportTournamentBackupUseCase', () {
    test(
      'throws UnauthorizedRoleFailure when actor is not organizer',
      () async {
        expect(
          () => importUseCase.execute(
            rawJson: '{}',
            actorRole: UserRole.coach,
            isTwoStepConfirmed: true,
          ),
          throwsA(isA<UnauthorizedRoleFailure>()),
        );
      },
    );

    test(
      'throws TournamentValidationFailure when isTwoStepConfirmed is false',
      () async {
        expect(
          () => importUseCase.execute(
            rawJson: '{}',
            actorRole: UserRole.organizer,
            isTwoStepConfirmed: false,
          ),
          throwsA(isA<TournamentValidationFailure>()),
        );
      },
    );

    test('aborts without modifying storage when backup is corrupt', () async {
      expect(
        () => importUseCase.execute(
          rawJson: '{"corrupted": true}',
          actorRole: UserRole.organizer,
          isTwoStepConfirmed: true,
        ),
        throwsA(
          predicate(
            (e) =>
                e is TournamentValidationFailure &&
                e.message ==
                    ValidateTournamentBackupUseCase.invalidBackupMessage,
          ),
        ),
      );

      // Verify original tournament and data remained completely intact
      final tournaments = await tournamentsRepo.loadTournaments();
      expect(tournaments.any((t) => t.id == 't-test-1'), isTrue);
    });

    test(
      'successfully restores package and performs isolated upsert without deleting other tournaments',
      () async {
        // Create a second tournament that must NOT be deleted by the restore
        final otherTournament = ChampionshipTournament(
          id: 't-other-2',
          name: 'Liga de Invierno',
          category: 'Senior',
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 9, 30),
          format: TournamentFormat.league,
          updatedAt: DateTime(2026, 7, 1),
        );
        await tournamentsRepo.saveTournament(otherTournament);

        final otherTeam = TournamentTeam(
          id: 'team-other',
          tournamentId: 't-other-2',
          name: 'Club Vecinal',
          shortCode: 'VEC',
        );
        await teamsRepo.saveTeam(otherTeam);

        // Prepare updated backup for t-test-1 with a renamed tournament and new team
        final updatedTournament = sampleTournament.copyWith(
          name: 'Copa Primavera Actualizada',
        );
        final newTeamC = TournamentTeam(
          id: 'team-c',
          tournamentId: 't-test-1',
          name: 'Equipo Gamma',
          shortCode: 'GAM',
        );

        final validPackageJson = jsonEncode({
          'formatSignature': 'vifutbol.tournament_backup',
          'schemaVersion': 1,
          'exportedAt': DateTime.now().toIso8601String(),
          'tournament': updatedTournament.toJson(),
          'teams': [newTeamC.toJson()],
          'matches': [],
          'matchReports': [],
          'newsItems': [],
        });

        final restored = await importUseCase.execute(
          rawJson: validPackageJson,
          actorRole: UserRole.organizer,
          isTwoStepConfirmed: true,
        );

        expect(restored.name, equals('Copa Primavera Actualizada'));

        // Check t-test-1 teams was replaced with team-c
        final test1Teams = await teamsRepo.loadTeamsForTournament('t-test-1');
        expect(test1Teams.length, equals(1));
        expect(test1Teams.first.id, equals('team-c'));

        // Crucial: check other tournament and team-other were preserved!
        final allTournaments = await tournamentsRepo.loadTournaments();
        expect(allTournaments.any((t) => t.id == 't-other-2'), isTrue);

        final otherTeams = await teamsRepo.loadTeamsForTournament('t-other-2');
        expect(otherTeams.length, equals(1));
        expect(otherTeams.first.id, equals('team-other'));
      },
    );
  });
}
