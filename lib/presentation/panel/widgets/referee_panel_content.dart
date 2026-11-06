import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/matches_catalog_providers.dart';
import 'package:vifutbol/domain/entities/championship_match.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/matches/digital_match_report_screen.dart';

/// Dynamic panel content for [UserRole.referee].
class RefereePanelContent extends ConsumerWidget {
  const RefereePanelContent({super.key});

  void _onOpenDigitalReport(BuildContext context, ChampionshipMatch match) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DigitalMatchReportScreen(initialMatch: match),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return KickPulseCard(
      key: const Key('referee_empty_matches_state'),
      child: Padding(
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
              decoration: BoxDecoration(
                color: KickPulseColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 40,
                color: KickPulseColors.textSecondary,
              ),
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
            Text(
              l10n.refereeEmptyMatchesTitle,
              style: KickPulseTypography.sectionHeader.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
            Text(
              l10n.refereeEmptyMatchesMessage,
              style: KickPulseTypography.captionMeta,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    ChampionshipMatch match,
    AppLocalizations l10n,
  ) {
    return KickPulseCard(
      key: Key('referee_match_item_${match.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  match.roundName,
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.accentPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              KickPulseBadge(
                label: match.status.name.toUpperCase(),
                variant: KickPulseBadgeVariant.info,
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          Text(
            '${match.homeTeamId.toUpperCase()} vs ${match.awayTeamId.toUpperCase()}',
            style: KickPulseTypography.screenTitle.copyWith(fontSize: 18),
          ),
          if (match.pitchName != null) ...[
            const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
            Row(
              children: [
                const Icon(
                  Icons.stadium_outlined,
                  size: 16,
                  color: KickPulseColors.textSecondary,
                ),
                const SizedBox(width: KickPulseRadiiSpacing.spaceXs),
                Text(match.pitchName!, style: KickPulseTypography.captionMeta),
              ],
            ),
          ],
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
          KickPulseButton(
            key: Key('referee_open_match_report_${match.id}'),
            label: l10n.refereeActionDigitalReport,
            icon: const Icon(Icons.edit_note, size: 20),
            variant: KickPulseButtonVariant.primary,
            onPressed: () async {
              _onOpenDigitalReport(context, match);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final matchesCatalogState = ref.watch(matchesCatalogControllerProvider);

    final currentUserId = authState.session?.user.id ?? 'referee-current';
    final assignedMatches = matchesCatalogState.matches
        .where((m) => m.refereeId == currentUserId)
        .toList();

    return SingleChildScrollView(
      key: const Key('referee_panel_content'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.refereeAssignedMatchesTitle,
            style: KickPulseTypography.sectionHeader,
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
          if (assignedMatches.isEmpty)
            _buildEmptyState(l10n)
          else
            Column(
              key: const Key('referee_assigned_matches_list'),
              children: assignedMatches
                  .map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: KickPulseRadiiSpacing.spaceSm,
                      ),
                      child: _buildMatchCard(context, m, l10n),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
