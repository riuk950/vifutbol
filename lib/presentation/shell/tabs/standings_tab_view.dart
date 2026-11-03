import 'package:flutter/material.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';

class StandingsTabView extends StatelessWidget {
  const StandingsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tabStandings, style: KickPulseTypography.screenTitle),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          KickPulseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tabStandings, style: KickPulseTypography.cardTitle),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                Text(
                  'Tabla de posiciones oficial calculada en tiempo real.',
                  style: KickPulseTypography.bodyPrimary.copyWith(
                    color: KickPulseColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
