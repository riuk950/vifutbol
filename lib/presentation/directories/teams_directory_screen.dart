import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/directory_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/team_directory_item.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_search_bar.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/teams/dialogs/create_team_dialog.dart';
import 'package:vifutbol/presentation/teams/team_detail_screen.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

/// Teams Directory screen with top persistent search bar, pull-to-refresh
/// cloud synchronization, roster detail navigation, and contextual create action.
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

  void _onTeamTapped(BuildContext context, TeamDirectoryItem team) {
    final enrolledTeams = ref.read(teamsControllerProvider).teams;
    final normalizedClubName = team.name.trim().toLowerCase();
    final matchedIndex = enrolledTeams.indexWhere(
      (t) => t.id == team.id || t.normalizedName == normalizedClubName,
    );
    final targetTeamId = matchedIndex >= 0
        ? enrolledTeams[matchedIndex].id
        : team.id;

    ref.read(teamsControllerProvider.notifier).selectTeam(targetTeamId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamDetailScreen(teamId: targetTeamId),
        settings: RouteSettings(name: '/teams/$targetTeamId'),
      ),
    );
  }

  void _openCreateTeamDialog(BuildContext context) {
    CreateTeamDialog.show(context);
  }

  Future<void> _handleRefresh() async {
    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(teamsDirectoryControllerProvider.notifier)
        .refreshTeams();
    if (!success && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.teamsDirectoryOfflineRefreshWarning),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  String _resolveCategoryLabel(TeamDirectoryItem team, AppLocalizations l10n) {
    if (team.tournamentCount == 0) {
      return l10n.teamsDirectoryNoTournamentAssigned;
    }
    if (team.tournamentCount > 1) {
      return l10n.teamsDirectoryMultipleTournaments;
    }
    final label = team.categoryLabel?.trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }
    return l10n.teamsDirectoryNoTournamentAssigned;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final directoryState = ref.watch(teamsDirectoryControllerProvider);
    final directoryController = ref.read(
      teamsDirectoryControllerProvider.notifier,
    );
    final capabilities = ref.watch(activeRoleCapabilitiesProvider);
    final canRegisterTeams = capabilities.contains(
      RoleCapability.manageTeamRoster,
    );

    final visibleTeams = directoryState.filteredTeams;

    return Scaffold(
      key: const Key('teams_directory_screen'),
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

          const SizedBox(height: KickPulseRadiiSpacing.spaceXs),

          // Teams List with Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              key: const Key('teams_refresh_indicator'),
              onRefresh: _handleRefresh,
              child: _buildBodyContent(
                context: context,
                directoryState: directoryState,
                visibleTeams: visibleTeams,
                l10n: l10n,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent({
    required BuildContext context,
    required dynamic directoryState,
    required List<TeamDirectoryItem> visibleTeams,
    required AppLocalizations l10n,
  }) {
    final viewState = directoryState.viewState;

    if (viewState is UiLoadingState && visibleTeams.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (viewState is UiErrorState && visibleTeams.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: KickPulseStateView<List<TeamDirectoryItem>>(
                key: const Key('teams_error_state'),
                state: viewState as UiViewState<List<TeamDirectoryItem>>,
              ),
            ),
          ),
        ),
      );
    }

    if (visibleTeams.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: KickPulseStateView<List<TeamDirectoryItem>>(
                key: const Key('teams_empty_state'),
                state: UiEmptyState<List<TeamDirectoryItem>>(
                  message: l10n.noTeamsFound,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('teams_directory_list'),
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(
        horizontal: KickPulseRadiiSpacing.spaceMd,
        vertical: KickPulseRadiiSpacing.spaceSm,
      ),
      itemCount: visibleTeams.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
      itemBuilder: (context, index) {
        final team = visibleTeams[index];
        final categoryText = _resolveCategoryLabel(team, l10n);
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
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            team.name,
                            style: KickPulseTypography.bodyPrimary.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                        Text(
                          team.shortCode,
                          style: KickPulseTypography.captionMeta.copyWith(
                            fontWeight: FontWeight.bold,
                            color: KickPulseColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '$categoryText • ${team.playerCount} jugadores inscritos',
                      style: KickPulseTypography.captionMeta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
    );
  }
}
