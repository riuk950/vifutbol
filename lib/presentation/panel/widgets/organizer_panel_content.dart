import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/panel/widgets/competition_delete_dialog.dart';
import 'package:vifutbol/presentation/panel/widgets/competition_edit_dialog.dart';
import 'package:vifutbol/presentation/panel/widgets/competition_lifecycle_dialog.dart';
import 'package:vifutbol/presentation/panel/widgets/organizer_competitions_section.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_enroll_team_dialog.dart';

/// Dynamic panel content for [UserRole.organizer].
class OrganizerPanelContent extends ConsumerWidget {
  const OrganizerPanelContent({super.key});

  Widget _buildMetricCard({
    required Key key,
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: KickPulseCard(
        key: key,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: KickPulseRadiiSpacing.spaceSm,
            horizontal: KickPulseRadiiSpacing.spaceXs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: iconColor),
              const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
              Text(
                value,
                style: KickPulseTypography.screenTitle.copyWith(
                  fontSize: 20,
                  color: KickPulseColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: KickPulseTypography.captionMeta.copyWith(
                  fontSize: 10,
                  color: KickPulseColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onEditTournament(
    BuildContext context,
    ChampionshipTournament tournament,
  ) async {
    await CompetitionEditDialog.show(context: context, tournament: tournament);
  }

  Future<void> _onChangeStatus(
    BuildContext context,
    WidgetRef ref,
    ChampionshipTournament tournament,
  ) async {
    final teams = ref.read(teamsControllerProvider).teams;
    final tournamentTeams = teams
        .where((t) => t.tournamentId == tournament.id)
        .toList();
    final matches = ref.read(matchesCatalogControllerProvider).matches;
    final hasFixture = matches.any((m) => m.tournamentId == tournament.id);

    await CompetitionLifecycleDialog.show(
      context: context,
      tournament: tournament,
      enrolledTeamsCount: tournamentTeams.length,
      hasGeneratedFixture: hasFixture,
      onEnrollTeamsRequested: () async {
        await CompetitionEnrollTeamDialog.show(context, tournament: tournament);
      },
      onGenerateFixtureRequested: () {
        Navigator.of(context).pushNamed('/competitions/${tournament.id}');
      },
    );
  }

  Future<void> _onDeleteTournament(
    BuildContext context,
    WidgetRef ref,
    ChampionshipTournament tournament,
  ) async {
    final l10n = AppLocalizations.of(context);
    final matches = ref
        .read(matchesCatalogControllerProvider)
        .matches
        .where((m) => m.tournamentId == tournament.id)
        .toList();
    final hasPlayedMatches = matches.any(
      (m) =>
          m.status == MatchStatus.inProgress ||
          m.status == MatchStatus.completed,
    );

    bool canDelete = true;
    String? blockReason;

    if (tournament.status != TournamentStatus.openRegistration) {
      canDelete = false;
      blockReason = l10n.competitionDeleteBlockedInProgress;
    } else if (hasPlayedMatches) {
      canDelete = false;
      blockReason = l10n.competitionDeleteBlockedHasMatches;
    }

    await CompetitionDeleteDialog.show(
      context: context,
      tournament: tournament,
      canDelete: canDelete,
      blockReason: blockReason,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final metrics = ref.watch(organizerPanelMetricsProvider);

    final activeTournamentsCount = metrics.activeTournamentsCount;
    final pendingScheduleMatchesCount = metrics.pendingScheduleMatchesCount;
    final unseededTournamentsCount = metrics.unseededTournamentsCount;

    return SingleChildScrollView(
      key: const Key('organizer_panel_content'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Metrics Summary Section
          Text(
            l10n.organizerSummaryTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          Row(
            children: [
              _buildMetricCard(
                key: const Key('organizer_metric_active_tournaments'),
                label: l10n.organizerMetricActiveTournaments,
                value: '$activeTournamentsCount',
                icon: Icons.emoji_events_outlined,
                iconColor: KickPulseColors.accentPrimary,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
              _buildMetricCard(
                key: const Key('organizer_metric_pending_matches'),
                label: l10n.organizerMetricPendingMatches,
                value: '$pendingScheduleMatchesCount',
                icon: Icons.schedule_outlined,
                iconColor: KickPulseColors.accentWarning,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
              _buildMetricCard(
                key: const Key('organizer_metric_unseeded_tournaments'),
                label: l10n.organizerMetricUnseededTournaments,
                value: '$unseededTournamentsCount',
                icon: Icons.alt_route_outlined,
                iconColor: KickPulseColors.accentElectric,
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          // Competitions Section
          OrganizerCompetitionsSection(
            onEditTournament: (tournament) =>
                _onEditTournament(context, tournament),
            onChangeStatus: (tournament) =>
                _onChangeStatus(context, ref, tournament),
            onDeleteTournament: (tournament) =>
                _onDeleteTournament(context, ref, tournament),
          ),
        ],
      ),
    );
  }
}
