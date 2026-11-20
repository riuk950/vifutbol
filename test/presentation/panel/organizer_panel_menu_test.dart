import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournament_news_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournament_news_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/news/widgets/create_news_dialog.dart';
import 'package:vifutbol/presentation/panel/panel_screen.dart';
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
    String? selectedTournamentId,
  }) : super(
         TournamentsCatalogState(
           tournaments: tournaments,
           selectedTournamentId: selectedTournamentId,
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTournamentNewsController extends StateNotifier<TournamentNewsState>
    implements TournamentNewsController {
  FakeTournamentNewsController({List<TournamentNewsItem> news = const []})
    : super(TournamentNewsState(news: news));

  @override
  Future<bool> publishNews({
    required TournamentNewsItem item,
    required UserRole userRole,
  }) async {
    state = state.copyWith(news: [item, ...state.news]);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createPanelScreenApp({
  required UserRole role,
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
      activeUserRoleProvider.overrideWith((ref) => role),
      tournamentsControllerProvider.overrideWith(
        (ref) => FakeTournamentsController(tournaments: tourList),
      ),
      teamsControllerProvider.overrideWith((ref) => FakeTeamsController()),
      matchesCatalogControllerProvider.overrideWith(
        (ref) => FakeMatchesCatalogController(matches: matches ?? []),
      ),
      tournamentNewsControllerProvider.overrideWith(
        (ref) => FakeTournamentNewsController(),
      ),
    ],
    child: MaterialApp(
      theme: KickPulseTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [Locale('es')],
      home: const PanelScreen(),
    ),
  );
}

void main() {
  group('PanelScreen Contextual Menu Tests (US2 & US3)', () {
    testWidgets(
      'displays organizer_panel_appbar_menu for UserRole.organizer in AppBar',
      (tester) async {
        await tester.pumpWidget(createPanelScreenApp(role: UserRole.organizer));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('organizer_panel_appbar_menu')),
          findsOneWidget,
        );
      },
    );

    for (final nonOrganizerRole in [
      UserRole.coach,
      UserRole.referee,
      UserRole.player,
      UserRole.fan,
    ]) {
      testWidgets(
        'hides organizer_panel_appbar_menu for ${nonOrganizerRole.name}',
        (tester) async {
          await tester.pumpWidget(createPanelScreenApp(role: nonOrganizerRole));
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('organizer_panel_appbar_menu')),
            findsNothing,
          );
        },
      );
    }

    testWidgets(
      'selecting publishNews opens CreateNewsDialog and publishes news with success snackbar',
      (tester) async {
        await tester.pumpWidget(createPanelScreenApp(role: UserRole.organizer));
        await tester.pumpAndSettle();

        // Tap AppBar menu
        await tester.tap(find.byKey(const Key('organizer_panel_appbar_menu')));
        await tester.pumpAndSettle();

        // Tap Publicar Noticia
        await tester.tap(find.byKey(const Key('organizer_menu_publish_news')));
        await tester.pumpAndSettle();

        // CreateNewsDialog is opened
        expect(find.byType(CreateNewsDialog), findsOneWidget);
        expect(
          find.byKey(const Key('create_news_tournament_dropdown')),
          findsOneWidget,
        );

        // Fill fields
        await tester.enterText(
          find.byKey(const Key('create_news_title_field')),
          'Fixture reprogramado',
        );
        await tester.enterText(
          find.byKey(const Key('create_news_body_field')),
          'Detalles de las nuevas fechas publicadas.',
        );

        // Submit
        await tester.tap(find.byKey(const Key('create_news_submit_button')));
        await tester.pumpAndSettle();

        // Success snackbar
        expect(find.text('Comunicado publicado con éxito'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting publishNews when no editable tournaments exist opens CreateNewsDialog with general fallback',
      (tester) async {
        await tester.pumpWidget(
          createPanelScreenApp(role: UserRole.organizer, tournaments: []),
        );
        await tester.pumpAndSettle();

        // Tap AppBar menu
        await tester.tap(find.byKey(const Key('organizer_panel_appbar_menu')));
        await tester.pumpAndSettle();

        // Tap Publicar Noticia
        await tester.tap(find.byKey(const Key('organizer_menu_publish_news')));
        await tester.pumpAndSettle();

        // CreateNewsDialog opens without tournament dropdown (general announcement fallback)
        expect(find.byType(CreateNewsDialog), findsOneWidget);
        expect(
          find.byKey(const Key('create_news_tournament_dropdown')),
          findsNothing,
        );

        // Fill and submit
        await tester.enterText(
          find.byKey(const Key('create_news_title_field')),
          'Aviso General',
        );
        await tester.enterText(
          find.byKey(const Key('create_news_body_field')),
          'Aviso general para toda la organización.',
        );

        await tester.tap(find.byKey(const Key('create_news_submit_button')));
        await tester.pumpAndSettle();

        expect(find.text('Comunicado publicado con éxito'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting backup opens TournamentBackupSheet when tournaments exist',
      (tester) async {
        await tester.pumpWidget(createPanelScreenApp(role: UserRole.organizer));
        await tester.pumpAndSettle();

        // Tap AppBar menu
        await tester.tap(find.byKey(const Key('organizer_panel_appbar_menu')));
        await tester.pumpAndSettle();

        // Tap Copia de Seguridad
        await tester.tap(find.byKey(const Key('organizer_menu_backup')));
        await tester.pumpAndSettle();

        // TournamentBackupSheet is opened
        expect(find.byType(TournamentBackupSheet), findsOneWidget);
      },
    );
  });
}
