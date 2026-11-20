import 'package:material_ui/material_ui.dart';
import 'package:vifutbol/domain/entities/season_honor_roll.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

/// Card presenting the official deterministic Season Honor Roll (Cuadro de Honor Oficial)
/// once a tournament has officially finished.
class SeasonHonorRollCard extends StatelessWidget {
  const SeasonHonorRollCard({super.key, required this.honorRoll});

  final SeasonHonorRoll honorRoll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      key: const Key('season_honor_roll_card'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceBase,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
        border: Border.all(
          color: KickPulseColors.accentPrimary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: KickPulseColors.accentPrimary,
                size: 24,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Text(
                  l10n.honorRollTitle,
                  style: KickPulseTypography.cardTitle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: KickPulseColors.surfaceElevated,
              borderRadius: BorderRadius.circular(
                KickPulseRadiiSpacing.badgeRadius,
              ),
              border: Border.all(color: KickPulseColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.history_toggle_off_rounded,
                  size: 14,
                  color: KickPulseColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l10n.seasonReadOnlyBadge,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          _HonorItem(
            icon: Icons.emoji_events,
            iconColor: const Color(0xFFFFD700),
            title: l10n.honorRollChampion,
            primaryText:
                '${honorRoll.championTeamName} (${honorRoll.championShortCode})',
            badgeKey: const Key('honor_roll_champion_item'),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          _HonorItem(
            icon: Icons.military_tech,
            iconColor: const Color(0xFFC0C0C0),
            title: l10n.honorRollRunnerUp,
            primaryText:
                '${honorRoll.runnerUpTeamName} (${honorRoll.runnerUpShortCode})',
            badgeKey: const Key('honor_roll_runner_up_item'),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          _HonorItem(
            icon: Icons.sports_soccer,
            iconColor: KickPulseColors.accentPrimary,
            title: l10n.honorRollTopScorer,
            primaryText: honorRoll.topScorerGoals > 0
                ? '${honorRoll.topScorerPlayerName ?? "-"} (${honorRoll.topScorerTeamName ?? "-"})'
                : l10n.honorRollNoGoals,
            secondaryText: honorRoll.topScorerGoals > 0
                ? l10n.honorRollGoalsCount(honorRoll.topScorerGoals)
                : null,
            badgeKey: const Key('honor_roll_top_scorer_item'),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          _HonorItem(
            icon: Icons.shield_outlined,
            iconColor: KickPulseColors.accentElectric,
            title: l10n.honorRollBestDefense,
            primaryText:
                '${honorRoll.bestDefenseTeamName} (${honorRoll.bestDefenseShortCode})',
            secondaryText: l10n.honorRollGoalsAgainstCount(
              honorRoll.bestDefenseGoalsAgainst,
            ),
            badgeKey: const Key('honor_roll_best_defense_item'),
          ),
        ],
      ),
    );
  }
}

class _HonorItem extends StatelessWidget {
  const _HonorItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.primaryText,
    this.secondaryText,
    required this.badgeKey,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String primaryText;
  final String? secondaryText;
  final Key badgeKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: badgeKey,
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceElevated,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.badgeRadius),
        border: Border.all(color: KickPulseColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  primaryText,
                  style: KickPulseTypography.bodyPrimary.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (secondaryText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    secondaryText!,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.accentPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
