import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';

class MockLocalStorageRepository extends Mock
    implements LocalStorageRepository {}

void main() {
  late MockLocalStorageRepository mockStorage;
  late EnvironmentConfig devConfig;
  late LocalTournamentsRepository repository;
  final inMemoryStore = <String, String>{};

  setUp(() {
    mockStorage = MockLocalStorageRepository();
    inMemoryStore.clear();

    when(() => mockStorage.readString(any())).thenAnswer((inv) async {
      final key = inv.positionalArguments[0] as String;
      return inMemoryStore[key];
    });

    when(() => mockStorage.writeString(any(), any())).thenAnswer((inv) async {
      final key = inv.positionalArguments[0] as String;
      final val = inv.positionalArguments[1] as String;
      inMemoryStore[key] = val;
    });

    devConfig = EnvironmentConfig.development();
    repository = LocalTournamentsRepository(
      storage: mockStorage,
      config: devConfig,
    );
  });

  group('LocalTournamentsRepository CRUD & organizerId Tests', () {
    test('loads dev seed tournaments with default organizerId org-seed-1', () async {
      final tournaments = await repository.loadTournaments();
      expect(tournaments.length, 3);
      for (final t in tournaments) {
        expect(t.organizerId, 'org-seed-1');
      }
    });

    test('deletes a tournament by ID from storage', () async {
      final initial = await repository.loadTournaments();
      expect(initial.length, 3);
      final idToDelete = initial.first.id;

      await repository.deleteTournament(idToDelete);

      final remaining = await repository.loadTournaments();
      expect(remaining.length, 2);
      expect(remaining.any((t) => t.id == idToDelete), isFalse);
    });

    test('saves and updates a tournament preserving custom organizerId', () async {
      final newTournament = ChampionshipTournament(
        id: 'tournament-custom-1',
        name: 'Torneo Empresarial',
        category: 'Libre',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 8, 30),
        format: TournamentFormat.league,
        status: TournamentStatus.openRegistration,
        rules: const TournamentRulesConfig(),
        updatedAt: DateTime(2026, 7, 1),
        organizerId: 'org-user-777',
      );

      await repository.saveTournament(newTournament);

      final loaded = await repository.loadTournaments();
      final found = loaded.firstWhere((t) => t.id == 'tournament-custom-1');
      expect(found.organizerId, 'org-user-777');
      expect(found.name, 'Torneo Empresarial');
    });
  });
}
