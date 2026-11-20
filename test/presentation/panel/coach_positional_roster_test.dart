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
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
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

class _MutableTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  _MutableTeamsController({List<TournamentTeam> teams = const []})
      : super(TeamsCatalogState(teams: teams));

  void updateTeams(List<TournamentTeam> newTeams) {
    state = state.copyWith(teams: newTeams);
  }

  @override
  void selectTeam(String? teamId) {
    state = state.copyWith(selectedTeamId: teamId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMatchesCatalogController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  _FakeMatchesCatalogController() : super(const MatchesCatalogState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const coachUserId = 'coach-seed-1';

  Widget createTestWidget({
    required Widget child,
    required _MutableTeamsController teamsController,
    Size screenSize = const Size(800, 1400),
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
        activeUserRoleProvider.overrideWith((ref) => UserRole.coach),
        teamsControllerProvider.overrideWith((ref) => teamsController),
        matchesCatalogControllerProvider.overrideWith(
          (ref) => _FakeMatchesCatalogController(),
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
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('CoachPositionalRosterSection in CoachPanelContent (HU 20.2)', () {
    testWidgets(
      '[US1] Displays 4 tactical lines in strict order, dynamic counts, ascending shirt order, and eligibility badges',
      (tester) async {
        final fullTeam = TournamentTeam(
          id: 'team-coach-1',
          tournamentId: 't-1',
          name: 'Real Titanes FC',
          shortCode: 'TIT',
          coachId: coachUserId,
          players: const [
            RegisteredPlayer(
              id: 'gk-13',
              fullName: 'David De Gea',
              shirtNumber: 13,
              position: PlayerPosition.goalkeeper,
              documentId: 'DOC-GK-13',
              isEligible: true,
            ),
            RegisteredPlayer(
              id: 'gk-1',
              fullName: 'Iker Casillas',
              shirtNumber: 1,
              position: PlayerPosition.goalkeeper,
              documentId: 'DOC-GK-1',
              isEligible: false,
            ),
            RegisteredPlayer(
              id: 'def-4',
              fullName: 'Sergio Ramos',
              shirtNumber: 4,
              position: PlayerPosition.defender,
              documentId: 'DOC-DEF-4',
              isEligible: true,
            ),
            RegisteredPlayer(
              id: 'def-2',
              fullName: 'Dani Carvajal',
              shirtNumber: 2,
              position: PlayerPosition.defender,
              documentId: 'DOC-DEF-2',
              isEligible: false,
            ),
            RegisteredPlayer(
              id: 'mid-10',
              fullName: 'Luka Modric',
              shirtNumber: 10,
              position: PlayerPosition.midfielder,
              documentId: 'DOC-MID-10',
              isEligible: true,
            ),
            RegisteredPlayer(
              id: 'mid-8',
              fullName: 'Toni Kroos',
              shirtNumber: 8,
              position: PlayerPosition.midfielder,
              documentId: 'DOC-MID-8',
              isEligible: true,
            ),
            RegisteredPlayer(
              id: 'fwd-9',
              fullName: 'Karim Benzema',
              shirtNumber: 9,
              position: PlayerPosition.forward,
              documentId: 'DOC-FWD-9',
              isEligible: true,
            ),
            RegisteredPlayer(
              id: 'fwd-7',
              fullName: 'Cristiano Ronaldo',
              shirtNumber: 7,
              position: PlayerPosition.forward,
              documentId: 'DOC-FWD-7',
              isEligible: false,
            ),
          ],
        );

        final teamsController = _MutableTeamsController(teams: [fullTeam]);

        await tester.pumpWidget(
          createTestWidget(
            child: const CoachPanelContent(),
            teamsController: teamsController,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify Section Container exists
        expect(find.byKey(const Key('coach_positional_roster_section')), findsOneWidget);
        expect(find.text('Plantilla por Posición'), findsOneWidget);

        // 2. No goalkeeper warning when goalkeepers exist
        expect(find.byKey(const Key('coach_no_goalkeeper_tactical_alert')), findsNothing);

        // 3. Verify 4 Tactical Groups in strict visual order (Y coordinate top to bottom)
        final gkGroupFinder = find.byKey(const Key('coach_roster_group_goalkeeper'));
        final defGroupFinder = find.byKey(const Key('coach_roster_group_defender'));
        final midGroupFinder = find.byKey(const Key('coach_roster_group_midfielder'));
        final fwdGroupFinder = find.byKey(const Key('coach_roster_group_forward'));

        expect(gkGroupFinder, findsOneWidget);
        expect(defGroupFinder, findsOneWidget);
        expect(midGroupFinder, findsOneWidget);
        expect(fwdGroupFinder, findsOneWidget);

        final gkTop = tester.getTopLeft(gkGroupFinder).dy;
        final defTop = tester.getTopLeft(defGroupFinder).dy;
        final midTop = tester.getTopLeft(midGroupFinder).dy;
        final fwdTop = tester.getTopLeft(fwdGroupFinder).dy;

        expect(gkTop, lessThan(defTop));
        expect(defTop, lessThan(midTop));
        expect(midTop, lessThan(fwdTop));

        // 4. Verify Dynamic Counts
        expect(find.text('Porteros (2)'), findsOneWidget);
        expect(find.text('Defensas (2)'), findsOneWidget);
        expect(find.text('Mediocampistas (2)'), findsOneWidget);
        expect(find.text('Delanteros (2)'), findsOneWidget);

        // 5. Verify Ascending Shirt Order inside lines
        // Goalkeepers: Iker (#1) must be visually above David (#13)
        final ikerFinder = find.byKey(const Key('coach_roster_player_1_gk-1'));
        final deGeaFinder = find.byKey(const Key('coach_roster_player_13_gk-13'));
        expect(ikerFinder, findsOneWidget);
        expect(deGeaFinder, findsOneWidget);
        expect(tester.getTopLeft(ikerFinder).dy, lessThan(tester.getTopLeft(deGeaFinder).dy));

        // Defenders: Dani (#2) above Sergio (#4)
        final carvajalFinder = find.byKey(const Key('coach_roster_player_2_def-2'));
        final ramosFinder = find.byKey(const Key('coach_roster_player_4_def-4'));
        expect(carvajalFinder, findsOneWidget);
        expect(ramosFinder, findsOneWidget);
        expect(tester.getTopLeft(carvajalFinder).dy, lessThan(tester.getTopLeft(ramosFinder).dy));

        // 6. Verify Eligibility Badges
        // 5 eligible players, 3 inactive/suspended
        expect(find.text('Elegible'), findsNWidgets(5));
        expect(find.text('Inactivo / Sancionado'), findsNWidgets(3));
      },
    );

    testWidgets(
      '[US2] Displays subtle empty state for positions without players and tactical alert when goalkeepers are missing',
      (tester) async {
        final teamWithoutGkAndMid = TournamentTeam(
          id: 'team-coach-2',
          tournamentId: 't-1',
          name: 'Sin Portero FC',
          shortCode: 'SPG',
          coachId: coachUserId,
          players: const [
            RegisteredPlayer(
              id: 'def-3',
              fullName: 'Gerard Piqué',
              shirtNumber: 3,
              position: PlayerPosition.defender,
              documentId: 'DOC-DEF-3',
              isEligible: true,
            ),
            RegisteredPlayer(
              id: 'fwd-11',
              fullName: 'Neymar Jr',
              shirtNumber: 11,
              position: PlayerPosition.forward,
              documentId: 'DOC-FWD-11',
              isEligible: true,
            ),
          ],
        );

        final teamsController = _MutableTeamsController(teams: [teamWithoutGkAndMid]);

        await tester.pumpWidget(
          createTestWidget(
            child: const CoachPanelContent(),
            teamsController: teamsController,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Missing Goalkeeper Alert must be visible
        expect(find.byKey(const Key('coach_no_goalkeeper_tactical_alert')), findsOneWidget);
        expect(find.text('Alerta táctica: El equipo no tiene porteros registrados.'), findsOneWidget);

        // 2. Dynamic counts reflect 0
        expect(find.text('Porteros (0)'), findsOneWidget);
        expect(find.text('Defensas (1)'), findsOneWidget);
        expect(find.text('Mediocampistas (0)'), findsOneWidget);
        expect(find.text('Delanteros (1)'), findsOneWidget);

        // 3. Subtle empty state for goalkeeper and midfielder
        expect(find.byKey(const Key('coach_roster_empty_goalkeeper')), findsOneWidget);
        expect(find.byKey(const Key('coach_roster_empty_midfielder')), findsOneWidget);
        expect(find.text('Sin jugadores en esta posición'), findsNWidgets(2));
      },
    );

    testWidgets(
      '[US3] Reactively updates positional blocks and dismisses goalkeeper alert when roster is updated in controller',
      (tester) async {
        final initialTeam = TournamentTeam(
          id: 'team-coach-3',
          tournamentId: 't-1',
          name: 'Mutante FC',
          shortCode: 'MTC',
          coachId: coachUserId,
          players: const [
            RegisteredPlayer(
              id: 'fwd-9',
              fullName: 'Luis Suárez',
              shirtNumber: 9,
              position: PlayerPosition.forward,
              documentId: 'DOC-FWD-9',
              isEligible: true,
            ),
          ],
        );

        final teamsController = _MutableTeamsController(teams: [initialTeam]);

        await tester.pumpWidget(
          createTestWidget(
            child: const CoachPanelContent(),
            teamsController: teamsController,
          ),
        );
        await tester.pumpAndSettle();

        // Before update: alert visible, Porteros (0)
        expect(find.byKey(const Key('coach_no_goalkeeper_tactical_alert')), findsOneWidget);
        expect(find.text('Porteros (0)'), findsOneWidget);

        // Mutate team: add a goalkeeper
        final updatedTeam = initialTeam.copyWith(
          players: [
            ...initialTeam.players,
            const RegisteredPlayer(
              id: 'gk-1',
              fullName: 'Marc-André ter Stegen',
              shirtNumber: 1,
              position: PlayerPosition.goalkeeper,
              documentId: 'DOC-GK-1',
              isEligible: true,
            ),
          ],
        );

        teamsController.updateTeams([updatedTeam]);
        await tester.pumpAndSettle();

        // After update: alert dismissed, Porteros (1), ter Stegen visible
        expect(find.byKey(const Key('coach_no_goalkeeper_tactical_alert')), findsNothing);
        expect(find.text('Porteros (1)'), findsOneWidget);
        expect(find.text('Marc-André ter Stegen'), findsOneWidget);
        expect(find.byKey(const Key('coach_roster_player_1_gk-1')), findsOneWidget);
      },
    );

    testWidgets(
      'Renders cleanly without overflow on compact 320px width screen',
      (tester) async {
        final fullTeam = TournamentTeam(
          id: 'team-coach-4',
          tournamentId: 't-1',
          name: 'Compact Test FC',
          shortCode: 'CTC',
          coachId: coachUserId,
          players: const [
            RegisteredPlayer(
              id: 'gk-1',
              fullName: 'Very Long Player Name For Testing Screen Limits',
              shirtNumber: 99,
              position: PlayerPosition.goalkeeper,
              documentId: 'DOC-99',
              isEligible: false,
            ),
          ],
        );

        final teamsController = _MutableTeamsController(teams: [fullTeam]);

        await tester.pumpWidget(
          createTestWidget(
            child: const CoachPanelContent(),
            teamsController: teamsController,
            screenSize: const Size(320, 800),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('coach_positional_roster_section')), findsOneWidget);
      },
    );
  });
}
