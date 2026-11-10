import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournament_news_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/match_enums.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/matches/dialogs/generate_fixture_confirmation_dialog.dart';
import 'package:vifutbol/presentation/matches/widgets/schedule_match_dialog.dart';
import 'package:vifutbol/presentation/news/widgets/create_news_dialog.dart';
import 'package:vifutbol/presentation/panel/widgets/competition_delete_dialog.dart';
import 'package:vifutbol/presentation/panel/widgets/competition_edit_dialog.dart';
import 'package:vifutbol/presentation/panel/widgets/competition_lifecycle_dialog.dart';
import 'package:vifutbol/presentation/panel/widgets/organizer_competitions_section.dart';
import 'package:vifutbol/presentation/panel/widgets/select_tournament_for_fixture_sheet.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_enroll_team_dialog.dart';
import 'package:vifutbol/presentation/tournaments/widgets/tournament_backup_sheet.dart';

/// Dynamic panel content for [UserRole.organizer].
class OrganizerPanelContent extends ConsumerStatefulWidget {
  const OrganizerPanelContent({super.key});

  @override
  ConsumerState<OrganizerPanelContent> createState() =>
      _OrganizerPanelContentState();
}

class _OrganizerPanelContentState extends ConsumerState<OrganizerPanelContent> {
  bool _isGeneratingFixture = false;

