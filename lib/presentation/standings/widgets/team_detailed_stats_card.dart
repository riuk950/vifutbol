import 'package:flutter/material.dart';
import 'package:vifutbol/domain/entities/team_detailed_stats.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'player_performance_profile_card.dart';

/// Modal bottom sheet or embedded card displaying a team's detailed statistics sheet (`US2`).
class TeamDetailedStatsCard extends StatelessWidget {
  const TeamDetailedStatsCard({
    super.key,
    required this.teamStats,
    this.onPlayerSelected,
    this.onClose,
  });

  final TeamDetailedStats teamStats;
  final ValueChanged<String>? onPlayerSelected;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final row = teamStats.standingsRow;

    return Container(
      key: const Key('team_detailed_stats_card'),
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
          // Header Row with Crest Color, Team Name, and Close
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Color(teamStats.primaryColorHex),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${teamStats.teamName} (${teamStats.teamShortCode})',
                      style: KickPulseTypography.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.standingsColPos} #${row.position} · ${row.points} ${l10n.standingsColPoints}',
                      style: KickPulseTypography.captionMeta.copyWith(
                        color: KickPulseColors.accentPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null) ...<Widget>[
                IconButton(
                  key: const Key('close_team_detailed_stats_button'),
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                ),
              ],
            ],
          ),

          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          // League Metrics Strip (tabular-nums)
          Wrap(
            spacing: KickPulseRadiiSpacing.spaceSm,
            runSpacing: KickPulseRadiiSpacing.spaceSm,
            children: <Widget>[
              _buildMetricTile(l10n.standingsColPlayed, '${row.played}'),
              _buildMetricTile(l10n.standingsColWon, '${row.won}'),
              _buildMetricTile(l10n.standingsColDrawn, '${row.drawn}'),
              _buildMetricTile(l10n.standingsColLost, '${row.lost}'),
              _buildMetricTile(l10n.standingsColGoalsFor, '${row.goalsFor}'),
              _buildMetricTile(
                l10n.standingsColGoalsAgainst,
                '${row.goalsAgainst}',
              ),
              _buildMetricTile(
                l10n.standingsColGoalDifference,
                row.goalDifference > 0
                    ? '+${row.goalDifference}'
                    : '${row.goalDifference}',
              ),
            ],
          ),

          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          // Recent 5-match Form Strip (V, E, D)
          Text(
            l10n.teamRecentFormTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          if (teamStats.recentForm.isEmpty)
            Text(
              l10n.teamRecentFormEmpty,
              style: KickPulseTypography.captionMeta,
            )
          else
            Row(
              key: const Key('team_recent_form_strip'),
              children: teamStats.recentForm.map((result) {
                Color color;
                switch (result) {
                  case TeamFormResult.win:
                    color = KickPulseColors.accentPrimary;
                    break;
                  case TeamFormResult.draw:
                    color = KickPulseColors.accentWarning;
                    break;
                  case TeamFormResult.loss:
                    color = KickPulseColors.accentLive;
                    break;
                }

                return Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.badgeRadius,
                    ),
                    border: Border.all(color: color),
                  ),
                  child: Center(
                    child: Text(
                      result.code,
                      style: KickPulseTypography.statMetric(
                        size: 13,
                        weight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          // Completed Match History
          Text(
            l10n.teamCompletedMatchesTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          if (teamStats.completedMatches.isEmpty)
            Text(
              l10n.teamCompletedMatchesEmpty,
              style: KickPulseTypography.captionMeta,
            )
          else
            ...teamStats.completedMatches.take(5).map((m) {
              return Container(
                key: Key('team_history_match_${m.matchId}'),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: KickPulseRadiiSpacing.spaceSm,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: KickPulseColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(
                    KickPulseRadiiSpacing.chipRadius,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      m.result.code,
                      style: KickPulseTypography.statMetric(
                        size: 13,
                        weight: FontWeight.w800,
                        color: m.result == TeamFormResult.win
                            ? KickPulseColors.accentPrimary
                            : (m.result == TeamFormResult.draw
                                  ? KickPulseColors.accentWarning
                                  : KickPulseColors.accentLive),
                      ),
                    ),
                    const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                    Expanded(
                      child: Text(
                        'vs ${m.opponentTeamName} (${m.opponentShortCode}) · ${m.roundName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KickPulseTypography.bodyPrimary,
                      ),
                    ),
                    const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                    Text(
                      '${m.teamScore} - ${m.opponentScore}',
                      style: KickPulseTypography.statMetric(
                        size: 14,
                        weight: FontWeight.w700,
                        color: KickPulseColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          // Upcoming Matches
          Text(
            l10n.teamUpcomingMatchesTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          if (teamStats.upcomingMatches.isEmpty)
            Text(
              l10n.teamUpcomingMatchesEmpty,
              style: KickPulseTypography.captionMeta,
            )
          else
            ...teamStats.upcomingMatches.take(3).map((m) {
              return Container(
                key: Key('team_upcoming_match_${m.matchId}'),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: KickPulseRadiiSpacing.spaceSm,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: KickPulseColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(
                    KickPulseRadiiSpacing.chipRadius,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: KickPulseColors.accentElectric,
                    ),
                    const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                    Expanded(
                      child: Text(
                        'vs ${m.opponentTeamName} (${m.opponentShortCode}) · ${m.roundName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KickPulseTypography.bodyPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          // Squad List with Individual Stats (tap navigates to player profile)
          Text(
            l10n.teamSquadStatsTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          if (teamStats.squadStats.isEmpty)
            Text(
              l10n.teamSquadStatsEmpty,
              style: KickPulseTypography.captionMeta,
            )
          else
            ...teamStats.squadStats.map((player) {
              return InkWell(
                key: Key('team_squad_player_row_${player.playerId}'),
                onTap: () {
                  if (onPlayerSelected != null) {
                    onPlayerSelected!(player.playerId);
                  } else {
                    showPlayerPerformanceProfileSheet(
                      context: context,
                      profile: player,
                      allTournamentPlayers: teamStats.squadStats,
                      onPlayerSelected: onPlayerSelected,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(
                  KickPulseRadiiSpacing.chipRadius,
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: KickPulseRadiiSpacing.spaceSm,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: KickPulseColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.chipRadius,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 28,
                        child: Text(
                          '#${player.shirtNumber}',
                          style: KickPulseTypography.statMetric(
                            size: 13,
                            weight: FontWeight.w700,
                            color: KickPulseColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              player.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KickPulseTypography.bodyPrimary.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${player.matchesPlayed} PJ · ${player.goals} G · ${player.assists} A',
                              style: KickPulseTypography.captionMeta,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: KickPulseColors.textTertiary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceElevated,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.badgeRadius),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: KickPulseTypography.microBadge.copyWith(
              color: KickPulseColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: KickPulseTypography.statMetric(
              size: 13,
              weight: FontWeight.w700,
              color: KickPulseColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show `TeamDetailedStatsCard` as a modal bottom sheet.
Future<void> showTeamDetailedStatsSheet({
  required BuildContext context,
  required TeamDetailedStats teamStats,
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
            child: TeamDetailedStatsCard(
              teamStats: teamStats,
              onPlayerSelected: onPlayerSelected,
              onClose: () => Navigator.of(modalContext).pop(),
            ),
          );
        },
      );
    },
  );
}
