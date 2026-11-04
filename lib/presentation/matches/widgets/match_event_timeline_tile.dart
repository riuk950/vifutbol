import 'package:flutter/material.dart';
import '../../../domain/entities/match_event.dart';
import '../../../domain/entities/match_report_enums.dart';
import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/kick_pulse_typography.dart';

/// Timeline item displaying an official match event with semantic signals and undo capability.
class MatchEventTimelineTile extends StatelessWidget {
  const MatchEventTimelineTile({
    super.key,
    required this.event,
    this.canUndo = false,
    this.onUndo,
  });

  final MatchEvent event;
  final bool canUndo;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final IconData icon;
    final Color eventColor;
    final String mainText;
    final String? subText;

    switch (event.type) {
      case MatchEventType.goal:
        icon = Icons.sports_soccer;
        eventColor = KickPulseColors.accentLive;
        final shirt = event.primaryPlayerShirtNumber != null
            ? ' #${event.primaryPlayerShirtNumber}'
            : '';
        mainText = 'Gol de ${event.primaryPlayerName ?? 'Jugador'}$shirt';
        if (event.secondaryPlayerName != null &&
            event.secondaryPlayerName!.isNotEmpty) {
          final assistShirt = event.secondaryPlayerShirtNumber != null
              ? ' #${event.secondaryPlayerShirtNumber}'
              : '';
          subText = 'Asistencia: ${event.secondaryPlayerName}$assistShirt';
        } else {
          subText = event.description;
        }
        break;

      case MatchEventType.yellowCard:
        icon = Icons.style;
        eventColor = Colors.amber;
        final shirt = event.primaryPlayerShirtNumber != null
            ? ' #${event.primaryPlayerShirtNumber}'
            : '';
        mainText =
            'Tarjeta Amarilla - ${event.primaryPlayerName ?? 'Jugador'}$shirt';
        subText = event.description;
        break;

      case MatchEventType.secondYellowRedCard:
        icon = Icons.warning_amber_rounded;
        eventColor = KickPulseColors.accentLive;
        final shirt = event.primaryPlayerShirtNumber != null
            ? ' #${event.primaryPlayerShirtNumber}'
            : '';
        mainText =
            'Segunda Amarilla y Expulsión - ${event.primaryPlayerName ?? 'Jugador'}$shirt';
        subText = 'Expulsión automática por acumulación';
        break;

      case MatchEventType.directRedCard:
        icon = Icons.dangerous;
        eventColor = KickPulseColors.accentLive;
        final shirt = event.primaryPlayerShirtNumber != null
            ? ' #${event.primaryPlayerShirtNumber}'
            : '';
        mainText =
            'Tarjeta Roja Directa - ${event.primaryPlayerName ?? 'Jugador'}$shirt';
        subText = event.description;
        break;

      case MatchEventType.substitution:
        icon = Icons.swap_horiz;
        eventColor = KickPulseColors.accentElectric;
        final outShirt = event.primaryPlayerShirtNumber != null
            ? ' #${event.primaryPlayerShirtNumber}'
            : '';
        final inShirt = event.secondaryPlayerShirtNumber != null
            ? ' #${event.secondaryPlayerShirtNumber}'
            : '';
        mainText =
            'Sale ${event.primaryPlayerName ?? 'Jugador'}$outShirt, entra ${event.secondaryPlayerName ?? 'Jugador'}$inShirt';
        subText = event.description;
        break;

      case MatchEventType.periodTransition:
        icon = Icons.timer;
        eventColor = Colors.white70;
        mainText = 'Hito: ${event.description ?? 'Cambio de Periodo'}';
        subText = null;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: KickPulseRadiiSpacing.spaceMd,
        vertical: KickPulseRadiiSpacing.spaceXs,
      ),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
      decoration: BoxDecoration(
        color: isDark ? KickPulseColors.surfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
        border: Border.all(
          color: isDark ? KickPulseColors.borderSubtle : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Minute badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KickPulseRadiiSpacing.spaceSm,
              vertical: KickPulseRadiiSpacing.spaceXs,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? KickPulseColors.surfaceBase
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(
                KickPulseRadiiSpacing.chipRadius,
              ),
              border: Border.all(
                color: eventColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Text(
              '${event.minute}\'',
              style: KickPulseTypography.bodyPrimary.copyWith(
                fontWeight: FontWeight.bold,
                color: eventColor,
              ),
            ),
          ),
          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),

          // Icon indicator
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: eventColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: eventColor),
          ),
          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),

          // Event Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mainText,
                  style: KickPulseTypography.cardTitle.copyWith(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (subText != null && subText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subText,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Unsynced indicator or Undo Action
          if (!event.isSynced) ...[
            Tooltip(
              message: 'Pendiente de sincronizar',
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(
                  Icons.cloud_off,
                  size: 18,
                  color: Colors.amber.shade300,
                ),
              ),
            ),
          ],

          if (canUndo &&
              onUndo != null &&
              event.type != MatchEventType.periodTransition)
            IconButton(
              icon: const Icon(Icons.undo, size: 20),
              color: Colors.redAccent,
              tooltip: 'Anular incidencia',
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: onUndo,
            ),
        ],
      ),
    );
  }
}
