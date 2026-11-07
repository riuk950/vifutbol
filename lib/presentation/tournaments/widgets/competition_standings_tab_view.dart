import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/standings_and_rankings_controller.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/standings_table.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/standings/widgets/knockout_bracket_card.dart';
import 'package:vifutbol/presentation/standings/widgets/standings_table_card.dart';
import 'package:vifutbol/presentation/standings/widgets/tournament_rankings_card.dart';

/// Tab view presenting tournament standings table, knockout bracket, and rankings.
class CompetitionStandingsTabView extends ConsumerWidget {
  final String tournamentId;

  const CompetitionStandingsTabView({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tournamentsCatalog = ref.watch(tournamentsControllerProvider);
    final tournament = tournamentsCatalog.tournaments
        .where((t) => t.id == tournamentId)
        .firstOrNull;
    final format = tournament?.format ?? TournamentFormat.league;

    final state = ref.watch(
      standingsAndRankingsControllerProvider(tournamentId),
    );
    final controller = ref.read(
      standingsAndRankingsControllerProvider(tournamentId).notifier,
    );

    // Resolve effective view mode ensuring format compatibility
    CompetitiveViewMode effectiveViewMode = state.activeViewMode;
    if (!format.hasStandingsTable &&
        effectiveViewMode == CompetitiveViewMode.standings) {
      effectiveViewMode = CompetitiveViewMode.brackets;
    } else if (!format.hasKnockoutBracket &&
        effectiveViewMode == CompetitiveViewMode.brackets) {
      effectiveViewMode = CompetitiveViewMode.standings;
    }

    Widget content;
    if (state.isLoading) {
      content = const Center(
        key: Key('competition_detail_standings_loading'),
        child: Padding(
          padding: EdgeInsets.all(KickPulseRadiiSpacing.spaceXl),
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      switch (effectiveViewMode) {
        case CompetitiveViewMode.standings:
          final mainTable = state.snapshot?.mainStandingsTable;
          final groupTables = state.snapshot?.groupStandingsTables ?? [];
          final hasStandingsData =
              (mainTable != null && mainTable.rows.isNotEmpty) ||
              groupTables.any((g) => g.rows.isNotEmpty);

          if (!hasStandingsData) {
            content = Center(
              child: Padding(
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
                child: KickPulseStateView<void>(
                  key: const Key('competition_detail_standings_empty_state'),
                  state: UiEmptyState<void>(
                    message: l10n.competitionStandingsEmptyTitle,
                    description: l10n.competitionStandingsEmptyDescription,
                  ),
                ),
              ),
            );
          } else {
            final effectiveMainTable =
                mainTable ??
                (groupTables.isNotEmpty
                    ? groupTables.first
                    : StandingsTable(
                        tournamentId: tournamentId,
                        rows: const [],
                        appliedTiebreakers: const [],
                        completedMatchesCount: 0,
                      ));
            content = StandingsTableCard(
              key: const Key('competition_standings_table_card'),
              mainTable: effectiveMainTable,
              groupTables: groupTables,
              onTeamSelected: null,
            );
          }
          break;

        case CompetitiveViewMode.brackets:
          final bracket = state.snapshot?.knockoutBracket;
          final hasBracketData = bracket != null && bracket.rounds.isNotEmpty;

          if (!hasBracketData) {
            content = Center(
              child: Padding(
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
                child: KickPulseStateView<void>(
                  key: const Key('competition_detail_brackets_empty_state'),
                  state: UiEmptyState<void>(
                    message: l10n.competitionBracketsEmptyTitle,
                    description: l10n.competitionBracketsEmptyDescription,
                  ),
                ),
              ),
            );
          } else {
            content = KnockoutBracketCard(
              key: const Key('competition_knockout_bracket_card'),
              bracket: bracket,
            );
          }
          break;

        case CompetitiveViewMode.rankings:
          final rankings = state.snapshot?.rankings;
          final hasRankingsData =
              rankings != null &&
              (rankings.topScorers.isNotEmpty ||
                  rankings.topAssists.isNotEmpty ||
                  rankings.teamFairPlay.isNotEmpty);

          if (!hasRankingsData) {
            content = Center(
              child: Padding(
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
                child: KickPulseStateView<void>(
                  key: const Key('competition_detail_rankings_empty_state'),
                  state: UiEmptyState<void>(
                    message: l10n.competitionRankingsEmptyTitle,
                    description: l10n.competitionRankingsEmptyDescription,
                  ),
                ),
              ),
            );
          } else {
            content = TournamentRankingsCard(
              key: const Key('competition_tournament_rankings_card'),
              rankings: rankings,
              onPlayerSelected: null,
              onTeamSelected: null,
            );
          }
          break;
      }
    }

    return Column(
      key: const Key('competition_detail_standings_content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KickPulseRadiiSpacing.spaceMd,
            KickPulseRadiiSpacing.spaceSm,
            KickPulseRadiiSpacing.spaceMd,
            KickPulseRadiiSpacing.spaceXs,
          ),
          child: Wrap(
            key: const Key('competition_standings_subview_selector'),
            spacing: KickPulseRadiiSpacing.spaceSm,
            runSpacing: KickPulseRadiiSpacing.spaceXs,
            children: [
              if (format.hasStandingsTable)
                ChoiceChip(
                  key: const Key('subview_chip_standings'),
                  label: Text(l10n.competitiveViewStandings),
                  selected: effectiveViewMode == CompetitiveViewMode.standings,
                  onSelected: (_) =>
                      controller.selectViewMode(CompetitiveViewMode.standings),
                ),
              if (format.hasKnockoutBracket)
                ChoiceChip(
                  key: const Key('subview_chip_brackets'),
                  label: Text(l10n.competitiveViewBrackets),
                  selected: effectiveViewMode == CompetitiveViewMode.brackets,
                  onSelected: (_) =>
                      controller.selectViewMode(CompetitiveViewMode.brackets),
                ),
              ChoiceChip(
                key: const Key('subview_chip_rankings'),
                label: Text(l10n.competitiveViewRankings),
                selected: effectiveViewMode == CompetitiveViewMode.rankings,
                onSelected: (_) =>
                    controller.selectViewMode(CompetitiveViewMode.rankings),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              KickPulseRadiiSpacing.spaceMd,
              KickPulseRadiiSpacing.spaceXs,
              KickPulseRadiiSpacing.spaceMd,
              KickPulseRadiiSpacing.spaceMd,
            ),
            child: content,
          ),
        ),
      ],
    );
  }
}
