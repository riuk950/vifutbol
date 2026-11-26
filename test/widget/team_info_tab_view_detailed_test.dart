import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/teams_directory_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/directory_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/authenticate_user_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/team_directory_item.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/auth_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/directories/teams_directory_screen.dart';
import 'package:vifutbol/presentation/panel/widgets/coach_panel_content.dart';
import 'package:vifutbol/presentation/teams/models/team_match_summary.dart';
import 'package:vifutbol/presentation/teams/widgets/team_info_tab_view.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAuthenticateUserUseCase extends Mock
    implements AuthenticateUserUseCase {}

class _MockTeamsRepository extends Mock implements TeamsRepository {}

class _MockTournamentsRepository extends Mock implements TournamentsRepository {}

class _MockLocalStorageRepository extends Mock
    implements LocalStorageRepository {}

class _TestAuthController extends AuthController {
  _TestAuthController({
    required super.authRepository,
    required UserAccount user,
  }) : super(authenticateUserUseCase: _MockAuthenticateUserUseCase()) {
    state = AuthFlowState(
      status: AuthStatus.authenticated,
      session: AuthSession(
        sessionId: 's-info-1',
        user: user,
        sessionToken: 'tok-info-1',
        authenticatedAt: DateTime(2026, 11, 26),
      ),
    );
  }
}

void main() {
  late _MockAuthRepository authRepository;
  late _MockTeamsRepository teamsRepository;
  late _MockTournamentsRepository tournamentsRepository;
  late _MockLocalStorageRepository localStorageRepository;

  setUp(() {
    authRepository = _MockAuthRepository();
    teamsRepository = _MockTeamsRepository();
    tournamentsRepository = _MockTournamentsRepository();
    localStorageRepository = _MockLocalStorageRepository();
    when(() => teamsRepository.loadTeams()).thenAnswer((_) async => []);
    when(() => teamsRepository.loadAllTeams())
        .thenAnswer((_) async => <TeamDirectoryItem>[]);
    when(() => tournamentsRepository.loadTournaments())
        .thenAnswer((_) async => []);
    when(() => localStorageRepository.readString(any()))
        .thenAnswer((_) async => null);
    when(() => localStorageRepository.writeString(any(), any()))
        .thenAnswer((_) async {});
  });

  testWidgets(
    'TeamInfoTabView displays delegate, formatted founded date, and colors for detailed team',
    (tester) async {
      final detailedTeam = TournamentTeam(
        id: 'team-det-1',
        name: 'Atlético Andino',
        shortCode: 'AA',
        primaryColorHex: 0xFF2979FF,
        secondaryColorHex: 0xFFFFD600,
        delegateName: 'María Fernanda Gómez',
        foundedDate: DateTime(2019, 4, 5),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamMatchSummaryProvider('team-det-1').overrideWithValue(
              TeamMatchSummary(
                team: detailedTeam,
                tournament: null,
                lastPlayedMatch: null,
                nextScheduledMatch: null,
                lastMatchOpponent: null,
                nextMatchOpponent: null,
                isLastMatchHome: false,
                isNextMatchHome: false,
              ),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('es'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: TeamInfoTabView(teamId: 'team-det-1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('team_info_delegate_row')), findsOneWidget);
      expect(find.text('María Fernanda Gómez'), findsOneWidget);
      expect(
        find.byKey(const Key('team_info_founded_date_row')),
        findsOneWidget,
      );
      expect(find.text('05/04/2019'), findsOneWidget);
      expect(find.byKey(const Key('team_primary_color_swatch')), findsOneWidget);
      expect(
        find.byKey(const Key('team_secondary_color_swatch')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'TeamInfoTabView gracefully handles legacy teams without delegate or foundedDate',
    (tester) async {
      final legacyTeam = TournamentTeam(
        id: 'team-leg-1',
        name: 'Club Histórico',
        shortCode: 'CH',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamMatchSummaryProvider('team-leg-1').overrideWithValue(
              TeamMatchSummary(
                team: legacyTeam,
                tournament: null,
                lastPlayedMatch: null,
                nextScheduledMatch: null,
                lastMatchOpponent: null,
                nextMatchOpponent: null,
                isLastMatchHome: false,
                isNextMatchHome: false,
              ),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('es'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: TeamInfoTabView(teamId: 'team-leg-1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No registrado'), findsOneWidget);
      expect(find.text('No registrada'), findsOneWidget);
    },
  );

  testWidgets(
    'CoachPanelContent navigates to /teams/create instead of dialog',
    (tester) async {
      final coach = UserAccount(
        id: 'coach-nav-1',
        fullName: 'DT Nav',
        email: 'nav@vifutbol.com',
        activeRole: UserRole.coach,
        authorizedRoles: {UserRole.coach},
        onboardingCompleted: true,
      );

      var navigatedFromPanel = false;
      final authCtrl = _TestAuthController(
        authRepository: authRepository,
        user: coach,
      );
      final teamsCtrl = TeamsController(
        teamsRepository: teamsRepository,
        manageTeamsEligibilityUseCase:
            ManageTeamsEligibilityUseCase(teamsRepository),
      );
      final tournamentsCtrl = TournamentsController(
        tournamentsRepository: tournamentsRepository,
        manageTournamentsUseCase:
            ManageTournamentsUseCase(tournamentsRepository),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            environmentConfigProvider
                .overrideWithValue(EnvironmentConfig.development()),
            localStorageRepositoryProvider
                .overrideWithValue(localStorageRepository),
            authControllerProvider.overrideWith((_) => authCtrl),
            teamsControllerProvider.overrideWith((_) => teamsCtrl),
            tournamentsControllerProvider.overrideWith((_) => tournamentsCtrl),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routes: {
              '/teams/create': (_) {
                navigatedFromPanel = true;
                return const Scaffold(body: Text('Nueva Página Equipo'));
              },
            },
            home: const Scaffold(body: CoachPanelContent()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('coach_action_register_team_empty')),
      );
      await tester.pumpAndSettle();
      expect(navigatedFromPanel, isTrue);
    },
  );

  testWidgets(
    'TeamsDirectoryScreen navigates to /teams/create instead of dialog',
    (tester) async {
      final coach = UserAccount(
        id: 'coach-nav-2',
        fullName: 'DT Nav 2',
        email: 'nav2@vifutbol.com',
        activeRole: UserRole.coach,
        authorizedRoles: {UserRole.coach},
        onboardingCompleted: true,
      );

      var navigatedFromDirectory = false;
      final authCtrl = _TestAuthController(
        authRepository: authRepository,
        user: coach,
      );
      final teamsCtrl = TeamsController(
        teamsRepository: teamsRepository,
        manageTeamsEligibilityUseCase:
            ManageTeamsEligibilityUseCase(teamsRepository),
      );
      final dirCtrl = TeamsDirectoryController(
        teamsRepository: teamsRepository,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            environmentConfigProvider
                .overrideWithValue(EnvironmentConfig.development()),
            authControllerProvider.overrideWith((_) => authCtrl),
            teamsControllerProvider.overrideWith((_) => teamsCtrl),
            teamsDirectoryControllerProvider.overrideWith((_) => dirCtrl),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routes: {
              '/teams/create': (_) {
                navigatedFromDirectory = true;
                return const Scaffold(body: Text('Nueva Página Equipo'));
              },
            },
            home: const TeamsDirectoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('create_team_from_directory_button')),
      );
      await tester.pumpAndSettle();
      expect(navigatedFromDirectory, isTrue);
    },
  );
}
