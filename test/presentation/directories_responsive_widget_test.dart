import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/directories/competitions_directory_screen.dart';
import 'package:vifutbol/presentation/directories/players_directory_screen.dart';
import 'package:vifutbol/presentation/directories/teams_directory_screen.dart';
import 'package:vifutbol/presentation/panel/panel_screen.dart';
import 'package:vifutbol/presentation/shell/app_shell_screen.dart';
import 'package:vifutbol/presentation/shell/widgets/app_navigation_drawer.dart';

class FakeLocalStorageRepository implements LocalStorageRepository {
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

class FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);

  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;
}

class FakeTournamentsRepository implements TournamentsRepository {
  final List<ChampionshipTournament> tournaments;

  FakeTournamentsRepository(this.tournaments);

  @override
  Future<List<ChampionshipTournament>> loadTournaments() async => tournaments;

  @override
  Future<ChampionshipTournament> saveTournament(
    ChampionshipTournament tournament,
  ) async => tournament;

  @override
  Future<TournamentDraft?> loadDraft() async => null;

  @override
  Future<void> saveDraft(dynamic draft) async {}

  @override
  Future<void> clearDraft() async {}
}

class FakeTeamsRepository implements TeamsRepository {
  final List<TournamentTeam> teams;

  FakeTeamsRepository(this.teams);

  @override
  Future<List<TournamentTeam>> loadTeams() async => teams;

  @override
  Future<List<TournamentTeam>> loadTeamsForTournament(
    String tournamentId,
  ) async {
    return teams.where((t) => t.tournamentId == tournamentId).toList();
  }

  @override
  Future<TournamentTeam> saveTeam(TournamentTeam team) async => team;

  @override
  Future<void> replaceTeamsForTournament(
    String tournamentId,
    List<TournamentTeam> updatedTeams,
  ) async {}
}

Widget createResponsiveApp({
  required Widget child,
  required List<ChampionshipTournament> tournaments,
  required List<TournamentTeam> teams,
  UserRole role = UserRole.organizer,
  double textScaleFactor = 1.3,
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      environmentConfigProvider.overrideWithValue(
        EnvironmentConfig.development(),
      ),
      localStorageRepositoryProvider.overrideWithValue(
        FakeLocalStorageRepository(),
      ),
      connectivityRepositoryProvider.overrideWithValue(
        FakeConnectivityRepository(),
      ),
      activeUserRoleProvider.overrideWith((ref) => role),
      tournamentsControllerProvider.overrideWith((ref) {
        return TournamentsController(
          tournamentsRepository: FakeTournamentsRepository(tournaments),
          manageTournamentsUseCase: ref.watch(manageTournamentsUseCaseProvider),
        );
      }),
      teamsRepositoryProvider.overrideWithValue(FakeTeamsRepository(teams)),
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
      builder: (context, c) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
          child: c!,
        );
      },
      home: child,
    ),
  );
}

void main() {
  final tournament = ChampionshipTournament(
    id: 't-1',
    name: 'Liga Premier Apertura Torneo Regional',
    category: 'Libre Masculino Categoría A',
    format: TournamentFormat.league,
    status: TournamentStatus.inProgress,
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2026, 6, 30),
    updatedAt: DateTime(2026, 3, 1),
  );

  final player = const RegisteredPlayer(
    id: 'p-1',
    fullName: 'Carlos Alberto Gómez Rodríguez',
    documentId: 'DOC-1012345678',
    shirtNumber: 10,
    position: PlayerPosition.forward,
    isEligible: true,
  );

  final team = TournamentTeam(
    id: 'team-1',
    tournamentId: 't-1',
    name: 'Club Deportivo Tigres de la Montaña',
    shortCode: 'TIG',
    players: [player],
  );

  group('Compact Viewport (320x640) & 130% Text Scaling Validation', () {
    testWidgets('AppNavigationDrawer opens without RenderFlex overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createResponsiveApp(
          child: Scaffold(
            appBar: AppBar(
              leading: Builder(
                builder: (context) => IconButton(
                  key: const Key('app_bar_drawer_button'),
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            drawer: const AppNavigationDrawer(),
          ),
          tournaments: [tournament],
          teams: [team],
          role: UserRole.organizer,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Open drawer via drawer button
      await tester.tap(find.byKey(const Key('app_bar_drawer_button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('app_navigation_drawer')), findsOneWidget);
    });

    testWidgets('CompetitionsDirectoryScreen renders without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createResponsiveApp(
          child: const CompetitionsDirectoryScreen(),
          tournaments: [tournament],
          teams: [team],
          role: UserRole.organizer,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('competition_item_t-1')), findsOneWidget);
    });

    testWidgets('TeamsDirectoryScreen renders without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createResponsiveApp(
          child: const TeamsDirectoryScreen(),
          tournaments: [tournament],
          teams: [team],
          role: UserRole.organizer,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('team_item_team-1')), findsOneWidget);
    });

    testWidgets('PlayersDirectoryScreen renders without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createResponsiveApp(
          child: const PlayersDirectoryScreen(),
          tournaments: [tournament],
          teams: [team],
          role: UserRole.organizer,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('player_item_p-1')), findsOneWidget);
    });

    testWidgets(
      'PanelScreen renders without RenderFlex overflow at 320x640 with 130% text scaling',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final expectedRoleKeys = {
          UserRole.organizer: const Key('organizer_panel_content'),
          UserRole.coach: const Key('coach_panel_content'),
          UserRole.referee: const Key('referee_panel_content'),
          UserRole.player: const Key('player_panel_content'),
          UserRole.fan: const Key('fan_panel_restricted_content'),
        };

        for (final role in UserRole.values) {
          await tester.pumpWidget(
            createResponsiveApp(
              child: const PanelScreen(),
              tournaments: [tournament],
              teams: [team],
              role: role,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('panel_screen')), findsOneWidget);
          expect(find.byKey(const Key('panel_screen_title')), findsOneWidget);
          expect(find.byKey(expectedRoleKeys[role]!), findsOneWidget);
        }
      },
    );

    testWidgets(
      'AppShellScreen renders with 3 tabs without RenderFlex overflow at 320x640 with 130% text scaling',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createResponsiveApp(
            child: const AppShellScreen(),
            tournaments: [tournament],
            teams: [team],
            role: UserRole.organizer,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationDestination), findsNWidgets(3));
        expect(find.text('Explorar'), findsNothing);
      },
    );
  });
}
