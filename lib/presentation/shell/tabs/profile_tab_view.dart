import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/auth_providers.dart';
import '../../../application/providers/foundation_providers.dart';
import '../../../application/providers/sync_providers.dart';
import '../../../application/providers/team_join_requests_providers.dart';
import '../../../domain/entities/app_environment.dart';
import '../../../domain/entities/role_permission_matrix.dart';
import '../../../domain/entities/user_role.dart';
import '../../../l10n/app_localizations.dart';
import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/kick_pulse_typography.dart';
import '../../design_system/widgets/kick_pulse_badge.dart';
import '../../design_system/widgets/kick_pulse_button.dart';
import '../../design_system/widgets/kick_pulse_card.dart';
import '../../sync/sign_out_pending_sync_dialog.dart';
import 'complete_profile_dialog.dart';

/// Profile screen displaying identity, active sports role, role switching,
/// full RBAC permissions matrix, and secure session termination.
class ProfileTabView extends ConsumerWidget {
  const ProfileTabView({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authControllerProvider).session?.user;
    final isGuest = user?.isGuestFan ?? true;
    var pendingCount = 0;
    if (!isGuest) {
      try {
        pendingCount = ref
            .read(syncStatusControllerProvider)
            .totalAttentionCount;
      } catch (_) {
        pendingCount = 0;
      }
    }

    if (pendingCount > 0) {
      final decision = await SignOutPendingSyncDialog.show(
        context,
        pendingCount: pendingCount,
      );
      if (decision == SignOutGuardDecision.syncedAndExit ||
          decision == SignOutGuardDecision.keepPendingAndExit) {
        await ref.read(authControllerProvider.notifier).signOut();
      }
      return;
    }

    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KickPulseColors.surfaceBase,
        title: Text(
          l10n.profileLogoutDialogTitle,
          style: const TextStyle(color: KickPulseColors.textPrimary),
        ),
        content: Text(
          l10n.profileLogoutDialogMessage,
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
              l10n.profileLogoutAction,
              style: const TextStyle(color: KickPulseColors.accentLive),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final user = authState.session?.user;
    final config = ref.watch(environmentConfigProvider);
    final isDev = config.environment == AppEnvironment.development;

    final activeRole = user?.activeRole ?? UserRole.fan;
    final isGuest = user?.isGuestFan ?? false;

    // In dev, any of the 5 roles can be switched for end-to-end testing;
    // In prod, only authorizedRoles are permitted.
    final availableRoles = isDev
        ? UserRole.values.toList()
        : (user?.authorizedRoles.toList() ?? [UserRole.fan]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tabProfile, style: KickPulseTypography.screenTitle),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          // User Identity Card
          KickPulseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: KickPulseColors.surfaceSubtle,
                      child: Icon(
                        isGuest ? Icons.person_outline : Icons.sports_soccer,
                        color: KickPulseColors.accentPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Aficionado Invitado',
                            style: KickPulseTypography.cardTitle,
                          ),
                          const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                          Text(
                            isGuest ? 'Modo Visitante' : (user?.email ?? ''),
                            style: TextStyle(
                              color: KickPulseColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        KickPulseBadge(
                          label: _roleName(l10n, activeRole),
                          variant: _roleBadgeVariant(activeRole),
                        ),
                        if (!isGuest && user != null) ...[
                          const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                          KickPulseBadge(
                            key: const ValueKey('profile_completeness_badge'),
                            label: user.isProfileCompleteForActiveRole
                                ? l10n.profileCompleteBadge
                                : l10n.profileIncompleteBadge,
                            variant: user.isProfileCompleteForActiveRole
                                ? KickPulseBadgeVariant.success
                                : KickPulseBadgeVariant.warning,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (!isGuest &&
                    user != null &&
                    !user.isProfileCompleteForActiveRole) ...[
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                  const Divider(color: KickPulseColors.borderSubtle),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                  Text(
                    l10n.profileIncompleteBannerTitle,
                    style: const TextStyle(
                      color: KickPulseColors.accentWarning,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                  Text(
                    l10n.profileIncompleteBannerSubtitle,
                    style: const TextStyle(
                      color: KickPulseColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                  KickPulseButton(
                    key: const ValueKey('profile_complete_action_button'),
                    label: l10n.profileCompleteAction,
                    variant: KickPulseButtonVariant.primary,
                    isFullWidth: true,
                    onPressed: () async {
                      CompleteProfileDialog.show(context, user: user);
                    },
                  ),
                ],
                if (isGuest) ...[
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                  const Divider(color: KickPulseColors.borderSubtle),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                  Text(
                    l10n.profileGuestBannerTitle,
                    style: const TextStyle(
                      color: KickPulseColors.accentWarning,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                  Text(
                    l10n.profileGuestBannerSubtitle,
                    style: const TextStyle(
                      color: KickPulseColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          // Role Switcher Section
          Text(
            l10n.profileSwitchRole,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          KickPulseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDev
                      ? 'Entorno DEV activo: Todos los roles están habilitados para alternar en pruebas.'
                      : 'Roles autorizados en tu cuenta:',
                  style: const TextStyle(
                    color: KickPulseColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                Wrap(
                  spacing: KickPulseRadiiSpacing.spaceSm,
                  runSpacing: KickPulseRadiiSpacing.spaceSm,
                  children: availableRoles.map((role) {
                    final isCurrent = role == activeRole;
                    return ChoiceChip(
                      selected: isCurrent,
                      label: Text(_roleName(l10n, role)),
                      selectedColor: KickPulseColors.accentPrimary.withAlpha(
                        50,
                      ),
                      backgroundColor: KickPulseColors.surfaceSubtle,
                      labelStyle: TextStyle(
                        color: isCurrent
                            ? KickPulseColors.accentPrimary
                            : KickPulseColors.textSecondary,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isCurrent
                            ? KickPulseColors.accentPrimary
                            : KickPulseColors.borderSubtle,
                      ),
                      onSelected: (selected) {
                        if (selected && !isCurrent) {
                          ref
                              .read(authControllerProvider.notifier)
                              .switchActiveRole(role);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          // Player Team Join Requests Section (Only visible for player role)
          if (!isGuest &&
              (activeRole == UserRole.player ||
                  (user?.authorizedRoles.contains(UserRole.player) ?? false))) ...[
            KickPulseCard(
              child: InkWell(
                key: const Key('profile_team_requests_tile'),
                onTap: () {
                  Navigator.of(context).pushNamed('/profile/team-requests');
                },
                borderRadius: BorderRadius.circular(
                  KickPulseRadiiSpacing.cardRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KickPulseRadiiSpacing.spaceSm,
                    vertical: KickPulseRadiiSpacing.spaceXs,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: KickPulseColors.surfaceElevated,
                        child: Icon(
                          Icons.mail_outline,
                          color: KickPulseColors.accentElectric,
                        ),
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
                      Expanded(
                        child: Text(
                          l10n.profileTeamRequestsTile,
                          style: KickPulseTypography.cardTitle,
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          final pendingCount = ref.watch(
                            playerPendingRequestsCountProvider,
                          );
                          if (pendingCount > 0) {
                            return KickPulseBadge(
                              label: '$pendingCount',
                              variant: KickPulseBadgeVariant.dev,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right,
                        color: KickPulseColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
          ],

          // RBAC Matrix Capabilities Section
          Text(
            l10n.profileCapabilitiesTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          KickPulseCard(
            child: Column(
              children: RoleCapability.values.map((cap) {
                final isGranted = isGuest
                    ? cap == RoleCapability.viewPublicContent
                    : RolePermissionMatrix.hasCapability(activeRole, cap);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: KickPulseRadiiSpacing.spaceXs,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isGranted
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: isGranted
                            ? KickPulseColors.accentPrimary
                            : KickPulseColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                      Expanded(
                        child: Text(
                          _capabilityLabel(l10n, cap),
                          style: TextStyle(
                            color: isGranted
                                ? KickPulseColors.textPrimary
                                : KickPulseColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      KickPulseBadge(
                        label: isGranted
                            ? l10n.capabilityGranted
                            : l10n.capabilityDenied,
                        variant: isGranted
                            ? KickPulseBadgeVariant.info
                            : KickPulseBadgeVariant.neutral,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceXl),

          // Logout Action Button
          KickPulseButton(
            label: isGuest
                ? l10n.profileLoginRegisterButton
                : l10n.profileLogoutAction,
            variant: KickPulseButtonVariant.outline,
            isFullWidth: true,
            icon: Icon(
              isGuest ? Icons.login_rounded : Icons.logout_rounded,
              color: isGuest
                  ? KickPulseColors.accentPrimary
                  : KickPulseColors.accentLive,
              size: 20,
            ),
            onPressed: () => _handleLogout(context, ref),
          ),
        ],
      ),
    );
  }

  String _roleName(AppLocalizations l10n, UserRole role) => switch (role) {
    UserRole.organizer => l10n.roleOrganizer,
    UserRole.coach => l10n.roleCoach,
    UserRole.referee => l10n.roleReferee,
    UserRole.player => l10n.rolePlayer,
    UserRole.fan => l10n.roleFan,
  };

  KickPulseBadgeVariant _roleBadgeVariant(UserRole role) => switch (role) {
    UserRole.organizer => KickPulseBadgeVariant.live,
    UserRole.coach => KickPulseBadgeVariant.info,
    UserRole.referee => KickPulseBadgeVariant.warning,
    UserRole.player => KickPulseBadgeVariant.dev,
    UserRole.fan => KickPulseBadgeVariant.neutral,
  };

  String _capabilityLabel(AppLocalizations l10n, RoleCapability cap) =>
      switch (cap) {
        RoleCapability.manageTournaments => l10n.capManageTournaments,
        RoleCapability.manageVenues => l10n.capManageVenues,
        RoleCapability.approveRegistrations => l10n.capApproveRegistrations,
        RoleCapability.assignReferees => l10n.capAssignReferees,
        RoleCapability.manageTeamRoster => l10n.capManageTeamRoster,
        RoleCapability.manageLineups => l10n.capManageLineups,
        RoleCapability.recordMatchEvents => l10n.capRecordMatchEvents,
        RoleCapability.closeMatchReport => l10n.capCloseMatchReport,
        RoleCapability.viewPersonalStats => l10n.capViewPersonalStats,
        RoleCapability.viewPublicContent => l10n.capViewPublicContent,
        RoleCapability.viewCloudSyncIndicator => l10n.capViewCloudSyncIndicator,
      };
}
