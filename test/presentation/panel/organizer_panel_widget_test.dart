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
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/matches/dialogs/generate_fixture_confirmation_dialog.dart';
import 'package:vifutbol/presentation/matches/widgets/schedule_match_dialog.dart';
import 'package:vifutbol/presentation/news/widgets/create_news_dialog.dart';
import 'package:vifutbol/presentation/panel/panel_screen.dart';
import 'package:vifutbol/presentation/panel/widgets/organizer_panel_content.dart';
import 'package:vifutbol/presentation/panel/widgets/select_tournament_for_fixture_sheet.dart';
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

class FakeTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  FakeTeamsController({List<TournamentTeam> teams = const []})
    : super(TeamsCatalogState(teams: teams));

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
    state = state.copyWith(
      matches: [
        ...state.matches,
        ChampionshipMatch(
          id: 'gen-match-1',
          tournamentId: tournament.id,
          roundNumber: 1,
          roundName: 'Jornada 1',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          status: MatchStatus.pendingSchedule,
        ),
      ],
    );
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createOrganizerPanelApp({
  List<ChampionshipTournament>? tournaments,
  List<ChampionshipMatch>? matches,
  List<TournamentTeam>? teams,
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

  final teamList =
      teams ??
      [
        TournamentTeam(
          id: 'team-a',
          name: 'Equipo Alfa',
          shortCode: 'ALF',
          tournamentId: 't-active-1',
          eligibilityStatus: TeamEligibilityStatus.eligible,
        ),
        TournamentTeam(
          id: 'team-b',
          name: 'Equipo Beta',
          shortCode: 'BET',
          tournamentId: 't-active-1',
          eligibilityStatus: TeamEligibilityStatus.eligible,
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
      teamsControllerProvider.overrideWith(
        (ref) => FakeTeamsController(teams: teamList),
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
      onGenerateRoute: (settings) {
        if (settings.name != null &&
            settings.name!.startsWith('/competitions/')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => Scaffold(
              body: Text('Competition Detail Screen: ${settings.name}'),
            ),
          );
        }
        return null;
      },
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
      expect(
        find.byKey(const Key('organizer_action_publish_news')),
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
      'Generate fixture action opens SelectTournamentForFixtureSheet, selects tournament, confirms, shows success snackbar and navigates to competition detail',
      (tester) async {
        await tester.pumpWidget(createOrganizerPanelApp());
        await tester.pumpAndSettle();

        // Tap "Generar Fixture"
        await tester.tap(
          find.byKey(const Key('organizer_action_generate_fixture')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify SelectTournamentForFixtureSheet is opened
        expect(find.byType(SelectTournamentForFixtureSheet), findsOneWidget);
        expect(
          find.byKey(const Key('select_tournament_fixture_item_t-active-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('select_tournament_fixture_item_t-unseeded-2')),
          findsOneWidget,
        );

        // Tap tournament item
        await tester.tap(
          find.byKey(const Key('select_tournament_fixture_item_t-active-1')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Confirmation dialog is shown
        expect(find.byType(GenerateFixtureConfirmationDialog), findsOneWidget);

        // Tap confirm
        await tester.tap(
          find.byKey(const Key('confirm_generate_fixture_button')),
        );
        await tester.pumpAndSettle();

        // Verify success snackbar
        expect(
          find.textContaining('Fixture generado exitosamente'),
          findsOneWidget,
        );

        // Verify automatic navigation to /competitions/:id
        expect(
          find.text('Competition Detail Screen: /competitions/t-active-1'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Generate fixture action displays info snackbar when no editable tournaments exist and does not open sheet',
      (tester) async {
        final finishedTournaments = [
          ChampionshipTournament(
            id: 't-finished-1',
            name: 'Torneo Cerrado 2025',
            category: 'Libre',
            format: TournamentFormat.league,
            status: TournamentStatus.finished,
            startDate: DateTime(2025, 1, 1),
            endDate: DateTime(2025, 5, 30),
            updatedAt: DateTime(2025, 5, 30),
          ),
        ];

        await tester.pumpWidget(
          createOrganizerPanelApp(tournaments: finishedTournaments),
        );
        await tester.pumpAndSettle();

        // Tap "Generar Fixture"
        await tester.tap(
          find.byKey(const Key('organizer_action_generate_fixture')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify sheet does not open and info snackbar is shown
        expect(find.byType(SelectTournamentForFixtureSheet), findsNothing);
        expect(
          find.text(
            'No hay competiciones activas disponibles para generar fixture',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'SelectTournamentForFixtureSheet renders without RenderFlex overflow on compact screen (320x640 at 130% text scale)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: createOrganizerPanelApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Tap "Generar Fixture"
        await tester.tap(
          find.byKey(const Key('organizer_action_generate_fixture')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify modal bottom sheet is displayed cleanly with zero overflow
        expect(find.byType(SelectTournamentForFixtureSheet), findsOneWidget);
        expect(
          find.byKey(const Key('select_tournament_fixture_item_t-active-1')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Publish news action opens CreateNewsDialog with editable tournaments and publishes announcement',
      (tester) async {
        final tournaments = [
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
            id: 't-finished-3',
            name: 'Torneo Histórico Clausura',
            category: 'Veteranos',
            format: TournamentFormat.league,
            status: TournamentStatus.finished,
            startDate: DateTime(2025, 3, 1),
            endDate: DateTime(2025, 6, 30),
            updatedAt: DateTime(2025, 3, 1),
          ),
        ];

        await tester.pumpWidget(
          createOrganizerPanelApp(tournaments: tournaments),
        );
        await tester.pumpAndSettle();

        // Tap "Publicar Noticia"
        await tester.tap(
          find.byKey(const Key('organizer_action_publish_news')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify CreateNewsDialog opened with tournament dropdown
        expect(find.byType(CreateNewsDialog), findsOneWidget);
        expect(
          find.byKey(const Key('create_news_tournament_dropdown')),
          findsOneWidget,
        );

        // Fill form fields
        await tester.enterText(
          find.byKey(const Key('create_news_title_field')),
          'Comunicado Urgente',
        );
        await tester.enterText(
          find.byKey(const Key('create_news_body_field')),
          'Se suspenden los partidos por clima.',
        );

        // Submit form
        await tester.tap(find.byKey(const Key('create_news_submit_button')));
        await tester.pumpAndSettle();

        // Verify success snackbar
        expect(find.text('Comunicado publicado con éxito'), findsOneWidget);
      },
    );

    testWidgets(
      'Publish news action shows snackbar when no editable tournaments exist',
      (tester) async {
        final finishedTournaments = [
          ChampionshipTournament(
            id: 't-finished-1',
            name: 'Torneo Cerrado 2025',
            category: 'Libre',
            format: TournamentFormat.league,
            status: TournamentStatus.finished,
            startDate: DateTime(2025, 1, 1),
            endDate: DateTime(2025, 5, 30),
            updatedAt: DateTime(2025, 5, 30),
          ),
        ];

        await tester.pumpWidget(
          createOrganizerPanelApp(tournaments: finishedTournaments),
        );
        await tester.pumpAndSettle();

        // Tap "Publicar Noticia"
        await tester.tap(
          find.byKey(const Key('organizer_action_publish_news')),
        );
        await tester.pumpAndSettle();

        // Verify info snackbar is shown and dialog is not opened
        expect(find.byType(CreateNewsDialog), findsNothing);
        expect(
          find.text(
            'No hay competiciones activas disponibles para publicar comunicados',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
