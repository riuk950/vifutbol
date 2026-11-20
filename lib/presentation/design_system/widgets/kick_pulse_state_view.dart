import 'package:material_ui/material_ui.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';

/// Standardized component rendering the 5 canonical UI states (Loading, Content, Empty, Error, Success).
class KickPulseStateView<T> extends StatelessWidget {
  final UiViewState<T> state;
  final Widget Function(BuildContext context, T data)? contentBuilder;
  final Future<void> Function()? onRetry;

  const KickPulseStateView({
    super.key,
    required this.state,
    this.contentBuilder,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return switch (state) {
      UiLoadingState<T>(:final message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  KickPulseColors.accentPrimary,
                ),
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              Text(
                message ?? l10n.stateLoadingTitle,
                style: KickPulseTypography.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
              Text(
                l10n.stateLoadingSubtitle,
                style: KickPulseTypography.captionMeta,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      UiContentState<T>(:final data) =>
        contentBuilder != null
            ? contentBuilder!(context, data)
            : Text(data.toString()),
      UiEmptyState<T>(:final message, :final description) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inbox_outlined,
                size: 48.0,
                color: KickPulseColors.textSecondary,
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              Text(
                message ?? l10n.stateEmptyTitle,
                style: KickPulseTypography.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
              Text(
                description ?? l10n.stateEmptyDescription,
                style: KickPulseTypography.captionMeta,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      UiErrorState<T>(:final failure, :final canRetry) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48.0,
                color: KickPulseColors.accentLive,
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              Text(
                l10n.stateErrorTitle,
                style: KickPulseTypography.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
              Text(
                failure.message,
                style: KickPulseTypography.captionMeta.copyWith(
                  color: KickPulseColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (canRetry && onRetry != null) ...[
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
                KickPulseButton(
                  label: l10n.actionRetry,
                  variant: KickPulseButtonVariant.secondary,
                  icon: const Icon(Icons.refresh, size: 16.0),
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
      UiSuccessState<T>(:final message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 48.0,
                color: KickPulseColors.accentPrimary,
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              Text(
                l10n.stateSuccessTitle,
                style: KickPulseTypography.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceXs),
              Text(
                message ?? l10n.stateSuccessDescription,
                style: KickPulseTypography.captionMeta,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    };
  }
}
