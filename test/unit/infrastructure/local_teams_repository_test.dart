import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';

class _InMemoryLocalStorageRepository implements LocalStorageRepository {
  final Map<String, String> _store = <String, String>{};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async {
    return LocalStorageStatus(
      isPersistent: true,
      storageNamespace: storagePrefix,
    );
  }

  @override
  Future<String?> readString(String key) async => _store[key];

  @override
  Future<void> writeString(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> clearNamespace() async {
    _store.clear();
  }

  @override
  bool get isUsingFallbackMemory => true;
}

void main() {
  group('LocalTeamsRepository', () {
    test('preloads 20 seed teams in development environment', () async {
      final storage = _InMemoryLocalStorageRepository();
      final repository = LocalTeamsRepository(
        storage: storage,
        config: EnvironmentConfig.development(),
      );

      final teams = await repository.loadTeams();
      expect(teams.length, equals(20));

      final atn = teams.firstWhere((t) => t.shortCode == 'ATN');
      expect(atn.name, equals('Atlético Norte FC'));
      expect(atn.tournamentId, equals('tournament-seed-liga-clausura'));
      expect(atn.eligibilityStatus, equals(TeamEligibilityStatus.eligible));
      expect(atn.players.length, equals(18));

      final rsc = teams.firstWhere((t) => t.shortCode == 'RSC');
      expect(rsc.name, equals('Real Sabana Club'));
      expect(rsc.tournamentId, equals('tournament-seed-liga-clausura'));
      expect(rsc.eligibilityStatus, equals(TeamEligibilityStatus.eligible));
      expect(rsc.players.length, equals(18));
    });

    test(
      'returns empty list in production environment when storage is empty',
      () async {
        final storage = _InMemoryLocalStorageRepository();
        final repository = LocalTeamsRepository(
          storage: storage,
          config: EnvironmentConfig.production(),
        );

        final teams = await repository.loadTeams();
        expect(teams, isEmpty);
      },
    );

    test('filters teams by tournamentId', () async {
      final storage = _InMemoryLocalStorageRepository();
      final repository = LocalTeamsRepository(
        storage: storage,
        config: EnvironmentConfig.development(),
      );

      final clausuraTeams = await repository.loadTeamsForTournament(
        'tournament-seed-liga-clausura',
      );
      expect(clausuraTeams.length, equals(20));

      final emptyTeams = await repository.loadTeamsForTournament(
        'non-existing-tournament',
      );
      expect(emptyTeams, isEmpty);
    });

    test('saves and updates team in storage', () async {
      final storage = _InMemoryLocalStorageRepository();
      final repository = LocalTeamsRepository(
        storage: storage,
        config: EnvironmentConfig.production(),
      );

      final newTeam = TournamentTeam(
        id: 'custom-team-1',
        tournamentId: 'tour-10',
        name: 'Deportivo ViFutbol',
        shortCode: 'DVF',
        crestShape: TeamCrestShape.diamond,
      );

      await repository.saveTeam(newTeam);

      final loaded = await repository.loadTeams();
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('custom-team-1'));
      expect(loaded.first.shortCode, equals('DVF'));

      final updated = newTeam.copyWith(name: 'Deportivo ViFutbol Pro');
      await repository.saveTeam(updated);

      final reloaded = await repository.loadTeams();
      expect(reloaded.length, equals(1));
      expect(reloaded.first.name, equals('Deportivo ViFutbol Pro'));
    });
  });
}
