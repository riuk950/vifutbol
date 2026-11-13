import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/players_directory_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/directory_providers.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_search_bar.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/standings/widgets/player_performance_profile_card.dart';

/// Players Directory screen with top persistent search bar, horizontal tournament
/// filter selector chips, player performance profile sheet on tap, and contextual register action.
class PlayersDirectoryScreen extends ConsumerStatefulWidget {
  const PlayersDirectoryScreen({super.key});

  @override
  ConsumerState<PlayersDirectoryScreen> createState() =>
      _PlayersDirectoryScreenState();
}

class _PlayersDirectoryScreenState
    extends ConsumerState<PlayersDirectoryScreen> {
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

  void _onPlayerTapped(BuildContext context, PlayerDirectoryItem item) {
    showPlayerPerformanceProfileSheet(
      context: context,
      profile: item.toPerformanceProfile(),
    );
  }

  void _openRegisterPlayerDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Inscripción de jugador disponible en la plantilla del equipo',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _positionLabel(AppLocalizations l10n, PlayerPosition pos) {
    switch (pos) {
      case PlayerPosition.goalkeeper:
        return l10n.playerPositionGoalkeeper;
      case PlayerPosition.defender:
        return l10n.playerPositionDefender;
      case PlayerPosition.midfielder:
        return l10n.playerPositionMidfielder;
      case PlayerPosition.forward:
        return l10n.playerPositionForward;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final directoryState = ref.watch(playersDirectoryControllerProvider);
    final directoryController = ref.read(
      playersDirectoryControllerProvider.notifier,
    );
    final capabilities = ref.watch(activeRoleCapabilitiesProvider);
    final canRegisterPlayers = capabilities.contains(
      RoleCapability.manageTeamRoster,
    );

    final visiblePlayers = directoryState.filteredPlayers;

    return Scaffold(
      backgroundColor: KickPulseColors.canvasBackground,
      appBar: AppBar(
        title: Text(l10n.drawerPlayers),
        actions: [
          if (canRegisterPlayers)
            IconButton(
              key: const Key('register_player_from_directory_button'),
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: l10n.registerPlayerAction,
              onPressed: () => _openRegisterPlayerDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KickPulseRadiiSpacing.spaceMd,
              KickPulseRadiiSpacing.spaceMd,
              KickPulseRadiiSpacing.spaceMd,
              KickPulseRadiiSpacing.spaceSm,
            ),
            child: KickPulseSearchBar(
              key: const Key('players_search_bar'),
              controller: _searchController,
              hintText: l10n.searchPlayersHint,
              onChanged: (val) {
                directoryController.updateSearchQuery(val);
              },
              onClear: () {
                directoryController.clearSearchQuery();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              key: const Key('players_refresh_indicator'),
              onRefresh: () async {
                final success = await directoryController.refreshPlayers();
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.playersDirectoryOfflineRefreshWarning),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: visiblePlayers.isEmpty
                  ? CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: KickPulseStateView<List<PlayerDirectoryItem>>(
                            key: const Key('players_empty_state'),
                            state: UiEmptyState<List<PlayerDirectoryItem>>(
                              message: l10n.noPlayersFound,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      key: const Key('players_directory_list'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(
                        KickPulseRadiiSpacing.spaceMd,
                      ),
                      itemCount: visiblePlayers.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                      itemBuilder: (context, index) {
                        final item = visiblePlayers[index];
                        final p = item.player;

                        return KickPulseCard(
                          key: Key('player_item_${p.id}'),
                          onTap: () => _onPlayerTapped(context, item),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    KickPulseColors.surfaceElevated,
                                child: Text(
                                  '#${p.shirtNumber}',
                                  style: const TextStyle(
                                    color: KickPulseColors.accentElectric,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: KickPulseRadiiSpacing.spaceMd,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.fullName,
                                            style: KickPulseTypography
                                                .bodyPrimary
                                                .copyWith(
                                                  color: KickPulseColors
                                                      .textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: KickPulseRadiiSpacing.spaceXs,
                                        ),
                                        KickPulseBadge(
                                          label: _positionLabel(
                                            l10n,
                                            p.position,
                                          ),
                                          variant:
                                              KickPulseBadgeVariant.neutral,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: KickPulseRadiiSpacing.spaceXs,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.teamName} (${item.teamShortCode})',
                                            style: KickPulseTypography
                                                .captionMeta
                                                .copyWith(
                                                  color: KickPulseColors
                                                      .textSecondary,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: KickPulseRadiiSpacing.spaceXs,
                                        ),
                                        KickPulseBadge(
                                          label: p.isEligible
                                              ? 'Elegible'
                                              : 'Inactivo',
                                          variant: p.isEligible
                                              ? KickPulseBadgeVariant.live
                                              : KickPulseBadgeVariant.neutral,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                width: KickPulseRadiiSpacing.spaceXs,
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: KickPulseColors.textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
