import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/teams/dialogs/create_team_dialog.dart';

class MockTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  MockTeamsController() : super(const TeamsCatalogState());

  bool createTeamCalled = false;
  String? createdName;
  String? createdShortCode;
  String? createdCoachId;

  @override
  Future<bool> createTeam({
    required String name,
    required String shortCode,
    ChampionshipTournament? tournament,
    String coachId = 'coach-seed-1',
    UserRole actorRole = UserRole.coach,
  }) async {
    createTeamCalled = true;
    createdName = name;
    createdShortCode = shortCode;
    createdCoachId = coachId;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  MockTournamentsController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthController extends StateNotifier<AuthFlowState>
    implements AuthController {
  MockAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockTeamsController mockTeamsController;
  late MockTournamentsController mockTournamentsController;
  late MockAuthController mockAuthController;

  final sampleTournament = ChampionshipTournament(
    id: 'tourn-open-1',
    name: 'Copa Apertura Viña',
    category: 'Honor',
    startDate: DateTime(2026, 6, 1),
    endDate: DateTime(2026, 12, 1),
    format: TournamentFormat.league,
    status: TournamentStatus.openRegistration,
    rules: const TournamentRulesConfig(),
    updatedAt: DateTime(2026, 6, 1),
  );

  setUp(() {
    mockTeamsController = MockTeamsController();
    mockTournamentsController = MockTournamentsController(
      TournamentsCatalogState(
        viewState: UiSuccessState([sampleTournament]),
        tournaments: [sampleTournament],
      ),
    );
    mockAuthController = MockAuthController(
      AuthFlowState(
        status: AuthStatus.authenticated,
        session: AuthSession(
          sessionId: 'session-coach',
          user: UserAccount(
            id: 'coach-custom-99',
            fullName: 'DT Bielsa',
            email: 'dt@vifutbol.cl',
            activeRole: UserRole.coach,
            authorizedRoles: {UserRole.coach},
            isGuestFan: false,
            onboardingCompleted: true,
          ),
          sessionToken: 'token',
          authenticatedAt: DateTime.now(),
        ),
      ),
    );
  });

  Widget buildTestableWidget({required Widget child}) {
    return ProviderScope(
      overrides: [
        teamsControllerProvider.overrideWith((ref) => mockTeamsController),
        tournamentsControllerProvider.overrideWith(
          (ref) => mockTournamentsController,
        ),
        authControllerProvider.overrideWith((ref) => mockAuthController),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(body: child),
      ),
    );
  }

  group('CreateTeamDialog Widget Tests (US1)', () {
    testWidgets('renders all input fields, labels and buttons', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const CreateTeamDialog()),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create_team_dialog')), findsOneWidget);
      expect(find.byKey(const Key('create_team_name_input')), findsOneWidget);
      expect(
        find.byKey(const Key('create_team_short_code_input')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('create_team_tournament_dropdown')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('create_team_submit_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('create_team_cancel_button')),
        findsOneWidget,
      );
    });

    testWidgets(
      'validates required minimum name length and short code bounds',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(child: const CreateTeamDialog()),
        );
        await tester.pumpAndSettle();

        // Tap submit with empty inputs
        await tester.tap(find.byKey(const Key('create_team_submit_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('El nombre del equipo debe tener al menos 3 caracteres'),
          findsOneWidget,
        );
        expect(mockTeamsController.createTeamCalled, isFalse);

        // Enter 1 char in name and 1 char in shortCode
        await tester.enterText(
          find.byKey(const Key('create_team_name_input')),
          'FC',
        );
        await tester.enterText(
          find.byKey(const Key('create_team_short_code_input')),
          'F',
        );
        await tester.tap(find.byKey(const Key('create_team_submit_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('El nombre del equipo debe tener al menos 3 caracteres'),
          findsOneWidget,
        );
        expect(
          find.text('La sigla debe tener entre 2 y 4 caracteres'),
          findsOneWidget,
        );
        expect(mockTeamsController.createTeamCalled, isFalse);
      },
    );

    testWidgets(
      'submits valid autonomous team successfully with coach session ID',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => CreateTeamDialog.show(ctx),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('create_team_name_input')),
          'Deportivo Viña',
        );
        await tester.enterText(
          find.byKey(const Key('create_team_short_code_input')),
          'DVI',
        );

        await tester.tap(find.byKey(const Key('create_team_submit_button')));
        await tester.pumpAndSettle();

        expect(mockTeamsController.createTeamCalled, isTrue);
        expect(mockTeamsController.createdName, equals('Deportivo Viña'));
        expect(mockTeamsController.createdShortCode, equals('DVI'));
        expect(mockTeamsController.createdCoachId, equals('coach-custom-99'));

        // Dialog should be dismissed
        expect(find.byKey(const Key('create_team_dialog')), findsNothing);
      },
    );
  });
}
