import '../../domain/entities/user_account.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// Use case orchestrating permanent cascade account deletion for authenticated users.
class DeleteAccountUseCase {
  const DeleteAccountUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call({required UserAccount user}) {
    if (user.isGuestFan) {
      throw const InvalidCredentialsFailure(
        'Los usuarios invitados no tienen una cuenta registrada para eliminar.',
      );
    }
    return _authRepository.deleteAccount(userId: user.id);
  }
}
