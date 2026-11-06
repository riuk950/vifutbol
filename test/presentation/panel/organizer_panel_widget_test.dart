import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/matches/widgets/schedule_match_dialog.dart';
import 'package:vifutbol/presentation/panel/panel_screen.dart';
import 'package:vifutbol/presentation/panel/widgets/organizer_panel_content.dart';
import 'package:vifutbol/presentation/tournaments/widgets/tournament_backup_sheet.dart';

class _FakeLocalStorageRepository implements LocalStorageRepository {
  @override
  bool get isUsingFallbackMemory => false;
  @override
  Future<void> clearNamespace() async {}
  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);
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

class FakeTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  FakeTournamentsController({
    List<ChampionshipTournament> tournaments = const [],
  }) : super(
         TournamentsCatalogState(
           tournaments: tournaments,
           viewState: UiContentState(tournaments),
         ),
       );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMatchesCatalogController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  FakeMatchesCatalogController({List<ChampionshipMatch> matches = const []})
    : super(MatchesCatalogState(matches: matches));

  @override
  Future<bool> generateFixture({
    required ChampionshipTournament tournament,
    required List<TournamentTeam> teams,
    required UserRole userRole,
  }) async {
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createOrganizerPanelApp({
  List<ChampionshipTournament>? tournaments,
  List<ChampionshipMatch>? matches,
}) {
  final tourList =
      tournaments ??
      [
        ChampionshipTournament(
          id: 't-active-1',
          name: 'Torneo Apertura 2026',
          category: 'Libre A',
          format: TournamentFormat.league,
          status: TournamentStatus.inProgress,
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 6, 30),
          updatedAt: DateTime(2026, 3, 1),
        ),
        ChampionshipTournament(
          id: 't-unseeded-2',
          name: 'Copa Regional 2026',
          category: 'Veteranos',
          format: TournamentFormat.knockoutCup,
          status: TournamentStatus.openRegistration,
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2026, 7, 30),
          updatedAt: DateTime(2026, 4, 1),
        ),
      ];

  final matchList =
      matches ??
      [
        ChampionshipMatch(
          id: 'm-pending-1',
          tournamentId: 't-active-1',
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-a',
          awayTeamId: 'team-b',
          status: MatchStatus.pendingSchedule,
          scheduledStartTime: null,
        ),
      ];

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
      activeUserRoleProvider.overrideWith((ref) => UserRole.organizer),
      tournamentsControllerProvider.overrideWith(
        (ref) => FakeTournamentsController(tournaments: tourList),
      ),
      matchesCatalogControllerProvider.overrideWith(
        (ref) => FakeMatchesCatalogController(matches: matchList),
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
      supportedLocales: const [Locale('es')],
      home: const PanelScreen(),
    ),
  );
}

void main() {
  group('OrganizerPanelContent Widget Tests (US1 - P1 MVP)', () {
    testWidgets('renders Organizer AppBar title and metric summary cards', (
      tester,
    ) async {
      await tester.pumpWidget(createOrganizerPanelApp());
      await tester.pumpAndSettle();

      // Verify AppBar title
      expect(find.text('Panel de Organización'), findsOneWidget);
      expect(find.byType(OrganizerPanelContent), findsOneWidget);

      // Verify Metric Cards
      expect(
        find.byKey(const Key('organizer_metric_active_tournaments')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('organizer_metric_pending_matches')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('organizer_metric_unseeded_tournaments')),
        findsOneWidget,
      );

      // Verify Metric Values (2 active, 1 pending match, 1 unseeded tournament)
      expect(find.text('2'), findsWidgets);
      expect(find.text('1'), findsWidgets);

      // Verify Quick Action Buttons
      expect(
        find.byKey(const Key('organizer_action_generate_fixture')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('organizer_action_schedule_matches')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('organizer_action_backup')), findsOneWidget);
    });

    testWidgets(
      'Schedule matches action opens ScheduleMatchDialog when pending match exists',
      (tester) async {
        await tester.pumpWidget(createOrganizerPanelApp());
        await tester.pumpAndSettle();

        // Tap "Programar Partido"
        await tester.tap(
          find.byKey(const Key('organizer_action_schedule_matches')),
        );
        await tester.pumpAndSettle();

        // ScheduleMatchDialog is opened
        expect(find.byType(ScheduleMatchDialog), findsOneWidget);
      },
    );

    testWidgets('Backup action opens TournamentBackupSheet', (tester) async {
      await tester.pumpWidget(createOrganizerPanelApp());
      await tester.pumpAndSettle();

      // Tap "Copia de Seguridad"
      await tester.tap(find.byKey(const Key('organizer_action_backup')));
      await tester.pumpAndSettle();

      // TournamentBackupSheet is opened
      expect(find.byType(TournamentBackupSheet), findsOneWidget);
    });

    testWidgets(
      'Generate fixture action triggers generation and shows snackbar',
      (tester) async {
        await tester.pumpWidget(createOrganizerPanelApp());
        await tester.pumpAndSettle();

        // Tap "Generar Fixture"
        await tester.tap(
          find.byKey(const Key('organizer_action_generate_fixture')),
        );
        await tester.pumpAndSettle();

        // Verify feedback snackbar is displayed
        expect(
          find.textContaining('Generar Fixture: Copa Regional 2026'),
          findsOneWidget,
        );
      },
    );
  });
}
