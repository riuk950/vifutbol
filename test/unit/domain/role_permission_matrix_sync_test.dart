import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/user_role.dart';

void main() {
  group('RolePermissionMatrix sync visibility capability', () {
    test('grants viewCloudSyncIndicator exclusively to operational roles', () {
      expect(
        RolePermissionMatrix.hasCapability(
          UserRole.organizer,
          RoleCapability.viewCloudSyncIndicator,
        ),
        isTrue,
      );
      expect(
        RolePermissionMatrix.hasCapability(
          UserRole.coach,
          RoleCapability.viewCloudSyncIndicator,
        ),
        isTrue,
      );
      expect(
        RolePermissionMatrix.hasCapability(
          UserRole.referee,
          RoleCapability.viewCloudSyncIndicator,
        ),
        isTrue,
      );
      expect(
        RolePermissionMatrix.hasCapability(
          UserRole.player,
          RoleCapability.viewCloudSyncIndicator,
        ),
        isFalse,
      );
      expect(
        RolePermissionMatrix.hasCapability(
          UserRole.fan,
          RoleCapability.viewCloudSyncIndicator,
        ),
        isFalse,
      );
    });
  });
}
