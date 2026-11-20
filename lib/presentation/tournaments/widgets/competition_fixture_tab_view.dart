import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/services/colombia_time_utils.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/matches/widgets/match_center_card.dart';
import 'package:vifutbol/presentation/matches/widgets/schedule_match_dialog.dart';
import 'package:vifutbol/presentation/tournaments/models/matchday_fixture_group.dart';

/// Tab view presenting the full tournament fixture organized chronologically by matchdays/rounds.
class CompetitionFixtureTabView extends ConsumerWidget {
  final String tournamentId;
  final List<ChampionshipMatch>? customMatches;
  final ChampionshipTournament? tournament;
  final Future<void> Function()? onRefresh;

  const CompetitionFixtureTabView({
    super.key,
    required this.tournamentId,
    this.customMatches,
    this.tournament,
    this.onRefresh,
  });

  void _openMatchDetailModal(
    BuildContext context,
    ChampionshipMatch match,
    TournamentTeam? homeTeam,
    TournamentTeam? awayTeam,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        final homeName = homeTeam?.name ?? match.homeTeamId;
        final awayName = awayTeam?.name ?? match.awayTeamId;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: KickPulseColors.surfaceBase,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(KickPulseRadiiSpacing.cardRadius),
              ),
            ),
            padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: KickPulseColors.borderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                Text(
                  match.roundName,
                  style: KickPulseTypography.sectionHeader.copyWith(
                    color: KickPulseColors.accentElectric,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                Text(
                  '$homeName vs $awayName',
                  style: KickPulseTypography.screenTitle.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                KickPulseCard(
                  child: Padding(
                    padding: const EdgeInsets.all(
                      KickPulseRadiiSpacing.spaceMd,
                    ),
                    child: Column(
                      children: [
                        if (match.scheduledStartTime != null) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: KickPulseColors.accentPrimary,
                              ),
                              const SizedBox(
                                width: KickPulseRadiiSpacing.spaceSm,
                              ),
                              Text(
                                ColombiaTimeUtils.formatDateTime12h(
                                  match.scheduledStartTime!,
                                  separator: ' - ',
                                ),
                                style: KickPulseTypography.bodyPrimary,
                              ),
                            ],
                          ),
                          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                        ],
                        if (match.pitchName != null &&
                            match.pitchName!.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.stadium_outlined,
                                size: 18,
                                color: KickPulseColors.accentElectric,
                              ),
                              const SizedBox(
                                width: KickPulseRadiiSpacing.spaceSm,
                              ),
                              Expanded(
                                child: Text(
                                  match.pitchName!,
                                  style: KickPulseTypography.bodyPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                        ],
                        Row(
                          children: [
                            const Icon(
                              Icons.sports_rounded,
                              size: 18,
                              color: KickPulseColors.accentWarning,
                            ),
                            const SizedBox(
                              width: KickPulseRadiiSpacing.spaceSm,
                            ),
                            Text(
                              match.refereeName ?? 'Árbitro sin asignar',
                              style: KickPulseTypography.captionMeta,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogisticsFooter({
    required ChampionshipMatch match,
    required AppLocalizations l10n,
  }) {
    final isPending = match.status == MatchStatus.pendingSchedule;

    if (isPending) {
      return Padding(
        key: Key('fixture_match_logistics_${match.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Row(
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: 14,
              color: KickPulseColors.accentElectric,
            ),
            const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
            Expanded(
              child: Text(
                l10n.fixtureMatchPendingLogistics,
                style: KickPulseTypography.captionMeta.copyWith(
                  color: KickPulseColors.accentElectric,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final dateStr = match.scheduledStartTime != null
        ? ColombiaTimeUtils.formatDateTime12h(match.scheduledStartTime!)
        : null;
    final pitchStr = match.pitchName;
    final refereeStr = match.refereeName;

    final segments = <String>[];
    if (dateStr != null) segments.add(dateStr);
    if (pitchStr != null && pitchStr.isNotEmpty) segments.add(pitchStr);
    if (refereeStr != null && refereeStr.isNotEmpty) segments.add(refereeStr);

    final summaryText = segments.isNotEmpty
        ? segments.join(' • ')
        : l10n.fixtureMatchPendingLogistics;

    return Padding(
      key: Key('fixture_match_logistics_${match.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Row(
        children: [
          const Icon(
            Icons.stadium_outlined,
            size: 14,
            color: KickPulseColors.textSecondary,
          ),
          const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
          Expanded(
            child: Text(
              summaryText,
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final teamsState = ref.watch(teamsControllerProvider);
    final teamsMap = {for (final t in teamsState.teams) t.id: t};

    final tournamentsCatalog = ref.watch(tournamentsControllerProvider);
    final activeTournament =
        tournament ??
        tournamentsCatalog.tournaments
            .where((t) => t.id == tournamentId)
            .firstOrNull;

    final userRole = ref.watch(activeUserRoleProvider);
    final isOrganizer = RolePermissionMatrix.hasCapability(
      userRole,
      RoleCapability.manageTournaments,
    );
    final isEditable =
        activeTournament != null &&
        (activeTournament.status == TournamentStatus.openRegistration ||
            activeTournament.status == TournamentStatus.inProgress);

    final List<ChampionshipMatch> matches;
    if (customMatches != null) {
      matches = customMatches!;
    } else {
      final catalogState = ref.watch(matchesCatalogControllerProvider);
      matches = catalogState.matches
          .where((m) => m.tournamentId == tournamentId)
          .toList();
    }

    Future<void> handleRefresh() async {
      if (onRefresh != null) {
        await onRefresh!();
      } else {
        await ref
            .read(matchesCatalogControllerProvider.notifier)
            .loadTournamentMatches(tournamentId);
      }
    }

    if (matches.isEmpty) {
      return RefreshIndicator(
        onRefresh: handleRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                key: const Key('fixture_empty_matches_state'),
                child: Padding(
                  padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
                  child: KickPulseStateView<void>(
                    state: UiEmptyState<void>(
                      message: l10n.fixtureEmptyMatchesTitle,
                      description: l10n.fixtureEmptyMatchesMessage,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final groups = groupMatchesByRoundNumber(matches);

    return RefreshIndicator(
      onRefresh: handleRefresh,
      child: ListView.builder(
        key: const Key('competition_detail_fixture_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: KickPulseRadiiSpacing.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Round Header
              Container(
                key: Key('fixture_round_header_${group.roundNumber}'),
                padding: const EdgeInsets.symmetric(
                  vertical: KickPulseRadiiSpacing.spaceSm,
                  horizontal: KickPulseRadiiSpacing.spaceMd,
                ),
                decoration: BoxDecoration(
                  color: KickPulseColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(
                    KickPulseRadiiSpacing.chipRadius,
                  ),
                  border: Border.all(color: KickPulseColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: KickPulseColors.accentPrimary,
                    ),
                    const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                    Expanded(
                      child: Text(
                        group.roundName,
                        style: KickPulseTypography.sectionHeader.copyWith(
                          fontSize: 16,
                          color: KickPulseColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${group.matches.length} ${group.matches.length == 1 ? 'partido' : 'partidos'}',
                      style: KickPulseTypography.captionMeta.copyWith(
                        color: KickPulseColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

              // Match Items for this Round
              ...group.matches.map((match) {
                final homeTeam = teamsMap[match.homeTeamId];
                final awayTeam = teamsMap[match.awayTeamId];

                final canSchedule =
                    isOrganizer &&
                    isEditable &&
                    (match.status == MatchStatus.pendingSchedule ||
                        match.status == MatchStatus.scheduled);

                return Padding(
                  key: Key('fixture_match_item_${match.id}'),
                  padding: const EdgeInsets.only(
                    bottom: KickPulseRadiiSpacing.spaceXs,
                  ),
                  child: MatchCenterCard(
                    match: match,
                    homeTeam: homeTeam,
                    awayTeam: awayTeam,
                    footer: _buildLogisticsFooter(match: match, l10n: l10n),
                    onTap: () async {
                      if (canSchedule) {
                        final saved = await ScheduleMatchDialog.show(
                          context: context,
                          match: match,
                          tournament: activeTournament,
                        );
                        if (saved == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.matchdayScheduleSavedSuccess),
                            ),
                          );
                        }
                      } else {
                        _openMatchDetailModal(
                          context,
                          match,
                          homeTeam,
                          awayTeam,
                          l10n,
                        );
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    ),
    );
  }
}
