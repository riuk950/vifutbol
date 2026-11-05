import 'package:flutter/material.dart';
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
import 'package:vifutbol/presentation/news/widgets/create_news_dialog.dart';
import 'package:vifutbol/presentation/news/widgets/tournament_news_card.dart';
import 'package:vifutbol/presentation/news/widgets/tournament_news_filter_bar.dart';

class TournamentNewsFeedView extends ConsumerStatefulWidget {
  const TournamentNewsFeedView({super.key, required this.tournamentId});

  final String tournamentId;

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

  Future<void> _onCreateNews(UserRole role) async {
    final newItem = await CreateNewsDialog.show(
      context: context,
      tournamentId: widget.tournamentId,
      authorUserId: 'organizer-current',
      authorName: 'Organizador Oficial',
    );

    if (newItem != null && mounted) {
      final success = await ref
          .read(tournamentNewsControllerProvider.notifier)
          .publishNews(item: newItem, userRole: role);

      if (success && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.newsPublishedSuccess),
            backgroundColor: KickPulseColors.accentPrimary,
          ),
        );
      }
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
    final isOrganizer = userRole == UserRole.organizer;

    final filteredNews = newsState.filteredNews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter bar & Header
        Row(
          children: [
            Expanded(
              child: TournamentNewsFilterBar(
                selectedCategory: newsState.categoryFilter,
                onCategorySelected: (cat) {
                  ref
                      .read(tournamentNewsControllerProvider.notifier)
                      .setCategoryFilter(cat);
                },
              ),
            ),
            if (isOrganizer) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                key: const Key('create_news_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KickPulseColors.accentPrimary,
                  foregroundColor: KickPulseColors.surfaceBase,
                  padding: const EdgeInsets.symmetric(
                    horizontal: KickPulseRadiiSpacing.spaceSm,
                    vertical: 8,
                  ),
                ),
                onPressed: () => _onCreateNews(userRole),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  l10n.newsCreateButton,
                  style: KickPulseTypography.captionMeta.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

        // News List
        if (newsState.isLoading) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ] else if (filteredNews.isEmpty) ...[
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
                canDelete: isOrganizer,
                onDelete: () => _onDeleteNews(item, userRole),
              );
            },
          ),
        ],
      ],
    );
  }
}
