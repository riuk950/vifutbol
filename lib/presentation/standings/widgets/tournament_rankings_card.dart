import 'package:flutter/material.dart';
import 'package:vifutbol/domain/entities/tournament_rankings.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

enum _RankingCategory { scorers, assists, fairPlay }

/// Displays individual & collective sports leaderboards (`Goleadores`, `Asistencias`, `Fair Play`)
/// with `tabular-nums` alignment (`FR-007`, `FR-008`, `FR-009`, `FR-010`).
class TournamentRankingsCard extends StatefulWidget {
  const TournamentRankingsCard({
    super.key,
    required this.rankings,
    this.onPlayerSelected,
    this.onTeamSelected,
  });

  final TournamentRankingsBundle rankings;
  final ValueChanged<String>? onPlayerSelected;
  final ValueChanged<String>? onTeamSelected;

  @override
  State<TournamentRankingsCard> createState() => _TournamentRankingsCardState();
}

class _TournamentRankingsCardState extends State<TournamentRankingsCard> {
  _RankingCategory _selectedCategory = _RankingCategory.scorers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      key: const Key('rankings_section_card'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceBase,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
        border: Border.all(color: KickPulseColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.military_tech_rounded,
                color: KickPulseColors.accentPrimary,
                size: 20,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Text(
                  l10n.rankingsSectionTitle,
                  style: KickPulseTypography.cardTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.rankingsSectionSubtitle,
            style: KickPulseTypography.captionMeta,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          Wrap(
            spacing: KickPulseRadiiSpacing.spaceSm,
            runSpacing: KickPulseRadiiSpacing.spaceXs,
            children: <Widget>[
              ChoiceChip(
                key: const Key('rankings_category_scorers'),
                label: Text(l10n.rankingsCategoryScorers),
                selected: _selectedCategory == _RankingCategory.scorers,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = _RankingCategory.scorers;
                  });
                },
              ),
              ChoiceChip(
                key: const Key('rankings_category_assists'),
                label: Text(l10n.rankingsCategoryAssists),
                selected: _selectedCategory == _RankingCategory.assists,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = _RankingCategory.assists;
                  });
                },
              ),
              ChoiceChip(
                key: const Key('rankings_category_fair_play'),
                label: Text(l10n.rankingsCategoryFairPlay),
                selected: _selectedCategory == _RankingCategory.fairPlay,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = _RankingCategory.fairPlay;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          if (_selectedCategory == _RankingCategory.scorers)
            _buildPlayerLeaderboard(
              l10n: l10n,
              entries: widget.rankings.topScorers,
              emptyMessage: l10n.rankingsEmptyScorers,
              isScorers: true,
            )
          else if (_selectedCategory == _RankingCategory.assists)
            _buildPlayerLeaderboard(
              l10n: l10n,
              entries: widget.rankings.topAssists,
              emptyMessage: l10n.rankingsEmptyAssists,
              isScorers: false,
            )
          else
            _buildFairPlayLeaderboard(l10n, widget.rankings.teamFairPlay),
        ],
      ),
    );
  }

  Widget _buildPlayerLeaderboard({
    required AppLocalizations l10n,
    required List<PlayerRankingEntry> entries,
    required String emptyMessage,
    required bool isScorers,
  }) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: KickPulseRadiiSpacing.spaceLg,
        ),
        child: Center(
          child: Text(
            emptyMessage,
            style: KickPulseTypography.bodyPrimary.copyWith(
              color: KickPulseColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: entries.map((entry) {
        final rowKey = isScorers
            ? Key('scorer_row_${entry.playerId}')
            : Key('assist_row_${entry.playerId}');
        final primaryMetric = isScorers
            ? l10n.rankingsGoalsUnit(entry.goals)
            : l10n.rankingsAssistsUnit(entry.assists);
        final secondaryMetric = isScorers && entry.assists > 0
            ? l10n.rankingsAssistsUnit(entry.assists)
            : (!isScorers && entry.goals > 0
                  ? l10n.rankingsGoalsUnit(entry.goals)
                  : null);

        return InkWell(
          key: rowKey,
          onTap: widget.onPlayerSelected != null
              ? () => widget.onPlayerSelected!(entry.playerId)
              : null,
          borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(
              horizontal: KickPulseRadiiSpacing.spaceSm,
              vertical: 10,
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
                    '${entry.rank}',
                    style: KickPulseTypography.statMetric(
                      size: 14,
                      weight: FontWeight.w800,
                      color: entry.rank == 1
                          ? KickPulseColors.accentPrimary
                          : KickPulseColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${entry.playerName} (#${entry.shirtNumber})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KickPulseTypography.bodyPrimary.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${entry.teamName} (${entry.teamShortCode})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KickPulseTypography.captionMeta,
                      ),
                    ],
                  ),
                ),
                if (secondaryMetric != null) ...<Widget>[
                  const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                  Text(
                    secondaryMetric,
                    style: KickPulseTypography.statMetric(
                      size: 12,
                      weight: FontWeight.w500,
                      color: KickPulseColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: KickPulseColors.accentPrimary.withValues(
                      alpha: 0.16,
                    ),
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.badgeRadius,
                    ),
                  ),
                  child: Text(
                    primaryMetric,
                    style: KickPulseTypography.statMetric(
                      size: 13,
                      weight: FontWeight.w800,
                      color: KickPulseColors.accentPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFairPlayLeaderboard(
    AppLocalizations l10n,
    List<TeamFairPlayRow> rows,
  ) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: KickPulseRadiiSpacing.spaceLg,
        ),
        child: Center(
          child: Text(
            l10n.rankingsEmptyFairPlay,
            style: KickPulseTypography.bodyPrimary.copyWith(
              color: KickPulseColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ...rows.map((row) {
          return InkWell(
            key: Key('fair_play_row_${row.teamId}'),
            onTap: widget.onTeamSelected != null
                ? () => widget.onTeamSelected!(row.teamId)
                : null,
            borderRadius: BorderRadius.circular(
              KickPulseRadiiSpacing.chipRadius,
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                horizontal: KickPulseRadiiSpacing.spaceSm,
                vertical: 10,
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
                      '${row.rank}',
                      style: KickPulseTypography.statMetric(
                        size: 14,
                        weight: FontWeight.w800,
                        color: row.rank == 1
                            ? KickPulseColors.accentPrimary
                            : KickPulseColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${row.teamName} (${row.teamShortCode})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KickPulseTypography.bodyPrimary.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'TA: ${row.yellowCards} · 2A/R: ${row.secondYellowRedCards} · TR: ${row.directRedCards}',
                          style: KickPulseTypography.statMetric(
                            size: 11,
                            weight: FontWeight.w500,
                            color: KickPulseColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: row.penaltyPoints == 0
                          ? KickPulseColors.accentPrimary.withValues(
                              alpha: 0.16,
                            )
                          : KickPulseColors.accentWarning.withValues(
                              alpha: 0.16,
                            ),
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.badgeRadius,
                      ),
                    ),
                    child: Text(
                      l10n.rankingsFairPlayPointsUnit(row.penaltyPoints),
                      style: KickPulseTypography.statMetric(
                        size: 13,
                        weight: FontWeight.w800,
                        color: row.penaltyPoints == 0
                            ? KickPulseColors.accentPrimary
                            : KickPulseColors.accentWarning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
        Text(
          l10n.rankingsFairPlayLegend,
          style: KickPulseTypography.captionMeta,
        ),
      ],
    );
  }
}
