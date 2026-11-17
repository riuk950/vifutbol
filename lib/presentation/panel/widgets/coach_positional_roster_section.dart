import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/teams/models/team_squad_roster.dart';

/// Positional roster section displayed in [CoachPanelContent] (HU 20.2).
/// Displays players grouped into 4 tactical lines: Goalkeepers, Defenders,
/// Midfielders, and Forwards, sorted ascending by shirt number.
class CoachPositionalRosterSection extends ConsumerWidget {
  final String teamId;

  const CoachPositionalRosterSection({
    super.key,
    required this.teamId,
  });

  Widget _buildPositionGroup({
    required BuildContext context,
    required Key groupKey,
    required String title,
    required List<TeamSquadPlayerItem> players,
    required Key emptyKey,
    required AppLocalizations l10n,
  }) {
    return KickPulseCard(
      key: groupKey,
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: KickPulseTypography.cardTitle,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: KickPulseRadiiSpacing.spaceXs,
              ),
              child: Text(
                l10n.coachRosterEmptyPosition,
                key: emptyKey,
                style: KickPulseTypography.captionMeta.copyWith(
                  color: KickPulseColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: players.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 1,
                color: KickPulseColors.borderSubtle,
              ),
              itemBuilder: (context, index) {
                final item = players[index];
                return Padding(
                  key: Key(
                    'coach_roster_player_${item.shirtNumber}_${item.player.id}',
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: KickPulseColors.surfaceSubtle,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: KickPulseColors.borderSubtle,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '#${item.shirtNumber}',
                          style: KickPulseTypography.microBadge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: KickPulseColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                      Expanded(
                        child: Text(
                          item.fullName,
                          style: KickPulseTypography.bodyPrimary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                      Flexible(
                        fit: FlexFit.loose,
                        child: KickPulseBadge(
                          label: item.isEligible
                              ? l10n.coachRosterPlayerEligible
                              : l10n.coachRosterPlayerInactive,
                          variant: item.isEligible
                              ? KickPulseBadgeVariant.success
                              : KickPulseBadgeVariant.warning,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roster = ref.watch(teamSquadRosterProvider(teamId));

    final hasNoGoalkeeper = roster.goalkeepers.isEmpty;

    return Column(
      key: const Key('coach_positional_roster_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.coachRosterSectionTitle,
          style: KickPulseTypography.sectionHeader,
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

        // Tactical alert when no goalkeeper is present
        if (hasNoGoalkeeper) ...[
          KickPulseCard(
            key: const Key('coach_no_goalkeeper_tactical_alert'),
            backgroundColor: KickPulseColors.accentWarning.withAlpha(25),
            borderSide: BorderSide(
              color: KickPulseColors.accentWarning.withAlpha(140),
              width: 1.0,
            ),
            padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: KickPulseColors.accentWarning,
                  size: 20,
                ),
                const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                Expanded(
                  child: Text(
                    l10n.coachRosterNoGoalkeeperAlert,
                    style: KickPulseTypography.bodyPrimary.copyWith(
                      color: KickPulseColors.accentWarning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
        ],

        // 1. Goalkeepers line
        _buildPositionGroup(
          context: context,
          groupKey: const Key('coach_roster_group_goalkeeper'),
          title: l10n.coachRosterPositionGoalkeepers(roster.goalkeepers.length),
          players: roster.goalkeepers,
          emptyKey: const Key('coach_roster_empty_goalkeeper'),
          l10n: l10n,
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

        // 2. Defenders line
        _buildPositionGroup(
          context: context,
          groupKey: const Key('coach_roster_group_defender'),
          title: l10n.coachRosterPositionDefenders(roster.defenders.length),
          players: roster.defenders,
          emptyKey: const Key('coach_roster_empty_defender'),
          l10n: l10n,
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

        // 3. Midfielders line
        _buildPositionGroup(
          context: context,
          groupKey: const Key('coach_roster_group_midfielder'),
          title: l10n.coachRosterPositionMidfielders(roster.midfielders.length),
          players: roster.midfielders,
          emptyKey: const Key('coach_roster_empty_midfielder'),
          l10n: l10n,
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

        // 4. Forwards line
        _buildPositionGroup(
          context: context,
          groupKey: const Key('coach_roster_group_forward'),
          title: l10n.coachRosterPositionForwards(roster.forwards.length),
          players: roster.forwards,
          emptyKey: const Key('coach_roster_empty_forward'),
          l10n: l10n,
        ),
      ],
    );
  }
}
