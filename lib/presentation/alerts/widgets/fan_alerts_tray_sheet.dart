import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vifutbol/application/providers/fan_alerts_and_favorites_providers.dart';
import 'package:vifutbol/domain/entities/match_alert_type.dart';
import 'package:vifutbol/domain/entities/match_live_alert.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';

class FanAlertsTraySheet extends ConsumerStatefulWidget {
  const FanAlertsTraySheet({
    super.key,
    required this.userId,
    this.onSelectAlert,
  });

  final String userId;
  final ValueChanged<MatchLiveAlert>? onSelectAlert;

  static Future<void> show({
    required BuildContext context,
    required String userId,
    ValueChanged<MatchLiveAlert>? onSelectAlert,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KickPulseColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KickPulseRadiiSpacing.cardRadius),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) =>
            FanAlertsTraySheet(userId: userId, onSelectAlert: onSelectAlert),
      ),
    );
  }

  @override
  ConsumerState<FanAlertsTraySheet> createState() => _FanAlertsTraySheetState();
}

class _FanAlertsTraySheetState extends ConsumerState<FanAlertsTraySheet> {
  bool _isSelectingAlert = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trayState = ref.watch(fanAlertsTrayControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: KickPulseColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

          // Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(l10n.alertsTrayTitle, style: KickPulseTypography.cardTitle),
              if (trayState.alerts.any((a) => !a.isRead))
                TextButton(
                  key: const Key('mark_all_alerts_read_button'),
                  onPressed: () {
                    ref
                        .read(fanAlertsTrayControllerProvider.notifier)
                        .markAllAsRead(widget.userId);
                  },
                  child: Text(
                    l10n.alertsMarkAllRead,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.accentPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          // Fallback notice if OS push permissions denied
          if (!trayState.isPermissionGranted) ...[
            Container(
              margin: const EdgeInsets.symmetric(
                vertical: KickPulseRadiiSpacing.spaceSm,
              ),
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
              decoration: BoxDecoration(
                color: KickPulseColors.surfaceBase,
                borderRadius: BorderRadius.circular(
                  KickPulseRadiiSpacing.chipRadius,
                ),
                border: Border.all(color: KickPulseColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_off_outlined,
                    size: 18,
                    color: KickPulseColors.accentWarning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.alertsPushDeniedWarning,
                      style: KickPulseTypography.captionMeta.copyWith(
                        color: KickPulseColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

          // Alerts list
          Expanded(
            child: trayState.alerts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          size: 48,
                          color: KickPulseColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.alertsTrayEmpty,
                          textAlign: TextAlign.center,
                          style: KickPulseTypography.bodyPrimary.copyWith(
                            color: KickPulseColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: trayState.alerts.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    itemBuilder: (context, index) {
                      final alert = trayState.alerts[index];
                      return _buildAlertTile(context, ref, alert, l10n);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTile(
    BuildContext context,
    WidgetRef ref,
    MatchLiveAlert alert,
    AppLocalizations l10n,
  ) {
    final timeStr = DateFormat('HH:mm').format(alert.timestamp);

    final (typeLabel, badgeVariant, iconData) = switch (alert.type) {
      MatchAlertType.matchUpcoming => (
        l10n.alertTypeUpcoming,
        KickPulseBadgeVariant.info,
        Icons.alarm,
      ),
      MatchAlertType.matchStarted => (
        l10n.alertTypeStarted,
        KickPulseBadgeVariant.live,
        Icons.sports_soccer,
      ),
      MatchAlertType.goalScored => (
        l10n.alertTypeGoal,
        KickPulseBadgeVariant.live,
        Icons.sports_soccer,
      ),
      MatchAlertType.matchEnded => (
        l10n.alertTypeEnded,
        KickPulseBadgeVariant.neutral,
        Icons.flag_outlined,
      ),
      MatchAlertType.newsPublished => (
        l10n.alertTypeNews,
        KickPulseBadgeVariant.info,
        Icons.newspaper,
      ),
      MatchAlertType.refereeMatchAssigned => (
        l10n.alertTypeRefereeAssigned,
        KickPulseBadgeVariant.warning,
        Icons.sports,
      ),
    };

    return Semantics(
      button: true,
      label: '${alert.title}. ${alert.message}',
      child: InkWell(
        key: Key('alert_tile_${alert.id}'),
        onTap: () {
          if (_isSelectingAlert) return;
          _isSelectingAlert = true;
          ref
              .read(fanAlertsTrayControllerProvider.notifier)
              .markAsRead(alert.id);
          Navigator.of(context).pop();
          widget.onSelectAlert?.call(alert);
        },
      borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
        decoration: BoxDecoration(
          color: alert.isRead
              ? KickPulseColors.surfaceBase
              : KickPulseColors.surfaceElevated.withAlpha(200),
          borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
          border: Border.all(
            color: alert.isRead
                ? KickPulseColors.borderSubtle
                : KickPulseColors.accentElectric.withAlpha(100),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            CircleAvatar(
              radius: 16,
              backgroundColor: alert.isRead
                  ? KickPulseColors.surfaceSubtle
                  : KickPulseColors.accentElectric.withAlpha(40),
              child: Icon(
                iconData,
                size: 16,
                color: alert.isRead
                    ? KickPulseColors.textSecondary
                    : KickPulseColors.accentElectric,
              ),
            ),
            const SizedBox(width: KickPulseRadiiSpacing.spaceSm),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      KickPulseBadge(label: typeLabel, variant: badgeVariant),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: KickPulseTypography.captionMeta.copyWith(
                          color: KickPulseColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                  Text(
                    alert.title,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: Colors.white,
                      fontWeight: alert.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.message,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (!alert.isRead) ...[
              const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: KickPulseColors.accentElectric,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}
