import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/standings_and_rankings_controller.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';
import 'package:vifutbol/presentation/standings/widgets/standings_table_card.dart';

/// Tab view presenting tournament standings table and rankings.
class CompetitionStandingsTabView extends ConsumerWidget {
  final String tournamentId;

  const CompetitionStandingsTabView({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      standingsAndRankingsControllerProvider(tournamentId),
    );

    final mainTable = state.snapshot?.mainStandingsTable;
    final groupTables = state.snapshot?.groupStandingsTables ?? [];

    if (state.isLoading) {
      return const Center(
        key: Key('competition_detail_standings_content'),
        child: CircularProgressIndicator(),
      );
    }

    if (mainTable == null || (mainTable.rows.isEmpty && groupTables.isEmpty)) {
      return const Center(
        key: Key('competition_detail_standings_content'),
        child: Padding(
          padding: EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
          child: KickPulseStateView<void>(
            state: UiEmptyState<void>(
              message: 'Sin Clasificación Disponible',
              description:
                  'La tabla de posiciones se generará cuando se registren los primeros resultados.',
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      key: const Key('competition_detail_standings_content'),
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: StandingsTableCard(mainTable: mainTable, groupTables: groupTables),
    );
  }
}
