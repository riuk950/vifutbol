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
      'returns empty referees and matches in development when storage is empty',
      () async {
        final referees = await repository.loadOfficialReferees();
        expect(referees, isEmpty);

        final matches = await repository.loadMatchesForTournament(
          'tournament-1',
        );
        expect(matches, isEmpty);
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

    test('streams reactive updates for tournament matches', () async {
      final initialMatches = await repository.loadMatchesForTournament(
        'tourn-stream',
      );
      expect(initialMatches, isEmpty);

      final stream = repository.watchMatchesForTournament('tourn-stream');
      final emissions = <List<ChampionshipMatch>>[];
      final sub = stream.listen(emissions.add);

      // Allow initial yield
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.length, 1);
      expect(emissions.first, isEmpty);

      final newMatch = ChampionshipMatch(
        id: 'stream-match-1',
        tournamentId: 'tourn-stream',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: 'h1',
        awayTeamId: 'a1',
        status: MatchStatus.inProgress,
        homeScore: 1,
        awayScore: 0,
      );

      await repository.saveMatch(newMatch);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions.length, 2);
      expect(emissions[1].length, 1);
      expect(emissions[1].first.status, MatchStatus.inProgress);
      expect(emissions[1].first.homeScore, 1);

      await sub.cancel();
    });
  });
}
