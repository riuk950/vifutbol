import 'package:flutter/material.dart';
import 'package:vifutbol/domain/entities/tournament_news_category.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

class TournamentNewsFilterBar extends StatelessWidget {
  const TournamentNewsFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final TournamentNewsCategory? selectedCategory;
  final ValueChanged<TournamentNewsCategory?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            label: l10n.newsCategoryAll,
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: l10n.newsCategoryGeneral,
            isSelected: selectedCategory == TournamentNewsCategory.general,
            onTap: () => onCategorySelected(TournamentNewsCategory.general),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: l10n.newsCategoryDisciplinary,
            isSelected: selectedCategory == TournamentNewsCategory.disciplinary,
            onTap: () =>
                onCategorySelected(TournamentNewsCategory.disciplinary),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: l10n.newsCategoryRescheduling,
            isSelected: selectedCategory == TournamentNewsCategory.rescheduling,
            onTap: () =>
                onCategorySelected(TournamentNewsCategory.rescheduling),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: KickPulseTypography.captionMeta.copyWith(
          color: isSelected
              ? KickPulseColors.surfaceBase
              : KickPulseColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: KickPulseColors.accentPrimary,
      backgroundColor: KickPulseColors.surfaceElevated,
      onSelected: (_) => onTap(),
    );
  }
}
