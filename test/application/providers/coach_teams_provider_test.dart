import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/auth_controller.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/auth_flow_state.dart';
import 'package:vifutbol/domain/entities/auth_session.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';

class SimpleTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  SimpleTeamsController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SimpleAuthController extends StateNotifier<AuthFlowState>
    implements AuthController {
  SimpleAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('coachTeamsProvider Unit Tests (US1)', () {
    final teamCoach1 = TournamentTeam(
      id: 'team-coach-1',
      name: 'Equipo Coach 1',
      shortCode: 'EC1',
      coachId: 'coach-123',
    );

    final teamSeed = TournamentTeam(
      id: 'team-seed-1',
      name: 'Equipo Seed',
      shortCode: 'ESD',
      coachId: 'coach-seed-1',
    );

    final teamOther = TournamentTeam(
      id: 'team-other-coach',
      name: 'Equipo Rival',
      shortCode: 'ERV',
      coachId: 'coach-other-999',
    );

    final teamNullCoach = TournamentTeam(
      id: 'team-no-coach',
      name: 'Equipo Sin Coach',
      shortCode: 'ESC',
      coachId: null,
    );

    test('filters teams strictly matching active coach ID', () {
      final authSession = AuthSession(
        sessionId: 'session-coach',
        user: UserAccount(
          id: 'coach-123',
          fullName: 'Entrenador Marcelo',
          email: 'marcelo@vifutbol.cl',
          activeRole: UserRole.coach,
          authorizedRoles: {UserRole.coach},
          isGuestFan: false,
          onboardingCompleted: true,
        ),
        sessionToken: 'token-abc',
        authenticatedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          teamsControllerProvider.overrideWith(
            (ref) => SimpleTeamsController(
              TeamsCatalogState(
                teams: [teamCoach1, teamSeed, teamOther, teamNullCoach],
              ),
            ),
          ),
          authControllerProvider.overrideWith(
            (ref) => SimpleAuthController(
              AuthFlowState(
                status: AuthStatus.authenticated,
                session: authSession,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final coachTeams = container.read(coachTeamsProvider);

      expect(coachTeams.length, equals(1));
      expect(coachTeams.first.id, equals('team-coach-1'));
      expect(coachTeams.map((t) => t.id), isNot(contains('team-seed-1')));
      expect(coachTeams.map((t) => t.id), isNot(contains('team-other-coach')));
      expect(coachTeams.map((t) => t.id), isNot(contains('team-no-coach')));
    });

    test(
      'retains coach-seed-1 teams when session has no active coach or is null',
      () {
        final container = ProviderContainer(
          overrides: [
            teamsControllerProvider.overrideWith(
              (ref) => SimpleTeamsController(
                TeamsCatalogState(
                  teams: [teamCoach1, teamSeed, teamOther, teamNullCoach],
                ),
              ),
            ),
            authControllerProvider.overrideWith(
              (ref) => SimpleAuthController(
                const AuthFlowState(status: AuthStatus.unauthenticated),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final coachTeams = container.read(coachTeamsProvider);

        expect(coachTeams.length, equals(1));
        expect(coachTeams.first.id, equals('team-seed-1'));
      },
    );
  });
}
