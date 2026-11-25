import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/auth_providers.dart';
import '../../../application/providers/sync_providers.dart';
import '../../../application/providers/team_join_requests_providers.dart';
import '../../../domain/entities/role_permission_matrix.dart';
import '../../../domain/entities/user_account.dart';
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
import 'widgets/delete_account_dialog.dart';
import 'widgets/profile_legal_support_section.dart';

/// Profile screen displaying identity, read-only active sports role,
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

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final deleted = await DeleteAccountDialog.show(
      context,
      onConfirmDelete: () =>
          ref.read(authControllerProvider.notifier).deleteAccount(),
    );

    if (deleted == false && context.mounted) {
      final failureMessage =
          ref.read(authControllerProvider).lastFailure?.message ??
          l10n.deleteAccountGenericError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failureMessage),
          backgroundColor: KickPulseColors.accentLive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final user = authState.session?.user;

    final activeRole = user?.activeRole ?? UserRole.fan;
    final isGuest = user?.isGuestFan ?? false;

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
                    _buildUserAvatar(user, isGuest, activeRole),
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
                        Semantics(
                          readOnly: true,
                          label: _roleName(l10n, activeRole),
                          child: KickPulseBadge(
                            key: const ValueKey('profile_active_role_badge'),
                            label: _roleName(l10n, activeRole),
                            variant: _roleBadgeVariant(activeRole),
                          ),
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
                      if (activeRole == UserRole.player) {
                        Navigator.of(context)
                            .pushNamed('/profile/personal-data');
                      } else {
                        CompleteProfileDialog.show(context, user: user);
                      }
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

          // Player Personal Data Section (Only visible for player role)
          if (!isGuest &&
              (activeRole == UserRole.player ||
                  (user?.authorizedRoles.contains(UserRole.player) ?? false))) ...[
            KickPulseCard(
              child: InkWell(
                key: const Key('profile_personal_data_tile'),
                onTap: () {
                  final isComplete =
                      user?.isProfileCompleteForActiveRole ?? false;
                  Navigator.of(context).pushNamed(
                    isComplete
                        ? '/profile/personal-data/summary'
                        : '/profile/personal-data',
                  );
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
                          Icons.badge_outlined,
                          color: KickPulseColors.accentElectric,
                        ),
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.profilePersonalDataTile,
                              style: KickPulseTypography.cardTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (user?.isProfileCompleteForActiveRole ?? false)
                                  ? l10n.playerPersonalDataSummarySubtitle
                                  : l10n.profilePersonalDataSubtitle,
                              style: const TextStyle(
                                color: KickPulseColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: KickPulseColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          ],

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
            key: const Key('profile_capabilities_section'),
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
          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          // Legal, Support & Remove Ads Section
          const ProfileLegalSupportSection(),
          const SizedBox(height: KickPulseRadiiSpacing.spaceXl),

          // Logout Action Button
          KickPulseButton(
            key: const Key('profile_logout_action_button'),
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
          if (!isGuest && user != null) ...[
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('profile_delete_account_button'),
                onPressed: () => _handleDeleteAccount(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KickPulseColors.accentLive,
                  side: const BorderSide(color: KickPulseColors.accentLive),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.cardRadius,
                    ),
                  ),
                ),
                icon: const Icon(
                  Icons.delete_forever_outlined,
                  color: KickPulseColors.accentLive,
                  size: 20,
                ),
                label: Text(l10n.profileDeleteAccountButton),
              ),
            ),
          ],
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

  Widget _buildUserAvatar(
    UserAccount? user,
    bool isGuest,
    UserRole activeRole,
  ) {
    ImageProvider? imageProvider;
    final photo = user?.photoUrl;
    if (photo != null && photo.trim().isNotEmpty) {
      if (photo.startsWith('http://') || photo.startsWith('https://')) {
        imageProvider = NetworkImage(photo);
      } else {
        final localFile = File(photo);
        if (localFile.existsSync()) {
          imageProvider = FileImage(localFile);
        }
      }
    }

    final hasPhoto = imageProvider != null;

    return CircleAvatar(
      key: const ValueKey('profile_identity_avatar'),
      radius: 28,
      backgroundColor: KickPulseColors.surfaceSubtle,
      backgroundImage: imageProvider,
      onBackgroundImageError:
          imageProvider != null ? (exception, stackTrace) {} : null,
      child: !hasPhoto
          ? Icon(
              isGuest ? Icons.person_outline : Icons.sports_soccer,
              color: KickPulseColors.accentPrimary,
              size: 32,
            )
          : null,
    );
  }
}
