import 'package:material_ui/material_ui.dart';
import 'package:vifutbol/domain/entities/standings_table.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

/// Displays the official deterministic league or group-stage standings table
/// with `tabular-nums` alignment (`FR-010`) and zero horizontal overflow (`SC-004`).
class StandingsTableCard extends StatefulWidget {
  const StandingsTableCard({
    super.key,
    required this.mainTable,
    this.groupTables = const <StandingsTable>[],
    this.onTeamSelected,
  });

  final StandingsTable mainTable;
  final List<StandingsTable> groupTables;
  final ValueChanged<String>? onTeamSelected;

  @override
  State<StandingsTableCard> createState() => _StandingsTableCardState();
}

class _StandingsTableCardState extends State<StandingsTableCard> {
  int _selectedGroupIndex = 0;

  String _formatTiebreakerLabel(
    AppLocalizations l10n,
    TiebreakerCriterion criterion,
  ) {
    switch (criterion) {
      case TiebreakerCriterion.goalDifference:
        return l10n.tiebreakerGoalDifference;
      case TiebreakerCriterion.goalsFor:
        return l10n.tiebreakerGoalsFor;
      case TiebreakerCriterion.headToHead:
        return l10n.tiebreakerHeadToHead;
      case TiebreakerCriterion.fairPlay:
        return l10n.tiebreakerFairPlay;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasGroups = widget.groupTables.isNotEmpty;
    final safeIndex = hasGroups
        ? _selectedGroupIndex.clamp(0, widget.groupTables.length - 1)
        : 0;
    final activeTable = hasGroups
        ? widget.groupTables[safeIndex]
        : widget.mainTable;

    final criteriaText = activeTable.appliedTiebreakers
        .map((c) => _formatTiebreakerLabel(l10n, c))
        .join(' → ');

    return Container(
      key: const Key('standings_table_card'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceBase,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
        border: Border.all(color: KickPulseColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: KickPulseRadiiSpacing.spaceSm,
            runSpacing: KickPulseRadiiSpacing.spaceXs,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.leaderboard_rounded,
                    color: KickPulseColors.accentPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                  Flexible(
                    child: Text(
                      activeTable.groupName != null
                          ? '${l10n.standingsTableTitle} · ${activeTable.groupName}'
                          : l10n.standingsTableTitle,
                      style: KickPulseTypography.cardTitle,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KickPulseRadiiSpacing.spaceSm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: KickPulseColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(
                    KickPulseRadiiSpacing.badgeRadius,
                  ),
                ),
                child: Text(
                  l10n.standingsCompletedMatchesBadge(
                    activeTable.completedMatchesCount,
                  ),
                  style: KickPulseTypography.captionMeta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.standingsTableSubtitle,
            style: KickPulseTypography.captionMeta,
          ),
          if (hasGroups) ...<Widget>[
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List<Widget>.generate(widget.groupTables.length, (i) {
                  final group = widget.groupTables[i];
                  final isSelected = i == safeIndex;
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: KickPulseRadiiSpacing.spaceSm,
                    ),
                    child: ChoiceChip(
                      key: Key('standings_group_chip_$i'),
                      label: Text(group.groupName ?? 'Grupo ${i + 1}'),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedGroupIndex = i;
                        });
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          if (activeTable.rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: KickPulseRadiiSpacing.spaceLg,
              ),
              child: Center(
                child: Text(
                  l10n.standingsEmptyTeams,
                  style: KickPulseTypography.bodyPrimary.copyWith(
                    color: KickPulseColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 520,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildHeaderRow(l10n),
                    const SizedBox(height: 6),
                    ...activeTable.rows.map(
                      (row) => _buildTeamStandingRow(context, l10n, row),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          Wrap(
            spacing: KickPulseRadiiSpacing.spaceMd,
            runSpacing: KickPulseRadiiSpacing.spaceXs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: KickPulseColors.accentPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.standingsQualificationZoneLabel,
                      style: KickPulseTypography.captionMeta,
                    ),
                  ),
                ],
              ),
              Text(
                l10n.standingsTiebreakerCaption(criteriaText),
                style: KickPulseTypography.captionMeta,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(AppLocalizations l10n) {
    final headerStyle = KickPulseTypography.microBadge.copyWith(
      color: KickPulseColors.textSecondary,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KickPulseRadiiSpacing.spaceSm,
        vertical: KickPulseRadiiSpacing.spaceXs,
      ),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceSubtle.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 38,
            child: Text(l10n.standingsColPos, style: headerStyle),
          ),
          SizedBox(
            width: 150,
            child: Text(l10n.standingsColTeam, style: headerStyle),
          ),
          _buildStatCell(l10n.standingsColPlayed, headerStyle),
          _buildStatCell(l10n.standingsColWon, headerStyle),
          _buildStatCell(l10n.standingsColDrawn, headerStyle),
          _buildStatCell(l10n.standingsColLost, headerStyle),
          _buildStatCell(l10n.standingsColGoalsFor, headerStyle),
          _buildStatCell(l10n.standingsColGoalsAgainst, headerStyle),
          _buildStatCell(l10n.standingsColGoalDifference, headerStyle),
          _buildStatCell(l10n.standingsColFairPlay, headerStyle),
          _buildStatCell(
            l10n.standingsColPoints,
            KickPulseTypography.microBadge.copyWith(
              color: KickPulseColors.accentPrimary,
            ),
            width: 44,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStandingRow(
    BuildContext context,
    AppLocalizations l10n,
    StandingsRow row,
  ) {
    final tabularStyle = KickPulseTypography.statMetric(
      size: 13,
      weight: FontWeight.w600,
      color: KickPulseColors.textPrimary,
    );
    final mutedTabularStyle = KickPulseTypography.statMetric(
      size: 13,
      weight: FontWeight.w500,
      color: KickPulseColors.textSecondary,
    );
    final pointsStyle = KickPulseTypography.statMetric(
      size: 14,
      weight: FontWeight.w800,
      color: KickPulseColors.accentPrimary,
    );

    final dgFormatted = row.goalDifference > 0
        ? '+${row.goalDifference}'
        : '${row.goalDifference}';

    return InkWell(
      key: Key('standings_row_${row.teamId}'),
      onTap: widget.onTeamSelected != null
          ? () => widget.onTeamSelected!(row.teamId)
          : null,
      borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: KickPulseRadiiSpacing.spaceSm,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: row.position.isEven
              ? KickPulseColors.surfaceElevated.withValues(alpha: 0.55)
              : KickPulseColors.surfaceElevated,
          borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
          border: Border(
            left: BorderSide(
              color: row.isQualified
                  ? KickPulseColors.accentPrimary
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 35,
              child: Text(
                '${row.position}',
                style: KickPulseTypography.statMetric(
                  size: 13,
                  weight: FontWeight.w700,
                  color: row.isQualified
                      ? KickPulseColors.accentPrimary
                      : KickPulseColors.textSecondary,
                ),
              ),
            ),
            SizedBox(
              width: 150,
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
                  if (row.isTiedOnAllCriteria)
                    Text(
                      l10n.standingsTechnicalTieBadge,
                      style: KickPulseTypography.microBadge.copyWith(
                        color: KickPulseColors.accentWarning,
                      ),
                    ),
                ],
              ),
            ),
            _buildStatCell('${row.played}', tabularStyle),
            _buildStatCell('${row.won}', mutedTabularStyle),
            _buildStatCell('${row.drawn}', mutedTabularStyle),
            _buildStatCell('${row.lost}', mutedTabularStyle),
            _buildStatCell('${row.goalsFor}', mutedTabularStyle),
            _buildStatCell('${row.goalsAgainst}', mutedTabularStyle),
            _buildStatCell(dgFormatted, tabularStyle),
            _buildStatCell('${row.fairPlayPenaltyPoints}', mutedTabularStyle),
            _buildStatCell('${row.points}', pointsStyle, width: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCell(String text, TextStyle style, {double width = 34}) {
    return SizedBox(
      width: width,
      child: Text(text, textAlign: TextAlign.right, style: style),
    );
  }
}
