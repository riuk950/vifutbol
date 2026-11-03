import '../../domain/entities/role_permission_matrix.dart';
import '../../domain/entities/user_role.dart';

/// Use case evaluating sports role authorization against required capabilities.
class CheckRolePermissionUseCase {
  const CheckRolePermissionUseCase();

  /// Returns true if [role] is authorized to execute [capability].
  bool hasPermission({
    required UserRole role,
    required RoleCapability capability,
    bool isGuestFan = false,
  }) {
    if (isGuestFan) {
      return capability == RoleCapability.viewPublicContent;
    }
    return RolePermissionMatrix.hasCapability(role, capability);
  }

  /// Returns the complete set of capabilities granted to [role].
  Set<RoleCapability> getCapabilitiesForRole({
    required UserRole role,
    bool isGuestFan = false,
  }) {
    if (isGuestFan) {
      return const {RoleCapability.viewPublicContent};
    }
    return RolePermissionMatrix.capabilitiesForRole(role);
  }
}
