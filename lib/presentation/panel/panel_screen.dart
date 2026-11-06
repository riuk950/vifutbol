import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';

/// Base screen container for the dynamic role panel (`/panel`).
///
/// Implemented for HU 12.1 as a verified navigation destination providing
/// a structured container for role-specific administrative tools and metrics
/// that will be fully developed in HU 12.2.
class PanelScreen extends ConsumerWidget {
  const PanelScreen({super.key});

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

  KickPulseBadgeVariant _badgeVariant(UserRole role) {
    switch (role) {
      case UserRole.organizer:
        return KickPulseBadgeVariant.live;
      case UserRole.coach:
        return KickPulseBadgeVariant.info;
      case UserRole.referee:
        return KickPulseBadgeVariant.warning;
      case UserRole.player:
        return KickPulseBadgeVariant.dev;
      case UserRole.fan:
        return KickPulseBadgeVariant.neutral;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final activeRole = ref.watch(activeUserRoleProvider);

    return Scaffold(
      key: const Key('panel_screen'),
      backgroundColor: KickPulseColors.canvasBackground,
      appBar: AppBar(
        leading: const BackButton(key: Key('panel_back_button')),
        title: Text(l10n.drawerPanel),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
          child: Center(
            child: KickPulseCard(
              key: const Key('panel_placeholder_content'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(
                      KickPulseRadiiSpacing.spaceMd,
                    ),
                    decoration: BoxDecoration(
                      color: KickPulseColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.dashboard_outlined,
                      size: 48,
                      color: KickPulseColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                  KickPulseBadge(
                    key: const Key('panel_role_badge'),
                    label: _roleLabel(l10n, activeRole),
                    variant: _badgeVariant(activeRole),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                  Text(
                    l10n.panelPlaceholderTitle,
                    style: KickPulseTypography.sectionHeader,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                  Text(
                    l10n.panelPlaceholderSubtitle,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
