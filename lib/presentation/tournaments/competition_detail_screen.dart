import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/standings_and_rankings_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/backup_and_season_closure_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/providers/venues_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/matches/dialogs/generate_fixture_confirmation_dialog.dart';
import 'package:vifutbol/presentation/tournaments/widgets/add_teams_to_competition_modal.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_detail_fab_menu.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_fixture_tab_view.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_info_tab_view.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_standings_tab_view.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_teams_tab_view.dart';

/// Dedicated competition detail screen (`/competitions/:id`) featuring fixed horizontal
/// tabs for Matches, Standings, and Official Rules, with an Organizer Speed Dial FAB Menu.
class CompetitionDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const CompetitionDetailScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<CompetitionDetailScreen> createState() =>
      _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState
    extends ConsumerState<CompetitionDetailScreen> {
  bool _isHydrating = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_hydrateCompetitionData);
  }

  Future<void> _hydrateCompetitionData() async {
    if (_isHydrating || !mounted) return;
    _isHydrating = true;
    try {
      await Future.wait([
        ref.read(tournamentsControllerProvider.notifier).loadCatalog(),
        ref.read(teamsControllerProvider.notifier).loadTeams(),
        ref
            .read(matchesCatalogControllerProvider.notifier)
            .loadTournamentMatches(widget.tournamentId),
        ref.read(venuesControllerProvider.notifier).loadCatalog(),
      ]);
      if (!mounted) return;
      await ref
          .read(
            standingsAndRankingsControllerProvider(
              widget.tournamentId,
            ).notifier,
          )
          .loadCompetitiveSnapshot();
      ref.invalidate(tournamentHonorRollProvider(widget.tournamentId));
    } finally {
      _isHydrating = false;
    }
  }

  (String, KickPulseBadgeVariant) _statusBadgeInfo(
    TournamentStatus status,
    AppLocalizations l10n,
  ) {
    switch (status) {
      case TournamentStatus.openRegistration:
        return (
          l10n.tournamentStatusOpenRegistration,
          KickPulseBadgeVariant.dev,
        );
      case TournamentStatus.inProgress:
        return (l10n.tournamentStatusInProgress, KickPulseBadgeVariant.live);
      case TournamentStatus.finished:
        return (l10n.tournamentStatusFinished, KickPulseBadgeVariant.neutral);
    }
  }

  Future<void> _handleGenerateFixture(
    ChampionshipTournament tournament, {
    bool isRegeneration = false,
  }) async {
    if (ref.read(matchesCatalogControllerProvider).isSaving) return;

    final confirmed = await GenerateFixtureConfirmationDialog.show(
      context,
      isRegeneration: isRegeneration,
    );
    if (confirmed != true || !mounted) return;

    final userRole = ref.read(activeUserRoleProvider);
    final teams = ref.read(teamsControllerProvider).teams;
    final controller = ref.read(matchesCatalogControllerProvider.notifier);

    final success = await controller.generateFixture(
      tournament: tournament,
      teams: teams,
      userRole: userRole,
    );

    if (!mounted) return;

    if (success) {
      final l10n = AppLocalizations.of(context);
      final matches = ref
          .read(matchesCatalogControllerProvider)
          .matches
          .where((m) => m.tournamentId == tournament.id)
          .toList();
      ref.read(dailyMatchesFeedControllerProvider.notifier).refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.matchdayFixtureGeneratedSuccess(matches.length)),
          backgroundColor: KickPulseColors.accentPrimary,
        ),
      );
    } else {
      final catalogState = ref.read(matchesCatalogControllerProvider);
      if (catalogState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(catalogState.errorMessage!),
            backgroundColor: KickPulseColors.accentWarning,
          ),
        );
      }
    }
  }

  Widget? _buildFloatingActionButton(
    BuildContext context,
    ChampionshipTournament? tournament,
    AppLocalizations l10n,
  ) {
    final userRole = ref.watch(activeUserRoleProvider);
    final canManage = RolePermissionMatrix.hasCapability(
      userRole,
      RoleCapability.manageTournaments,
    );

    if (!canManage || tournament == null || !tournament.status.isEditable) {
      return null;
    }

    final matchesState = ref.watch(matchesCatalogControllerProvider);
    final tournamentMatches = matchesState.matches
        .where((m) => m.tournamentId == tournament.id)
        .toList();
    final hasStartedOrFinishedMatches = tournamentMatches.any(
      (m) =>
          m.status == MatchStatus.inProgress ||
          m.status == MatchStatus.completed,
    );

    return CompetitionDetailFabMenu(
      showGenerateFixture: !hasStartedOrFinishedMatches && !matchesState.isSaving,
      onGenerateFixture: () => _handleGenerateFixture(
        tournament,
        isRegeneration: tournamentMatches.isNotEmpty,
      ),
      onAddTeams: () =>
          AddTeamsToCompetitionModal.show(context, tournament: tournament),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tournamentsState = ref.watch(tournamentsControllerProvider);
    final tournament = tournamentsState.tournaments
        .where((t) => t.id == widget.tournamentId)
        .firstOrNull;

    final (statusLabel, statusVariant) = tournament != null
        ? _statusBadgeInfo(tournament.status, l10n)
        : ('', KickPulseBadgeVariant.neutral);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        key: const Key('competition_detail_screen'),
        floatingActionButton: _buildFloatingActionButton(
          context,
          tournament,
          l10n,
        ),
        appBar: AppBar(
          backgroundColor: KickPulseColors.surfaceBase,
          elevation: 0,
          leading: IconButton(
            key: const Key('competition_detail_back_button'),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: KickPulseColors.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tournament?.name ?? 'Competición',
                key: const Key('competition_detail_title'),
                style: KickPulseTypography.screenTitle.copyWith(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
              if (tournament != null)
                Text(
                  tournament.category,
                  key: const Key('competition_detail_category'),
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.textSecondary,
                  ),
                ),
            ],
          ),
          actions: [
            if (tournament != null)
              Padding(
                padding: const EdgeInsets.only(
                  right: KickPulseRadiiSpacing.spaceMd,
                ),
                child: Center(
                  child: KickPulseBadge(
                    key: const Key('competition_detail_status_badge'),
                    label: statusLabel,
                    variant: statusVariant,
                  ),
                ),
              ),
          ],
          bottom: TabBar(
            key: const Key('competition_detail_tab_bar'),
            isScrollable: true,
            indicatorColor: KickPulseColors.accentPrimary,
            indicatorWeight: 3,
            labelColor: KickPulseColors.accentPrimary,
            unselectedLabelColor: KickPulseColors.textSecondary,
            labelStyle: KickPulseTypography.bodyPrimary.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                key: const Key('competition_detail_tab_matches'),
                text: l10n.competitionDetailTabMatches,
              ),
              Tab(
                key: const Key('competition_detail_tab_standings'),
                text: l10n.competitionDetailTabStandings,
              ),
              Tab(
                key: const Key('competition_detail_tab_teams'),
                text: l10n.competitionDetailTabTeams,
              ),
              Tab(
                key: const Key('competition_detail_tab_info'),
                text: l10n.competitionDetailTabInfo,
              ),
            ],
          ),
        ),
        body: TabBarView(
          key: const Key('competition_detail_tab_bar_view'),
          children: [
            CompetitionFixtureTabView(
              tournamentId: widget.tournamentId,
              onRefresh: _hydrateCompetitionData,
            ),
            CompetitionStandingsTabView(
              tournamentId: widget.tournamentId,
              onRefresh: _hydrateCompetitionData,
            ),
            CompetitionTeamsTabView(
              tournamentId: widget.tournamentId,
              onRefresh: _hydrateCompetitionData,
            ),
            CompetitionInfoTabView(
              tournamentId: widget.tournamentId,
              onRefresh: _hydrateCompetitionData,
            ),
          ],
        ),
      ),
    );
  }
}
