import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_fixture_tab_view.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_info_tab_view.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_standings_tab_view.dart';

/// Dedicated competition detail screen (`/competitions/:id`) featuring fixed horizontal
/// tabs for Matches, Standings, and Official Rules.
class CompetitionDetailScreen extends ConsumerWidget {
  final String tournamentId;

  const CompetitionDetailScreen({super.key, required this.tournamentId});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tournamentsState = ref.watch(tournamentsControllerProvider);
    final tournament = tournamentsState.tournaments
        .where((t) => t.id == tournamentId)
        .firstOrNull;

    final (statusLabel, statusVariant) = tournament != null
        ? _statusBadgeInfo(tournament.status, l10n)
        : ('', KickPulseBadgeVariant.neutral);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: const Key('competition_detail_screen'),
        backgroundColor: KickPulseColors.canvasBackground,
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
            CompetitionFixtureTabView(tournamentId: tournamentId),
            CompetitionStandingsTabView(tournamentId: tournamentId),
            CompetitionInfoTabView(tournamentId: tournamentId),
          ],
        ),
      ),
    );
  }
}
