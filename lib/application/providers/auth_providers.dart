import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_environment.dart';
import '../../domain/entities/auth_flow_state.dart';
import '../../domain/entities/role_permission_matrix.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../infrastructure/auth/local_auth_repository.dart';
import '../../infrastructure/auth/supabase_auth_repository.dart';
import '../controllers/auth_controller.dart';
import '../use_cases/authenticate_user_use_case.dart';
import '../use_cases/delete_account_use_case.dart';
import 'foundation_providers.dart';
import 'supabase_providers.dart';

/// Provider exposing the concrete [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(localStorageRepositoryProvider);
  final connectivity = ref.watch(connectivityRepositoryProvider);
  final config = ref.watch(environmentConfigProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);

  if (config.environment == AppEnvironment.development &&
      config.supabase.isConfigured &&
      supabaseClient != null) {
    return SupabaseAuthRepository(
      client: supabaseClient,
      storage: storage,
      connectivity: connectivity,
      config: config,
    );
  }

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

/// Provider exposing [DeleteAccountUseCase].
final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return DeleteAccountUseCase(authRepository);
});

/// StateNotifierProvider exposing the central [AuthController] and its [AuthFlowState].
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthFlowState>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      final useCase = ref.watch(authenticateUserUseCaseProvider);
      final deleteAccountUseCase = ref.watch(deleteAccountUseCaseProvider);

      return AuthController(
        authRepository: repository,
        authenticateUserUseCase: useCase,
        deleteAccountUseCase: deleteAccountUseCase,
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
