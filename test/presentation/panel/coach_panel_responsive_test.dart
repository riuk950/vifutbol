import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/matches_catalog_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/panel/widgets/coach_panel_content.dart';
import 'package:vifutbol/presentation/teams/dialogs/create_team_dialog.dart';

class _FakeTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  _FakeTeamsController({List<TournamentTeam> teams = const []})
      : super(TeamsCatalogState(teams: teams));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMatchesController extends StateNotifier<MatchesCatalogState>
    implements MatchesCatalogController {
  _FakeMatchesController({List<ChampionshipMatch> matches = const []})
      : super(MatchesCatalogState(matches: matches));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthController extends StateNotifier<AuthFlowState>
    implements AuthController {
  _FakeAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  _FakeTournamentsController()
      : super(
          const TournamentsCatalogState(
            viewState: UiSuccessState<List<ChampionshipTournament>>([]),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildResponsiveApp({
    required Widget child,
    List<TournamentTeam> teams = const [],
    List<ChampionshipMatch> matches = const [],
  }) {
    final session = AuthSession(
      sessionId: 'session-coach',
      user: UserAccount(
        id: 'coach-123',
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
          (ref) => _FakeMatchesController(matches: matches),
        ),
        tournamentsControllerProvider.overrideWith(
          (ref) => _FakeTournamentsController(),
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
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  group('CoachPanel Responsive Tests (320x640 at 130% scaling)', () {
    testWidgets('empty state card renders without RenderFlex overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildResponsiveApp(child: const CoachPanelContent(), teams: const []),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('coach_no_team_card')), findsOneWidget);
      expect(
        find.byKey(const Key('coach_action_register_team_empty')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('populated panel renders without RenderFlex overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final team = TournamentTeam(
        id: 'team-active-1',
        name: 'Club Atlético Viña del Mar',
        shortCode: 'CAVM',
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
          RegisteredPlayer(
            id: 'player-2',
            fullName: 'Alexis Sánchez',
            documentId: '12345678-0',
            shirtNumber: 7,
            position: PlayerPosition.forward,
            isEligible: false,
          ),
        ],
      );

      final nextMatch = ChampionshipMatch(
        id: 'm-1',
        tournamentId: 'tourn-1',
        roundNumber: 1,
        roundName: 'Jornada 1',
        homeTeamId: team.id,
        awayTeamId: 'team-other',
      );

      await tester.pumpWidget(
        buildResponsiveApp(
          child: const CoachPanelContent(),
          teams: [team],
          matches: [nextMatch],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('coach_panel_content')), findsOneWidget);
      expect(find.text('Club Atlético Viña del Mar'), findsOneWidget);
      expect(
        find.byKey(const Key('coach_metric_total_players')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('coach_next_match_card')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CreateTeamDialog renders without RenderFlex overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildResponsiveApp(
          child: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => CreateTeamDialog.show(ctx),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create_team_dialog')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
