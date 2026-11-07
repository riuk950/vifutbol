import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/providers/venues_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/tournaments/widgets/tournament_rules_summary_card.dart';

/// Tab view presenting competition information, official tournament rules,
/// scoring systems, tiebreakers, squad limits, and primary sports venue.
class CompetitionInfoTabView extends ConsumerWidget {
  final String tournamentId;

  const CompetitionInfoTabView({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tournamentsCatalog = ref.watch(tournamentsControllerProvider);
    final activeRole = ref.watch(activeUserRoleProvider);
    final matchesCatalog = ref.watch(matchesCatalogControllerProvider);
    final venuesCatalog = ref.watch(venuesControllerProvider);

    if (tournamentsCatalog.viewState is UiLoadingState) {
      return const Center(
        key: Key('competition_detail_info_loading'),
        child: Padding(
          padding: EdgeInsets.all(KickPulseRadiiSpacing.spaceXl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final ChampionshipTournament? tournament = tournamentsCatalog.tournaments
        .where((t) => t.id == tournamentId)
        .firstOrNull;

    if (tournament == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
          child: KickPulseStateView<void>(
            key: const Key('competition_detail_info_not_found'),
            state: UiEmptyState<void>(
              message: l10n.competitionInfoNotFoundTitle,
              description: l10n.competitionInfoNotFoundDescription,
            ),
          ),
        ),
      );
    }

    // Resolve primary venue: match venue first, fallback to first catalog venue
    final tournamentMatches = matchesCatalog.matches
        .where((m) => m.tournamentId == tournamentId)
        .toList();
    final matchWithVenue = tournamentMatches
        .where((m) => m.venueId != null && m.venueId!.trim().isNotEmpty)
        .firstOrNull;
    final String? assignedVenueId = matchWithVenue?.venueId;

    final SportsVenue? primaryVenue = assignedVenueId != null
        ? venuesCatalog.venues
                  .where((v) => v.id == assignedVenueId)
                  .firstOrNull ??
              venuesCatalog.venues.firstOrNull
        : venuesCatalog.venues.firstOrNull;

    final isOrganizer = activeRole == UserRole.organizer;

    return SingleChildScrollView(
      key: const Key('competition_detail_info_content'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TournamentRulesSummaryCard(
            key: const Key('competition_tournament_rules_card'),
            tournament: tournament,
            isOrganizer: isOrganizer,
            onEditPressed: null,
            onTransitionStatusPressed: null,
            onBackupPressed: null,
            onCloseSeasonPressed: null,
          ),
          if (primaryVenue != null) ...[
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            KickPulseCard(
              key: const Key('competition_main_venue_card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: KickPulseRadiiSpacing.spaceSm,
                    runSpacing: KickPulseRadiiSpacing.spaceXs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(
                          KickPulseRadiiSpacing.spaceXs,
                        ),
                        decoration: BoxDecoration(
                          color: KickPulseColors.accentElectric.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(
                            KickPulseRadiiSpacing.chipRadius,
                          ),
                        ),
                        child: const Icon(
                          Icons.stadium_outlined,
                          size: 20,
                          color: KickPulseColors.accentElectric,
                        ),
                      ),
                      Text(
                        l10n.competitionMainVenueTitle,
                        style: KickPulseTypography.cardTitle,
                      ),
                      Container(
                        key: const Key('competition_venue_pitches_badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: KickPulseRadiiSpacing.spaceSm,
                          vertical: KickPulseRadiiSpacing.spaceXs,
                        ),
                        decoration: BoxDecoration(
                          color: KickPulseColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(
                            KickPulseRadiiSpacing.badgeRadius,
                          ),
                          border: Border.all(
                            color: KickPulseColors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          l10n.competitionMainVenuePitches(
                            primaryVenue.pitches.length,
                          ),
                          style: KickPulseTypography.microBadge.copyWith(
                            color: KickPulseColors.accentElectric,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                  Text(
                    primaryVenue.name,
                    style: KickPulseTypography.sectionHeader,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: KickPulseColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          primaryVenue.address,
                          style: KickPulseTypography.captionMeta,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
