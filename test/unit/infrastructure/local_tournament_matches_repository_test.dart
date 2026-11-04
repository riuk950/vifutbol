import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_matches_repository.dart';

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
  group('LocalTournamentMatchesRepository', () {
    late _InMemoryLocalStorageRepository storage;
    late LocalTournamentMatchesRepository repository;

    setUp(() {
      storage = _InMemoryLocalStorageRepository();
      repository = LocalTournamentMatchesRepository(
        storage: storage,
        config: EnvironmentConfig.development(),
      );
    });

    test(
      'preloads seed referees and seed matches in dev environment',
      () async {
        final referees = await repository.loadOfficialReferees();
        expect(referees.length, 3);
        expect(referees.any((r) => r.fullName == 'Wilmar Roldán'), isTrue);

        final matches = await repository.loadMatchesForTournament(
          'tournament-seed-liga-clausura',
        );
        expect(matches.length, 2);
        expect(matches.first.roundName, 'Jornada 1');
        expect(matches.first.status, MatchStatus.scheduled);
      },
    );

    test('saves and updates individual matches in persistent store', () async {
      final newMatch = ChampionshipMatch(
        id: 'test-match-1',
        tournamentId: 'tourn-custom',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'team-x',
        awayTeamId: 'team-y',
        status: MatchStatus.pendingSchedule,
      );

      await repository.saveMatch(newMatch);

      var loaded = await repository.loadMatchesForTournament('tourn-custom');
      expect(loaded.length, 1);
      expect(loaded.first.id, 'test-match-1');

      // Update match
      final updatedMatch = newMatch.copyWith(status: MatchStatus.scheduled);
      await repository.saveMatch(updatedMatch);

      loaded = await repository.loadMatchesForTournament('tourn-custom');
      expect(loaded.length, 1);
      expect(loaded.first.status, MatchStatus.scheduled);
    });

    test('saves matches in batch efficiently', () async {
      final batch = [
        ChampionshipMatch(
          id: 'batch-1',
          tournamentId: 'tourn-batch',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 't1',
          awayTeamId: 't2',
        ),
        ChampionshipMatch(
          id: 'batch-2',
          tournamentId: 'tourn-batch',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 't3',
          awayTeamId: 't4',
        ),
      ];

      final saved = await repository.saveMatchesBatch(batch);
      expect(saved.length, 2);

      final loaded = await repository.loadMatchesForTournament('tourn-batch');
      expect(loaded.length, 2);
    });
  });
}
