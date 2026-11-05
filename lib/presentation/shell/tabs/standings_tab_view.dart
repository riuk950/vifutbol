import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/standings_and_rankings_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/backup_and_season_closure_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/player_performance_profile.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/standings/widgets/knockout_bracket_card.dart';
import 'package:vifutbol/presentation/standings/widgets/player_performance_profile_card.dart';
import 'package:vifutbol/presentation/standings/widgets/season_honor_roll_card.dart';
import 'package:vifutbol/presentation/standings/widgets/standings_table_card.dart';
import 'package:vifutbol/presentation/standings/widgets/team_detailed_stats_card.dart';
import 'package:vifutbol/presentation/standings/widgets/tournament_rankings_card.dart';
import 'package:vifutbol/presentation/teams/widgets/tournament_teams_section.dart';
import 'package:vifutbol/presentation/tournaments/tournament_form_screen.dart';
import 'package:vifutbol/presentation/tournaments/widgets/season_closure_confirmation_dialog.dart';
import 'package:vifutbol/presentation/tournaments/widgets/tournament_backup_sheet.dart';
import 'package:vifutbol/presentation/tournaments/widgets/tournament_rules_summary_card.dart';

/// Standings & Championship Tournaments Center (`Posiciones`) displaying
/// registered championships, format filters, official custom rules, and
/// organizer-only creation/editing/lifecycle controls.
class StandingsTabView extends ConsumerWidget {
  const StandingsTabView({super.key});

