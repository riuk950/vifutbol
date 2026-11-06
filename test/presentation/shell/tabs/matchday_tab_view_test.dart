import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/daily_matches_feed_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/daily_matches_group.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/shell/tabs/matchday_tab_view.dart';

class _FakeLocalStorageRepository implements LocalStorageRepository {
  final Map<String, String> _store = {};

  @override
  bool get isUsingFallbackMemory => false;

  @override
  Future<void> clearNamespace() async => _store.clear();

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
}

class _FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;
}

class _FakeDailyMatchesFeedController extends DailyMatchesFeedController {
  _FakeDailyMatchesFeedController(super.ref, DailyMatchesFeedState initial) {
    state = initial;
  }

  @override
  void refresh() {
    // Preserve fake state during tests
  }
}

void main() {
  final tournament = ChampionshipTournament(
    id: 't-1',
    name: 'Copa Ciudad 2026',
    category: 'Libre',
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 12, 31),
    format: TournamentFormat.knockoutCup,
    status: TournamentStatus.inProgress,
    updatedAt: DateTime(2026, 1, 1),
  );

  final match = ChampionshipMatch(
    id: 'm-1',
    tournamentId: 't-1',
    roundNumber: 1,
    roundName: 'Octavos',
    homeTeamId: 'team-a',
    awayTeamId: 'team-b',
    scheduledStartTime: DateTime.now(),
    status: MatchStatus.inProgress,
  );

  testWidgets('renders empty state when there are no matches for date', (
    tester,
  ) async {
    final emptyState = DailyMatchesFeedState(
      dateState: DailyMatchesDateState.today(),
      tournamentGroups: const [],
      isLoading: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          environmentConfigProvider.overrideWithValue(
            EnvironmentConfig.development(),
          ),
          localStorageRepositoryProvider.overrideWithValue(
            _FakeLocalStorageRepository(),
          ),
          connectivityRepositoryProvider.overrideWithValue(
            _FakeConnectivityRepository(),
          ),
          activeUserRoleProvider.overrideWith((ref) => UserRole.fan),
          dailyMatchesFeedControllerProvider.overrideWith(
            (ref) => _FakeDailyMatchesFeedController(ref, emptyState),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: MatchdayTabView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('No hay partidos programados para esta fecha'),
      findsOneWidget,
    );
  });

  testWidgets('renders tournament group card when matches are available', (
    tester,
  ) async {
    final populatedState = DailyMatchesFeedState(
      dateState: DailyMatchesDateState.today(),
      tournamentGroups: [
        TournamentMatchesGroup(tournament: tournament, matches: [match]),
      ],
      isLoading: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          environmentConfigProvider.overrideWithValue(
            EnvironmentConfig.development(),
          ),
          localStorageRepositoryProvider.overrideWithValue(
            _FakeLocalStorageRepository(),
          ),
          connectivityRepositoryProvider.overrideWithValue(
            _FakeConnectivityRepository(),
          ),
          activeUserRoleProvider.overrideWith((ref) => UserRole.fan),
          dailyMatchesFeedControllerProvider.overrideWith(
            (ref) => _FakeDailyMatchesFeedController(ref, populatedState),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: MatchdayTabView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Copa Ciudad 2026'), findsOneWidget);
    expect(find.byKey(const Key('tournament_group_t-1')), findsOneWidget);
  });
}
