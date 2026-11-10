import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_teams_tab_view.dart';

import '../../test_helpers/teams_eligibility_test_helper.dart';

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

class _FakeTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  _FakeTournamentsController(ChampionshipTournament tournament)
    : super(
        TournamentsCatalogState(
          viewState: UiSuccessState<List<ChampionshipTournament>>([tournament]),
          tournaments: [tournament],
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  _FakeTeamsController(List<TournamentTeam> teams)
    : super(TeamsCatalogState(teams: teams));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildRoleTestApp({
  required ChampionshipTournament tournament,
  required List<TournamentTeam> teams,
  required UserRole role,
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
      tournamentsControllerProvider.overrideWith(
        (ref) => _FakeTournamentsController(tournament),
      ),
      teamsControllerProvider.overrideWith(
        (ref) => _FakeTeamsController(teams),
      ),
      activeUserRoleProvider.overrideWithValue(role),
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
        body: CompetitionTeamsTabView(tournamentId: tournament.id),
      ),
    ),
  );
}

void main() {
  group(
    'CompetitionTeamsTabView Role Visibility & Roster Count Tests (HU 16.3 / US2)',
    () {
      testWidgets(
        'renders correct roster count text for incomplete (<11) and complete (>=11) teams',
        (tester) async {
          final tournament = createTestTournament(minPlayers: 11);
          final team9 = createTestTeam(
            id: 'team-9',
            tournamentId: tournament.id,
            name: 'Incomplete Team',
            shortCode: 'INC',
            playerCount: 9,
          );
          final team12 = createTestTeam(
            id: 'team-12',
            tournamentId: tournament.id,
            name: 'Complete Team',
            shortCode: 'COM',
            playerCount: 12,
            status: TeamEligibilityStatus.eligible,
          );

          await tester.pumpWidget(
            _buildRoleTestApp(
              tournament: tournament,
              teams: [team9, team12],
              role: UserRole.organizer,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('9/11 jugadores - Incompleto'), findsOneWidget);
          expect(find.text('12 jugadores - Nómina válida'), findsOneWidget);
        },
      );

      testWidgets('shows action buttons for organizer', (tester) async {
        final tournament = createTestTournament(minPlayers: 11);
        final team9 = createTestTeam(
          id: 'team-9',
          tournamentId: tournament.id,
          playerCount: 9,
          status: TeamEligibilityStatus.pendingVerification,
        );
        final team12 = createTestTeam(
          id: 'team-12',
          tournamentId: tournament.id,
          playerCount: 12,
          status: TeamEligibilityStatus.eligible,
        );

        await tester.pumpWidget(
          _buildRoleTestApp(
            tournament: tournament,
            teams: [team9, team12],
            role: UserRole.organizer,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(Key('competition_team_action_approve_${team9.id}')),
          findsOneWidget,
        );
        expect(
          find.byKey(Key('competition_team_action_revoke_${team12.id}')),
          findsOneWidget,
        );
      });

      testWidgets(
        'hides approval and revocation action buttons for non-organizer roles',
        (tester) async {
          final tournament = createTestTournament(minPlayers: 11);
          final team9 = createTestTeam(
            id: 'team-9',
            tournamentId: tournament.id,
            playerCount: 9,
            status: TeamEligibilityStatus.pendingVerification,
          );
          final team12 = createTestTeam(
            id: 'team-12',
            tournamentId: tournament.id,
            playerCount: 12,
            status: TeamEligibilityStatus.eligible,
          );

          for (final nonOrganizerRole in [
            UserRole.coach,
            UserRole.referee,
            UserRole.player,
            UserRole.fan,
          ]) {
            await tester.pumpWidget(
              _buildRoleTestApp(
                tournament: tournament,
                teams: [team9, team12],
                role: nonOrganizerRole,
              ),
            );
            await tester.pumpAndSettle();

            // Roster counts are visible in read-only mode for all roles
            expect(find.text('9/11 jugadores - Incompleto'), findsOneWidget);
            expect(find.text('12 jugadores - Nómina válida'), findsOneWidget);

            // Action buttons are strictly hidden
            expect(
              find.byKey(Key('competition_team_action_approve_${team9.id}')),
              findsNothing,
              reason:
                  'Approve button must be hidden for role $nonOrganizerRole',
            );
            expect(
              find.byKey(Key('competition_team_action_revoke_${team12.id}')),
              findsNothing,
              reason: 'Revoke button must be hidden for role $nonOrganizerRole',
            );
          }
        },
      );
    },
  );
}
