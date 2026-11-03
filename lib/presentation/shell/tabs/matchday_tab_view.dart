import 'package:flutter/material.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_badge.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_state_view.dart';

enum DemoUiStateOption { loading, content, empty, error, success }

class MatchdayTabView extends StatefulWidget {
  const MatchdayTabView({super.key});

  @override
  State<MatchdayTabView> createState() => _MatchdayTabViewState();
}

class _MatchdayTabViewState extends State<MatchdayTabView> {
  DemoUiStateOption _selectedOption = DemoUiStateOption.content;

  UiViewState<String> _buildCurrentState() {
    return switch (_selectedOption) {
      DemoUiStateOption.loading => const UiLoadingState<String>(),
      DemoUiStateOption.content => const UiContentState<String>(
        'Jornada 1 — Liga Metropolitana',
      ),
      DemoUiStateOption.empty => const UiEmptyState<String>(),
      DemoUiStateOption.error => const UiErrorState<String>(
        DataLoadFailure(
          'No se pudieron sincronizar los partidos con el servidor.',
        ),
        canRetry: true,
      ),
      DemoUiStateOption.success => const UiSuccessState<String>(
        'Acta deportiva actualizada',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentState = _buildCurrentState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.tabMatchday, style: KickPulseTypography.screenTitle),
              const KickPulseBadge(
                label: 'OFICIAL',
                variant: KickPulseBadgeVariant.live,
              ),
            ],
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          // State Demonstration Segmented Control for interactive verification
          KickPulseCard(
            padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verificación de Estados de Interfaz (5 Estados Base)',
                  style: KickPulseTypography.captionMeta.copyWith(
                    color: KickPulseColors.textSecondary,
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStateChip('Carga', DemoUiStateOption.loading),
                      const SizedBox(width: 6),
                      _buildStateChip('Contenido', DemoUiStateOption.content),
                      const SizedBox(width: 6),
                      _buildStateChip('Vacío', DemoUiStateOption.empty),
                      const SizedBox(width: 6),
                      _buildStateChip('Error', DemoUiStateOption.error),
                      const SizedBox(width: 6),
                      _buildStateChip('Éxito', DemoUiStateOption.success),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

          // Interactive State View Renderer
          KickPulseCard(
            child: KickPulseStateView<String>(
              state: currentState,
              contentBuilder: (context, data) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.stateContentTitle,
                      style: KickPulseTypography.cardTitle,
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    Text(
                      data,
                      style: KickPulseTypography.displayScore.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
                    Text(
                      'Próximos partidos y resultados oficiales de la jornada.',
                      style: KickPulseTypography.bodyPrimary.copyWith(
                        color: KickPulseColors.textSecondary,
                      ),
                    ),
                  ],
                );
              },
              onRetry: () async {
                setState(() {
                  _selectedOption = DemoUiStateOption.content;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateChip(String label, DemoUiStateOption option) {
    final isSelected = _selectedOption == option;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOption = option;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? KickPulseColors.accentPrimary
              : KickPulseColors.surfaceSubtle,
          borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : KickPulseColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