  Future<void> _openTournamentForm(
    BuildContext context, {
    ChampionshipTournament? initialTournament,
  }) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            TournamentFormScreen(initialTournament: initialTournament),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalogState = ref.watch(tournamentsControllerProvider);
    final controller = ref.read(tournamentsControllerProvider.notifier);
    final activeRole = ref.watch(activeUserRoleProvider);
    final capabilities = ref.watch(activeRoleCapabilitiesProvider);
    final canManageTournaments = capabilities.contains(
      RoleCapability.manageTournaments,
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KickPulseRadiiSpacing.spaceMd,
              KickPulseRadiiSpacing.spaceMd,
              KickPulseRadiiSpacing.spaceMd,
              KickPulseRadiiSpacing.spaceSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.tournamentsTitle,
                            style: KickPulseTypography.screenTitle,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.tournamentsSubtitle,
                            style: KickPulseTypography.captionMeta,
                          ),
                        ],
                      ),
                    ),
                    if (canManageTournaments)
                      ElevatedButton.icon(
                        key: const Key('create_tournament_button'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KickPulseColors.accentPrimary,
                          foregroundColor: KickPulseColors.canvasBackground,
                        ),
                        onPressed: () => _openTournamentForm(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.tournamentsCreateAction),
                      ),
                  ],
                ),
                if (canManageTournaments && catalogState.hasSavedDraft) ...[
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                  Container(
                    key: const Key('standings_saved_draft_banner'),
                    padding: const EdgeInsets.all(
                      KickPulseRadiiSpacing.spaceSm,
                    ),
                    decoration: BoxDecoration(
                      color: KickPulseColors.accentElectric.withValues(
                        alpha: 0.14,
                      ),
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.chipRadius,
                      ),
                      border: Border.all(color: KickPulseColors.accentElectric),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          color: KickPulseColors.accentElectric,
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                        Expanded(
                          child: Text(
                            l10n.tournamentsDraftBannerTitle,
                            style: KickPulseTypography.bodyPrimary,
                          ),
                        ),
                        TextButton(
                          key: const Key('resume_draft_button'),
                          onPressed: () => _openTournamentForm(context),
                          child: Text(l10n.tournamentsDraftBannerContinue),
                        ),
                        IconButton(
                          key: const Key('discard_saved_draft_icon_button'),
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: controller.clearDraft,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        key: const Key('filter_format_all'),
                        label: Text(l10n.tournamentsFilterAll),
                        selected: catalogState.selectedFormatFilter == null,
                        onSelected: (_) => controller.setFormatFilter(null),
                      ),
                      const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                      ...TournamentFormat.values.map(
                        (format) => Padding(
                          padding: const EdgeInsets.only(
                            right: KickPulseRadiiSpacing.spaceXs,
                          ),
                          child: FilterChip(
                            key: Key('filter_format_${format.name}'),
                            label: Text(l10n.formatLabel(format)),
                            selected:
                                catalogState.selectedFormatFilter == format,
                            onSelected: (_) =>
                                controller.setFormatFilter(format),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KickPulseRadiiSpacing.spaceMd,
              vertical: KickPulseRadiiSpacing.spaceSm,
            ),
            child: KickPulseStateView<List<ChampionshipTournament>>(
              state: catalogState.viewState,
              onRetry: controller.loadCatalog,
              contentBuilder: (context, _) {
                final visible = catalogState.filteredTournaments;
                final selected = catalogState.selectedTournament;
                if (visible.isEmpty || selected == null) {
                  return Center(
                    child: Text(
                      l10n.venuesEmptyFilterSubtitle,
                      style: KickPulseTypography.bodyPrimary,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: visible.map((tournament) {
                          final isSelected = tournament.id == selected.id;
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: KickPulseRadiiSpacing.spaceSm,
                            ),
                            child: ChoiceChip(
                              key: Key('select_tournament_${tournament.id}'),
                              label: Text(tournament.name),
                              selected: isSelected,
                              onSelected: (_) =>
                                  controller.selectTournament(tournament.id),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                    TournamentRulesSummaryCard(
                      tournament: selected,
                      isOrganizer: canManageTournaments,
                      onEditPressed: () => _openTournamentForm(
                        context,
                        initialTournament: selected,
                      ),
                      onTransitionStatusPressed: (targetStatus) {
                        controller.transitionTournamentStatus(
                          tournament: selected,
                          targetStatus: targetStatus,
                          actorRole: activeRole,
                        );
                      },
                      onBackupPressed: () => TournamentBackupSheet.show(
                        context: context,
                        tournament: selected,
                      ),
                      onCloseSeasonPressed: () =>
                          SeasonClosureConfirmationDialog.show(
                            context,
                            tournament: selected,
                            actorRole: activeRole,
                            onSeasonClosed: () {
                              controller.loadCatalog();
                              ref.invalidate(
                                tournamentHonorRollProvider(selected.id),
                              );
                            },
                          ),
                    ),
                    if (selected.status == TournamentStatus.finished) ...[
                      const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
                      Consumer(
                        builder: (context, ref, _) {
                          final honorRollAsync = ref.watch(
                            tournamentHonorRollProvider(selected.id),
                          );
                          return honorRollAsync.when(
                            data: (honorRoll) => honorRoll != null
                                ? SeasonHonorRollCard(honorRoll: honorRoll)
                                : const SizedBox.shrink(),
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(
                                  KickPulseRadiiSpacing.spaceMd,
                                ),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (_, _) => const SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
                    TournamentTeamsSection(
                      tournament: selected,
                      actorRole: activeRole,
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
                    _TournamentCompetitiveSection(tournament: selected),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TournamentCompetitiveSection extends ConsumerWidget {
  const _TournamentCompetitiveSection({required this.tournament});

  final ChampionshipTournament tournament;

  void _openTeamDetails(
    BuildContext context,
    String teamId,
    StandingsAndRankingsState compState,
  ) {
    final teamStats = compState.snapshot?.teamDetailedStatsById[teamId];
    if (teamStats == null) return;

    showTeamDetailedStatsSheet(
      context: context,
      teamStats: teamStats,
      onPlayerSelected: (playerId) =>
          _openPlayerProfile(context, playerId, compState),
    );
  }

  void _openPlayerProfile(
    BuildContext context,
    String playerId,
    StandingsAndRankingsState compState,
  ) {
    final profile = compState.snapshot?.playerProfilesById[playerId];
    if (profile == null) return;

    final allPlayers =
        compState.snapshot?.playerProfilesById.values.toList() ??
        <PlayerPerformanceProfile>[];

    showPlayerPerformanceProfileSheet(
      context: context,
      profile: profile,
      allTournamentPlayers: allPlayers,
      onPlayerSelected: (selectedId) {
        Navigator.of(context).pop();
        _openPlayerProfile(context, selectedId, compState);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final compState = ref.watch(
      standingsAndRankingsControllerProvider(tournament.id),
    );
    final compController = ref.read(
      standingsAndRankingsControllerProvider(tournament.id).notifier,
    );
    final snapshot = compState.snapshot;

    final myProfile =
        snapshot?.cachedMyPlayerProfile ??
        snapshot?.playerProfilesById.values.firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: KickPulseRadiiSpacing.spaceSm,
          runSpacing: KickPulseRadiiSpacing.spaceXs,
          children: <Widget>[
            Wrap(
              spacing: KickPulseRadiiSpacing.spaceSm,
              runSpacing: KickPulseRadiiSpacing.spaceXs,
              children: <Widget>[
                if (tournament.format.hasStandingsTable)
                  ChoiceChip(
                    key: const Key('competitive_view_selector_standings'),
                    label: Text(l10n.competitiveViewStandings),
                    selected:
                        compState.activeViewMode ==
                        CompetitiveViewMode.standings,
                    onSelected: (_) => compController.selectViewMode(
                      CompetitiveViewMode.standings,
                    ),
                  ),
                if (tournament.format.hasKnockoutBracket)
                  ChoiceChip(
                    key: const Key('competitive_view_selector_brackets'),
                    label: Text(l10n.competitiveViewBrackets),
                    selected:
                        compState.activeViewMode ==
                        CompetitiveViewMode.brackets,
                    onSelected: (_) => compController.selectViewMode(
                      CompetitiveViewMode.brackets,
                    ),
                  ),
                ChoiceChip(
                  key: const Key('competitive_view_selector_rankings'),
                  label: Text(l10n.competitiveViewRankings),
                  selected:
                      compState.activeViewMode == CompetitiveViewMode.rankings,
                  onSelected: (_) => compController.selectViewMode(
                    CompetitiveViewMode.rankings,
                  ),
                ),
              ],
            ),
            if (myProfile != null)
              OutlinedButton.icon(
                key: const Key('open_my_player_profile_button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KickPulseColors.accentPrimary,
                  side: const BorderSide(color: KickPulseColors.accentPrimary),
                ),
                onPressed: () =>
                    _openPlayerProfile(context, myProfile.playerId, compState),
                icon: const Icon(Icons.person_pin_rounded, size: 18),
                label: Text(l10n.playerProfileMyProfileButton),
              ),
          ],
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
        if (snapshot == null)
          const SizedBox.shrink()
        else if (compState.activeViewMode == CompetitiveViewMode.standings &&
            tournament.format.hasStandingsTable)
          StandingsTableCard(
            mainTable: snapshot.mainStandingsTable,
            groupTables: snapshot.groupStandingsTables,
            onTeamSelected: (teamId) =>
                _openTeamDetails(context, teamId, compState),
          )
        else if (compState.activeViewMode == CompetitiveViewMode.brackets &&
            snapshot.knockoutBracket != null)
          KnockoutBracketCard(bracket: snapshot.knockoutBracket!)
        else
          TournamentRankingsCard(
            rankings: snapshot.rankings,
            onPlayerSelected: (playerId) =>
                _openPlayerProfile(context, playerId, compState),
            onTeamSelected: (teamId) =>
                _openTeamDetails(context, teamId, compState),
          ),
      ],
    );
  }
}
