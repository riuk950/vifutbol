import 'package:flutter/material.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';

/// Tab view presenting competition information and official tournament rules.
class CompetitionInfoTabView extends StatelessWidget {
  final String tournamentId;

  const CompetitionInfoTabView({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      key: const Key('competition_detail_info_content'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
        child: KickPulseCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: KickPulseRadiiSpacing.spaceLg,
              horizontal: KickPulseRadiiSpacing.spaceMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: KickPulseColors.accentElectric.withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: KickPulseColors.accentElectric,
                    size: 32,
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                Text(
                  l10n.competitionInfoTitle,
                  style: KickPulseTypography.sectionHeader,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                Text(
                  l10n.competitionInfoMessage,
                  style: KickPulseTypography.bodyPrimary.copyWith(
                    color: KickPulseColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
