import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/services/colombia_time_utils.dart';
import 'package:vifutbol/domain/services/referee_assigned_matches_service.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/matches/digital_match_report_screen.dart';

/// Dynamic panel content for [UserRole.referee] displaying multi-tournament
/// assigned matches with real team/tournament/venue names, Colombia date/time,
/// operational ordering, status filters, and pull-to-refresh.
class RefereePanelContent extends ConsumerStatefulWidget {
  const RefereePanelContent({super.key});

  @override
  ConsumerState<RefereePanelContent> createState() =>
      _RefereePanelContentState();
}

class _RefereePanelContentState extends ConsumerState<RefereePanelContent> {
  RefereeMatchFilter _selectedFilter = RefereeMatchFilter.all;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMatches(silent: true);
    });
  }

  Future<void> _refreshMatches({bool silent = false}) async {
    if (_isRefreshing || !mounted) return;
    _isRefreshing = true;
    try {
      await Future.wait([
        ref
            .read(matchesCatalogControllerProvider.notifier)
            .loadAllMatches(silent: silent),
        ref.read(tournamentsControllerProvider.notifier).loadCatalog(),
        ref.read(teamsControllerProvider.notifier).loadTeams(),
      ]);
    } catch (_) {
      // Offline-first controllers preserve cached data and expose error state.
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _onOpenDigitalReport(
    BuildContext context,
    ChampionshipMatch match,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DigitalMatchReportScreen(initialMatch: match),
      ),
    );
    if (mounted) {
      await _refreshMatches(silent: true);
    }
  }

  String _resolveTeamName(
    String teamId,
    Map<String, TournamentTeam> teamsById, {
    required String fallback,
  }) {
    final team = teamsById[teamId];
    if (team != null && team.name.trim().isNotEmpty) {
      return team.name;
    }
    return fallback;
  }

  String _statusLabel(AppLocalizations l10n, MatchStatus status) {
    return switch (status) {
      MatchStatus.scheduled => l10n.refereeMatchStatusScheduled,
      MatchStatus.inProgress => l10n.refereeMatchStatusInProgress,
      MatchStatus.completed => l10n.refereeMatchStatusCompleted,
      MatchStatus.pendingSchedule => l10n.refereeMatchStatusPending,
      MatchStatus.cancelled => l10n.refereeMatchStatusCancelled,
    };
  }

  KickPulseBadgeVariant _statusVariant(MatchStatus status) {
    return switch (status) {
      MatchStatus.inProgress => KickPulseBadgeVariant.live,
      MatchStatus.scheduled => KickPulseBadgeVariant.info,
      MatchStatus.completed => KickPulseBadgeVariant.success,
      MatchStatus.pendingSchedule => KickPulseBadgeVariant.warning,
      MatchStatus.cancelled => KickPulseBadgeVariant.neutral,
    };
  }

  Widget _buildFilterBar(AppLocalizations l10n) {
    final options = [
      (
        filter: RefereeMatchFilter.all,
        label: l10n.refereeFilterAll,
        key: const Key('referee_filter_all'),
      ),
      (
        filter: RefereeMatchFilter.inProgress,
        label: l10n.refereeFilterInProgress,
        key: const Key('referee_filter_in_progress'),
      ),
      (
        filter: RefereeMatchFilter.scheduled,
        label: l10n.refereeFilterScheduled,
        key: const Key('referee_filter_scheduled'),
      ),
      (
        filter: RefereeMatchFilter.completed,
        label: l10n.refereeFilterCompleted,
        key: const Key('referee_filter_completed'),
      ),
    ];

    return SingleChildScrollView(
      key: const Key('referee_matches_filter_bar'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isSelected = _selectedFilter == opt.filter;
          return Padding(
            padding: const EdgeInsets.only(right: KickPulseRadiiSpacing.spaceXs),
            child: ChoiceChip(
              key: opt.key,
              label: Text(opt.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = opt.filter),
              selectedColor: KickPulseColors.accentPrimary.withAlpha(45),
              labelStyle: TextStyle(
                color: isSelected
                    ? KickPulseColors.accentPrimary
                    : KickPulseColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? KickPulseColors.accentPrimary
                    : KickPulseColors.borderSubtle,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, {required bool isFiltered}) {
    return KickPulseCard(
      key: const Key('referee_empty_matches_state'),
      child: Padding(
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
              decoration: const BoxDecoration(
                color: KickPulseColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 40,
                color: KickPulseColors.textSecondary,
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            Text(
              l10n.refereeEmptyMatchesTitle,
              style: KickPulseTypography.sectionHeader.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            Text(
              isFiltered
                  ? l10n.refereeEmptyFilterMessage
                  : l10n.refereeEmptyMatchesMessage,
              style: KickPulseTypography.captionMeta,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    ChampionshipMatch match,
    AppLocalizations l10n, {
    required Map<String, TournamentTeam> teamsById,
    required Map<String, ChampionshipTournament> tournamentsById,
  }) {
    final homeName = _resolveTeamName(
      match.homeTeamId,
      teamsById,
      fallback: 'Equipo Local',
    );
    final awayName = _resolveTeamName(
      match.awayTeamId,
      teamsById,
      fallback: 'Equipo Visitante',
    );
    final tournamentName = tournamentsById[match.tournamentId]?.name;
    final headerText = tournamentName != null && tournamentName.trim().isNotEmpty
        ? '$tournamentName · ${match.roundName}'
        : match.roundName;

    final scheduleText = match.scheduledStartTime != null
        ? ColombiaTimeUtils.formatDateTime12h(match.scheduledStartTime!)
        : l10n.refereeMatchDateUnscheduled;

    final showScore = match.status == MatchStatus.inProgress ||
        match.status == MatchStatus.completed;
    final isCompleted = match.status == MatchStatus.completed;

    return Semantics(
      label: '$homeName vs $awayName, $headerText, ${_statusLabel(l10n, match.status)}',
      child: KickPulseCard(
        key: Key('referee_match_item_${match.id}'),
        child: InkWell(
          onTap: () => _onOpenDigitalReport(context, match),
          borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.cardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      headerText,
                      style: KickPulseTypography.captionMeta.copyWith(
                        color: KickPulseColors.accentPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                  KickPulseBadge(
                    label: _statusLabel(l10n, match.status),
                    variant: _statusVariant(match.status),
                  ),
                ],
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$homeName vs $awayName',
                      style: KickPulseTypography.screenTitle.copyWith(
                        fontSize: 17,
                      ),
                    ),
                  ),
                  if (showScore)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KickPulseRadiiSpacing.spaceSm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: KickPulseColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
                        style: KickPulseTypography.cardTitle.copyWith(
                          color: KickPulseColors.accentPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: KickPulseColors.textSecondary,
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                  Expanded(
                    child: Text(
                      scheduleText,
                      style: KickPulseTypography.captionMeta,
                    ),
                  ),
                ],
              ),
              if (match.pitchName != null &&
                  match.pitchName!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.stadium_outlined,
                      size: 16,
                      color: KickPulseColors.textSecondary,
                    ),
                    const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                    Expanded(
                      child: Text(
                        match.pitchName!,
                        style: KickPulseTypography.captionMeta,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              KickPulseButton(
                key: Key('referee_open_match_report_${match.id}'),
                label: isCompleted
                    ? l10n.refereeMatchActionViewClosed
                    : l10n.refereeMatchActionManage,
                icon: Icon(
                  isCompleted ? Icons.visibility_outlined : Icons.edit_note,
                  size: 20,
                ),
                variant: isCompleted
                    ? KickPulseButtonVariant.secondary
                    : KickPulseButtonVariant.primary,
                onPressed: () => _onOpenDigitalReport(context, match),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final matchesCatalogState = ref.watch(matchesCatalogControllerProvider);
    final tournamentsState = ref.watch(tournamentsControllerProvider);
    final teamsState = ref.watch(teamsControllerProvider);

    final user = authState.session?.user;
    final userId = user?.id;
    final linkedRefereeId = user?.roleProfile?.linkedRefereeId;

    final allAssigned = RefereeAssignedMatchesService.filterAndSort(
      matchesCatalogState.matches,
      userId: userId,
      linkedRefereeId: linkedRefereeId,
      filter: RefereeMatchFilter.all,
    );
    final filteredMatches = RefereeAssignedMatchesService.filterAndSort(
      matchesCatalogState.matches,
      userId: userId,
      linkedRefereeId: linkedRefereeId,
      filter: _selectedFilter,
    );

    final teamsById = {for (final t in teamsState.teams) t.id: t};
    final tournamentsById = {
      for (final t in tournamentsState.tournaments) t.id: t,
    };

    return RefreshIndicator(
      onRefresh: () => _refreshMatches(silent: false),
      child: SingleChildScrollView(
        key: const Key('referee_panel_content'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.refereeAssignedMatchesTitle,
              style: KickPulseTypography.sectionHeader,
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            _buildFilterBar(l10n),
            if (matchesCatalogState.isLoading && allAssigned.isEmpty) ...[
              const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              if (matchesCatalogState.errorMessage != null) ...[
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                Container(
                  padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                  decoration: BoxDecoration(
                    color: KickPulseColors.accentWarning.withAlpha(25),
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.cardRadius,
                    ),
                    border: Border.all(
                      color: KickPulseColors.accentWarning.withAlpha(120),
                    ),
                  ),
                  child: Text(
                    matchesCatalogState.errorMessage!,
                    style: const TextStyle(
                      color: KickPulseColors.accentWarning,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              if (filteredMatches.isEmpty)
                _buildEmptyState(
                  l10n,
                  isFiltered: allAssigned.isNotEmpty &&
                      _selectedFilter != RefereeMatchFilter.all,
                )
              else
                Column(
                  key: const Key('referee_assigned_matches_list'),
                  children: filteredMatches
                      .map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: KickPulseRadiiSpacing.spaceSm,
                          ),
                          child: _buildMatchCard(
                            context,
                            m,
                            l10n,
                            teamsById: teamsById,
                            tournamentsById: tournamentsById,
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
