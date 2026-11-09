import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/matches/dialogs/generate_fixture_confirmation_dialog.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_fixture_tab_view.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_info_tab_view.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_standings_tab_view.dart';

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
  bool _isSpeedDialOpen = false;

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

  Future<void> _handleGenerateFixture(ChampionshipTournament tournament) async {
    setState(() => _isSpeedDialOpen = false);

    final confirmed = await GenerateFixtureConfirmationDialog.show(context);
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isSpeedDialOpen) ...[
          FloatingActionButton.extended(
            key: const Key('competition_detail_fab_generate_fixture'),
            heroTag: 'fab_action_generate_fixture',
            backgroundColor: KickPulseColors.surfaceElevated,
            foregroundColor: KickPulseColors.accentPrimary,
            elevation: 4,
            icon: const Icon(Icons.alt_route, size: 20),
            label: Text(
              l10n.competitionFabGenerateFixtureLabel,
              style: KickPulseTypography.captionMeta.copyWith(
                fontWeight: FontWeight.bold,
                color: KickPulseColors.accentPrimary,
              ),
            ),
            onPressed: () => _handleGenerateFixture(tournament),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
        ],
        FloatingActionButton(
          key: const Key('competition_detail_fab_menu'),
          heroTag: 'fab_main_speed_dial',
          backgroundColor: KickPulseColors.accentPrimary,
          foregroundColor: KickPulseColors.surfaceBase,
          tooltip: l10n.competitionFabMenuTooltip,
          onPressed: () {
            setState(() => _isSpeedDialOpen = !_isSpeedDialOpen);
          },
          child: Icon(_isSpeedDialOpen ? Icons.close : Icons.add, size: 24),
        ),
      ],
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
      length: 3,
      child: Scaffold(
        key: const Key('competition_detail_screen'),
        backgroundColor: KickPulseColors.canvasBackground,
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
                key: const Key('competition_detail_tab_info'),
                text: l10n.competitionDetailTabInfo,
              ),
            ],
          ),
        ),
        body: TabBarView(
          key: const Key('competition_detail_tab_bar_view'),
          children: [
            CompetitionFixtureTabView(tournamentId: widget.tournamentId),
            CompetitionStandingsTabView(tournamentId: widget.tournamentId),
            CompetitionInfoTabView(tournamentId: widget.tournamentId),
          ],
        ),
      ),
    );
  }
}
