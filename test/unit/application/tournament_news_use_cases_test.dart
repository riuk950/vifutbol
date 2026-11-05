import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/manage_tournament_news_use_cases.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/tournament_news_category.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_news_repository.dart';

class _InMemoryLocalStorage implements LocalStorageRepository {
  final Map<String, String> _store = {};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _store[key];

  @override
  Future<void> writeString(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> clearNamespace() async => _store.clear();

  @override
  bool get isUsingFallbackMemory => true;
}

void main() {
  group('Tournament News Use Cases & Repository', () {
    late _InMemoryLocalStorage storage;
    late LocalTournamentNewsRepository repository;
    late PublishTournamentNewsUseCase publishUseCase;
    late DeleteTournamentNewsUseCase deleteUseCase;

    setUp(() {
      storage = _InMemoryLocalStorage();
      repository = LocalTournamentNewsRepository(
        storage: storage,
        config: EnvironmentConfig.production(),
      );
      publishUseCase = PublishTournamentNewsUseCase(newsRepository: repository);
      deleteUseCase = DeleteTournamentNewsUseCase(newsRepository: repository);
    });

    final testNews = TournamentNewsItem(
      id: 'news-test-1',
      tournamentId: 'tournament-1',
      title: 'Boletín Disciplinario Fecha 1',
      body: 'Detalle de amonestaciones y suspensiones para la fecha.',
      category: TournamentNewsCategory.disciplinary,
      publishedAt: DateTime(2026, 11, 5, 10, 0),
      authorUserId: 'user-organizer',
      authorName: 'Comité Organizador',
    );

    test('organizer can successfully publish news item', () async {
      final result = await publishUseCase.execute(
        newsItem: testNews,
        userRole: UserRole.organizer,
      );

      expect(result.id, 'news-test-1');

      final loaded = await repository.loadNewsForTournament('tournament-1');
      expect(loaded.length, 1);
      expect(loaded.first.title, testNews.title);
    });

    test(
      'non-organizer role cannot publish news item (throws UnauthorizedRoleFailure)',
      () async {
        expect(
          () => publishUseCase.execute(
            newsItem: testNews,
            userRole: UserRole.fan,
          ),
          throwsA(isA<UnauthorizedRoleFailure>()),
        );

        expect(
          () => publishUseCase.execute(
            newsItem: testNews,
            userRole: UserRole.coach,
          ),
          throwsA(isA<UnauthorizedRoleFailure>()),
        );
      },
    );

    test(
      'organizer can delete news item and stream updates reactively',
      () async {
        await publishUseCase.execute(
          newsItem: testNews,
          userRole: UserRole.organizer,
        );

        final stream = repository.watchNewsForTournament('tournament-1');
        final emissions = <List<TournamentNewsItem>>[];
        final sub = stream.listen(emissions.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(emissions.length, 1);
        expect(emissions.first.length, 1);

        await deleteUseCase.execute(
          newsItemId: testNews.id,
          userRole: UserRole.organizer,
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(emissions.length, 2);
        expect(emissions[1], isEmpty);

        await sub.cancel();
      },
    );

    test('non-organizer role cannot delete news item', () async {
      expect(
        () => deleteUseCase.execute(
          newsItemId: testNews.id,
          userRole: UserRole.player,
        ),
        throwsA(isA<UnauthorizedRoleFailure>()),
      );
    });
  });
}
