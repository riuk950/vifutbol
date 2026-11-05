import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/matches/dialogs/generate_fixture_confirmation_dialog.dart';
import 'package:vifutbol/presentation/matches/widgets/match_card.dart';
import 'package:vifutbol/presentation/matches/widgets/schedule_match_dialog.dart';
import 'package:vifutbol/presentation/news/tournament_news_feed_view.dart';

class MatchdayTabView extends ConsumerStatefulWidget {
  const MatchdayTabView({super.key});

  @override
  ConsumerState<MatchdayTabView> createState() => _MatchdayTabViewState();
}

class _MatchdayTabViewState extends ConsumerState<MatchdayTabView> {
  String? _selectedTournamentId;
  int _selectedSegment = 0; // 0: matches, 1: news

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _initData() {
    final tournamentsState = ref.read(tournamentsControllerProvider);
    if (tournamentsState.tournaments.isNotEmpty) {
      final tournamentId = tournamentsState.tournaments.first.id;
      _selectedTournamentId = tournamentId;
      ref
          .read(matchesCatalogControllerProvider.notifier)
          .loadTournamentMatches(tournamentId);
      ref.read(teamsControllerProvider.notifier).loadTeams();
    }
  }

  Future<void> _onGenerateFixture(
    ChampionshipTournament tournament,
    List<TournamentTeam> teams,
  ) async {
    final confirmed = await GenerateFixtureConfirmationDialog.show(context);
    if (confirmed == true && mounted) {
      final userRole = ref.read(activeUserRoleProvider);
      final controller = ref.read(matchesCatalogControllerProvider.notifier);
      final success = await controller.generateFixture(
        tournament: tournament,
        teams: teams,
        userRole: userRole,
      );

      if (success && mounted) {
        final l10n = AppLocalizations.of(context);
        final matches = ref.read(matchesCatalogControllerProvider).matches;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.matchdayFixtureGeneratedSuccess(matches.length)),
            backgroundColor: KickPulseColors.accentPrimary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tournamentsState = ref.watch(tournamentsControllerProvider);
    final teamsState = ref.watch(teamsControllerProvider);
    final catalogState = ref.watch(matchesCatalogControllerProvider);
    final capabilities = ref.watch(activeRoleCapabilitiesProvider);
    final canManageTournaments = capabilities.contains(
      RoleCapability.manageTournaments,
    );

    // If no tournament is currently selected, pick first
    if (_selectedTournamentId == null &&
        tournamentsState.tournaments.isNotEmpty) {
      _selectedTournamentId = tournamentsState.tournaments.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(matchesCatalogControllerProvider.notifier)
              .loadTournamentMatches(_selectedTournamentId!);
          ref.read(teamsControllerProvider.notifier).loadTeams();
        }
      });
    }

    final currentTournament = tournamentsState.tournaments.firstWhere(
      (t) => t.id == _selectedTournamentId,
      orElse: () => tournamentsState.tournaments.isNotEmpty
          ? tournamentsState.tournaments.first
          : ChampionshipTournament(
              id: 'tournament-seed-liga-clausura',
              name: 'Liga Clausura ViFutbol 2026',
              category: 'Libre Masculino',
              startDate: DateTime(2026, 5, 1),
              endDate: DateTime(2026, 9, 30),
              format: TournamentFormat.league,
              status: TournamentStatus.openRegistration,
              rules: const TournamentRulesConfig(
                pointsForWin: 3,
                pointsForDraw: 1,
                pointsForLoss: 0,
                yellowCardSuspensionLimit: 3,
                minPlayersPerTeam: 7,
                maxPlayersPerTeam: 18,
                halfDurationMinutes: 45,
                leagueRounds: 1,
              ),
              updatedAt: DateTime.now(),
            ),
    );

    final tournamentTeams = teamsState.teams
        .where((t) => t.tournamentId == currentTournament.id)
        .toList();

    final teamsMap = {for (final t in tournamentTeams) t.id: t};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.tabMatchday, style: KickPulseTypography.screenTitle),
              const KickPulseBadge(
                label: 'OFICIAL',
                variant: KickPulseBadgeVariant.live,
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

          // Tournament Header & Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  currentTournament.name,
                  style: KickPulseTypography.cardTitle.copyWith(
                    color: KickPulseColors.accentPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canManageTournaments)
                ElevatedButton.icon(
                  key: const Key('generate_fixture_button'),
                  onPressed: catalogState.isSaving
                      ? null
                      : () => _onGenerateFixture(
                          currentTournament,
                          tournamentTeams,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KickPulseColors.accentPrimary,
                    foregroundColor: KickPulseColors.surfaceBase,
                    padding: const EdgeInsets.symmetric(
                      horizontal: KickPulseRadiiSpacing.spaceMd,
                      vertical: KickPulseRadiiSpacing.spaceXs,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.chipRadius,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(
                    l10n.matchdayGenerateFixtureButton,
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.surfaceBase,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          // Segmented Switch ("Partidos" | "Noticias")
          Center(
            child: SegmentedButton<int>(
              key: const Key('matchday_segmented_button'),
              segments: [
                ButtonSegment<int>(
                  value: 0,
                  label: Text(l10n.segmentedMatches),
                  icon: const Icon(Icons.sports_soccer, size: 16),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text(l10n.segmentedNews),
                  icon: const Icon(Icons.newspaper, size: 16),
                ),
              ],
              selected: {_selectedSegment},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedSegment = newSelection.first;
                });
              },
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          if (_selectedSegment == 1) ...[
            TournamentNewsFeedView(
              key: Key('tournament_news_feed_${currentTournament.id}'),
              tournamentId: currentTournament.id,
            ),
          ] else ...[
            // Live Matches Section (if any inProgress matches)
            if (catalogState.matches.any(
              (m) => m.status == MatchStatus.inProgress,
            )) ...[
              Container(
                key: const Key('live_matches_section'),
                margin: const EdgeInsets.only(
                  bottom: KickPulseRadiiSpacing.spaceLg,
                ),
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                decoration: BoxDecoration(
                  color: KickPulseColors.accentLive.withAlpha(20),
                  borderRadius: BorderRadius.circular(
                    KickPulseRadiiSpacing.cardRadius,
                  ),
                  border: Border.all(
                    color: KickPulseColors.accentLive.withAlpha(80),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: KickPulseColors.accentLive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.matchLiveSectionTitle,
                          style: KickPulseTypography.cardTitle.copyWith(
                            color: KickPulseColors.accentLive,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        KickPulseBadge(
                          label: l10n.matchLiveBadge,
                          variant: KickPulseBadgeVariant.live,
                        ),
                      ],
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: catalogState.matches
                          .where((m) => m.status == MatchStatus.inProgress)
                          .length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                      itemBuilder: (context, index) {
                        final liveMatch = catalogState.matches
                            .where((m) => m.status == MatchStatus.inProgress)
                            .toList()[index];
                        return MatchCard(
                          key: Key('live_match_card_${liveMatch.id}'),
                          match: liveMatch,
                          homeTeam: teamsMap[liveMatch.homeTeamId],
                          awayTeam: teamsMap[liveMatch.awayTeamId],
                          canSchedule: canManageTournaments,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            // Error Message Banner (if any)
            if (catalogState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                margin: const EdgeInsets.only(
                  bottom: KickPulseRadiiSpacing.spaceMd,
                ),
                decoration: BoxDecoration(
                  color: KickPulseColors.accentLive.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    KickPulseRadiiSpacing.chipRadius,
                  ),
                  border: Border.all(color: KickPulseColors.accentLive),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: KickPulseColors.accentLive,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        catalogState.errorMessage!,
                        style: KickPulseTypography.captionMeta.copyWith(
                          color: KickPulseColors.accentLive,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => ref
                          .read(matchesCatalogControllerProvider.notifier)
                          .clearErrorMessage(),
                    ),
                  ],
                ),
              ),
            ],

            // Round Selector Chips (Horizontal Scroll)
            if (catalogState.availableRounds.isNotEmpty) ...[
              SingleChildScrollView(
                key: const Key('matchday_round_chips_list'),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: catalogState.availableRounds.map((round) {
                    final isSelected = catalogState.selectedRound == round;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        key: Key('round_chip_$round'),
                        label: Text(
                          l10n.matchdayRoundChip(round),
                          style: KickPulseTypography.captionMeta.copyWith(
                            color: isSelected
                                ? KickPulseColors.surfaceBase
                                : KickPulseColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: KickPulseColors.accentPrimary,
                        backgroundColor: KickPulseColors.surfaceElevated,
                        onSelected: (_) {
                          ref
                              .read(matchesCatalogControllerProvider.notifier)
                              .selectRound(round);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            ],

            // Filter Row: Status Filters
            SingleChildScrollView(
              key: const Key('matchday_status_filter_chips'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusFilterChip(
                    label: l10n.matchdayFilterAll,
                    status: null,
                    isSelected: catalogState.statusFilter == null,
                  ),
                  const SizedBox(width: 6),
                  _buildStatusFilterChip(
                    label: l10n.matchdayFilterPending,
                    status: MatchStatus.pendingSchedule,
                    isSelected:
                        catalogState.statusFilter ==
                        MatchStatus.pendingSchedule,
                  ),
                  const SizedBox(width: 6),
                  _buildStatusFilterChip(
                    label: l10n.matchdayFilterScheduled,
                    status: MatchStatus.scheduled,
                    isSelected:
                        catalogState.statusFilter == MatchStatus.scheduled,
                  ),
                  const SizedBox(width: 6),
                  _buildStatusFilterChip(
                    label: l10n.matchdayFilterCompleted,
                    status: MatchStatus.completed,
                    isSelected:
                        catalogState.statusFilter == MatchStatus.completed,
                  ),
                ],
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

            // Matches Content List
            if (catalogState.isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (catalogState.matches.isEmpty) ...[
              KickPulseCard(
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.event_busy,
                        size: 48,
                        color: KickPulseColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.matchdayEmptyFixtureTitle,
                        style: KickPulseTypography.cardTitle,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.matchdayEmptyFixtureSubtitle,
                        textAlign: TextAlign.center,
                        style: KickPulseTypography.bodyPrimary.copyWith(
                          color: KickPulseColors.textSecondary,
                        ),
                      ),
                      if (canManageTournaments) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          key: const Key('empty_generate_fixture_button'),
                          onPressed: () => _onGenerateFixture(
                            currentTournament,
                            tournamentTeams,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KickPulseColors.accentPrimary,
                            foregroundColor: KickPulseColors.surfaceBase,
                          ),
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: Text(l10n.matchdayGenerateFixtureButton),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else if (catalogState.filteredMatches.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    l10n.matchdayNoMatchesFiltered,
                    style: KickPulseTypography.bodyPrimary.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: catalogState.filteredMatches.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                itemBuilder: (context, index) {
                  final match = catalogState.filteredMatches[index];
                  return MatchCard(
                    key: Key('match_card_${match.id}'),
                    match: match,
                    homeTeam: teamsMap[match.homeTeamId],
                    awayTeam: teamsMap[match.awayTeamId],
                    canSchedule: canManageTournaments,
                    onScheduleTap: () {
                      ScheduleMatchDialog.show(
                        context: context,
                        match: match,
                        tournament: currentTournament,
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    required MatchStatus? status,
    required bool isSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: KickPulseTypography.captionMeta.copyWith(
          color: isSelected
              ? KickPulseColors.surfaceBase
              : KickPulseColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: KickPulseColors.accentPrimary,
      backgroundColor: KickPulseColors.surfaceElevated,
      onSelected: (_) {
        ref
            .read(matchesCatalogControllerProvider.notifier)
            .setStatusFilter(status);
      },
    );
  }
}
