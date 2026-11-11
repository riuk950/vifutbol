import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/tournament_news_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/news/widgets/create_news_dialog.dart';
import 'package:vifutbol/presentation/panel/models/organizer_menu_action.dart';
import 'package:vifutbol/presentation/tournaments/widgets/tournament_backup_sheet.dart';

/// AppBar contextual action menu displaying global administrative options for organizers.
class OrganizerPanelAppBarMenu extends ConsumerWidget {
  const OrganizerPanelAppBarMenu({super.key, this.onActionSelected});

  /// Optional callback invoked when an action is selected, primarily for testing.
  final void Function(OrganizerMenuAction action)? onActionSelected;

  Future<void> _handlePublishNews(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final tournaments = ref.read(tournamentsControllerProvider).tournaments;
    final editableTournaments = tournaments
        .where((t) => t.status != TournamentStatus.finished)
        .toList();

    final String initialTournamentId;
    final List<ChampionshipTournament>? availableTournaments;

    if (editableTournaments.isEmpty) {
      // General announcement fallback when no editable competitions exist
      initialTournamentId = 'general';
      availableTournaments = null;
    } else {
      initialTournamentId =
          ref.read(tournamentsControllerProvider).selectedTournamentId ??
          editableTournaments.first.id;
      availableTournaments = editableTournaments;
    }

    final newItem = await CreateNewsDialog.show(
      context: context,
      tournamentId: initialTournamentId,
      authorUserId: 'organizer-current',
      authorName: 'Organizador Oficial',
      availableTournaments: availableTournaments,
    );

    if (newItem != null && context.mounted) {
      final userRole = ref.read(activeUserRoleProvider);
      final success = await ref
          .read(tournamentNewsControllerProvider.notifier)
          .publishNews(item: newItem, userRole: userRole);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.newsPublishedSuccess),
            backgroundColor: KickPulseColors.accentPrimary,
          ),
        );
      }
    }
  }

  void _handleBackup(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final tournaments = ref.read(tournamentsControllerProvider).tournaments;
    if (tournaments.isNotEmpty) {
      TournamentBackupSheet.show(
        context: context,
        tournament: tournaments.first,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.organizerCompetitionsEmptyTitle),
          backgroundColor: KickPulseColors.surfaceElevated,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<OrganizerMenuAction>(
      key: const Key('organizer_panel_appbar_menu'),
      icon: const Icon(Icons.more_vert, color: KickPulseColors.textPrimary),
      color: KickPulseColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
      ),
      onSelected: (action) {
        if (onActionSelected != null) {
          onActionSelected!(action);
          return;
        }

        switch (action) {
          case OrganizerMenuAction.publishNews:
            _handlePublishNews(context, ref, l10n);
            break;
          case OrganizerMenuAction.backup:
            _handleBackup(context, ref, l10n);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<OrganizerMenuAction>(
          key: const Key('organizer_menu_publish_news'),
          value: OrganizerMenuAction.publishNews,
          child: Row(
            children: [
              const Icon(
                Icons.campaign_outlined,
                size: 20,
                color: KickPulseColors.accentElectric,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Text(
                  l10n.organizerActionPublishNews,
                  style: KickPulseTypography.bodyPrimary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<OrganizerMenuAction>(
          key: const Key('organizer_menu_backup'),
          value: OrganizerMenuAction.backup,
          child: Row(
            children: [
              const Icon(
                Icons.backup_outlined,
                size: 20,
                color: KickPulseColors.accentPrimary,
              ),
              const SizedBox(width: KickPulseRadiiSpacing.spaceSm),
              Expanded(
                child: Text(
                  l10n.organizerActionBackup,
                  style: KickPulseTypography.bodyPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
