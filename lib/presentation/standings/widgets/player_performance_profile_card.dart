import 'package:flutter/material.dart';
import 'package:vifutbol/domain/entities/player_performance_profile.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

/// Modal bottom sheet or embedded card displaying a player's official performance profile (`US1`).
class PlayerPerformanceProfileCard extends StatelessWidget {
  const PlayerPerformanceProfileCard({
    super.key,
    required this.profile,
    this.allTournamentPlayers = const <PlayerPerformanceProfile>[],
    this.onPlayerSelected,
    this.onClose,
  });

  final PlayerPerformanceProfile profile;
  final List<PlayerPerformanceProfile> allTournamentPlayers;
  final ValueChanged<String>? onPlayerSelected;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      key: const Key('player_performance_profile_card'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceBase,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
        border: Border.all(color: KickPulseColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Header Row with Title, Disciplinary Badge, and Close
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.person_rounded,
                color: KickPulseColors.accentPrimary,
                size: 22,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      profile.fullName,
                      style: KickPulseTypography.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${profile.teamName} (${profile.teamShortCode}) · #${profile.shirtNumber} · ${profile.position.name.toUpperCase()}',
                      style: KickPulseTypography.captionMeta,
                    ),
                  ],
                ),
              ),
              _buildDisciplinaryBadge(l10n),
              if (onClose != null) ...<Widget>[
                const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                IconButton(
                  key: const Key('close_player_profile_button'),
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                ),
              ],
            ],
          ),

          // Optional player switcher chip list
          if (allTournamentPlayers.length > 1 &&
              onPlayerSelected != null) ...<Widget>[
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: allTournamentPlayers.map((p) {
                  final isSelected = p.playerId == profile.playerId;
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: KickPulseRadiiSpacing.spaceXs,
                    ),
                    child: ChoiceChip(
                      key: Key('player_switcher_chip_${p.playerId}'),
                      label: Text('#${p.shirtNumber} ${p.fullName}'),
                      selected: isSelected,
                      onSelected: (_) => onPlayerSelected!(p.playerId),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          // Metric Cards Grid (tabular-nums)
          Wrap(
            spacing: KickPulseRadiiSpacing.spaceSm,
            runSpacing: KickPulseRadiiSpacing.spaceSm,
            children: <Widget>[
              _buildMetricTile(
                key: const Key('player_metric_matches_played'),
                label: l10n.playerMetricMatchesPlayed,
                value: '${profile.matchesPlayed}',
                color: KickPulseColors.accentElectric,
              ),
              _buildMetricTile(
                key: const Key('player_metric_starts'),
                label: l10n.playerMetricStarts,
                value: '${profile.startsCount}',
                color: KickPulseColors.textPrimary,
              ),
              _buildMetricTile(
                key: const Key('player_metric_goals'),
                label: l10n.playerMetricGoals,
                value: '${profile.goals}',
                color: KickPulseColors.accentPrimary,
              ),
              _buildMetricTile(
                key: const Key('player_metric_assists'),
                label: l10n.playerMetricAssists,
                value: '${profile.assists}',
                color: KickPulseColors.accentElectric,
              ),
              _buildMetricTile(
                key: const Key('player_metric_goal_average'),
                label: l10n.playerMetricGoalAverage,
                value: profile.formattedGoalsAverage,
                color: KickPulseColors.accentPrimary,
              ),
              _buildMetricTile(
                key: const Key('player_metric_yellow_cards'),
                label: l10n.playerMetricYellowCards,
                value: '${profile.yellowCards}',
                color: KickPulseColors.accentWarning,
              ),
              _buildMetricTile(
                key: const Key('player_metric_red_cards'),
                label: l10n.playerMetricRedCards,
                value: '${profile.redCards}',
                color: KickPulseColors.accentLive,
              ),
            ],
          ),

          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          // Match-by-match section or empty message
          Text(
            l10n.playerMatchBreakdownTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

          if (!profile.hasParticipations)
            Container(
              key: const Key('player_empty_participations_message'),
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
              decoration: BoxDecoration(
                color: KickPulseColors.surfaceElevated,
                borderRadius: BorderRadius.circular(
                  KickPulseRadiiSpacing.chipRadius,
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.info_outline_rounded,
                    color: KickPulseColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                  Expanded(
                    child: Text(
                      l10n.playerEmptyParticipationsMessage,
                      style: KickPulseTypography.bodyPrimary.copyWith(
                        color: KickPulseColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...profile.matchParticipations.map(
              (participation) =>
                  _buildParticipationRow(context, l10n, participation),
            ),
        ],
      ),
    );
  }

  Widget _buildDisciplinaryBadge(AppLocalizations l10n) {
    final isSuspended = profile.isSuspended;
    final text = isSuspended
        ? l10n.playerDisciplinaryStatusSuspended
        : l10n.playerDisciplinaryStatusEnabled;
    final color = isSuspended
        ? KickPulseColors.accentLive
        : KickPulseColors.accentPrimary;

    return Container(
      key: const Key('player_disciplinary_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.badgeRadius),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: KickPulseTypography.microBadge.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required Key key,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      key: key,
      width: 96,
      padding: const EdgeInsets.symmetric(
        horizontal: KickPulseRadiiSpacing.spaceSm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceElevated,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KickPulseTypography.microBadge.copyWith(
              color: KickPulseColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: KickPulseTypography.statMetric(
              size: 16,
              weight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipationRow(
    BuildContext context,
    AppLocalizations l10n,
    PlayerMatchParticipation p,
  ) {
    return Container(
      key: Key('player_match_participation_${p.matchId}'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: KickPulseRadiiSpacing.spaceSm,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceElevated,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: p.wasStarter
                  ? KickPulseColors.accentPrimary.withValues(alpha: 0.18)
                  : KickPulseColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(
                KickPulseRadiiSpacing.badgeRadius,
              ),
            ),
            child: Text(
              p.wasStarter
                  ? l10n.playerStarterBadge
                  : l10n.playerSubstituteBadge,
              style: KickPulseTypography.microBadge.copyWith(
                color: p.wasStarter
                    ? KickPulseColors.accentPrimary
                    : KickPulseColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'vs ${p.opponentTeamName} (${p.opponentShortCode})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KickPulseTypography.bodyPrimary.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${p.roundName} · Resultado: ${p.teamScore}-${p.opponentScore}',
                  style: KickPulseTypography.captionMeta,
                ),
              ],
            ),
          ),
          const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
          if (p.goals > 0)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                '⚽ ${p.goals}',
                style: KickPulseTypography.statMetric(
                  size: 12,
                  weight: FontWeight.w700,
                  color: KickPulseColors.accentPrimary,
                ),
              ),
            ),
          if (p.assists > 0)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                '👟 ${p.assists}',
                style: KickPulseTypography.statMetric(
                  size: 12,
                  weight: FontWeight.w700,
                  color: KickPulseColors.accentElectric,
                ),
              ),
            ),
          if (p.yellowCards > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '🟨 ${p.yellowCards}',
                style: KickPulseTypography.statMetric(
                  size: 11,
                  weight: FontWeight.w700,
                  color: KickPulseColors.accentWarning,
                ),
              ),
            ),
          if (p.redCards > 0)
            Text(
              '🟥 ${p.redCards}',
              style: KickPulseTypography.statMetric(
                size: 11,
                weight: FontWeight.w700,
                color: KickPulseColors.accentLive,
              ),
            ),
        ],
      ),
    );
  }
}

/// Helper function to show `PlayerPerformanceProfileCard` as a modal bottom sheet.
Future<void> showPlayerPerformanceProfileSheet({
  required BuildContext context,
  required PlayerPerformanceProfile profile,
  List<PlayerPerformanceProfile> allTournamentPlayers = const [],
  ValueChanged<String>? onPlayerSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: PlayerPerformanceProfileCard(
              profile: profile,
              allTournamentPlayers: allTournamentPlayers,
              onPlayerSelected: onPlayerSelected,
              onClose: () => Navigator.of(modalContext).pop(),
            ),
          );
        },
      );
    },
  );
}
