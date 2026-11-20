import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/tournament_news_providers.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/news/widgets/tournament_news_card.dart';

class TournamentNewsFeedView extends ConsumerStatefulWidget {
  const TournamentNewsFeedView({
    super.key,
    required this.tournamentId,
    this.isHistoricalReadOnly = false,
  });

  final String tournamentId;
  final bool isHistoricalReadOnly;

  @override
  ConsumerState<TournamentNewsFeedView> createState() =>
      _TournamentNewsFeedViewState();
}

class _TournamentNewsFeedViewState
    extends ConsumerState<TournamentNewsFeedView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(tournamentNewsControllerProvider.notifier)
          .loadNews(widget.tournamentId);
    });
  }

  @override
  void didUpdateWidget(covariant TournamentNewsFeedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tournamentId != widget.tournamentId) {
      ref
          .read(tournamentNewsControllerProvider.notifier)
          .loadNews(widget.tournamentId);
    }
  }

  Future<void> _onDeleteNews(TournamentNewsItem item, UserRole role) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KickPulseColors.surfaceElevated,
        title: Text(
          l10n.newsDeleteConfirmTitle,
          style: KickPulseTypography.cardTitle,
        ),
        content: Text(
          l10n.newsDeleteConfirmMessage,
          style: KickPulseTypography.bodyPrimary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: KickPulseTypography.captionMeta.copyWith(
                color: KickPulseColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KickPulseColors.accentLive,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(tournamentNewsControllerProvider.notifier)
          .deleteNews(newsItemId: item.id, userRole: role);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.newsDeletedSuccess),
            backgroundColor: KickPulseColors.accentPrimary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final newsState = ref.watch(tournamentNewsControllerProvider);
    final userRole = ref.watch(activeUserRoleProvider);
    final isFinished = widget.isHistoricalReadOnly;
    final isOrganizer = userRole == UserRole.organizer;

    final filteredNews = newsState.filteredNews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isFinished) ...[
          Container(
            key: const Key('news_readonly_badge'),
            margin: const EdgeInsets.only(
              bottom: KickPulseRadiiSpacing.spaceSm,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: KickPulseRadiiSpacing.spaceSm,
              vertical: KickPulseRadiiSpacing.spaceXs,
            ),
            decoration: BoxDecoration(
              color: KickPulseColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(
                KickPulseRadiiSpacing.badgeRadius,
              ),
              border: Border.all(color: KickPulseColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_clock_outlined,
                  size: 14,
                  color: KickPulseColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.seasonReadOnlyBadge,
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        // News List
        if (newsState.isLoading) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ] else if (filteredNews.isEmpty) ...[
          if (newsState.categoryFilter != null)
            KickPulseCard(
              key: const Key('news_feed_empty_filter'),
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.filter_list_off_outlined,
                      size: 48,
                      color: KickPulseColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.newsFeedEmptyCategoryFilter,
                      textAlign: TextAlign.center,
                      style: KickPulseTypography.bodyPrimary.copyWith(
                        color: KickPulseColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    TextButton(
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
                  ],
                ),
              ),
            )
          else
            KickPulseCard(
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.newspaper_outlined,
                      size: 48,
                      color: KickPulseColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.newsFeedEmpty,
                      textAlign: TextAlign.center,
                      style: KickPulseTypography.bodyPrimary.copyWith(
                        color: KickPulseColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredNews.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            itemBuilder: (context, index) {
              final item = filteredNews[index];
              return TournamentNewsCard(
                key: Key('news_card_${item.id}'),
                newsItem: item,
                canDelete: isOrganizer && !isFinished,
                onDelete: () => _onDeleteNews(item, userRole),
              );
            },
          ),
        ],
      ],
    );
  }
}
