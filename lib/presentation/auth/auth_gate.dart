import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/auth_providers.dart';
import '../../domain/entities/auth_flow_state.dart';
import '../design_system/kick_pulse_colors.dart';
import '../shell/app_shell_screen.dart';
import 'role_onboarding_screen.dart';
import 'welcome_auth_screen.dart';

/// Reactive entry gate directing users to Welcome, Onboarding, or Shell
/// based on the live authentication state.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return switch (authState.status) {
      AuthStatus.initializing => const Scaffold(
        backgroundColor: KickPulseColors.canvasBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: KickPulseColors.accentPrimary,
          ),
        ),
      ),
      AuthStatus.unauthenticated => const WelcomeAuthScreen(),
      AuthStatus.needsOnboarding => const RoleOnboardingScreen(),
      AuthStatus.authenticated => const AppShellScreen(),
    };
  }
}
