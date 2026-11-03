import '../../domain/entities/auth_session.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// Use case encapsulating authentication validation and execution rules.
class AuthenticateUserUseCase {
  const AuthenticateUserUseCase(this._authRepository);

  final AuthRepository _authRepository;

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  /// Validates format of email string.
  bool isValidEmail(String email) {
    return _emailRegExp.hasMatch(email.trim());
  }

  /// Validates password meets security minimum length (8 characters).
  bool isValidPassword(String password) {
    return password.length >= 8;
  }

  /// Validates full name meets minimum length (2 characters).
  bool isValidFullName(String fullName) {
    return fullName.trim().length >= 2;
  }

  /// Authenticates using email and password after checking format constraints.
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (!isValidEmail(trimmedEmail)) {
      throw const InvalidCredentialsFailure(
        'El formato del correo electrónico no es válido.',
      );
    }
    if (!isValidPassword(password)) {
      throw const InvalidCredentialsFailure(
        'La contraseña debe tener al menos 8 caracteres.',
      );
    }

    return _authRepository.signInWithEmail(
      email: trimmedEmail,
      password: password,
    );
  }

  /// Registers a new user account after validating all registration fields.
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim().toLowerCase();

    if (!isValidFullName(trimmedName)) {
      throw const InvalidCredentialsFailure(
        'El nombre completo debe tener al menos 2 caracteres.',
      );
    }
    if (!isValidEmail(trimmedEmail)) {
      throw const InvalidCredentialsFailure(
        'El formato del correo electrónico no es válido.',
      );
    }
    if (!isValidPassword(password)) {
      throw const InvalidCredentialsFailure(
        'La contraseña debe tener al menos 8 caracteres.',
      );
    }

    return _authRepository.registerAccount(
      fullName: trimmedName,
      email: trimmedEmail,
      password: password,
    );
  }

  /// Initiates guest fan access, operating offline without credentials.
  Future<AuthSession> continueAsGuestFan() async {
    return _authRepository.continueAsGuestFan();
  }
}
