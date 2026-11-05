import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/directory_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_search_bar.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/teams/team_roster_detail_screen.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

/// Teams Directory screen with top persistent search bar, horizontal tournament
/// filter selector chips, roster detail navigation, and contextual create action.
class TeamsDirectoryScreen extends ConsumerStatefulWidget {
  const TeamsDirectoryScreen({super.key});

  @override
  ConsumerState<TeamsDirectoryScreen> createState() =>
      _TeamsDirectoryScreenState();
}

class _TeamsDirectoryScreenState extends ConsumerState<TeamsDirectoryScreen> {
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

  void _onTeamTapped(BuildContext context, TournamentTeam team) {
    ref.read(teamsControllerProvider.notifier).selectTeam(team.id);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TeamRosterDetailScreen()));
  }

  void _openCreateTeamDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulario de registro de equipo disponible en torneo'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final directoryState = ref.watch(teamsDirectoryControllerProvider);
    final directoryController = ref.read(
      teamsDirectoryControllerProvider.notifier,
    );
    final capabilities = ref.watch(activeRoleCapabilitiesProvider);
    final canRegisterTeams =
        capabilities.contains(RoleCapability.manageTournaments) ||
        capabilities.contains(RoleCapability.manageTeamRoster) ||
        capabilities.contains(RoleCapability.approveRegistrations);

    final visibleTeams = directoryState.filteredTeams;
    final tournaments = directoryState.availableTournaments;

    return Scaffold(
      backgroundColor: KickPulseColors.canvasBackground,
      appBar: AppBar(
        title: Text(l10n.drawerTeams),
        actions: [
          if (canRegisterTeams)
            IconButton(
              key: const Key('create_team_from_directory_button'),
              icon: const Icon(Icons.add),
              tooltip: l10n.registerTeamAction,
              onPressed: () => _openCreateTeamDialog(context),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KickPulseRadiiSpacing.spaceMd,
              KickPulseRadiiSpacing.spaceMd,
              KickPulseRadiiSpacing.spaceMd,
              KickPulseRadiiSpacing.spaceSm,
            ),
            child: KickPulseSearchBar(
              key: const Key('teams_search_bar'),
              controller: _searchController,
              hintText: l10n.searchTeamsHint,
              onChanged: directoryController.setSearchQuery,
              onClear: () {
                _searchController.clear();
                directoryController.clearSearchQuery();
              },
            ),
          ),

          // Horizontal Tournament Filter Chips
          if (tournaments.isNotEmpty)
            SingleChildScrollView(
              key: const Key('teams_tournament_selector'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: KickPulseRadiiSpacing.spaceMd,
                vertical: KickPulseRadiiSpacing.spaceXs,
              ),
              child: Row(
                children: [
                  ChoiceChip(
                    key: const Key('teams_tournament_chip_all'),
                    label: Text(l10n.filterAllTournaments),
                    selected: directoryState.selectedTournamentId == null,
                    onSelected: (_) =>
                        directoryController.selectTournamentFilter(null),
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                  ...tournaments.map((tournament) {
                    final isSelected =
                        directoryState.selectedTournamentId == tournament.id;
                    return Padding(
                      padding: const EdgeInsets.only(
                        right: KickPulseRadiiSpacing.spaceSm,
                      ),
                      child: ChoiceChip(
                        key: Key('teams_tournament_chip_${tournament.id}'),
                        label: Text(tournament.name),
                        selected: isSelected,
                        onSelected: (_) => directoryController
                            .selectTournamentFilter(tournament.id),
                      ),
                    );
                  }),
                ],
              ),
            ),

          const SizedBox(height: KickPulseRadiiSpacing.spaceXs),

          // Teams List
          Expanded(
            child: visibleTeams.isEmpty
                ? KickPulseStateView<List<TournamentTeam>>(
                    key: const Key('teams_empty_state'),
                    state: UiEmptyState<List<TournamentTeam>>(
                      message: l10n.noTeamsFound,
                    ),
                  )
                : ListView.separated(
                    key: const Key('teams_directory_list'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: KickPulseRadiiSpacing.spaceMd,
                      vertical: KickPulseRadiiSpacing.spaceSm,
                    ),
                    itemCount: visibleTeams.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    itemBuilder: (context, index) {
                      final team = visibleTeams[index];
                      return KickPulseCard(
                        key: Key('team_item_${team.id}'),
                        onTap: () => _onTeamTapped(context, team),
                        child: Row(
                          children: [
                            KickPulseTeamCrest(
                              shortCode: team.shortCode,
                              crestShape: team.crestShape,
                              primaryColorHex: team.primaryColorHex,
                              secondaryColorHex: team.secondaryColorHex,
                              size: 44.0,
                            ),
                            const SizedBox(
                              width: KickPulseRadiiSpacing.spaceSm,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          team.name,
                                          style: KickPulseTypography.bodyPrimary
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: KickPulseRadiiSpacing.spaceXs,
                                      ),
                                      Text(
                                        team.shortCode,
                                        style: KickPulseTypography.captionMeta
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  KickPulseColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    '${team.players.length} jugadores inscritos',
                                    style: KickPulseTypography.captionMeta,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: KickPulseColors.textSecondary,
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
