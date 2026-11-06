import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vifutbol/application/controllers/daily_matches_feed_controller.dart';
import 'package:vifutbol/domain/entities/daily_matches_group.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

/// Barra horizontal con 3 pestañas fijas: Ayer, Hoy, Mañana y selector condicional de fecha custom.
class DailyMatchesTabBar extends StatelessWidget {
  final DailyMatchesDateState dateState;
  final ValueChanged<MatchesDailyTab> onTabSelected;

  const DailyMatchesTabBar({
    super.key,
    required this.dateState,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final tomorrow = now.add(const Duration(days: 1));

    return Container(
      color: KickPulseColors.surfaceBase,
      padding: const EdgeInsets.symmetric(
        horizontal: KickPulseRadiiSpacing.spaceMd,
        vertical: 8.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Pestaña Ayer
              Expanded(
                child: _buildTabItem(
                  key: const Key('quick_tab_yesterday'),
                  title: l10n.tabYesterday,
                  dateStr: '${yesterday.day} ${_monthName(yesterday.month)}',
                  isSelected: dateState.activeTab == MatchesDailyTab.yesterday,
                  onTap: () => onTabSelected(MatchesDailyTab.yesterday),
                ),
              ),
              const SizedBox(width: 8),

              // Pestaña Hoy
              Expanded(
                child: _buildTabItem(
                  key: const Key('quick_tab_today'),
                  title: l10n.tabToday,
                  dateStr: '${now.day} ${_monthName(now.month)}',
                  isSelected: dateState.activeTab == MatchesDailyTab.today,
                  onTap: () => onTabSelected(MatchesDailyTab.today),
                ),
              ),
              const SizedBox(width: 8),

              // Pestaña Mañana
              Expanded(
                child: _buildTabItem(
                  key: const Key('quick_tab_tomorrow'),
                  title: l10n.tabTomorrow,
                  dateStr: '${tomorrow.day} ${_monthName(tomorrow.month)}',
                  isSelected: dateState.activeTab == MatchesDailyTab.tomorrow,
                  onTap: () => onTabSelected(MatchesDailyTab.tomorrow),
                ),
              ),
            ],
          ),

          // Indicador de fecha personalizada seleccionada vía calendario
          if (dateState.isCustomDate) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KickPulseRadiiSpacing.spaceSm,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: KickPulseColors.accentPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(
                  KickPulseRadiiSpacing.chipRadius,
                ),
                border: Border.all(
                  color: KickPulseColors.accentPrimary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_outlined,
                    size: 14,
                    color: KickPulseColors.accentPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('EEE d MMM y', 'es').format(dateState.selectedDate),
                    style: KickPulseTypography.captionMeta.copyWith(
                      color: KickPulseColors.accentPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required Key key,
    required String title,
    required String dateStr,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title, $dateStr',
      child: Material(
        color: isSelected
            ? KickPulseColors.surfaceElevated
            : KickPulseColors.surfaceBase,
        borderRadius: BorderRadius.circular(10.0),
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: isSelected
                    ? KickPulseColors.accentPrimary
                    : KickPulseColors.borderSubtle,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: isSelected
                        ? KickPulseColors.accentPrimary
                        : KickPulseColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: isSelected
                        ? KickPulseColors.textPrimary
                        : KickPulseColors.textTertiary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return months[month - 1];
  }
}
