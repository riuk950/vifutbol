import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_flow_state.dart';
import '../../domain/entities/role_permission_matrix.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../infrastructure/auth/local_auth_repository.dart';
import '../controllers/auth_controller.dart';
import '../use_cases/authenticate_user_use_case.dart';
import 'foundation_providers.dart';

/// Provider exposing the concrete [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final connectivity = ref.watch(connectivityRepositoryProvider);
  final config = ref.watch(environmentConfigProvider);

  return LocalAuthRepository(
    storage: storage,
    connectivity: connectivity,
    config: config,
  );
});

/// Provider exposing [AuthenticateUserUseCase].
final authenticateUserUseCaseProvider = Provider<AuthenticateUserUseCase>((
  ref,
) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthenticateUserUseCase(authRepository);
});

/// StateNotifierProvider exposing the central [AuthController] and its [AuthFlowState].
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthFlowState>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      final useCase = ref.watch(authenticateUserUseCaseProvider);

      return AuthController(
        authRepository: repository,
        authenticateUserUseCase: useCase,
      );
    });

/// Reactive provider of the currently active [UserRole].
final activeUserRoleProvider = Provider<UserRole>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.session?.user.activeRole ?? UserRole.fan;
});

/// Reactive provider exposing the set of capabilities for the active sports role.
final activeRoleCapabilitiesProvider = Provider<Set<RoleCapability>>((ref) {
  final activeRole = ref.watch(activeUserRoleProvider);
  return RolePermissionMatrix.capabilitiesForRole(activeRole);
});
