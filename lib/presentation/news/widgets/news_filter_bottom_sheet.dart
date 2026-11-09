import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/tournament_news_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_news_category.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

/// Modal bottom sheet allowing users to filter news by tournament and category in real time.
class NewsFilterBottomSheet extends ConsumerWidget {
  const NewsFilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KickPulseColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KickPulseRadiiSpacing.cardRadius),
        ),
      ),
      builder: (context) => const NewsFilterBottomSheet(),
    );
  }

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

    return SafeArea(
      key: const Key('news_filter_bottom_sheet'),
      child: Padding(
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.newsFilterSheetTitle,
                      style: KickPulseTypography.sectionHeader,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    key: const Key('news_filter_reset_button'),
                    onPressed: () {
                      ref
                          .read(tournamentNewsControllerProvider.notifier)
                          .setCategoryFilter(null);
                    },
                    child: Text(
                      l10n.newsFilterResetButton,
                      style: KickPulseTypography.captionMeta.copyWith(
                        color: KickPulseColors.accentPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('news_filter_close_button'),
                    icon: const Icon(Icons.close),
                    color: KickPulseColors.textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: KickPulseColors.borderSubtle),
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

              // Tournaments Section
              if (tournaments.isNotEmpty) ...[
                Text(
                  l10n.newsFilterTournamentSectionTitle,
                  style: KickPulseTypography.cardTitle.copyWith(
                    color: KickPulseColors.textPrimary,
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: tournaments.map((tournament) {
                    final isSelected = tournament.id == currentTournament?.id;
                    return ChoiceChip(
                      key: Key('news_filter_tournament_chip_${tournament.id}'),
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
                      backgroundColor: KickPulseColors.surfaceSubtle,
                      onSelected: (_) {
                        ref
                            .read(tournamentsControllerProvider.notifier)
                            .selectTournament(tournament.id);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              ],

              // Categories Section
              Text(
                l10n.newsFilterCategorySectionTitle,
                style: KickPulseTypography.cardTitle.copyWith(
                  color: KickPulseColors.textPrimary,
                ),
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ChoiceChip(
                    key: const Key('news_filter_category_chip_all'),
                    label: Text(
                      l10n.newsCategoryAll,
                      style: KickPulseTypography.captionMeta.copyWith(
                        color: newsState.categoryFilter == null
                            ? KickPulseColors.surfaceBase
                            : KickPulseColors.textSecondary,
                        fontWeight: newsState.categoryFilter == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: newsState.categoryFilter == null,
                    selectedColor: KickPulseColors.accentPrimary,
                    backgroundColor: KickPulseColors.surfaceSubtle,
                    onSelected: (_) {
                      ref
                          .read(tournamentNewsControllerProvider.notifier)
                          .setCategoryFilter(null);
                    },
                  ),
                  ...TournamentNewsCategory.values.map((category) {
                    final isSelected = newsState.categoryFilter == category;
                    final categoryLabel = switch (category) {
                      TournamentNewsCategory.general =>
                        l10n.newsCategoryGeneral,
                      TournamentNewsCategory.disciplinary =>
                        l10n.newsCategoryDisciplinary,
                      TournamentNewsCategory.rescheduling =>
                        l10n.newsCategoryRescheduling,
                    };

                    return ChoiceChip(
                      key: Key('news_filter_category_chip_${category.name}'),
                      label: Text(
                        categoryLabel,
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
                      backgroundColor: KickPulseColors.surfaceSubtle,
                      onSelected: (_) {
                        ref
                            .read(tournamentNewsControllerProvider.notifier)
                            .setCategoryFilter(category);
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceLg),
            ],
          ),
        ),
      ),
    );
  }
}
