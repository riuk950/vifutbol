import '../entities/auth_session.dart';
import '../entities/role_profile_data.dart';
import '../entities/user_account.dart';
import '../entities/user_role.dart';

/// Contract defining authentication, guest session, and role onboarding operations.
abstract class AuthRepository {
  /// Restores any persisted authentication session from local storage.
  /// Returns `null` if no active session is found.
  Future<AuthSession?> restoreSession();

  /// Authenticates an existing user account using email and password.
  /// Enforces network connectivity and lockout guards.
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registers a new user account with initial uncompleted onboarding state.
  /// Enforces email normalization and network connectivity.
  Future<AuthSession> registerAccount({
    required String fullName,
    required String email,
    required String password,
  });

  /// Creates and persists an offline guest session assigned to [UserRole.fan].
  /// Operates seamlessly without network connectivity.
  Future<AuthSession> continueAsGuestFan();

  /// Completes mandatory onboarding for the user account by assigning the initial active role.
  /// Validates authorization codes for roles that require them in production.
  Future<UserAccount> completeRoleOnboarding({
    required String userId,
    required UserRole selectedRole,
    String? authorizationCode,
  });

  /// Switches the active role for the current user among authorized roles.
  Future<UserAccount> switchActiveRole({
    required String userId,
    required UserRole targetRole,
  });

  /// Updates personal contact/document data and role-specific profile attributes
  /// in the cloud, linking existing athlete or referee records by document when applicable.
  Future<UserAccount> updateRoleProfile({
    required String userId,
    required UserRole role,
    String? fullName,
    String? phone,
    String? documentId,
    RoleProfileData? roleProfile,
  });

  /// Permanently deletes the authenticated user account and all associated
  /// personal data across cloud and local storage.
  Future<void> deleteAccount({required String userId});

  /// Clears stored authentication session and returns the user to unauthenticated state.
  Future<void> signOut();

  /// Emits session lifecycle updates when the underlying auth provider refreshes or invalidates a session.
  Stream<AuthSession?> get onSessionStateChanged => const Stream.empty();
}
