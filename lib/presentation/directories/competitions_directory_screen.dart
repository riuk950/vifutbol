import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/directory_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_search_bar.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/tournaments/competition_detail_screen.dart';
import 'package:vifutbol/presentation/tournaments/tournament_form_screen.dart';
import 'package:vifutbol/presentation/tournaments/widgets/tournament_rules_summary_card.dart';

/// Competitions Directory screen with top persistent search bar, real-time
/// filtering, tournament selection navigation, and contextual creation action.
class CompetitionsDirectoryScreen extends ConsumerStatefulWidget {
  const CompetitionsDirectoryScreen({super.key});

  @override
  ConsumerState<CompetitionsDirectoryScreen> createState() =>
      _CompetitionsDirectoryScreenState();
}

class _CompetitionsDirectoryScreenState
    extends ConsumerState<CompetitionsDirectoryScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  KickPulseBadgeVariant _statusBadgeVariant(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.openRegistration:
        return KickPulseBadgeVariant.dev;
      case TournamentStatus.inProgress:
        return KickPulseBadgeVariant.live;
      case TournamentStatus.finished:
        return KickPulseBadgeVariant.neutral;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _onTournamentTapped(
    BuildContext context,
    ChampionshipTournament tournament,
  ) {
    ref
        .read(tournamentsControllerProvider.notifier)
        .selectTournament(tournament.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompetitionDetailScreen(tournamentId: tournament.id),
        settings: RouteSettings(name: '/competitions/${tournament.id}'),
      ),
    );
  }

  void _openCreateTournament(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TournamentFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final directoryState = ref.watch(competitionsDirectoryControllerProvider);
    final directoryController = ref.read(
      competitionsDirectoryControllerProvider.notifier,
    );
    final capabilities = ref.watch(activeRoleCapabilitiesProvider);
    final canManageTournaments = capabilities.contains(
      RoleCapability.manageTournaments,
    );

    final visibleTournaments = directoryState.filteredTournaments;

    return Scaffold(
      backgroundColor: KickPulseColors.canvasBackground,
      appBar: AppBar(
        title: Text(l10n.drawerCompetitions),
        actions: [
          if (canManageTournaments)
            IconButton(
              key: const Key('create_tournament_from_directory_button'),
              icon: const Icon(Icons.add),
              tooltip: l10n.createCompetitionAction,
              onPressed: () => _openCreateTournament(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
            child: KickPulseSearchBar(
              key: const Key('competitions_search_bar'),
              controller: _searchController,
              hintText: l10n.searchCompetitionsHint,
              onChanged: directoryController.setSearchQuery,
              onClear: () {
                _searchController.clear();
                directoryController.clearSearchQuery();
              },
            ),
          ),
          Expanded(
            child: visibleTournaments.isEmpty
                ? KickPulseStateView<List<ChampionshipTournament>>(
                    key: const Key('competitions_empty_state'),
                    state: UiEmptyState<List<ChampionshipTournament>>(
                      message: l10n.noCompetitionsFound,
                    ),
                  )
                : ListView.separated(
                    key: const Key('competitions_directory_list'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: KickPulseRadiiSpacing.spaceMd,
                      vertical: KickPulseRadiiSpacing.spaceSm,
                    ),
                    itemCount: visibleTournaments.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    itemBuilder: (context, index) {
                      final tournament = visibleTournaments[index];
                      return KickPulseCard(
                        key: Key('competition_item_${tournament.id}'),
                        onTap: () => _onTournamentTapped(context, tournament),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    tournament.name,
                                    style: KickPulseTypography.bodyPrimary
                                        .copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(
                                  width: KickPulseRadiiSpacing.spaceSm,
                                ),
                                KickPulseBadge(
                                  label: l10n.statusLabel(tournament.status),
                                  variant: _statusBadgeVariant(
                                    tournament.status,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: KickPulseRadiiSpacing.spaceXs,
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 2.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: KickPulseColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    l10n.formatLabel(tournament.format),
                                    style: KickPulseTypography.microBadge,
                                  ),
                                ),
                                const SizedBox(
                                  width: KickPulseRadiiSpacing.spaceSm,
                                ),
                                Flexible(
                                  child: Text(
                                    tournament.category,
                                    style: KickPulseTypography.captionMeta,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: KickPulseRadiiSpacing.spaceXs,
                            ),
                            Text(
                              '${_formatDate(tournament.startDate)} — ${_formatDate(tournament.endDate)}',
                              style: KickPulseTypography.captionMeta.copyWith(
                                color: KickPulseColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
