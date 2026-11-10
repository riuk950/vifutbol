import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/use_cases/check_role_permission_use_case.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/user_role.dart';

void main() {
  const checkRolePermissionUseCase = CheckRolePermissionUseCase();

  group('RolePermissionMatrix & CheckRolePermissionUseCase unit tests (US2)', () {
    test(
      'organizer has official tournament, referee, and match management capabilities',
      () {
        final capabilities = RolePermissionMatrix.capabilitiesForRole(
          UserRole.organizer,
        );

        expect(capabilities, contains(RoleCapability.manageTournaments));
        expect(capabilities, contains(RoleCapability.manageVenues));
        expect(capabilities, contains(RoleCapability.approveRegistrations));
        expect(capabilities, contains(RoleCapability.assignReferees));
        expect(capabilities, contains(RoleCapability.recordMatchEvents));
        expect(capabilities, contains(RoleCapability.closeMatchReport));
        expect(capabilities, contains(RoleCapability.viewPersonalStats));
        expect(capabilities, contains(RoleCapability.viewPublicContent));

        // Cannot manage coach-specific lineups or team roster
        expect(capabilities, isNot(contains(RoleCapability.manageTeamRoster)));
        expect(capabilities, isNot(contains(RoleCapability.manageLineups)));
      },
    );

    test('coach has roster and tactical lineup capabilities only', () {
      final capabilities = RolePermissionMatrix.capabilitiesForRole(
        UserRole.coach,
      );

      expect(capabilities, contains(RoleCapability.manageTeamRoster));
      expect(capabilities, contains(RoleCapability.manageLineups));
      expect(capabilities, contains(RoleCapability.viewPersonalStats));
      expect(capabilities, contains(RoleCapability.viewPublicContent));

      expect(capabilities, isNot(contains(RoleCapability.manageTournaments)));
      expect(capabilities, isNot(contains(RoleCapability.assignReferees)));
      expect(capabilities, isNot(contains(RoleCapability.closeMatchReport)));
    });

    test(
      'referee has match event recording and report closing capabilities',
      () {
        final capabilities = RolePermissionMatrix.capabilitiesForRole(
          UserRole.referee,
        );

        expect(capabilities, contains(RoleCapability.recordMatchEvents));
        expect(capabilities, contains(RoleCapability.closeMatchReport));
        expect(capabilities, contains(RoleCapability.viewPersonalStats));
        expect(capabilities, contains(RoleCapability.viewPublicContent));

        expect(capabilities, isNot(contains(RoleCapability.manageTournaments)));
        expect(capabilities, isNot(contains(RoleCapability.manageTeamRoster)));
      },
    );

    test(
      'manageTeamRoster capability is strictly exclusive to UserRole.coach',
      () {
        for (final role in UserRole.values) {
          final hasManageRoster = RolePermissionMatrix.hasCapability(
            role,
            RoleCapability.manageTeamRoster,
          );
          if (role == UserRole.coach) {
            expect(
              hasManageRoster,
              isTrue,
              reason: 'Coach must have manageTeamRoster',
            );
          } else {
            expect(
              hasManageRoster,
              isFalse,
              reason: '${role.name} must NOT have manageTeamRoster',
            );
          }
        }
      },
    );

    test('player has only personal stats and public browsing capabilities', () {
      final capabilities = RolePermissionMatrix.capabilitiesForRole(
        UserRole.player,
      );

      expect(capabilities, contains(RoleCapability.viewPersonalStats));
      expect(capabilities, contains(RoleCapability.viewPublicContent));
      expect(capabilities.length, equals(2));
    });

    test('fan has strictly public browsing capability', () {
      final capabilities = RolePermissionMatrix.capabilitiesForRole(
        UserRole.fan,
      );

      expect(capabilities, contains(RoleCapability.viewPublicContent));
      expect(capabilities.length, equals(1));
    });

    test('guest fan is always restricted to public content only', () {
      expect(
        checkRolePermissionUseCase.hasPermission(
          role: UserRole.organizer,
          capability: RoleCapability.manageTournaments,
          isGuestFan: true,
        ),
        isFalse,
      );

      expect(
        checkRolePermissionUseCase.hasPermission(
          role: UserRole.organizer,
          capability: RoleCapability.viewPublicContent,
          isGuestFan: true,
        ),
        isTrue,
      );
    });

    test(
      'validates authorization code requirements per environment and role',
      () {
        expect(UserRole.organizer.requiresAuthorizationCodeInProd, isTrue);
        expect(UserRole.referee.requiresAuthorizationCodeInProd, isTrue);
        expect(UserRole.coach.requiresAuthorizationCodeInProd, isFalse);
        expect(UserRole.player.requiresAuthorizationCodeInProd, isFalse);
        expect(UserRole.fan.requiresAuthorizationCodeInProd, isFalse);
      },
    );
  });
}
