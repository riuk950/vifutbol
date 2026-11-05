import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/matches_catalog_state.dart';
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

class MatchdayTabView extends ConsumerStatefulWidget {
  const MatchdayTabView({super.key});

  @override
  ConsumerState<MatchdayTabView> createState() => _MatchdayTabViewState();
}

class _MatchdayTabViewState extends ConsumerState<MatchdayTabView> {
  String? _selectedTournamentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _initData() {
    final tournamentsState = ref.read(tournamentsControllerProvider);
    final tournamentId =
        tournamentsState.selectedTournamentId ??
        (tournamentsState.tournaments.isNotEmpty
            ? tournamentsState.tournaments.first.id
            : null);
    if (tournamentId != null) {
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

    // If tournament selected in global controller changed, react to it
    final globalTournamentId =
        tournamentsState.selectedTournamentId ??
        (tournamentsState.tournaments.isNotEmpty
            ? tournamentsState.tournaments.first.id
            : null);

    if (globalTournamentId != null &&
        globalTournamentId != _selectedTournamentId) {
      _selectedTournamentId = globalTournamentId;
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
            key: const Key('matches_tab_header'),
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.tabMatchday,
                  style: KickPulseTypography.screenTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const KickPulseBadge(
                label: 'OFICIAL',
                variant: KickPulseBadgeVariant.live,
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

          // Tournament Header & Selector
          if (tournamentsState.tournaments.length > 1) ...[
            SingleChildScrollView(
              key: const Key('matches_tournament_selector'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tournamentsState.tournaments.map((tournament) {
                  final isSelected = tournament.id == currentTournament.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      key: Key('tournament_chip_${tournament.id}'),
                      label: Text(
                        tournament.name,
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
                            .read(tournamentsControllerProvider.notifier)
                            .selectTournament(tournament.id);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          ],
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

          // Live Matches Section (if any inProgress matches)
          if (catalogState.liveMatches.isNotEmpty) ...[
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
                    itemCount: catalogState.liveMatches.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    itemBuilder: (context, index) {
                      final liveMatch = catalogState.liveMatches[index];
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

          // Unscheduled Matches Section ("Por programar (N)") - Exclusive for Organizer
          if (canManageTournaments &&
              catalogState.unscheduledMatches.isNotEmpty) ...[
            Container(
              key: const Key('unscheduled_matches_section'),
              margin: const EdgeInsets.only(
                bottom: KickPulseRadiiSpacing.spaceMd,
              ),
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
              decoration: BoxDecoration(
                color: KickPulseColors.surfaceElevated,
                borderRadius: BorderRadius.circular(
                  KickPulseRadiiSpacing.cardRadius,
                ),
                border: Border.all(color: KickPulseColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.pending_actions,
                        color: KickPulseColors.accentPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.matchdayUnscheduledSectionTitle(
                          catalogState.unscheduledMatches.length,
                        ),
                        style: KickPulseTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: catalogState.unscheduledMatches.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    itemBuilder: (context, index) {
                      final unscheduledMatch =
                          catalogState.unscheduledMatches[index];
                      return MatchCard(
                        key: Key(
                          'unscheduled_match_card_${unscheduledMatch.id}',
                        ),
                        match: unscheduledMatch,
                        homeTeam: teamsMap[unscheduledMatch.homeTeamId],
                        awayTeam: teamsMap[unscheduledMatch.awayTeamId],
                        canSchedule: true,
                        onScheduleTap: () {
                          ScheduleMatchDialog.show(
                            context: context,
                            match: unscheduledMatch,
                            tournament: currentTournament,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],

          // Calendar Date Selector Chips (Horizontal Scroll)
          if (catalogState.availableCalendarDates.isNotEmpty) ...[
            SingleChildScrollView(
              key: const Key('matchday_date_chips_list'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: catalogState.availableCalendarDates.map((date) {
                  final isSelected = catalogState.selectedDate == date;
                  final dateKeyStr = DateFormat('yyyy-MM-dd').format(date);
                  final label = _buildDateChipLabel(date, l10n);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      key: Key('date_chip_$dateKeyStr'),
                      label: Text(
                        label,
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
                            .selectDate(date);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          ],

          // Round Selector Chips (Horizontal Scroll - retained for round compatibility)
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
                      catalogState.statusFilter == MatchStatus.pendingSchedule,
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
          ] else if (catalogState.scheduledMatchesForSelectedDate.isEmpty &&
              catalogState.filteredMatches.isEmpty) ...[
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
            Builder(
              builder: (context) {
                final displayMatches =
                    catalogState.scheduledMatchesForSelectedDate.isNotEmpty
                    ? catalogState.scheduledMatchesForSelectedDate
                    : catalogState.filteredMatches;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayMatches.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                  itemBuilder: (context, index) {
                    final match = displayMatches[index];
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
                );
              },
            ),
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

  String _buildDateChipLabel(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = MatchesCatalogState.normalizeDate(now);
    final tomorrow = MatchesCatalogState.normalizeDate(
      now.add(const Duration(days: 1)),
    );

    if (date == today) {
      return l10n.matchdayDateToday;
    } else if (date == tomorrow) {
      return l10n.matchdayDateTomorrow;
    } else {
      return DateFormat('EEE d MMM', 'es').format(date);
    }
  }
}
