import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/tournament_news_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
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
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_news_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/news/tournament_news_feed_view.dart';
import 'package:vifutbol/presentation/news/widgets/news_filter_bottom_sheet.dart';
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

List<Override> _createTestOverrides({
  required LocalStorageRepository storage,
  required EnvironmentConfig config,
  required UserRole role,
  required TournamentsRepository tournamentsRepo,
  required TournamentsController tournamentsController,
  required LocalTournamentNewsRepository newsRepo,
  required TournamentNewsController newsController,
}) {
  return [
    localStorageRepositoryProvider.overrideWithValue(storage),
    environmentConfigProvider.overrideWithValue(config),
    activeUserRoleProvider.overrideWith((ref) => role),
    tournamentsRepositoryProvider.overrideWithValue(tournamentsRepo),
    tournamentsControllerProvider.overrideWith((ref) => tournamentsController),
    tournamentNewsRepositoryProvider.overrideWithValue(newsRepo),
    tournamentNewsControllerProvider.overrideWith((ref) => newsController),
  ];
}

void main() {
  testWidgets('News feed renders items and adapts by role (US1)', (
    tester,
  ) async {
    final storage = _MockNewsStorage();
    final config = EnvironmentConfig.production();
    final repo = LocalTournamentNewsRepository(
      storage: storage,
      config: config,
    );
    final tournamentsRepo = LocalTournamentsRepository(
      storage: storage,
      config: config,
    );
    final tournamentsUseCase = ManageTournamentsUseCase(tournamentsRepo);
    final tournamentsController = TournamentsController(
      tournamentsRepository: tournamentsRepo,
      manageTournamentsUseCase: tournamentsUseCase,
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
    final newsController = TournamentNewsController(
      newsRepository: repo,
      publishUseCase: publishUseCase,
      deleteUseCase: deleteUseCase,
    );

    // Test as Fan: no create button, no delete button
    await tester.pumpWidget(
      ProviderScope(
        overrides: _createTestOverrides(
          storage: storage,
          config: config,
          role: UserRole.fan,
          tournamentsRepo: tournamentsRepo,
          tournamentsController: tournamentsController,
          newsRepo: repo,
          newsController: newsController,
        ),
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

    // Filter by Disciplinary programmatically via controller
    newsController.setCategoryFilter(TournamentNewsCategory.disciplinary);
    await tester.pumpAndSettle();

    expect(find.byType(TournamentNewsCard), findsOneWidget);
    expect(find.text('Boletín Disciplinario de Sanciones'), findsOneWidget);
    expect(find.text('Aviso de Reprogramación Cancha 1'), findsNothing);
  });

  testWidgets(
    'News feed hides create button even for organizer but preserves delete option (US1)',
    (tester) async {
      final storage = _MockNewsStorage();
      final config = EnvironmentConfig.production();
      final repo = LocalTournamentNewsRepository(
        storage: storage,
        config: config,
      );
      final tournamentsRepo = LocalTournamentsRepository(
        storage: storage,
        config: config,
      );
      final tournamentsUseCase = ManageTournamentsUseCase(tournamentsRepo);
      final tournamentsController = TournamentsController(
        tournamentsRepository: tournamentsRepo,
        manageTournamentsUseCase: tournamentsUseCase,
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
      final newsController = TournamentNewsController(
        newsRepository: repo,
        publishUseCase: publishUseCase,
        deleteUseCase: deleteUseCase,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _createTestOverrides(
            storage: storage,
            config: config,
            role: UserRole.organizer,
            tournamentsRepo: tournamentsRepo,
            tournamentsController: tournamentsController,
            newsRepo: repo,
            newsController: newsController,
          ),
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

      // Verify create_news_button is completely absent in feed
      expect(find.byKey(const Key('create_news_button')), findsNothing);
      // Organizer can still delete existing announcement
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    },
  );

  testWidgets(
    'NewsTabView renders header, active tournament subtitle, and cleans up horizontal selector (US3)',
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
          overrides: _createTestOverrides(
            storage: storage,
            config: config,
            role: UserRole.organizer,
            tournamentsRepo: tournamentsRepo,
            tournamentsController: tournamentsController,
            newsRepo: newsRepo,
            newsController: newsController,
          ),
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
      tournamentsController.selectTournament('tourn-1');
      await tester.pump();

      // Verify header is rendered
      expect(find.byKey(const Key('news_tab_header')), findsOneWidget);

      // Verify horizontal tournament selector was removed
      expect(find.byKey(const Key('news_tournament_selector')), findsNothing);

      // Verify active tournament subtitle is displayed
      expect(
        find.byKey(const Key('news_active_tournament_subtitle')),
        findsOneWidget,
      );
      expect(find.text('Torneo Apertura 2026'), findsWidgets);
    },
  );

  testWidgets(
    'NewsFilterBottomSheet updates tournament and category filters reactively in real time (US2)',
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
        id: 't-1',
        name: 'Liga Premier',
        category: 'Libre',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 6, 1),
        format: TournamentFormat.league,
        status: TournamentStatus.inProgress,
        updatedAt: DateTime.now(),
      );
      final t2 = ChampionshipTournament(
        id: 't-2',
        name: 'Copa de Oro',
        category: 'Libre',
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 7, 1),
        format: TournamentFormat.knockoutCup,
        status: TournamentStatus.inProgress,
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
          overrides: _createTestOverrides(
            storage: storage,
            config: config,
            role: UserRole.organizer,
            tournamentsRepo: tournamentsRepo,
            tournamentsController: tournamentsController,
            newsRepo: newsRepo,
            newsController: newsController,
          ),
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('es'),
            home: Scaffold(body: NewsFilterBottomSheet()),
          ),
        ),
      );

      await tester.pump();
      await tournamentsController.loadCatalog();
      await tester.pump();

      // Verify bottom sheet title and reset button
      expect(find.byKey(const Key('news_filter_bottom_sheet')), findsOneWidget);
      expect(find.byKey(const Key('news_filter_reset_button')), findsOneWidget);

      // Verify tournament chips
      expect(
        find.byKey(const Key('news_filter_tournament_chip_t-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('news_filter_tournament_chip_t-2')),
        findsOneWidget,
      );

      // Tap tournament 2
      await tester.tap(
        find.byKey(const Key('news_filter_tournament_chip_t-2')),
      );
      await tester.pump();

      expect(tournamentsController.state.selectedTournamentId, 't-2');

      // Tap category chip
      await tester.tap(
        find.byKey(const Key('news_filter_category_chip_disciplinary')),
      );
      await tester.pump();

      expect(
        newsController.state.categoryFilter,
        TournamentNewsCategory.disciplinary,
      );

      // Tap reset button
      await tester.tap(find.byKey(const Key('news_filter_reset_button')));
      await tester.pump();

      expect(newsController.state.categoryFilter, isNull);
    },
  );

  testWidgets(
    'news_active_filter_chip displays active category and clears filter on tap (US3)',
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
        id: 't-single',
        name: 'Liga de Prueba',
        category: 'Libre',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 6, 1),
        format: TournamentFormat.league,
        status: TournamentStatus.inProgress,
        updatedAt: DateTime.now(),
      );
      await tournamentsRepo.saveTournament(t1);

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
          overrides: _createTestOverrides(
            storage: storage,
            config: config,
            role: UserRole.organizer,
            tournamentsRepo: tournamentsRepo,
            tournamentsController: tournamentsController,
            newsRepo: newsRepo,
            newsController: newsController,
          ),
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

      // Initially no active filter chip
      expect(find.byKey(const Key('news_active_filter_chip')), findsNothing);

      // Set category filter to rescheduling
      newsController.setCategoryFilter(TournamentNewsCategory.rescheduling);
      await tester.pump();

      // Active filter chip appears with delete icon
      expect(find.byKey(const Key('news_active_filter_chip')), findsOneWidget);
      expect(find.text('Reprogramaciones'), findsOneWidget);
      expect(
        find.byKey(const Key('news_active_filter_clear_button')),
        findsOneWidget,
      );

      // Tap clear button on chip
      await tester.tap(
        find.byKey(const Key('news_active_filter_clear_button')),
      );
      await tester.pump();

      // Filter cleared and chip disappears
      expect(newsController.state.categoryFilter, isNull);
      expect(find.byKey(const Key('news_active_filter_chip')), findsNothing);
    },
  );

  testWidgets(
    'NewsTabView and NewsFilterBottomSheet render without RenderFlex overflow at 320x640 with 130% text scaling (T012)',
    (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
        id: 'tourn-responsive',
        name: 'Torneo Apertura 2026 Metropolitano',
        category: 'Libre Primera A',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 6, 1),
        format: TournamentFormat.league,
        status: TournamentStatus.inProgress,
        updatedAt: DateTime.now(),
      );
      await tournamentsRepo.saveTournament(t1);

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
      newsController.setCategoryFilter(TournamentNewsCategory.disciplinary);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _createTestOverrides(
            storage: storage,
            config: config,
            role: UserRole.organizer,
            tournamentsRepo: tournamentsRepo,
            tournamentsController: tournamentsController,
            newsRepo: newsRepo,
            newsController: newsController,
          ),
          child: MaterialApp(
            theme: KickPulseTheme.darkTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('es'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const Scaffold(body: NewsTabView()),
          ),
        ),
      );

      await tester.pump();
      await tournamentsController.loadCatalog();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('news_active_filter_chip')), findsOneWidget);

      // Also test NewsFilterBottomSheet at 320x640 with 130% text scaling
      await tester.pumpWidget(
        ProviderScope(
          overrides: _createTestOverrides(
            storage: storage,
            config: config,
            role: UserRole.organizer,
            tournamentsRepo: tournamentsRepo,
            tournamentsController: tournamentsController,
            newsRepo: newsRepo,
            newsController: newsController,
          ),
          child: MaterialApp(
            theme: KickPulseTheme.darkTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('es'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const Scaffold(body: NewsFilterBottomSheet()),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('news_filter_bottom_sheet')), findsOneWidget);
    },
  );
}
