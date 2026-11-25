import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vifutbol/application/controllers/app_shell_controller.dart';
import 'package:vifutbol/application/providers/fan_alerts_and_favorites_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/domain/entities/app_shell_section.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/match_alert_type.dart';
import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/alerts/widgets/fan_alerts_tray_sheet.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/matches/digital_match_report_screen.dart';
import 'package:vifutbol/presentation/panel/panel_screen.dart';

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
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(fanAlertsTrayControllerProvider.notifier)
          .init(widget.userId, tournamentId: widget.tournamentId);
    });
  }

  @override
  void didUpdateWidget(covariant FanAlertsBellAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.tournamentId != widget.tournamentId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(fanAlertsTrayControllerProvider.notifier)
            .init(widget.userId, tournamentId: widget.tournamentId);
      });
    }
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

  Future<void> _handleDeepLink(MatchLiveAlert alert) async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    try {
      if (alert.type == MatchAlertType.refereeMatchAssigned) {
        ChampionshipMatch? targetMatch;
        final cached = ref.read(matchesCatalogControllerProvider).matches;
        for (final m in cached) {
          if (m.id == alert.matchId) {
            targetMatch = m;
            break;
          }
        }

        if (targetMatch == null) {
          try {
            final tournamentMatches = await ref
                .read(tournamentMatchesRepositoryProvider)
                .loadMatchesForTournament(alert.tournamentId);
            for (final m in tournamentMatches) {
              if (m.id == alert.matchId) {
                targetMatch = m;
                break;
              }
            }
          } catch (_) {
            // Safe fallback to Referee Panel below
          }
        }

        if (!mounted) return;
        if (targetMatch != null) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  DigitalMatchReportScreen(initialMatch: targetMatch),
            ),
          );
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PanelScreen(),
            ),
          );
        }
        return;
      }

      // Default fan/general match alert flow
      ref
          .read(appShellControllerProvider.notifier)
          .setSection(AppShellSection.matches);

      ref
          .read(matchesCatalogControllerProvider.notifier)
          .loadTournamentMatches(alert.tournamentId);
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trayState = ref.watch(fanAlertsTrayControllerProvider);
    final unread = trayState.unreadCount;
    final badgeText = unread > 99 ? '99+' : '$unread';

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
            badgeText,
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