  Future<void> _onGenerateFixture(
    BuildContext context,
    List<ChampionshipTournament> tournaments,
    AppLocalizations l10n,
  ) async {
    if (_isGeneratingFixture) return;

    final editableTournaments = tournaments
        .where(
          (t) =>
              t.status == TournamentStatus.openRegistration ||
              t.status == TournamentStatus.inProgress,
        )
        .toList();

    if (editableTournaments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.organizerNoEditableTournamentsForFixture),
          backgroundColor: KickPulseColors.surfaceElevated,
        ),
      );
      return;
    }

    final selectedTournament = await SelectTournamentForFixtureSheet.show(
      context: context,
      tournaments: editableTournaments,
    );

    if (selectedTournament == null || !context.mounted) return;

    final confirmed = await GenerateFixtureConfirmationDialog.show(context);
    if (confirmed != true || !context.mounted) return;

    setState(() => _isGeneratingFixture = true);

    try {
      final teams = ref.read(teamsControllerProvider).teams;
      final userRole = ref.read(activeUserRoleProvider);
      final success = await ref
          .read(matchesCatalogControllerProvider.notifier)
          .generateFixture(
            tournament: selectedTournament,
            teams: teams,
            userRole: userRole,
          );

      if (success && context.mounted) {
        final matches = ref
            .read(matchesCatalogControllerProvider)
            .matches
            .where((m) => m.tournamentId == selectedTournament.id)
            .toList();
        ref.read(dailyMatchesFeedControllerProvider.notifier).refresh();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.matchdayFixtureGeneratedSuccess(matches.length)),
            backgroundColor: KickPulseColors.accentPrimary,
          ),
        );

        Navigator.of(
          context,
        ).pushNamed('/competitions/${selectedTournament.id}');
      } else if (!success && context.mounted) {
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
    } finally {
      if (mounted) {
        setState(() => _isGeneratingFixture = false);
      }
    }
  }

  void _onScheduleMatches(
    BuildContext context,
    List<ChampionshipTournament> tournaments,
    List<ChampionshipMatch> matches,
    AppLocalizations l10n,
  ) {
    final pendingMatches = matches
        .where((m) => m.scheduledStartTime == null)
        .toList();

    if (pendingMatches.isNotEmpty) {
      final match = pendingMatches.first;
      final tournament = tournaments.cast<ChampionshipTournament?>().firstWhere(
        (t) => t?.id == match.tournamentId,
        orElse: () => null,
      );

      if (tournament != null) {
        ScheduleMatchDialog.show(
          context: context,
          match: match,
          tournament: tournament,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.organizerPendingMatchesAction}: 0'),
          backgroundColor: KickPulseColors.surfaceElevated,
        ),
      );
    }
  }

  void _onBackup(
    BuildContext context,
    List<ChampionshipTournament> tournaments,
    AppLocalizations l10n,
  ) {
    if (tournaments.isNotEmpty) {
      TournamentBackupSheet.show(
        context: context,
        tournament: tournaments.first,
      );
    }
  }

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

  Future<void> _onPublishNews(
    BuildContext context,
    List<ChampionshipTournament> tournaments,
    AppLocalizations l10n,
  ) async {
    final editableTournaments = tournaments
        .where((t) => t.status != TournamentStatus.finished)
        .toList();

    if (editableTournaments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.organizerNoEditableTournamentsForNews),
          backgroundColor: KickPulseColors.surfaceElevated,
        ),
      );
      return;
    }

    final initialTournamentId =
        ref.read(tournamentsControllerProvider).selectedTournamentId ??
        editableTournaments.first.id;

    final newItem = await CreateNewsDialog.show(
      context: context,
      tournamentId: initialTournamentId,
      authorUserId: 'organizer-current',
      authorName: 'Organizador Oficial',
      availableTournaments: editableTournaments,
    );

    if (newItem != null && context.mounted) {
      final userRole = ref.read(activeUserRoleProvider);
      final success = await ref
          .read(tournamentNewsControllerProvider.notifier)
          .publishNews(item: newItem, userRole: userRole);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.newsPublishedSuccess),
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
    final matchesCatalogState = ref.watch(matchesCatalogControllerProvider);

    final tournaments = tournamentsState.tournaments;
    final matches = matchesCatalogState.matches;

    final activeTournamentsCount = tournaments
        .where(
          (t) =>
              t.status == TournamentStatus.inProgress ||
              t.status == TournamentStatus.openRegistration,
        )
        .length;

    final pendingScheduleMatchesCount = matches
        .where((m) => m.scheduledStartTime == null)
        .length;

    final unseededTournamentsCount = tournaments
        .where(
          (t) =>
              (t.status == TournamentStatus.openRegistration ||
                  t.status == TournamentStatus.inProgress) &&
              !matches.any((m) => m.tournamentId == t.id),
        )
        .length;

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

          // Quick Actions Section
          Text(
            l10n.organizerQuickActionsTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          KickPulseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KickPulseButton(
                  key: const Key('organizer_action_generate_fixture'),
                  label: l10n.organizerActionGenerateFixture,
                  icon: const Icon(Icons.alt_route, size: 20),
                  variant: KickPulseButtonVariant.primary,
                  isLoading: _isGeneratingFixture,
                  onPressed: () async {
                    await _onGenerateFixture(context, tournaments, l10n);
                  },
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                KickPulseButton(
                  key: const Key('organizer_action_schedule_matches'),
                  label: l10n.organizerActionScheduleMatches,
                  icon: const Icon(Icons.calendar_month, size: 20),
                  variant: KickPulseButtonVariant.secondary,
                  onPressed: () async {
                    _onScheduleMatches(context, tournaments, matches, l10n);
                  },
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                KickPulseButton(
                  key: const Key('organizer_action_publish_news'),
                  label: l10n.organizerActionPublishNews,
                  icon: const Icon(Icons.campaign_outlined, size: 20),
                  variant: KickPulseButtonVariant.secondary,
                  onPressed: () async {
                    await _onPublishNews(context, tournaments, l10n);
                  },
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                KickPulseButton(
                  key: const Key('organizer_action_backup'),
                  label: l10n.organizerActionBackup,
                  icon: const Icon(Icons.backup_outlined, size: 20),
                  variant: KickPulseButtonVariant.outline,
                  onPressed: () async {
                    _onBackup(context, tournaments, l10n);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
          OrganizerCompetitionsSection(
            onEditTournament: (tournament) => _onEditTournament(context, tournament),
            onChangeStatus: (tournament) => _onChangeStatus(context, tournament),
            onDeleteTournament: (tournament) => _onDeleteTournament(context, tournament),
          ),
        ],
      ),
    );
  }

  Future<void> _onEditTournament(
    BuildContext context,
    ChampionshipTournament tournament,
  ) async {
    await CompetitionEditDialog.show(
      context: context,
      tournament: tournament,
    );
  }

  Future<void> _onChangeStatus(
    BuildContext context,
    ChampionshipTournament tournament,
  ) async {
    final teams = ref.read(teamsControllerProvider).teams;
    final tournamentTeams =
        teams.where((t) => t.tournamentId == tournament.id).toList();
    final matches = ref.read(matchesCatalogControllerProvider).matches;
    final hasFixture = matches.any((m) => m.tournamentId == tournament.id);
    final l10n = AppLocalizations.of(context);

    await CompetitionLifecycleDialog.show(
      context: context,
      tournament: tournament,
      enrolledTeamsCount: tournamentTeams.length,
      hasGeneratedFixture: hasFixture,
      onEnrollTeamsRequested: () async {
        await CompetitionEnrollTeamDialog.show(
          context,
          tournament: tournament,
        );
      },
      onGenerateFixtureRequested: () async {
        await _onGenerateFixture(context, [tournament], l10n);
      },
    );
  }

  Future<void> _onDeleteTournament(
    BuildContext context,
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
}
