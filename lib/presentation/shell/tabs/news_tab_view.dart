import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/tournament_news_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_news_category.dart';
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
    final newsState = ref.watch(tournamentNewsControllerProvider);

    ChampionshipTournament? currentTournament;
    for (final t in tournaments) {
      if (t.id == tournamentsState.selectedTournamentId) {
        currentTournament = t;
        break;
      }
    }
    currentTournament ??= tournaments.isNotEmpty ? tournaments.first : null;

    final activeCategory = newsState.categoryFilter;

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

          // Active tournament subtitle (always visible if tournament exists)
          if (currentTournament != null) ...[
            Text(
              currentTournament.name,
              key: const Key('news_active_tournament_subtitle'),
              style: KickPulseTypography.cardTitle.copyWith(
                color: KickPulseColors.accentPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          ],

          // Removable active filter chip if a category is filtered
          if (activeCategory != null) ...[
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InputChip(
                  key: const Key('news_active_filter_chip'),
                  avatar: const Icon(
                    Icons.filter_list,
                    size: 16,
                    color: KickPulseColors.accentPrimary,
                  ),
                  label: Text(
                    switch (activeCategory) {
                      TournamentNewsCategory.general =>
                        l10n.newsCategoryGeneral,
                      TournamentNewsCategory.disciplinary =>
                        l10n.newsCategoryDisciplinary,
                      TournamentNewsCategory.rescheduling =>
                        l10n.newsCategoryRescheduling,
                    },
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  deleteIcon: const Icon(
                    Icons.close,
                    key: Key('news_active_filter_clear_button'),
                    size: 16,
                    color: KickPulseColors.textSecondary,
                  ),
                  deleteButtonTooltipMessage:
                      l10n.newsActiveFilterClearSemantics,
                  onDeleted: () {
                    ref
                        .read(tournamentNewsControllerProvider.notifier)
                        .setCategoryFilter(null);
                  },
                  backgroundColor: KickPulseColors.surfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      KickPulseRadiiSpacing.badgeRadius,
                    ),
                    side: const BorderSide(color: KickPulseColors.borderSubtle),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
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
