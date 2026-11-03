import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/auth_providers.dart';
import '../../../domain/entities/role_permission_matrix.dart';
import '../../../domain/entities/user_role.dart';
import '../../../l10n/app_localizations.dart';
import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/widgets/kick_pulse_card.dart';

/// Guard widget checking if the current user possesses [requiredCapability].
/// Renders [child] if authorized, or [fallback] (or a default Spanish warning card) if unauthorized.
class KickPulseRoleGuard extends ConsumerWidget {
  const KickPulseRoleGuard({
    super.key,
    required this.requiredCapability,
    required this.child,
    this.fallback,
    this.hideWhenUnauthorized = false,
  });

  /// The operative capability required to access [child].
  final RoleCapability requiredCapability;

  /// The protected UI element or view.
  final Widget child;

  /// Custom fallback widget to render when access is denied.
  final Widget? fallback;

  /// If true and [fallback] is null, renders [SizedBox.shrink] instead of the default warning card.
  final bool hideWhenUnauthorized;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.session?.user;
    final activeRole = user?.activeRole ?? UserRole.fan;
    final isGuest = user?.isGuestFan ?? false;

    final isAuthorized = !isGuest
        ? RolePermissionMatrix.hasCapability(activeRole, requiredCapability)
        : requiredCapability == RoleCapability.viewPublicContent;

    if (isAuthorized) {
      return child;
    }

    if (fallback != null) {
      return fallback!;
    }

    if (hideWhenUnauthorized) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    return KickPulseCard(
      borderSide: BorderSide(
        color: KickPulseColors.accentLive.withAlpha(80),
        width: 1.0,
      ),
      backgroundColor: KickPulseColors.surfaceBase,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
            decoration: BoxDecoration(
              color: KickPulseColors.accentLive.withAlpha(30),
              borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: KickPulseColors.accentLive,
              size: 24,
            ),
          ),
          const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.rbacAccessRestricted,
                  style: const TextStyle(
                    color: KickPulseColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                Text(
                  l10n.rbacRequiredRoleMessage,
                  style: const TextStyle(
                    color: KickPulseColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
