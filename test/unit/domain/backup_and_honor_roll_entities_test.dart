import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/backup_validation_result.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/season_honor_roll.dart';
import 'package:vifutbol/domain/entities/tournament_backup_package.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';

void main() {
  group('SeasonHonorRoll Domain Entity', () {
    test(
      'creates valid SeasonHonorRoll and correctly evaluates hasTopScorer',
      () {
        final honorRoll = SeasonHonorRoll(
          tournamentId: 't-1',
          tournamentName: 'Liga Apertura',
          closedAt: DateTime(2026, 6, 30),
          championTeamId: 'team-1',
          championTeamName: 'Atlético Norte',
          championShortCode: 'ATN',
          runnerUpTeamId: 'team-2',
          runnerUpTeamName: 'Deportivo Sur',
          runnerUpShortCode: 'DPS',
          topScorerPlayerId: 'p-1',
          topScorerPlayerName: 'Carlos P.',
          topScorerTeamName: 'Atlético Norte',
          topScorerGoals: 10,
          bestDefenseTeamId: 'team-1',
          bestDefenseTeamName: 'Atlético Norte',
          bestDefenseShortCode: 'ATN',
          bestDefenseGoalsAgainst: 4,
        );

        expect(honorRoll.hasTopScorer, isTrue);
        expect(honorRoll.championTeamId, equals('team-1'));
        expect(honorRoll.runnerUpTeamId, equals('team-2'));
      },
    );

    test('evaluates hasTopScorer as false when no goals or player is null', () {
      final honorRoll = SeasonHonorRoll(
        tournamentId: 't-1',
        tournamentName: 'Liga Apertura',
        closedAt: DateTime(2026, 6, 30),
        championTeamId: 'team-1',
        championTeamName: 'Atlético Norte',
        championShortCode: 'ATN',
        runnerUpTeamId: 'team-2',
        runnerUpTeamName: 'Deportivo Sur',
        runnerUpShortCode: 'DPS',
        topScorerPlayerId: null,
        topScorerGoals: 0,
        bestDefenseTeamId: 'team-2',
        bestDefenseTeamName: 'Deportivo Sur',
        bestDefenseShortCode: 'DPS',
        bestDefenseGoalsAgainst: 6,
      );

      expect(honorRoll.hasTopScorer, isFalse);
    });

    test('serializes to and from JSON correctly', () {
      final honorRoll = SeasonHonorRoll(
        tournamentId: 't-1',
        tournamentName: 'Liga Apertura',
        closedAt: DateTime(2026, 6, 30, 18, 0),
        championTeamId: 'team-1',
        championTeamName: 'Atlético Norte',
        championShortCode: 'ATN',
        runnerUpTeamId: 'team-2',
        runnerUpTeamName: 'Deportivo Sur',
        runnerUpShortCode: 'DPS',
        topScorerPlayerId: 'p-1',
        topScorerPlayerName: 'Carlos P.',
        topScorerTeamName: 'Atlético Norte',
        topScorerGoals: 8,
        bestDefenseTeamId: 'team-1',
        bestDefenseTeamName: 'Atlético Norte',
        bestDefenseShortCode: 'ATN',
        bestDefenseGoalsAgainst: 3,
      );

      final json = honorRoll.toJson();
      final restored = SeasonHonorRoll.fromJson(json);

      expect(restored, equals(honorRoll));
      expect(restored.championTeamName, equals('Atlético Norte'));
      expect(restored.topScorerGoals, equals(8));
    });

    test('throws AssertionError if championTeamId == runnerUpTeamId', () {
      expect(
        () => SeasonHonorRoll(
          tournamentId: 't-1',
          tournamentName: 'Liga Apertura',
          closedAt: DateTime(2026, 6, 30),
          championTeamId: 'same-team',
          championTeamName: 'Mismo Equipo',
          championShortCode: 'EQP',
          runnerUpTeamId: 'same-team',
          runnerUpTeamName: 'Mismo Equipo',
          runnerUpShortCode: 'EQP',
          bestDefenseTeamId: 'same-team',
          bestDefenseTeamName: 'Mismo Equipo',
          bestDefenseShortCode: 'EQP',
          bestDefenseGoalsAgainst: 5,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('TournamentBackupPackage Domain Entity', () {
    test('computes suggestedFileName and totalPlayersCount correctly', () {
      final tournament = ChampionshipTournament(
        id: 't-100',
        name: 'Torneo Relámpago',
        category: 'Libre',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31),
        format: TournamentFormat.knockoutCup,
        updatedAt: DateTime(2026, 3, 1),
      );

      final package = TournamentBackupPackage(
        exportedAt: DateTime(2026, 11, 5, 12, 0),
        tournament: tournament,
      );

      expect(package.suggestedFileName, equals('respaldo_t-100_20261105.json'));
      expect(
        package.formatSignature,
        equals(TournamentBackupPackage.currentSignature),
      );
      expect(
        package.schemaVersion,
        equals(TournamentBackupPackage.currentSchemaVersion),
      );
      expect(package.totalPlayersCount, equals(0));
    });

    test('serializes to and from JSON correctly', () {
      final tournament = ChampionshipTournament(
        id: 't-100',
        name: 'Torneo Relámpago',
        category: 'Libre',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31),
        format: TournamentFormat.knockoutCup,
        updatedAt: DateTime(2026, 3, 1),
      );

      final package = TournamentBackupPackage(
        exportedAt: DateTime(2026, 11, 5, 12, 0),
        tournament: tournament,
      );

      final json = package.toJson();
      final restored = TournamentBackupPackage.fromJson(json);

      expect(restored.formatSignature, equals(package.formatSignature));
      expect(restored.schemaVersion, equals(package.schemaVersion));
      expect(restored.tournament.id, equals(tournament.id));
      expect(restored.suggestedFileName, equals(package.suggestedFileName));
    });
  });

  group('BackupValidationResult Domain Entity', () {
    test('creates valid and invalid instances correctly', () {
      final valid = BackupValidationResult.valid(
        TournamentBackupPackage(
          exportedAt: DateTime(2026, 11, 5),
          tournament: ChampionshipTournament(
            id: 't-1',
            name: 'Torneo',
            category: 'Cat',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 2, 1),
            format: TournamentFormat.league,
            updatedAt: DateTime(2026, 1, 1),
          ),
        ),
      );

      expect(valid.isValid, isTrue);
      expect(valid.errorMessage, isNull);
      expect(valid.package, isNotNull);

      final invalid = BackupValidationResult.invalid('Error message');
      expect(invalid.isValid, isFalse);
      expect(invalid.errorMessage, equals('Error message'));
      expect(invalid.package, isNull);
    });
  });
}
