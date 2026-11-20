import 'package:material_ui/material_ui.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

/// Banner de alerta destacado para el rol Organizador cuando hay partidos pendientes de programar o fixture sin generar.
class OrganizerPendingMatchesBanner extends StatelessWidget {
  final int pendingMatchesCount;
  final int unseededTournamentsCount;
  final VoidCallback? onScheduleTap;
  final VoidCallback? onGenerateFixtureTap;

  const OrganizerPendingMatchesBanner({
    super.key,
    required this.pendingMatchesCount,
    required this.unseededTournamentsCount,
    this.onScheduleTap,
    this.onGenerateFixtureTap,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingMatchesCount <= 0 && unseededTournamentsCount <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(
        left: KickPulseRadiiSpacing.spaceMd,
        right: KickPulseRadiiSpacing.spaceMd,
        top: KickPulseRadiiSpacing.spaceSm,
      ),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceElevated,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
        border: Border.all(
          color: KickPulseColors.accentWarning.withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: KickPulseColors.accentWarning.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_outlined,
                  size: 18,
                  color: KickPulseColors.accentWarning,
                ),
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Text(
                  'Panel de Organización',
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.accentWarning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          if (pendingMatchesCount > 0)
            Text(
              '$pendingMatchesCount partidos pendientes de programar fecha y sede',
              style: KickPulseTypography.bodyPrimary.copyWith(
                color: KickPulseColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (unseededTournamentsCount > 0) ...[
            const SizedBox(height: 2),
            Text(
              '$unseededTournamentsCount torneos activos sin calendario generado',
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onScheduleTap != null && pendingMatchesCount > 0)
                ElevatedButton.icon(
                  key: const Key('organizer_schedule_pending_button'),
                  onPressed: onScheduleTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KickPulseColors.accentPrimary,
                    foregroundColor: KickPulseColors.surfaceBase,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    textStyle: KickPulseTypography.microBadge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  icon: const Icon(Icons.calendar_today, size: 14),
                  label: const Text('Programar'),
                ),
              if (onGenerateFixtureTap != null &&
                  unseededTournamentsCount > 0) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  key: const Key('organizer_generate_fixture_button'),
                  onPressed: onGenerateFixtureTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KickPulseColors.accentPrimary,
                    side: const BorderSide(
                      color: KickPulseColors.accentPrimary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 14),
                  label: const Text('Generar Fixture'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
