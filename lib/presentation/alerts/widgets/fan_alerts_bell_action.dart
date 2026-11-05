import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/app_shell_controller.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/fan_alerts_and_favorites_providers.dart';
import 'package:vifutbol/domain/entities/app_shell_section.dart';
import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/alerts/widgets/fan_alerts_tray_sheet.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

class FanAlertsBellAction extends ConsumerStatefulWidget {
  const FanAlertsBellAction({
    super.key,
    required this.userId,
    this.tournamentId,
  });

  final String userId;
  final String? tournamentId;

  @override
  ConsumerState<FanAlertsBellAction> createState() =>
      _FanAlertsBellActionState();
}

class _FanAlertsBellActionState extends ConsumerState<FanAlertsBellAction> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(fanAlertsTrayControllerProvider.notifier)
          .init(widget.userId, tournamentId: widget.tournamentId);
    });
  }

  void _onOpenTray() {
    FanAlertsTraySheet.show(
      context: context,
      userId: widget.userId,
      onSelectAlert: (alert) {
        _handleDeepLink(alert);
      },
    );
  }

  void _handleDeepLink(MatchLiveAlert alert) {
    // 1. Switch active shell section to matchday
    ref
        .read(appShellControllerProvider.notifier)
        .setSection(AppShellSection.matchday);

    // 2. Load the tournament matches if needed
    ref
        .read(matchesCatalogControllerProvider.notifier)
        .loadTournamentMatches(alert.tournamentId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trayState = ref.watch(fanAlertsTrayControllerProvider);
    final unread = trayState.unreadCount;

    return Semantics(
      button: true,
      label: unread > 0
          ? l10n.alertsUnreadBadgeTooltip(unread)
          : l10n.alertsTrayTitle,
      child: IconButton(
        key: const Key('fan_alerts_bell_button'),
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text(
            '$unread',
            style: KickPulseTypography.captionMeta.copyWith(
              color: KickPulseColors.surfaceBase,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: KickPulseColors.accentLive,
          child: const Icon(Icons.notifications_outlined, size: 24),
        ),
        onPressed: _onOpenTray,
      ),
    );
  }
}
