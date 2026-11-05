import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/tournament_news_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/tournament_news_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/manage_tournament_news_use_cases.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_news_category.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_news_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/news/tournament_news_feed_view.dart';
import 'package:vifutbol/presentation/news/widgets/tournament_news_card.dart';
import 'package:vifutbol/presentation/shell/tabs/news_tab_view.dart';

class _MockNewsStorage implements LocalStorageRepository {
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
  testWidgets('News feed renders items, category filters, and adapts by role', (
    tester,
  ) async {
    final storage = _MockNewsStorage();
    final config = EnvironmentConfig.production();
    final repo = LocalTournamentNewsRepository(
      storage: storage,
      config: config,
    );

    final item1 = TournamentNewsItem(
      id: 'news-1',
      tournamentId: 'tourn-news-1',
      title: 'Aviso de Reprogramación Cancha 1',
      body: 'Por mantenimiento, los partidos se trasladan a la cancha 2.',
      category: TournamentNewsCategory.rescheduling,
      publishedAt: DateTime(2026, 11, 5, 8, 0),
      authorUserId: 'org-1',
      authorName: 'Comité Organizador',
    );

    final item2 = TournamentNewsItem(
      id: 'news-2',
      tournamentId: 'tourn-news-1',
      title: 'Boletín Disciplinario de Sanciones',
      body: 'Lista de jugadores suspendidos para la fecha 2.',
      category: TournamentNewsCategory.disciplinary,
      publishedAt: DateTime(2026, 11, 5, 9, 0),
      authorUserId: 'org-1',
      authorName: 'Tribunal de Penas',
    );

    await repo.saveNewsItem(item1);
    await repo.saveNewsItem(item2);

    final publishUseCase = PublishTournamentNewsUseCase(newsRepository: repo);
    final deleteUseCase = DeleteTournamentNewsUseCase(newsRepository: repo);

    // 1. Test as Fan: no create button, no delete button
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeUserRoleProvider.overrideWith((ref) => UserRole.fan),
          tournamentNewsRepositoryProvider.overrideWithValue(repo),
          tournamentNewsControllerProvider.overrideWith(
            (ref) => TournamentNewsController(
              newsRepository: repo,
              publishUseCase: publishUseCase,
              deleteUseCase: deleteUseCase,
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentNewsFeedView(tournamentId: 'tourn-news-1'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify news items rendered
    expect(find.byType(TournamentNewsCard), findsNWidgets(2));
    expect(find.text('Aviso de Reprogramación Cancha 1'), findsOneWidget);
    expect(find.text('Boletín Disciplinario de Sanciones'), findsOneWidget);

    // Verify fan does NOT see create button or delete action
    expect(find.byKey(const Key('create_news_button')), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);

    // Filter by Disciplinary
    await tester.tap(
      find.widgetWithText(ChoiceChip, 'Boletines Disciplinarios'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TournamentNewsCard), findsOneWidget);
    expect(find.text('Boletín Disciplinario de Sanciones'), findsOneWidget);
    expect(find.text('Aviso de Reprogramación Cancha 1'), findsNothing);
  });

  testWidgets('News feed shows create button and delete option for organizer', (
    tester,
  ) async {
    final storage = _MockNewsStorage();
    final config = EnvironmentConfig.production();
    final repo = LocalTournamentNewsRepository(
      storage: storage,
      config: config,
    );

    final item = TournamentNewsItem(
      id: 'news-3',
      tournamentId: 'tourn-news-2',
      title: 'Aviso General para Delegados',
      body: 'Reunión informativa el próximo viernes a las 19:00.',
      category: TournamentNewsCategory.general,
      publishedAt: DateTime(2026, 11, 5, 8, 0),
      authorUserId: 'org-1',
      authorName: 'Organizador Oficial',
    );
    await repo.saveNewsItem(item);

    final publishUseCase = PublishTournamentNewsUseCase(newsRepository: repo);
    final deleteUseCase = DeleteTournamentNewsUseCase(newsRepository: repo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeUserRoleProvider.overrideWith((ref) => UserRole.organizer),
          tournamentNewsRepositoryProvider.overrideWithValue(repo),
          tournamentNewsControllerProvider.overrideWith(
            (ref) => TournamentNewsController(
              newsRepository: repo,
              publishUseCase: publishUseCase,
              deleteUseCase: deleteUseCase,
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentNewsFeedView(tournamentId: 'tourn-news-2'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify create button and delete icon are visible for Organizer
    expect(find.byKey(const Key('create_news_button')), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets(
    'NewsTabView renders header, synchronized tournament selector, and feed',
    (tester) async {
      final storage = _MockNewsStorage();
      final config = EnvironmentConfig.production();
      final newsRepo = LocalTournamentNewsRepository(
        storage: storage,
        config: config,
      );
      final tournamentsRepo = LocalTournamentsRepository(
        storage: storage,
        config: config,
      );

      final t1 = ChampionshipTournament(
        id: 'tourn-1',
        name: 'Torneo Apertura 2026',
        category: 'Libre',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 5, 30),
        format: TournamentFormat.league,
        status: TournamentStatus.inProgress,
        rules: const TournamentRulesConfig(halfDurationMinutes: 45),
        updatedAt: DateTime.now(),
      );

      final t2 = ChampionshipTournament(
        id: 'tourn-2',
        name: 'Torneo Histórico Clausura',
        category: 'Veteranos',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 11, 30),
        format: TournamentFormat.league,
        status: TournamentStatus.finished,
        rules: const TournamentRulesConfig(halfDurationMinutes: 40),
        updatedAt: DateTime.now(),
      );

      await tournamentsRepo.saveTournament(t1);
      await tournamentsRepo.saveTournament(t2);

      final tournamentsUseCase = ManageTournamentsUseCase(tournamentsRepo);
      final tournamentsController = TournamentsController(
        tournamentsRepository: tournamentsRepo,
        manageTournamentsUseCase: tournamentsUseCase,
      );

      final publishUseCase = PublishTournamentNewsUseCase(
        newsRepository: newsRepo,
      );
      final deleteUseCase = DeleteTournamentNewsUseCase(
        newsRepository: newsRepo,
      );
      final newsController = TournamentNewsController(
        newsRepository: newsRepo,
        publishUseCase: publishUseCase,
        deleteUseCase: deleteUseCase,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserRoleProvider.overrideWith((ref) => UserRole.organizer),
            tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
            tournamentsControllerProvider.overrideWith(
              (ref) => tournamentsController,
            ),
            tournamentNewsRepositoryProvider.overrideWithValue(newsRepo),
            tournamentNewsControllerProvider.overrideWith(
              (ref) => newsController,
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
            home: Scaffold(body: NewsTabView()),
          ),
        ),
      );

      await tester.pump();
      await tournamentsController.loadCatalog();
      await tester.pump();

      // Verify header and selector
      expect(find.byKey(const Key('news_tab_header')), findsOneWidget);
      expect(find.byKey(const Key('news_tournament_selector')), findsOneWidget);
      expect(find.text('Torneo Apertura 2026'), findsWidgets);

      // Switch tournament to finished tournament (t2)
      await tester.tap(find.byKey(const Key('news_tournament_chip_tourn-2')));
      await tester.pump();

      // Read-only badge should appear for finished tournament
      expect(find.byKey(const Key('news_readonly_badge')), findsOneWidget);
    },
  );
}
