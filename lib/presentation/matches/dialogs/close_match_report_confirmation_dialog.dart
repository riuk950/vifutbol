import 'package:flutter/material.dart';
import '../../../domain/entities/championship_match.dart';
import '../../../domain/entities/digital_match_report.dart';
import '../../../domain/entities/match_report_enums.dart';
import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/kick_pulse_typography.dart';

class CloseMatchReportConfirmationDialog extends StatelessWidget {
  const CloseMatchReportConfirmationDialog({
    super.key,
    required this.match,
    required this.report,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.onConfirmClose,
  });

  final ChampionshipMatch match;
  final DigitalMatchReport report;
  final String homeTeamName;
  final String awayTeamName;
  final VoidCallback onConfirmClose;

  @override
  Widget build(BuildContext context) {
    final goals = report.events
        .where((e) => e.type == MatchEventType.goal)
        .toList();
    final cards = report.events.where((e) => e.type.isCard).toList();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(
            Icons.assignment_turned_in,
            color: KickPulseColors.accentPrimary,
          ),
          SizedBox(width: 8),
          Expanded(child: Text('Cierre Oficial del Acta')),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Final Score Header
              Container(
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
                decoration: BoxDecoration(
                  color: KickPulseColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(
                    KickPulseRadiiSpacing.cardRadius,
                  ),
                  border: Border.all(color: KickPulseColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Marcador Definitivo',
                      style: KickPulseTypography.captionMeta,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$homeTeamName ${report.homeScore} - ${report.awayScore} $awayTeamName',
                      textAlign: TextAlign.center,
                      style: KickPulseTypography.cardTitle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Goals Summary
              Text(
                'Goles (${goals.length}):',
                style: KickPulseTypography.bodyPrimary.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (goals.isEmpty)
                const Text(
                  'Sin goles registrados',
                  style: KickPulseTypography.captionMeta,
                )
              else
                ...goals.map(
                  (g) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      '• ${g.minute}\' ${g.primaryPlayerName ?? 'Jugador'}'
                      '${g.secondaryPlayerName != null ? ' (asist. ${g.secondaryPlayerName})' : ''}',
                      style: KickPulseTypography.captionMeta,
                    ),
                  ),
                ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

              // Cards Summary
              Text(
                'Sanciones disciplinarias (${cards.length}):',
                style: KickPulseTypography.bodyPrimary.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (cards.isEmpty)
                const Text(
                  'Sin tarjetas registradas',
                  style: KickPulseTypography.captionMeta,
                )
              else
                ...cards.map((c) {
                  final typeLabel = c.type == MatchEventType.yellowCard
                      ? '🟨 Amarilla'
                      : (c.type == MatchEventType.secondYellowRedCard
                            ? '🟥 Doble Amarilla (Expulsión)'
                            : '🟥 Roja Directa');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      '• ${c.minute}\' $typeLabel - ${c.primaryPlayerName ?? 'Jugador'}',
                      style: KickPulseTypography.captionMeta,
                    ),
                  );
                }),
              const SizedBox(height: KickPulseRadiiSpacing.spaceLg),

              // Irreversibility Warning
              Container(
                padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(
                    KickPulseRadiiSpacing.chipRadius,
                  ),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta acción es definitiva. El acta quedará sellada e inmutable y se actualizarán las estadísticas oficiales.',
                        style: TextStyle(color: Colors.amber, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check_circle),
          label: const Text('Confirmar y Cerrar Acta'),
          style: FilledButton.styleFrom(
            backgroundColor: KickPulseColors.accentPrimary,
            foregroundColor: KickPulseColors.canvasBackground,
            minimumSize: const Size(140, 48),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            onConfirmClose();
          },
        ),
      ],
    );
  }
}
