import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';

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
  group('LocalTournamentsRepository', () {
    test(
      'preloads 3 representative seed tournaments in development environment',
      () async {
        final storage = _InMemoryLocalStorageRepository();
        final repository = LocalTournamentsRepository(
          storage: storage,
          config: EnvironmentConfig.development(),
        );

        final loaded = await repository.loadTournaments();
        expect(loaded.length, 3);
        expect(loaded.map((t) => t.format).toSet(), <TournamentFormat>{
          TournamentFormat.league,
          TournamentFormat.knockoutCup,
          TournamentFormat.mixedGroupsAndKnockout,
        });
      },
    );

    test(
      'returns empty list in production when storage is empty and persists new tournaments',
      () async {
        final storage = _InMemoryLocalStorageRepository();
        final repository = LocalTournamentsRepository(
          storage: storage,
          config: EnvironmentConfig.production(),
        );

        expect(await repository.loadTournaments(), isEmpty);

        final created = ChampionshipTournament(
          id: 't-prod-1',
          name: 'Liga Oficial Prod',
          category: 'Primera',
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 8, 1),
          format: TournamentFormat.league,
          updatedAt: DateTime(2026, 5, 1),
        );

        await repository.saveTournament(created);
        final afterSave = await repository.loadTournaments();
        expect(afterSave, <ChampionshipTournament>[created]);

        final updated = created.copyWith(name: 'Liga Oficial Prod Editada');
        await repository.saveTournament(updated);
        final afterUpdate = await repository.loadTournaments();
        expect(afterUpdate.single.name, 'Liga Oficial Prod Editada');
      },
    );

    test('saves, loads, and clears temporary creation draft', () async {
      final storage = _InMemoryLocalStorageRepository();
      final repository = LocalTournamentsRepository(
        storage: storage,
        config: EnvironmentConfig.development(),
      );

      expect(await repository.loadDraft(), isNull);

      final draft = TournamentDraft(
        name: 'Copa Nocturna Borrador',
        category: 'Libre',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 7, 1),
        format: TournamentFormat.knockoutCup,
        savedAt: DateTime(2026, 5, 15),
      );

      await repository.saveDraft(draft);
      expect(await repository.loadDraft(), draft);

      await repository.clearDraft();
      expect(await repository.loadDraft(), isNull);
    });
  });
}
