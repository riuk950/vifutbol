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
import 'package:vifutbol/presentation/panel/models/panel_presentation_models.dart';
import 'package:vifutbol/presentation/panel/panel_screen.dart';
import 'package:vifutbol/presentation/panel/widgets/player_panel_content.dart';

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMatchesCatalogController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  FakeMatchesCatalogController({List<ChampionshipMatch> matches = const []})
    : super(MatchesCatalogState(matches: matches));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createPlayerPanelApp({
  List<TournamentTeam>? teams,
  List<ChampionshipMatch>? matches,
  Widget? home,
}) {
  final player1 = const RegisteredPlayer(
    id: 'p-1',
    fullName: 'Julián Álvarez',
    shirtNumber: 9,
    position: PlayerPosition.forward,
    documentId: 'DOC-998877',
    isEligible: true,
  );

  final defaultTeams =
      teams ??
      [
        TournamentTeam(
          id: 'team-halcones',
          tournamentId: 't-1',
          name: 'Halcones Dorados',
          shortCode: 'HAL',
          players: [player1],
        ),
      ];

  final defaultMatches =
      matches ??
      [
        ChampionshipMatch(
          id: 'match-next-1',
          tournamentId: 't-1',
          roundNumber: 3,
          roundName: 'Jornada 3',
          homeTeamId: 'team-halcones',
          awayTeamId: 'team-rivales',
          status: MatchStatus.scheduled,
          scheduledStartTime: DateTime(2026, 5, 2, 16, 0),
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
      activeUserRoleProvider.overrideWith((ref) => UserRole.player),
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
      home: home ?? const PanelScreen(),
    ),
  );
}

void main() {
  group('PlayerPanelContent', () {
    testWidgets(
      'renders player panel with eligibility badge and season stats',
      (tester) async {
        await tester.pumpWidget(createPlayerPanelApp());
        await tester.pumpAndSettle();

        // Verify Screen Title
        expect(find.byKey(const Key('panel_screen_title')), findsOneWidget);
        expect(find.text('Ficha del Jugador'), findsOneWidget);
        expect(find.byType(PlayerPanelContent), findsOneWidget);

        // Verify Player Identity
        expect(find.byKey(const Key('player_identity_card')), findsOneWidget);
        expect(find.text('Julián Álvarez'), findsOneWidget);
        expect(find.text('Halcones Dorados'), findsOneWidget);
        expect(find.text('#9'), findsOneWidget);

        // Verify Eligibility Badge (Habilitado)
        expect(
          find.byKey(const Key('player_eligibility_badge')),
          findsOneWidget,
        );
        expect(find.text('Habilitado'), findsOneWidget);

        // Verify Season Statistics Section
        expect(find.text('Estadísticas de Temporada'), findsOneWidget);
        expect(
          find.byKey(const Key('player_stat_matches_played')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('player_stat_goals')), findsOneWidget);
        expect(find.byKey(const Key('player_stat_assists')), findsOneWidget);
        expect(
          find.byKey(const Key('player_stat_yellow_cards')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('player_stat_red_cards')), findsOneWidget);

        // Verify Next Club Match Card
        expect(find.byKey(const Key('player_next_match_card')), findsOneWidget);
        expect(find.text('Jornada 3'), findsOneWidget);
        expect(find.text('TEAM-HALCONES vs TEAM-RIVALES'), findsOneWidget);
      },
    );

    testWidgets('renders Sancionado status when player is not eligible', (
      tester,
    ) async {
      const suspendedPlayer = RegisteredPlayer(
        id: 'p-suspended',
        fullName: 'Lucas Romero',
        shirtNumber: 4,
        position: PlayerPosition.defender,
        documentId: 'DOC-445566',
        isEligible: false,
      );

      final teams = [
        TournamentTeam(
          id: 'team-halcones',
          tournamentId: 't-1',
          name: 'Halcones Dorados',
          shortCode: 'HAL',
          players: [suspendedPlayer],
        ),
      ];

      await tester.pumpWidget(createPlayerPanelApp(teams: teams));
      await tester.pumpAndSettle();

      expect(find.text('Lucas Romero'), findsOneWidget);
      expect(find.byKey(const Key('player_eligibility_badge')), findsOneWidget);
      expect(find.text('Sancionado'), findsOneWidget);
    });

    testWidgets('renders customized PlayerPanelData stats correctly', (
      tester,
    ) async {
      const customPlayer = RegisteredPlayer(
        id: 'p-scorer',
        fullName: 'Mateo Retegui',
        shirtNumber: 19,
        position: PlayerPosition.forward,
        documentId: 'DOC-191919',
        isEligible: true,
      );

      final team = TournamentTeam(
        id: 'team-tigre',
        tournamentId: 't-1',
        name: 'Club Atlético Tigre',
        shortCode: 'CAT',
      );

      final data = PlayerPanelData(
        player: customPlayer,
        team: team,
        isEligible: true,
        goals: 12,
        assists: 5,
        yellowCards: 2,
        redCards: 1,
        matchesPlayed: 14,
      );

      await tester.pumpWidget(
        createPlayerPanelApp(
          home: Scaffold(body: PlayerPanelContent(data: data)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mateo Retegui'), findsOneWidget);
      expect(find.text('Club Atlético Tigre'), findsOneWidget);
      expect(find.text('#19'), findsOneWidget);
      expect(find.text('Habilitado'), findsOneWidget);

      // Verify specific numerical stat values
      expect(find.text('12'), findsOneWidget); // Goals
      expect(find.text('5'), findsOneWidget); // Assists
      expect(find.text('2'), findsOneWidget); // Yellow cards
      expect(find.text('1'), findsOneWidget); // Red cards
      expect(find.text('14'), findsOneWidget); // Matches played
    });
  });
}
