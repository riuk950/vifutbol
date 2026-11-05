import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/fan_alerts_and_favorites_controllers.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/fan_alerts_and_favorites_providers.dart';
import 'package:vifutbol/application/providers/tournament_news_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_alert_type.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/domain/entities/tournament_news_category.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_match_alerts_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournament_news_repository.dart';
import 'package:vifutbol/infrastructure/services/local_notification_service.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/alerts/widgets/fan_alerts_tray_sheet.dart';
import 'package:vifutbol/presentation/matches/widgets/match_card.dart';
import 'package:vifutbol/presentation/news/widgets/tournament_news_card.dart';

class _MockStorage implements LocalStorageRepository {
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
  testWidgets(
    'Renders live match card, news card, and alerts tray at 320px with 130% text scaling with 0 overflows',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final storage = _MockStorage();
      final config = EnvironmentConfig.production();
      final newsRepo = LocalTournamentNewsRepository(
        storage: storage,
        config: config,
      );
      final alertsRepo = LocalMatchAlertsRepository(storage: storage);
      final notifService = LocalNotificationService(
        storage: storage,
        alertsRepository: alertsRepo,
      );

      final liveMatch = ChampionshipMatch(
        id: 'match-compact',
        tournamentId: 'tourn-compact',
        roundNumber: 1,
        roundName: 'Jornada 1 - Fecha Inaugural Metropolitana',
        homeTeamId: 'team-h',
        awayTeamId: 'team-a',
        status: MatchStatus.inProgress,
        homeScore: 3,
        awayScore: 2,
      );

      final homeTeam = TournamentTeam(
        id: 'team-h',
        tournamentId: 'tourn-compact',
        name: 'Club Atlético Deportivo Los Halcones',
        shortCode: 'HAL',
      );
      final awayTeam = TournamentTeam(
        id: 'team-a',
        tournamentId: 'tourn-compact',
        name: 'Asociación Social y Deportiva Las Águilas Doradas',
        shortCode: 'AGU',
      );

      final newsItem = TournamentNewsItem(
        id: 'news-compact',
        tournamentId: 'tourn-compact',
        title: 'Resolución de Sanciones y Reprogramación Oficial',
        body:
            'El tribunal deportivo comunica las medidas disciplinarias aplicadas.',
        category: TournamentNewsCategory.disciplinary,
        publishedAt: DateTime(2026, 11, 5, 10, 0),
        authorUserId: 'org-1',
        authorName: 'Comité Organizador ViFutbol',
        isPinned: true,
      );

      final alert = MatchLiveAlert(
        id: 'alert-compact',
        matchId: 'match-compact',
        tournamentId: 'tourn-compact',
        type: MatchAlertType.goalScored,
        title: '¡Golazo de Halcones en tiempo suplementario!',
        message: 'Anotación celebrada en la cancha principal.',
        timestamp: DateTime(2026, 11, 5, 10, 10),
      );
      await alertsRepo.saveAlert(alert);

      final trayController = FanAlertsTrayController(
        alertsRepository: alertsRepo,
        notificationService: notifService,
      );
      await trayController.init('user-compact');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserRoleProvider.overrideWith((ref) => UserRole.fan),
            tournamentNewsRepositoryProvider.overrideWithValue(newsRepo),
            matchAlertsRepositoryProvider.overrideWithValue(alertsRepo),
            notificationServiceProvider.overrideWithValue(notifService),
            fanAlertsTrayControllerProvider.overrideWith(
              (ref) => trayController,
            ),
          ],
          child: MaterialApp(
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
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    MatchCard(
                      match: liveMatch,
                      homeTeam: homeTeam,
                      awayTeam: awayTeam,
                    ),
                    const SizedBox(height: 16),
                    TournamentNewsCard(newsItem: newsItem),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 500,
                      child: FanAlertsTraySheet(userId: 'user-compact'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Zero RenderFlex overflows
      expect(tester.takeException(), isNull);
    },
  );
}
