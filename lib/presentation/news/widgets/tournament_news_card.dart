import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:vifutbol/domain/entities/tournament_news_category.dart';
import 'package:vifutbol/domain/entities/tournament_news_item.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';

class TournamentNewsCard extends StatelessWidget {
  const TournamentNewsCard({
    super.key,
    required this.newsItem,
    this.canDelete = false,
    this.onDelete,
  });

  final TournamentNewsItem newsItem;
  final bool canDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formattedDate = DateFormat(
      'EEE d MMM yyyy, HH:mm',
      'es',
    ).format(newsItem.publishedAt);

    final (categoryLabel, categoryVariant) = switch (newsItem.category) {
      TournamentNewsCategory.general => (
        l10n.newsCategoryGeneral,
        KickPulseBadgeVariant.info,
      ),
      TournamentNewsCategory.disciplinary => (
        l10n.newsCategoryDisciplinary,
        KickPulseBadgeVariant.warning,
      ),
      TournamentNewsCategory.rescheduling => (
        l10n.newsCategoryRescheduling,
        KickPulseBadgeVariant.live,
      ),
    };

    return Semantics(
      container: true,
      label: 'Comunicado oficial: ${newsItem.title}',
      child: KickPulseCard(
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Category Badge, Pin Icon and Delete Action
            Row(
              children: [
                Flexible(
                  child: KickPulseBadge(
                    label: categoryLabel,
                    variant: categoryVariant,
                  ),
                ),
                if (newsItem.isPinned) ...[
                  const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                  const Icon(
                    Icons.push_pin,
                    size: 14,
                    color: KickPulseColors.accentElectric,
                  ),
                ],
                const Spacer(),
                if (canDelete)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: KickPulseColors.textSecondary,
                    ),
                    tooltip: 'Eliminar comunicado',
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

            // Title
            Text(newsItem.title, style: KickPulseTypography.cardTitle),
            const SizedBox(height: KickPulseRadiiSpacing.spaceXs),

            // Body
            Text(
              newsItem.body,
              style: KickPulseTypography.bodyPrimary.copyWith(
                color: KickPulseColors.textSecondary,
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

            // Footer metadata: Author and Published date
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: KickPulseRadiiSpacing.spaceSm,
              runSpacing: 4,
              children: [
                Text(
                  newsItem.authorName,
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.accentPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formattedDate,
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
