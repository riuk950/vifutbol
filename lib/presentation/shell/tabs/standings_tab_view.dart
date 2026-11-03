import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/tournaments/tournament_form_screen.dart';
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
                    ),
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
