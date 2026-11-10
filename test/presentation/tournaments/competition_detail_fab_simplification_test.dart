import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/tournaments/competition_detail_screen.dart';

class _FakeLocalStorageRepository implements LocalStorageRepository {
  @override
  bool get isUsingFallbackMemory => false;
  @override
  Future<void> clearNamespace() async {}
  @override
  Future<LocalStorageStatus> initialize(String prefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: prefix);
  @override
  Future<String?> readString(String key) async => null;
  @override
  Future<void> writeString(String key, String value) async {}
}

class _FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);
  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;
}

class _FakeTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  _FakeTournamentsController({
    List<ChampionshipTournament> tournaments = const [],
  }) : super(
         TournamentsCatalogState(
           viewState: UiSuccessState<List<ChampionshipTournament>>(tournaments),
           tournaments: tournaments,
         ),
       );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  _FakeTeamsController() : super(const TeamsCatalogState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMatchesCatalogController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  _FakeMatchesCatalogController({List<ChampionshipMatch> matches = const []})
    : super(MatchesCatalogState(matches: matches));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildApp({
    required ChampionshipTournament tournament,
    UserRole userRole = UserRole.organizer,
    List<ChampionshipMatch> matches = const [],
  }) {
    return ProviderScope(
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
        activeUserRoleProvider.overrideWith((ref) => userRole),
        tournamentsControllerProvider.overrideWith(
          (ref) => _FakeTournamentsController(tournaments: [tournament]),
        ),
        teamsControllerProvider.overrideWith((ref) => _FakeTeamsController()),
        matchesCatalogControllerProvider.overrideWith(
          (ref) => _FakeMatchesCatalogController(matches: matches),
        ),
      ],
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
        home: CompetitionDetailScreen(tournamentId: tournament.id),
      ),
    );
  }

  group('CompetitionDetailScreen FAB Simplification Tests (US2)', () {
    testWidgets(
      'displays direct competition_detail_fab_generate_fixture without speed dial or add team action',
      (tester) async {
        final editableTournamentWithoutFixture = ChampionshipTournament(
          id: 'tourn-no-fix',
          name: 'Torneo Apertura',
          category: 'Honor',
          status: TournamentStatus.openRegistration,
          format: TournamentFormat.league,
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 12, 1),
          updatedAt: DateTime(2026, 6, 1),
        );

        await tester.pumpWidget(
          buildApp(tournament: editableTournamentWithoutFixture),
        );
        await tester.pumpAndSettle();

        // 1. Direct single Generate Fixture FAB is visible immediately
        final fixtureFab = find.byKey(
          const Key('competition_detail_fab_generate_fixture'),
        );
        expect(fixtureFab, findsOneWidget);

        // 2. Speed dial menu button is completely removed
        expect(
          find.byKey(const Key('competition_detail_fab_menu')),
          findsNothing,
        );

        // 3. Team enrollment FAB action is completely removed
        expect(
          find.byKey(const Key('competition_detail_fab_add_team')),
          findsNothing,
        );

        // 4. Tap directly opens confirmation dialog without needing to expand a speed dial
        await tester.tap(fixtureFab);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('confirm_generate_fixture_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'hides generate fixture FAB when tournament already has a fixture or is non-editable',
      (tester) async {
        final tournamentWithFixture = ChampionshipTournament(
          id: 'tourn-with-fix',
          name: 'Torneo Clausura',
          category: 'Honor',
          status: TournamentStatus.inProgress,
          format: TournamentFormat.league,
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 12, 1),
          updatedAt: DateTime(2026, 6, 1),
        );

        final existingMatch = ChampionshipMatch(
          id: 'match-1',
          tournamentId: 'tourn-with-fix',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 't-1',
          awayTeamId: 't-2',
        );

        await tester.pumpWidget(
          buildApp(tournament: tournamentWithFixture, matches: [existingMatch]),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_detail_fab_generate_fixture')),
          findsNothing,
        );
      },
    );

    testWidgets('hides FAB for non-organizer roles', (tester) async {
      final tournament = ChampionshipTournament(
        id: 'tourn-open',
        name: 'Torneo Abierto',
        category: 'Honor',
        status: TournamentStatus.openRegistration,
        format: TournamentFormat.league,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 12, 1),
        updatedAt: DateTime(2026, 6, 1),
      );

      for (final role in [
        UserRole.coach,
        UserRole.referee,
        UserRole.player,
        UserRole.fan,
      ]) {
        await tester.pumpWidget(
          buildApp(tournament: tournament, userRole: role),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_detail_fab_generate_fixture')),
          findsNothing,
          reason: '${role.name} must NOT see fixture generation FAB',
        );
      }
    });
  });
}
