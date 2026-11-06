import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/navigation/app_router.dart';

/// Universal lateral navigation drawer providing direct access to platform
/// directories (Competitions, Teams, Players, and Venues) across all 5 roles.
class AppNavigationDrawer extends ConsumerWidget {
  const AppNavigationDrawer({super.key});

  String _roleLabel(AppLocalizations l10n, UserRole role) {
    switch (role) {
      case UserRole.organizer:
        return l10n.roleOrganizer;
      case UserRole.referee:
        return l10n.roleReferee;
      case UserRole.coach:
        return l10n.roleCoach;
      case UserRole.player:
        return l10n.rolePlayer;
      case UserRole.fan:
        return l10n.roleFan;
    }
  }

  void _navigateTo(BuildContext context, String route) {
    // 1. Close drawer smoothly before pushing route per spec FR-004
    Navigator.of(context).pop();

    // 2. Push directory route via AppRouter
    AppRouter.router.navigateTo(context, route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final activeRole = ref.watch(activeUserRoleProvider);
    final user = authState.session?.user;

    final userName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : l10n.drawerGuestUser;
    final userEmail = user?.email.isNotEmpty == true
        ? user!.email
        : l10n.drawerGuestEmail;

    final isPanelVisible = activeRole != UserRole.fan;

    return Drawer(
      key: const Key('app_navigation_drawer'),
      backgroundColor: KickPulseColors.canvasBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header with User Profile and Branding
            Container(
              key: const Key('app_drawer_header'),
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
              decoration: const BoxDecoration(
                color: KickPulseColors.surfaceBase,
                border: Border(
                  bottom: BorderSide(
                    color: KickPulseColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.sports_soccer,
                        color: KickPulseColors.accentPrimary,
                        size: 24,
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                      Expanded(
                        child: Text(
                          l10n.appTitle,
                          style: KickPulseTypography.screenTitle.copyWith(
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                      KickPulseBadge(
                        label: _roleLabel(l10n, activeRole),
                        variant: activeRole == UserRole.organizer
                            ? KickPulseBadgeVariant.live
                            : KickPulseBadgeVariant.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: KickPulseColors.surfaceElevated,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'V',
                          style: KickPulseTypography.sectionHeader.copyWith(
                            color: KickPulseColors.accentPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: KickPulseTypography.bodyPrimary.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userEmail,
                              style: KickPulseTypography.captionMeta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

            // Navigation Destinations
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: KickPulseRadiiSpacing.spaceSm,
                ),
                children: [
                  if (isPanelVisible) ...[
                    ListTile(
                      key: const Key('drawer_destination_panel'),
                      leading: const Icon(
                        Icons.dashboard_outlined,
                        color: KickPulseColors.accentElectric,
                      ),
                      title: Text(
                        l10n.drawerPanel,
                        style: KickPulseTypography.bodyPrimary,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: KickPulseColors.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          KickPulseRadiiSpacing.chipRadius,
                        ),
                      ),
                      onTap: () => _navigateTo(context, '/panel'),
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                  ],
                  ListTile(
                    key: const Key('drawer_destination_competitions'),
                    leading: const Icon(
                      Icons.emoji_events_outlined,
                      color: KickPulseColors.accentPrimary,
                    ),
                    title: Text(
                      l10n.drawerCompetitions,
                      style: KickPulseTypography.bodyPrimary,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: KickPulseColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.chipRadius,
                      ),
                    ),
                    onTap: () => _navigateTo(context, '/competitions'),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                  ListTile(
                    key: const Key('drawer_destination_teams'),
                    leading: const Icon(
                      Icons.shield_outlined,
                      color: KickPulseColors.accentElectric,
                    ),
                    title: Text(
                      l10n.drawerTeams,
                      style: KickPulseTypography.bodyPrimary,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: KickPulseColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.chipRadius,
                      ),
                    ),
                    onTap: () => _navigateTo(context, '/teams'),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                  ListTile(
                    key: const Key('drawer_destination_players'),
                    leading: const Icon(
                      Icons.groups_outlined,
                      color: KickPulseColors.textPrimary,
                    ),
                    title: Text(
                      l10n.drawerPlayers,
                      style: KickPulseTypography.bodyPrimary,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: KickPulseColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.chipRadius,
                      ),
                    ),
                    onTap: () => _navigateTo(context, '/players'),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                  ListTile(
                    key: const Key('drawer_destination_venues'),
                    leading: const Icon(
                      Icons.stadium_outlined,
                      color: KickPulseColors.accentWarning,
                    ),
                    title: Text(
                      l10n.drawerVenues,
                      style: KickPulseTypography.bodyPrimary,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: KickPulseColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.chipRadius,
                      ),
                    ),
                    onTap: () => _navigateTo(context, '/venues'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
