import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/panel/widgets/coach_panel_content.dart';

class _FakeTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  _FakeTeamsController({List<TournamentTeam> teams = const []})
      : super(TeamsCatalogState(teams: teams));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMatchesController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  _FakeMatchesController() : super(const MatchesCatalogState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthController extends StateNotifier<AuthFlowState>
    implements AuthController {
  _FakeAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildWidget({
    required List<TournamentTeam> teams,
    String coachId = 'coach-123',
  }) {
    final session = AuthSession(
      sessionId: 'session-coach',
      user: UserAccount(
        id: coachId,
        fullName: 'DT Entrenador',
        email: 'dt@vifutbol.cl',
        activeRole: UserRole.coach,
        authorizedRoles: {UserRole.coach},
        isGuestFan: false,
        onboardingCompleted: true,
      ),
      sessionToken: 'token',
      authenticatedAt: DateTime.now(),
    );

    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _FakeAuthController(
            AuthFlowState(status: AuthStatus.authenticated, session: session),
          ),
        ),
        teamsControllerProvider.overrideWith(
          (ref) => _FakeTeamsController(teams: teams),
        ),
        matchesCatalogControllerProvider.overrideWith(
          (ref) => _FakeMatchesController(),
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
        home: const Scaffold(body: CoachPanelContent()),
      ),
    );
  }

  group('CoachPanelContent Empty State & Roster Display Widget Tests (US1)', () {
    testWidgets('renders coach_no_team_card when coach has no registered teams', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(teams: []));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('coach_no_team_card')), findsOneWidget);
      expect(find.text('Sin Equipo Registrado'), findsOneWidget);
      expect(
        find.text(
          'Aún no tienes ningún equipo registrado bajo tu gestión como entrenador.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('coach_action_register_team_empty')),
        findsOneWidget,
      );
      expect(find.text('Registrar mi Equipo'), findsOneWidget);

      // Verify normal metrics are NOT rendered
      expect(
        find.byKey(const Key('coach_metric_total_players')),
        findsNothing,
      );
    });

    testWidgets('renders squad metrics when coach has a registered team', (
      tester,
    ) async {
      final team = TournamentTeam(
        id: 'team-active-1',
        name: 'Unión Viña',
        shortCode: 'UVI',
        coachId: 'coach-123',
        players: const [
          RegisteredPlayer(
            id: 'player-1',
            fullName: 'Arturo Vidal',
            documentId: '12345678-9',
            shirtNumber: 23,
            position: PlayerPosition.midfielder,
            isEligible: true,
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(teams: [team]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('coach_no_team_card')), findsNothing);
      expect(find.text('Unión Viña'), findsOneWidget);
      expect(find.text('UVI'), findsOneWidget);
      expect(
        find.byKey(const Key('coach_metric_total_players')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('coach_metric_eligible_players')),
        findsOneWidget,
      );
    });
  });
}
