import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/news/tournament_news_feed_view.dart';

/// Top-level Noticias tab displaying official tournament announcements and news,
/// synchronized globally with the active tournament context.
class NewsTabView extends ConsumerWidget {
  const NewsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tournamentsState = ref.watch(tournamentsControllerProvider);
    final tournaments = tournamentsState.tournaments;

    ChampionshipTournament? currentTournament;
    for (final t in tournaments) {
      if (t.id == tournamentsState.selectedTournamentId) {
        currentTournament = t;
        break;
      }
    }
    currentTournament ??= tournaments.isNotEmpty ? tournaments.first : null;

    return SingleChildScrollView(
      key: const Key('news_tab_view_scroll'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            key: const Key('news_tab_header'),
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.tabNews,
                  style: KickPulseTypography.screenTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              const KickPulseBadge(
                label: 'OFICIAL',
                variant: KickPulseBadgeVariant.live,
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

          // Tournament Selector if multiple tournaments exist
          if (tournaments.length > 1) ...[
            SingleChildScrollView(
              key: const Key('news_tournament_selector'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tournaments.map((tournament) {
                  final isSelected = tournament.id == currentTournament?.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      key: Key('news_tournament_chip_${tournament.id}'),
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
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          ] else if (currentTournament != null) ...[
            Text(
              currentTournament.name,
              style: KickPulseTypography.cardTitle.copyWith(
                color: KickPulseColors.accentPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          ],

          if (currentTournament != null) ...[
            TournamentNewsFeedView(
              key: Key('tournament_news_feed_${currentTournament.id}'),
              tournamentId: currentTournament.id,
              isHistoricalReadOnly:
                  currentTournament.status == TournamentStatus.finished,
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  l10n.newsFeedEmpty,
                  style: KickPulseTypography.bodyPrimary.copyWith(
                    color: KickPulseColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
