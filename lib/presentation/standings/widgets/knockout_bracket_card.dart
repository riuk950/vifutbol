import 'package:material_ui/material_ui.dart';
import 'package:vifutbol/domain/entities/knockout_bracket.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

/// Displays the chronological knockout bracket tree (`FR-005`) with two mobile-friendly modes:
/// 1. Round-by-round view via horizontal chips and head-to-head (`Vs`) pairing cards.
/// 2. 2D scrollable panoramic bracket tree viewer (`InteractiveViewer`).
class KnockoutBracketCard extends StatefulWidget {
  const KnockoutBracketCard({super.key, required this.bracket});

  final KnockoutBracket bracket;

  @override
  State<KnockoutBracketCard> createState() => _KnockoutBracketCardState();
}

class _KnockoutBracketCardState extends State<KnockoutBracketCard> {
  int _selectedRoundIndex = 0;
  bool _isPanoramicMode = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rounds = widget.bracket.rounds;
    if (rounds.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeRoundIdx = _selectedRoundIndex.clamp(0, rounds.length - 1);
    final activeRound = rounds[safeRoundIdx];

    return Container(
      key: const Key('knockout_bracket_card'),
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
                    Icons.account_tree_rounded,
                    color: KickPulseColors.accentPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                  Flexible(
                    child: Text(
                      l10n.knockoutBracketTitle,
                      style: KickPulseTypography.cardTitle,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ChoiceChip(
                    key: const Key('bracket_mode_rounds_chip'),
                    label: Text(l10n.knockoutViewModeByRound),
                    selected: !_isPanoramicMode,
                    onSelected: (_) {
                      setState(() {
                        _isPanoramicMode = false;
                      });
                    },
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                  ChoiceChip(
                    key: const Key('bracket_mode_panoramic_chip'),
                    label: Text(l10n.knockoutViewModePanoramic),
                    selected: _isPanoramicMode,
                    onSelected: (_) {
                      setState(() {
                        _isPanoramicMode = true;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.knockoutBracketSubtitle,
            style: KickPulseTypography.captionMeta,
          ),
          if (widget.bracket.championTeamName != null) ...<Widget>[
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            Container(
              key: const Key('knockout_champion_banner'),
              width: double.infinity,
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
              decoration: BoxDecoration(
                color: KickPulseColors.accentPrimary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(
                  KickPulseRadiiSpacing.chipRadius,
                ),
                border: Border.all(
                  color: KickPulseColors.accentPrimary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: KickPulseColors.accentPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                  Expanded(
                    child: Text(
                      l10n.knockoutChampionBannerTitle(
                        widget.bracket.championTeamName!,
                      ),
                      style: KickPulseTypography.cardTitle.copyWith(
                        color: KickPulseColors.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          if (!_isPanoramicMode) ...<Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List<Widget>.generate(rounds.length, (idx) {
                  final r = rounds[idx];
                  final isSelected = idx == safeRoundIdx;
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: KickPulseRadiiSpacing.spaceSm,
                    ),
                    child: ChoiceChip(
                      key: Key('bracket_round_chip_${r.round.name}'),
                      label: Text(r.roundTitle),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedRoundIndex = idx;
                        });
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            ...activeRound.ties.map(
              (node) => Padding(
                padding: const EdgeInsets.only(
                  bottom: KickPulseRadiiSpacing.spaceSm,
                ),
                child: _buildTiePairingCard(context, l10n, node),
              ),
            ),
          ] else
            _buildPanoramic2DBracket(context, l10n, rounds),
        ],
      ),
    );
  }

  Widget _buildTiePairingCard(
    BuildContext context,
    AppLocalizations l10n,
    KnockoutMatchTieNode node,
  ) {
    final isHomeWinner =
        node.isCompleted &&
        node.winnerTeamId != null &&
        node.winnerTeamId == node.homeTeamId;
    final isAwayWinner =
        node.isCompleted &&
        node.winnerTeamId != null &&
        node.winnerTeamId == node.awayTeamId;

    final homeDisplay = node.homeTeamShortCode != null
        ? '${node.homeTeamName} (${node.homeTeamShortCode})'
        : node.homeTeamName;
    final awayDisplay = node.awayTeamShortCode != null
        ? '${node.awayTeamName} (${node.awayTeamShortCode})'
        : node.awayTeamName;

    return Container(
      key: Key('bracket_tie_node_${node.nodeId}'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceElevated,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
        border: Border.all(
          color: node.isCompleted
              ? KickPulseColors.accentPrimary.withValues(alpha: 0.35)
              : KickPulseColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildCompetitorRow(
            teamName: homeDisplay,
            score: node.homeScore,
            isWinner: isHomeWinner,
            isTbd: node.homeTeamId == null,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, color: KickPulseColors.borderSubtle),
          ),
          _buildCompetitorRow(
            teamName: awayDisplay,
            score: node.awayScore,
            isWinner: isAwayWinner,
            isTbd: node.awayTeamId == null,
          ),
          if (node.isDecidedByPenalties ||
              node.winnerTeamName != null) ...<Widget>[
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            Wrap(
              spacing: KickPulseRadiiSpacing.spaceSm,
              runSpacing: 4,
              children: <Widget>[
                if (node.isDecidedByPenalties)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: KickPulseColors.accentWarning.withValues(
                        alpha: 0.18,
                      ),
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.badgeRadius,
                      ),
                    ),
                    child: Text(
                      l10n.knockoutPenaltyShootoutBadge(
                        node.homePenaltyScore!,
                        node.awayPenaltyScore!,
                      ),
                      style: KickPulseTypography.statMetric(
                        size: 11,
                        weight: FontWeight.w700,
                        color: KickPulseColors.accentWarning,
                      ),
                    ),
                  ),
                if (node.winnerTeamName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
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
                      l10n.knockoutWinnerAdvancesBadge(node.winnerTeamName!),
                      style: KickPulseTypography.microBadge.copyWith(
                        color: KickPulseColors.accentPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompetitorRow({
    required String teamName,
    required int? score,
    required bool isWinner,
    required bool isTbd,
  }) {
    return Row(
      children: <Widget>[
        Icon(
          isWinner ? Icons.check_circle_rounded : Icons.shield_outlined,
          size: 16,
          color: isWinner
              ? KickPulseColors.accentPrimary
              : (isTbd
                    ? KickPulseColors.textMuted
                    : KickPulseColors.textSecondary),
        ),
        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
        Expanded(
          child: Text(
            teamName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KickPulseTypography.bodyPrimary.copyWith(
              color: isWinner
                  ? KickPulseColors.accentPrimary
                  : (isTbd
                        ? KickPulseColors.textSecondary
                        : KickPulseColors.textPrimary),
              fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
        Text(
          score != null ? '$score' : '-',
          style: KickPulseTypography.statMetric(
            size: 15,
            weight: isWinner ? FontWeight.w800 : FontWeight.w600,
            color: isWinner
                ? KickPulseColors.accentPrimary
                : KickPulseColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPanoramic2DBracket(
    BuildContext context,
    AppLocalizations l10n,
    List<KnockoutBracketRound> rounds,
  ) {
    return SizedBox(
      key: const Key('knockout_panoramic_2d_viewer'),
      height: 320,
      child: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(24),
        minScale: 0.65,
        maxScale: 1.8,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List<Widget>.generate(rounds.length, (rIdx) {
            final round = rounds[rIdx];
            return Container(
              width: 220,
              margin: const EdgeInsets.only(
                right: KickPulseRadiiSpacing.spaceMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KickPulseRadiiSpacing.spaceSm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: KickPulseColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.chipRadius,
                      ),
                    ),
                    child: Text(
                      round.roundTitle,
                      style: KickPulseTypography.microBadge.copyWith(
                        color: KickPulseColors.accentPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                  ...round.ties.map(
                    (node) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: KickPulseRadiiSpacing.spaceSm,
                      ),
                      child: _buildTiePairingCard(context, l10n, node),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
