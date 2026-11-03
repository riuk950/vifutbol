import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

/// Use case managing session rehydration, sports role switching, and logout.
class ManageSessionUseCase {
  const ManageSessionUseCase(this._authRepository);

  final AuthRepository _authRepository;

  /// Restores active session from isolated local persistence.
  Future<AuthSession?> restoreSession() async {
    return _authRepository.restoreSession();
  }

  /// Switches user active sports role among authorized roles.
  Future<UserAccount> switchActiveRole({
    required String userId,
    required UserRole targetRole,
  }) async {
    return _authRepository.switchActiveRole(
      userId: userId,
      targetRole: targetRole,
    );
  }

  /// Terminates active session and purges local session token.
  Future<void> signOut() async {
    await _authRepository.signOut();
  }
}
