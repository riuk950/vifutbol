import 'package:material_ui/material_ui.dart';
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
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: CompetitionDetailScreen(tournamentId: tournament.id),
      ),
    );
  }

  group('CompetitionDetailScreen Expandable FAB Menu Tests (HU 18.4 / US1)', () {
    testWidgets(
      'organizer sees expandable FAB menu that reveals Generar Fixture and Agregar Equipos within 150ms',
      (tester) async {
        final tournament = ChampionshipTournament(
          id: 'tourn-no-fix',
          name: 'Torneo Apertura',
          category: 'Honor',
          status: TournamentStatus.openRegistration,
          format: TournamentFormat.league,
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 12, 1),
          updatedAt: DateTime(2026, 6, 1),
        );

        await tester.pumpWidget(buildApp(tournament: tournament));
        await tester.pumpAndSettle();

        final fabMenu = find.byKey(const Key('competition_detail_fab_menu'));
        expect(fabMenu, findsOneWidget);

        // Collapsed initially: sub-actions not visible
        expect(
          find.byKey(const Key('competition_detail_fab_generate_fixture')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('competition_detail_fab_add_team')),
          findsNothing,
        );

        // Expand within 150ms (SC-001)
        await tester.tap(fabMenu);
        await tester.pump(const Duration(milliseconds: 140));

        expect(
          find.byKey(const Key('competition_detail_fab_generate_fixture')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_detail_fab_add_team')),
          findsOneWidget,
        );
        expect(find.text('Generar Fixture'), findsOneWidget);
        expect(find.text('Agregar Equipos'), findsOneWidget);

        // Tapping Generar Fixture collapses menu and opens confirmation dialog
        await tester.tap(
          find.byKey(const Key('competition_detail_fab_generate_fixture')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('confirm_generate_fixture_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('competition_detail_fab_add_team')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'keeps FAB menu with Agregar Equipos when editable tournament already has fixture',
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

        final fabMenu = find.byKey(const Key('competition_detail_fab_menu'));
        expect(fabMenu, findsOneWidget);

        await tester.tap(fabMenu);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('competition_detail_fab_generate_fixture')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('competition_detail_fab_add_team')),
          findsOneWidget,
        );
      },
    );

    testWidgets('hides FAB menu when tournament is finished', (tester) async {
      final finishedTournament = ChampionshipTournament(
        id: 'tourn-fin',
        name: 'Torneo Finalizado',
        category: 'Honor',
        status: TournamentStatus.finished,
        format: TournamentFormat.league,
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 12, 1),
        updatedAt: DateTime(2025, 12, 1),
      );

      await tester.pumpWidget(buildApp(tournament: finishedTournament));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('competition_detail_fab_menu')),
        findsNothing,
      );
    });

    testWidgets('hides FAB menu for all non-organizer roles', (tester) async {
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
          find.byKey(const Key('competition_detail_fab_menu')),
          findsNothing,
          reason: '${role.name} must NOT see competition FAB menu',
        );
      }
    });
  });
}
