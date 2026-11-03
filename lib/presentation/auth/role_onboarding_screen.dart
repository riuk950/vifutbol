import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/auth_providers.dart';
import '../../application/providers/foundation_providers.dart';
import '../../domain/entities/app_environment.dart';
import '../../domain/entities/user_role.dart';
import '../../l10n/app_localizations.dart';
import '../design_system/kick_pulse_colors.dart';
import '../design_system/kick_pulse_radii_spacing.dart';
import '../design_system/widgets/kick_pulse_badge.dart';
import '../design_system/widgets/kick_pulse_button.dart';
import '../design_system/widgets/kick_pulse_card.dart';

/// Screen guiding newly registered users to select their initial sports role.
class RoleOnboardingScreen extends ConsumerStatefulWidget {
  const RoleOnboardingScreen({super.key});

  @override
  ConsumerState<RoleOnboardingScreen> createState() =>
      _RoleOnboardingScreenState();
}

class _RoleOnboardingScreenState extends ConsumerState<RoleOnboardingScreen> {
  UserRole _selectedRole = UserRole.player;
  late final TextEditingController _authCodeController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _authCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _authCodeController.dispose();
    super.dispose();
  }

  bool _requiresCode(EnvironmentConfig config) {
    return config.environment == AppEnvironment.production &&
        _selectedRole.requiresAuthorizationCodeInProd;
  }

  Future<void> _confirmRole() async {
    final config = ref.read(environmentConfigProvider);
    if (_requiresCode(config) && !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    await ref
        .read(authControllerProvider.notifier)
        .completeRoleOnboarding(
          selectedRole: _selectedRole,
          authorizationCode: _authCodeController.text.trim().isEmpty
              ? null
              : _authCodeController.text.trim(),
        );
  }

  Future<bool> _handlePopScope() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KickPulseColors.surfaceBase,
        title: Text(
          l10n.onboardingDiscardTitle,
          style: const TextStyle(color: KickPulseColors.textPrimary),
        ),
        content: Text(
          l10n.onboardingDiscardMessage,
          style: const TextStyle(color: KickPulseColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.actionCancel,
              style: const TextStyle(color: KickPulseColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.actionDiscard,
              style: const TextStyle(color: KickPulseColors.accentLive),
            ),
          ),
        ],
      ),
    );

    if (discard == true) {
      await ref.read(authControllerProvider.notifier).signOut();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(environmentConfigProvider);
    final authState = ref.watch(authControllerProvider);
    final requiresAuthCode = _requiresCode(config);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handlePopScope();
      },
      child: Scaffold(
        backgroundColor: KickPulseColors.canvasBackground,
        appBar: AppBar(
          backgroundColor: KickPulseColors.canvasBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: KickPulseColors.textPrimary,
            ),
            onPressed: () async {
              await _handlePopScope();
            },
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: KickPulseRadiiSpacing.spaceXl,
                vertical: KickPulseRadiiSpacing.spaceMd,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.onboardingTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: KickPulseColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                      Text(
                        l10n.onboardingSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: KickPulseColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceXl),

                      // Error Banner
                      if (authState.lastFailure != null) ...[
                        Container(
                          padding: const EdgeInsets.all(
                            KickPulseRadiiSpacing.spaceMd,
                          ),
                          decoration: BoxDecoration(
                            color: KickPulseColors.accentLive.withAlpha(40),
                            borderRadius:
                                KickPulseRadiiSpacing.chipBorderRadius,
                            border: Border.all(
                              color: KickPulseColors.accentLive,
                            ),
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

                      // 5 Sports Role Cards
                      ...UserRole.values.map((role) {
                        final isSelected = _selectedRole == role;
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: KickPulseRadiiSpacing.spaceMd,
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedRole = role;
                              });
                            },
                            borderRadius:
                                KickPulseRadiiSpacing.cardBorderRadius,
                            child: KickPulseCard(
                              borderSide: BorderSide(
                                color: isSelected
                                    ? KickPulseColors.accentPrimary
                                    : KickPulseColors.borderSubtle,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                              child: Row(
                                children: [
                                  // ignore: deprecated_member_use
                                  Radio<UserRole>(
                                    value: role,
                                    // ignore: deprecated_member_use
                                    groupValue: _selectedRole,
                                    activeColor: KickPulseColors.accentPrimary,
                                    // ignore: deprecated_member_use
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedRole = val;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(
                                    width: KickPulseRadiiSpacing.spaceXs,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              _roleLabel(l10n, role),
                                              style: const TextStyle(
                                                color:
                                                    KickPulseColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(
                                              width:
                                                  KickPulseRadiiSpacing.spaceSm,
                                            ),
                                            KickPulseBadge(
                                              label: _roleLabel(l10n, role),
                                              variant: _badgeVariant(role),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: KickPulseRadiiSpacing.spaceXs,
                                        ),
                                        Text(
                                          _roleDescription(l10n, role),
                                          style: const TextStyle(
                                            color: KickPulseColors.textMuted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // Authorization Code Field for Prod Organizer / Referee
                      if (requiresAuthCode) ...[
                        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                        TextFormField(
                          controller: _authCodeController,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(
                            color: KickPulseColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.onboardingAuthCodeLabel,
                            hintText: l10n.onboardingAuthCodeHint,
                            prefixIcon: const Icon(Icons.key_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.onboardingErrorInvalidCode;
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: KickPulseRadiiSpacing.spaceXl),

                      // Confirmation Button
                      KickPulseButton(
                        label: l10n.onboardingConfirmAction,
                        isLoading: authState.isSubmitting,
                        onPressed: _confirmRole,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _roleLabel(AppLocalizations l10n, UserRole role) => switch (role) {
    UserRole.organizer => l10n.roleOrganizer,
    UserRole.coach => l10n.roleCoach,
    UserRole.referee => l10n.roleReferee,
    UserRole.player => l10n.rolePlayer,
    UserRole.fan => l10n.roleFan,
  };

  String _roleDescription(
    AppLocalizations l10n,
    UserRole role,
  ) => switch (role) {
    UserRole.organizer =>
      'Gestiona campeonatos, sedes, canchas, inscripciones y designaciones oficiales.',
    UserRole.coach =>
      'Registra plantillas, define alineaciones tácticas y convocatorias.',
    UserRole.referee =>
      'Registra eventos en vivo (goles, tarjetas) y firma actas oficiales.',
    UserRole.player =>
      'Consulta convocatorias, estadísticas personales y seguimiento de equipo.',
    UserRole.fan =>
      'Visualiza resultados en vivo, tablas de posiciones y sedes de partidos.',
  };

  KickPulseBadgeVariant _badgeVariant(UserRole role) => switch (role) {
    UserRole.organizer => KickPulseBadgeVariant.live,
    UserRole.coach => KickPulseBadgeVariant.info,
    UserRole.referee => KickPulseBadgeVariant.warning,
    UserRole.player => KickPulseBadgeVariant.dev,
    UserRole.fan => KickPulseBadgeVariant.neutral,
  };
}
