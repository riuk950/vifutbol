import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/panel/panel_screen.dart';
import 'package:vifutbol/presentation/panel/widgets/coach_panel_content.dart';

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

class FakeTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  FakeTeamsController({List<TournamentTeam> teams = const []})
    : super(TeamsCatalogState(teams: teams));

  @override
  void selectTeam(String? teamId) {
    state = state.copyWith(selectedTeamId: teamId);
  }

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

Widget createCoachPanelApp({
  List<TournamentTeam>? teams,
  List<ChampionshipMatch>? matches,
}) {
  final player1 = const RegisteredPlayer(
    id: 'p-1',
    fullName: 'Carlos Gómez',
    shirtNumber: 10,
    position: PlayerPosition.forward,
    documentId: 'DOC-123456',
    isEligible: true,
  );

  final player2 = const RegisteredPlayer(
    id: 'p-2',
    fullName: 'Mateo Rodríguez',
    shirtNumber: 5,
    position: PlayerPosition.midfielder,
    documentId: 'DOC-234567',
    isEligible: false, // suspended
  );

  final defaultTeams =
      teams ??
      [
        TournamentTeam(
          id: 'team-tigres',
          tournamentId: 't-1',
          name: 'Tigres del Prado',
          shortCode: 'TDP',
          players: [player1, player2],
        ),
      ];

  final defaultMatches =
      matches ??
      [
        ChampionshipMatch(
          id: 'm-upcoming-1',
          tournamentId: 't-1',
          roundNumber: 2,
          roundName: 'Jornada 2',
          homeTeamId: 'team-tigres',
          awayTeamId: 'team-aguilas',
          status: MatchStatus.scheduled,
          scheduledStartTime: DateTime(2026, 4, 15, 14, 0),
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
      activeUserRoleProvider.overrideWith((ref) => UserRole.coach),
      teamsControllerProvider.overrideWith(
        (ref) => FakeTeamsController(teams: defaultTeams),
      ),
      matchesCatalogControllerProvider.overrideWith(
        (ref) => FakeMatchesCatalogController(matches: defaultMatches),
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
      routes: {
        '/tournaments/teams/detail': (context) => const Scaffold(
          body: Text('Team Roster Detail Destination'),
        ),
      },
    ),
  );
}

void main() {
  group('CoachPanelContent Widget Tests (US2 - P2)', () {
    testWidgets('renders Coach AppBar title, team summary and squad metrics', (
      tester,
    ) async {
      await tester.pumpWidget(createCoachPanelApp());
      await tester.pumpAndSettle();

      // Verify AppBar title
      expect(find.text('Panel Técnico'), findsOneWidget);
      expect(find.byType(CoachPanelContent), findsOneWidget);

      // Verify Team Name & ShortCode
      expect(find.text('Tigres del Prado'), findsOneWidget);
      expect(find.text('TDP'), findsOneWidget);

      // Verify Squad Metric Cards
      expect(
        find.byKey(const Key('coach_metric_total_players')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('coach_metric_eligible_players')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('coach_metric_suspended_players')),
        findsOneWidget,
      );

      // Values (2 total, 1 eligible, 1 suspended)
      expect(find.text('2'), findsWidgets);
      expect(find.text('1'), findsWidgets);

      // Verify Next Match Card
      expect(find.byKey(const Key('coach_next_match_card')), findsOneWidget);
      expect(find.text('Jornada 2'), findsOneWidget);
      expect(find.text('TEAM-TIGRES vs TEAM-AGUILAS'), findsOneWidget);

      // Verify Quick Action Buttons
      expect(
        find.byKey(const Key('coach_action_match_lineup')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('coach_action_manage_roster')),
        findsOneWidget,
      );
    });

    testWidgets('Tapping quick actions displays feedback snackbars', (
      tester,
    ) async {
      await tester.pumpWidget(createCoachPanelApp());
      await tester.pumpAndSettle();

      // Tap Convocatoria
      final lineupBtn = find.byKey(const Key('coach_action_match_lineup'));
      await tester.ensureVisible(lineupBtn);
      await tester.tap(lineupBtn);
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Convocatoria para el Próximo Partido: Tigres del Prado',
        ),
        findsOneWidget,
      );

      // Tap Gestionar Plantilla
      await tester.tap(find.byKey(const Key('coach_action_manage_roster')));
      await tester.pumpAndSettle();
      expect(
        find.text('Team Roster Detail Destination'),
        findsOneWidget,
      );
    });
  });
}
