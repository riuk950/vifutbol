import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/lineups_tracking_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/lineup_enums.dart';
import 'package:vifutbol/domain/entities/match_lineup_convocation.dart';
import 'package:vifutbol/domain/entities/player_internal_tracking.dart';
import 'package:vifutbol/domain/entities/registered_player.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/team_lineups_tracking_state.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/teams/widgets/kick_pulse_team_crest.dart';

/// Screen allowing coaches to manage match convocations, internal tracking,
/// and referee synchronized official lineup view.
class CoachLineupTrackingScreen extends ConsumerStatefulWidget {
  const CoachLineupTrackingScreen({super.key});

  @override
  ConsumerState<CoachLineupTrackingScreen> createState() =>
      _CoachLineupTrackingScreenState();
}

class _CoachLineupTrackingScreenState
    extends ConsumerState<CoachLineupTrackingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  void _loadData() {
    final team = ref.read(teamsControllerProvider).selectedTeam;
    final tournamentsState = ref.read(tournamentsControllerProvider);
    final tournaments = tournamentsState.tournaments;
    if (team != null) {
      final tournament = tournaments.firstWhere(
        (t) => t.id == team.tournamentId,
        orElse: () =>
            tournamentsState.selectedTournament ??
            ChampionshipTournament(
              id: team.tournamentId,
              name: 'Campeonato',
              category: 'Libre',
              format: TournamentFormat.league,
              startDate: DateTime.now(),
              endDate: DateTime.now().add(const Duration(days: 90)),
              updatedAt: DateTime.now(),
            ),
      );
      ref
          .read(lineupsTrackingControllerProvider.notifier)
          .loadForTeam(tournamentId: tournament.id, team: team);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeRole = ref.watch(activeUserRoleProvider);
    final teamsState = ref.watch(teamsControllerProvider);
    final team = teamsState.selectedTeam;
    final tournamentsState = ref.watch(tournamentsControllerProvider);
    final lineupsState = ref.watch(lineupsTrackingControllerProvider);

    if (team == null) {
      return Scaffold(
        backgroundColor: KickPulseColors.canvasBackground,
        appBar: AppBar(
          backgroundColor: KickPulseColors.surfaceBase,
          title: Text(l10n.lineupScreenTitle),
        ),
        body: Center(
          child: Text(
            l10n.teamsEmptyTitle,
            style: const TextStyle(color: KickPulseColors.textSecondary),
          ),
        ),
      );
    }

    final tournament = tournamentsState.tournaments.firstWhere(
      (t) => t.id == team.tournamentId,
      orElse: () =>
          tournamentsState.selectedTournament ??
          ChampionshipTournament(
            id: team.tournamentId,
            name: 'Campeonato',
            category: 'Libre',
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 90)),
            format: TournamentFormat.league,
            updatedAt: DateTime.now(),
          ),
    );

    final convocation =
        lineupsState.convocationForTeam(team.id) ??
        MatchLineupConvocation(
          id: 'conv-${tournament.id}-${team.id}',
          tournamentId: tournament.id,
          teamId: team.id,
        );

    final canManageLineups =
        (RolePermissionMatrix.hasCapability(
          activeRole,
          RoleCapability.manageLineups,
        ) ||
        RolePermissionMatrix.hasCapability(
          activeRole,
          RoleCapability.manageTournaments,
        ));

    final requiredStarters = ref
        .read(manageLineupsTrackingUseCaseProvider)
        .requiredStartersForTournament(tournament);

    return Scaffold(
      backgroundColor: KickPulseColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: KickPulseColors.surfaceBase,
        title: Text(
          l10n.lineupScreenTitle,
          style: KickPulseTypography.screenTitle.copyWith(
            color: KickPulseColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: KickPulseColors.accentPrimary,
          labelColor: KickPulseColors.accentPrimary,
          unselectedLabelColor: KickPulseColors.textSecondary,
          tabs: [
            Tab(text: l10n.lineupTabConvocation),
            Tab(text: l10n.lineupTabTracking),
            Tab(text: l10n.lineupTabRefereeRoster),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Convocation Builder
          _buildConvocationTab(
            context: context,
            l10n: l10n,
            activeRole: activeRole,
            tournament: tournament,
            team: team,
            convocation: convocation,
            lineupsState: lineupsState,
            canManageLineups: canManageLineups,
            requiredStarters: requiredStarters,
          ),
          // TAB 2: Internal Tracking
          _buildTrackingTab(
            context: context,
            l10n: l10n,
            activeRole: activeRole,
            tournament: tournament,
            team: team,
            lineupsState: lineupsState,
            canManageLineups: canManageLineups,
          ),
          // TAB 3: Referee Synced Roster
          _buildRefereeRosterTab(
            context: context,
            l10n: l10n,
            team: team,
            convocation: convocation,
          ),
        ],
      ),
    );
  }

  Widget _buildConvocationTab({
    required BuildContext context,
    required AppLocalizations l10n,
    required UserRole activeRole,
    required ChampionshipTournament tournament,
    required TournamentTeam team,
    required MatchLineupConvocation convocation,
    required TeamLineupsTrackingState lineupsState,
    required bool canManageLineups,
    required int requiredStarters,
  }) {
    final startersCount = convocation.starterPlayerIds.length;
    final isConfirmed = convocation.status == ConvocationStatus.confirmed;

    return SingleChildScrollView(
      key: const Key('convocation_scroll_view'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          KickPulseCard(
            child: Row(
              children: [
                KickPulseTeamCrest(
                  shortCode: team.shortCode,
                  crestShape: team.crestShape,
                  primaryColorHex: team.primaryColorHex,
                  secondaryColorHex: team.secondaryColorHex,
                  size: 48,
                ),
                const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: KickPulseTypography.cardTitle.copyWith(
                          color: KickPulseColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                      Text(
                        convocation.matchLabel,
                        style: KickPulseTypography.captionMeta.copyWith(
                          color: KickPulseColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                KickPulseBadge(
                  label: isConfirmed
                      ? l10n.lineupStatusConfirmed
                      : l10n.lineupStatusDraft,
                  variant: isConfirmed
                      ? KickPulseBadgeVariant.dev
                      : KickPulseBadgeVariant.info,
                ),
              ],
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          // Starters progress & captain summary
          KickPulseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.lineupStartersHeader,
                        style: KickPulseTypography.sectionHeader.copyWith(
                          color: KickPulseColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                    Text(
                      '$startersCount / $requiredStarters',
                      style: KickPulseTypography.sectionHeader.copyWith(
                        color: startersCount == requiredStarters
                            ? KickPulseColors.accentPrimary
                            : KickPulseColors.accentWarning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: LinearProgressIndicator(
                    value:
                        (startersCount /
                                (requiredStarters > 0 ? requiredStarters : 1))
                            .clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: KickPulseColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      startersCount == requiredStarters
                          ? KickPulseColors.accentPrimary
                          : KickPulseColors.accentWarning,
                    ),
                  ),
                ),
                if (convocation.captainPlayerId != null) ...[
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: KickPulseColors.accentWarning,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Capitán: ${_playerName(team, convocation.captainPlayerId!)}',
                        style: KickPulseTypography.captionMeta.copyWith(
                          color: KickPulseColors.accentWarning,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          if (lineupsState.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
              decoration: BoxDecoration(
                color: KickPulseColors.accentLive.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
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
                      lineupsState.errorMessage!,
                      style: const TextStyle(
                        color: KickPulseColors.accentLive,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          ],

          // Players List
          ...team.players.map((player) {
            final tracking =
                lineupsState.trackingForPlayer(player.id) ??
                PlayerInternalTracking(
                  playerId: player.id,
                  teamId: team.id,
                  tournamentId: tournament.id,
                );
            final yellowLimit = tournament.rules.yellowCardSuspensionLimit;
            final isSuspended = tracking.isSuspended(yellowLimit);
            final isWarning = tracking.isAtYellowCardWarning(yellowLimit);
            final role = convocation.roleForPlayer(player.id);
            final isCaptain = convocation.isCaptain(player.id);

            return Padding(
              padding: const EdgeInsets.only(
                bottom: KickPulseRadiiSpacing.spaceSm,
              ),
              child: KickPulseCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Shirt number badge
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: KickPulseColors.surfaceElevated,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: KickPulseColors.borderSubtle,
                            ),
                          ),
                          child: Text(
                            '${player.shirtNumber}',
                            style: KickPulseTypography.microBadge.copyWith(
                              color: KickPulseColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      player.fullName,
                                      style: KickPulseTypography.bodyPrimary
                                          .copyWith(
                                            color: KickPulseColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCaptain) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.star,
                                      color: KickPulseColors.accentWarning,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _positionLabel(l10n, player.position),
                                style: KickPulseTypography.captionMeta.copyWith(
                                  color: KickPulseColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Disciplinary Badge
                        if (isSuspended)
                          KickPulseBadge(
                            label: l10n.lineupDisciplinarySuspended(
                              tracking.effectiveSuspensionMatches(yellowLimit),
                            ),
                            variant: KickPulseBadgeVariant.live,
                          )
                        else if (isWarning)
                          KickPulseBadge(
                            label: l10n.lineupDisciplinaryWarning(
                              tracking.yellowCards,
                            ),
                            variant: KickPulseBadgeVariant.warning,
                          ),
                      ],
                    ),
                    if (canManageLineups) ...[
                      const Divider(
                        color: KickPulseColors.borderSubtle,
                        height: 16,
                      ),
                      Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: KickPulseRadiiSpacing.spaceXs,
                        runSpacing: KickPulseRadiiSpacing.spaceXs,
                        children: [
                          if (role == PlayerConvocationRole.starter &&
                              !isCaptain)
                            TextButton.icon(
                              key: Key('captain_action_${player.shirtNumber}'),
                              onPressed: isSuspended
                                  ? null
                                  : () {
                                      ref
                                          .read(
                                            lineupsTrackingControllerProvider
                                                .notifier,
                                          )
                                          .setCaptain(
                                            activeRole: activeRole,
                                            tournament: tournament,
                                            team: team,
                                            playerId: player.id,
                                          );
                                    },
                              icon: const Icon(Icons.star_border, size: 16),
                              label: Text(l10n.lineupSetCaptainAction),
                            ),
                          ChoiceChip(
                            key: Key('role_starter_${player.shirtNumber}'),
                            label: Text(l10n.lineupRoleStarter),
                            selected: role == PlayerConvocationRole.starter,
                            selectedColor: KickPulseColors.accentPrimary
                                .withAlpha(50),
                            onSelected: isSuspended
                                ? null
                                : (selected) {
                                    ref
                                        .read(
                                          lineupsTrackingControllerProvider
                                              .notifier,
                                        )
                                        .setPlayerRole(
                                          activeRole: activeRole,
                                          tournament: tournament,
                                          team: team,
                                          playerId: player.id,
                                          isStarter: selected,
                                          isSubstitute: false,
                                        );
                                  },
                          ),
                          ChoiceChip(
                            key: Key('role_substitute_${player.shirtNumber}'),
                            label: Text(l10n.lineupRoleSubstitute),
                            selected: role == PlayerConvocationRole.substitute,
                            selectedColor: KickPulseColors.accentElectric
                                .withAlpha(50),
                            onSelected: isSuspended
                                ? null
                                : (selected) {
                                    ref
                                        .read(
                                          lineupsTrackingControllerProvider
                                              .notifier,
                                        )
                                        .setPlayerRole(
                                          activeRole: activeRole,
                                          tournament: tournament,
                                          team: team,
                                          playerId: player.id,
                                          isStarter: false,
                                          isSubstitute: selected,
                                        );
                                  },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

          if (canManageLineups)
            KickPulseButton(
              key: const Key('confirm_convocation_action_button'),
              label: isConfirmed
                  ? l10n.lineupReconfirmAction
                  : l10n.lineupConfirmAction,
              variant: KickPulseButtonVariant.primary,
              isFullWidth: true,
              isLoading: lineupsState.isSaving,
              onPressed: () async {
                try {
                  await ref
                      .read(lineupsTrackingControllerProvider.notifier)
                      .confirmConvocation(
                        activeRole: activeRole,
                        tournament: tournament,
                        team: team,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.lineupSuccessConfirmation),
                        backgroundColor: KickPulseColors.accentPrimary,
                      ),
                    );
                  }
                } catch (_) {}
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTrackingTab({
    required BuildContext context,
    required AppLocalizations l10n,
    required UserRole activeRole,
    required ChampionshipTournament tournament,
    required TournamentTeam team,
    required TeamLineupsTrackingState lineupsState,
    required bool canManageLineups,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      itemCount: team.players.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
      itemBuilder: (context, index) {
        final player = team.players[index];
        final tracking =
            lineupsState.trackingForPlayer(player.id) ??
            PlayerInternalTracking(
              playerId: player.id,
              teamId: team.id,
              tournamentId: tournament.id,
            );
        final yellowLimit = tournament.rules.yellowCardSuspensionLimit;
        final isSuspended = tracking.isSuspended(yellowLimit);
        final isWarning = tracking.isAtYellowCardWarning(yellowLimit);

        return KickPulseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${player.shirtNumber} · ${player.fullName}',
                    style: KickPulseTypography.cardTitle.copyWith(
                      color: KickPulseColors.textPrimary,
                    ),
                  ),
                  if (isSuspended)
                    KickPulseBadge(
                      label: l10n.lineupDisciplinarySuspended(
                        tracking.effectiveSuspensionMatches(yellowLimit),
                      ),
                      variant: KickPulseBadgeVariant.live,
                    )
                  else if (isWarning)
                    KickPulseBadge(
                      label: l10n.lineupDisciplinaryWarning(
                        tracking.yellowCards,
                      ),
                      variant: KickPulseBadgeVariant.warning,
                    )
                  else
                    KickPulseBadge(
                      label: l10n.lineupDisciplinaryEligible,
                      variant: KickPulseBadgeVariant.dev,
                    ),
                ],
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              Wrap(
                spacing: KickPulseRadiiSpacing.spaceMd,
                runSpacing: KickPulseRadiiSpacing.spaceXs,
                children: [
                  Text(
                    l10n.lineupTrackingMatches(tracking.matchesPlayed),
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                  ),
                  Text(
                    l10n.lineupTrackingGoals(tracking.goals),
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.accentPrimary,
                    ),
                  ),
                  Text(
                    l10n.lineupTrackingAssists(tracking.assists),
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.accentElectric,
                    ),
                  ),
                  Text(
                    l10n.lineupTrackingYellowCards(tracking.yellowCards),
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.accentWarning,
                    ),
                  ),
                  Text(
                    l10n.lineupTrackingRedCards(tracking.redCards),
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.accentLive,
                    ),
                  ),
                  if (tracking.pendingSuspensionMatches > 0)
                    Text(
                      l10n.lineupTrackingSuspensionPending(
                        tracking.pendingSuspensionMatches,
                      ),
                      style: KickPulseTypography.captionMeta.copyWith(
                        color: KickPulseColors.accentLive,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              if (canManageLineups) ...[
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: Key('edit_tracking_${player.shirtNumber}'),
                    onPressed: () => _showEditTrackingDialog(
                      context,
                      l10n,
                      activeRole,
                      tournament,
                      team,
                      player,
                      tracking,
                    ),
                    icon: const Icon(Icons.edit, size: 14),
                    label: Text(l10n.lineupTrackingEditAction),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRefereeRosterTab({
    required BuildContext context,
    required AppLocalizations l10n,
    required TournamentTeam team,
    required MatchLineupConvocation convocation,
  }) {
    if (!convocation.isSyncedWithRefereeReport) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.assignment_late_outlined,
                size: 48,
                color: KickPulseColors.textSecondary,
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              Text(
                l10n.lineupRefereeRosterTitle,
                style: KickPulseTypography.cardTitle.copyWith(
                  color: KickPulseColors.textPrimary,
                ),
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              Text(
                l10n.lineupRefereeRosterEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(color: KickPulseColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final confirmedStarters = convocation.confirmedStarterPlayerIds
        .map((id) => team.players.firstWhere((p) => p.id == id))
        .toList();

    final confirmedSubs = convocation.confirmedSubstitutePlayerIds
        .map((id) => team.players.firstWhere((p) => p.id == id))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      children: [
        KickPulseCard(
          child: Row(
            children: [
              const Icon(Icons.verified, color: KickPulseColors.accentPrimary),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Text(
                  l10n.lineupRefereeRosterTitle,
                  style: KickPulseTypography.cardTitle.copyWith(
                    color: KickPulseColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
        Text(
          l10n.lineupStartersHeader,
          style: KickPulseTypography.sectionHeader.copyWith(
            color: KickPulseColors.textPrimary,
          ),
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
        ...confirmedStarters.map((player) {
          final isCaptain = player.id == convocation.confirmedCaptainPlayerId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: KickPulseCard(
              child: Row(
                children: [
                  Text(
                    '#${player.shirtNumber}',
                    style: KickPulseTypography.cardTitle.copyWith(
                      color: KickPulseColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
                  Expanded(
                    child: Text(
                      player.fullName,
                      style: KickPulseTypography.bodyPrimary.copyWith(
                        color: KickPulseColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isCaptain)
                    KickPulseBadge(
                      label: l10n.lineupCaptainBadge,
                      variant: KickPulseBadgeVariant.warning,
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
        Text(
          l10n.lineupSubstitutesHeader,
          style: KickPulseTypography.sectionHeader.copyWith(
            color: KickPulseColors.textPrimary,
          ),
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
        ...confirmedSubs.map((player) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: KickPulseCard(
              child: Row(
                children: [
                  Text(
                    '#${player.shirtNumber}',
                    style: KickPulseTypography.cardTitle.copyWith(
                      color: KickPulseColors.accentElectric,
                    ),
                  ),
                  const SizedBox(width: KickPulseRadiiSpacing.spaceMd),
                  Expanded(
                    child: Text(
                      player.fullName,
                      style: KickPulseTypography.bodyPrimary.copyWith(
                        color: KickPulseColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showEditTrackingDialog(
    BuildContext context,
    AppLocalizations l10n,
    UserRole activeRole,
    ChampionshipTournament tournament,
    TournamentTeam team,
    RegisteredPlayer player,
    PlayerInternalTracking tracking,
  ) {
    final matchesCtrl = TextEditingController(
      text: '${tracking.matchesPlayed}',
    );
    final goalsCtrl = TextEditingController(text: '${tracking.goals}');
    final assistsCtrl = TextEditingController(text: '${tracking.assists}');
    final yellowCtrl = TextEditingController(text: '${tracking.yellowCards}');
    final redCtrl = TextEditingController(text: '${tracking.redCards}');
    final suspensionCtrl = TextEditingController(
      text: '${tracking.pendingSuspensionMatches}',
    );

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: KickPulseColors.surfaceBase,
        title: Text(
          'Métricas: ${player.fullName}',
          style: const TextStyle(color: KickPulseColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('tracking_matches_input'),
                controller: matchesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Partidos jugados',
                ),
              ),
              TextField(
                key: const Key('tracking_goals_input'),
                controller: goalsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Goles'),
              ),
              TextField(
                key: const Key('tracking_assists_input'),
                controller: assistsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Asistencias'),
              ),
              TextField(
                key: const Key('tracking_yellow_cards_input'),
                controller: yellowCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tarjetas amarillas',
                ),
              ),
              TextField(
                key: const Key('tracking_red_cards_input'),
                controller: redCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tarjetas rojas'),
              ),
              TextField(
                key: const Key('tracking_suspension_input'),
                controller: suspensionCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fechas de suspensión pendientes',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            key: const Key('save_tracking_submit_button'),
            onPressed: () async {
              final updated = tracking.copyWith(
                matchesPlayed: int.tryParse(matchesCtrl.text) ?? 0,
                goals: int.tryParse(goalsCtrl.text) ?? 0,
                assists: int.tryParse(assistsCtrl.text) ?? 0,
                yellowCards: int.tryParse(yellowCtrl.text) ?? 0,
                redCards: int.tryParse(redCtrl.text) ?? 0,
                pendingSuspensionMatches:
                    int.tryParse(suspensionCtrl.text) ?? 0,
              );

              Navigator.pop(dialogCtx);

              await ref
                  .read(lineupsTrackingControllerProvider.notifier)
                  .updatePlayerMetrics(
                    activeRole: activeRole,
                    tournament: tournament,
                    team: team,
                    updatedTracking: updated,
                  );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.lineupTrackingSaveSuccess),
                    backgroundColor: KickPulseColors.accentPrimary,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  String _playerName(TournamentTeam team, String playerId) {
    try {
      return team.players.firstWhere((p) => p.id == playerId).fullName;
    } catch (_) {
      return '';
    }
  }

  String _positionLabel(AppLocalizations l10n, PlayerPosition pos) {
    return switch (pos) {
      PlayerPosition.goalkeeper => l10n.playerPositionGoalkeeper,
      PlayerPosition.defender => l10n.playerPositionDefender,
      PlayerPosition.midfielder => l10n.playerPositionMidfielder,
      PlayerPosition.forward => l10n.playerPositionForward,
    };
  }
}
