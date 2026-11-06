import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/panel/widgets/coach_panel_content.dart';
import 'package:vifutbol/presentation/panel/widgets/fan_panel_restricted_content.dart';
import 'package:vifutbol/presentation/panel/widgets/organizer_panel_content.dart';
import 'package:vifutbol/presentation/panel/widgets/player_panel_content.dart';
import 'package:vifutbol/presentation/panel/widgets/referee_panel_content.dart';

/// Dynamic role-adaptive panel screen container (`/panel`).
///
/// Adapts its AppBar title and body content based on the active role (`activeRole`).
class PanelScreen extends ConsumerWidget {
  const PanelScreen({super.key});

  String _appBarTitle(AppLocalizations l10n, UserRole role) {
    switch (role) {
      case UserRole.organizer:
        return l10n.panelTitleOrganizer;
      case UserRole.coach:
        return l10n.panelTitleCoach;
      case UserRole.referee:
        return l10n.panelTitleReferee;
      case UserRole.player:
        return l10n.panelTitlePlayer;
      case UserRole.fan:
        return l10n.drawerPanel;
    }
  }

  Widget _buildRoleContent(UserRole role) {
    switch (role) {
      case UserRole.organizer:
        return const OrganizerPanelContent();
      case UserRole.coach:
        return const CoachPanelContent();
      case UserRole.referee:
        return const RefereePanelContent();
      case UserRole.player:
        return const PlayerPanelContent();
      case UserRole.fan:
        return const FanPanelRestrictedContent();
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
        title: Text(
          _appBarTitle(l10n, activeRole),
          key: const Key('panel_screen_title'),
        ),
      ),
      body: SafeArea(child: _buildRoleContent(activeRole)),
    );
  }
}
