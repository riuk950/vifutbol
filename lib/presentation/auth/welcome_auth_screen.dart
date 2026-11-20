import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/auth_providers.dart';
import '../../l10n/app_localizations.dart';
import '../design_system/kick_pulse_colors.dart';
import '../design_system/kick_pulse_radii_spacing.dart';
import '../design_system/widgets/kick_pulse_button.dart';

/// Screen managing user authentication, account creation, and guest fan onboarding.
class WelcomeAuthScreen extends ConsumerStatefulWidget {
  const WelcomeAuthScreen({super.key});

  @override
  ConsumerState<WelcomeAuthScreen> createState() => _WelcomeAuthScreenState();
}

class _WelcomeAuthScreenState extends ConsumerState<WelcomeAuthScreen> {
  int _selectedTab = 0; // 0 = Iniciar sesión, 1 = Crear cuenta

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _fullNameController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authControllerProvider);
    _emailController = TextEditingController(text: authState.draftEmail);
    _passwordController = TextEditingController();
    _fullNameController = TextEditingController(text: authState.draftFullName);

    _emailController.addListener(_syncDrafts);
    _fullNameController.addListener(_syncDrafts);
  }

  void _syncDrafts() {
    ref
        .read(authControllerProvider.notifier)
        .updateDrafts(
          email: _emailController.text,
          fullName: _fullNameController.text,
        );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref
        .read(authControllerProvider.notifier)
        .register(
          fullName: _fullNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  Future<void> _continueAsGuest() async {
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).continueAsGuestFan();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: KickPulseColors.canvasBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: KickPulseRadiiSpacing.spaceXl,
              vertical: KickPulseRadiiSpacing.spaceLg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand / Header
                    const Icon(
                      Icons.sports_soccer_rounded,
                      size: 56,
                      color: KickPulseColors.accentPrimary,
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                    Text(
                      l10n.authWelcomeTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: KickPulseColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                    Text(
                      l10n.authWelcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: KickPulseColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceXl),

                    // Lockout Warning Banner
                    if (authState.isLockedOut) ...[
                      Container(
                        padding: const EdgeInsets.all(
                          KickPulseRadiiSpacing.spaceMd,
                        ),
                        decoration: BoxDecoration(
                          color: KickPulseColors.accentLive.withAlpha(40),
                          borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
                          border: Border.all(color: KickPulseColors.accentLive),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_clock_rounded,
                              color: KickPulseColors.accentLive,
                              size: 24,
                            ),
                            const SizedBox(
                              width: KickPulseRadiiSpacing.spaceSm,
                            ),
                            Expanded(
                              child: Text(
                                l10n.authErrorRateLimited(
                                  authState.remainingLockoutSeconds,
                                ),
                                style: const TextStyle(
                                  color: KickPulseColors.accentLive,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
                    ] else if (authState.lastFailure != null) ...[
                      Container(
                        padding: const EdgeInsets.all(
                          KickPulseRadiiSpacing.spaceMd,
                        ),
                        decoration: BoxDecoration(
                          color: KickPulseColors.accentLive.withAlpha(40),
                          borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
                          border: Border.all(color: KickPulseColors.accentLive),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: KickPulseColors.accentLive,
                              size: 24,
                            ),
                            const SizedBox(
                              width: KickPulseRadiiSpacing.spaceSm,
                            ),
                            Expanded(
                              child: Text(
                                authState.lastFailure!.message,
                                style: const TextStyle(
                                  color: KickPulseColors.accentLive,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
                    ],

                    // Tab Selector
                    Container(
                      decoration: BoxDecoration(
                        color: KickPulseColors.surfaceBase,
                        borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTabButton(
                              label: l10n.authLoginTab,
                              isSelected: _selectedTab == 0,
                              onTap: () {
                                setState(() {
                                  _selectedTab = 0;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildTabButton(
                              label: l10n.authRegisterTab,
                              isSelected: _selectedTab == 1,
                              onTap: () {
                                setState(() {
                                  _selectedTab = 1;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

                    // Registration Name Field
                    if (_selectedTab == 1) ...[
                      TextFormField(
                        controller: _fullNameController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          color: KickPulseColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.authFullNameLabel,
                          hintText: l10n.authFullNameHint,
                          prefixIcon: const Icon(Icons.person_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return l10n.authErrorNameTooShort;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                    ],

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        color: KickPulseColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.authEmailLabel,
                        hintText: l10n.authEmailHint,
                        prefixIcon: const Icon(Icons.email_rounded),
                      ),
                      validator: (value) {
                        if (value == null ||
                            !value.contains('@') ||
                            !value.contains('.')) {
                          return l10n.authErrorInvalidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        color: KickPulseColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.authPasswordLabel,
                        hintText: l10n.authPasswordHint,
                        prefixIcon: const Icon(Icons.lock_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return l10n.authErrorPasswordTooShort;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        if (_selectedTab == 0) {
                          _submitLogin();
                        } else {
                          _submitRegister();
                        }
                      },
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceXl),

                    // Action Button (Login or Register)
                    KickPulseButton(
                      label: _selectedTab == 0
                          ? l10n.authLoginTab
                          : l10n.authRegisterTab,
                      isLoading: authState.isSubmitting,
                      onPressed: authState.isLockedOut
                          ? null
                          : () => _selectedTab == 0
                                ? _submitLogin()
                                : _submitRegister(),
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

                    // Divider
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: KickPulseColors.borderSubtle),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: KickPulseRadiiSpacing.spaceMd,
                          ),
                          child: Text(
                            l10n.authOrDivider,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: KickPulseColors.textMuted),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: KickPulseColors.borderSubtle),
                        ),
                      ],
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

                    // Guest Fan CTA Button
                    KickPulseButton(
                      label: l10n.authContinueAsFan,
                      variant: KickPulseButtonVariant.outline,
                      icon: const Icon(
                        Icons.visibility_rounded,
                        size: 20,
                        color: KickPulseColors.textPrimary,
                      ),
                      onPressed: _continueAsGuest,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? KickPulseColors.accentPrimary
              : Colors.transparent,
          borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? KickPulseColors.canvasBackground
                : KickPulseColors.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
