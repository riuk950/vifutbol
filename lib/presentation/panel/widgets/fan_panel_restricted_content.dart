import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vifutbol/application/controllers/app_shell_controller.dart';
import 'package:vifutbol/domain/entities/app_shell_section.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_button.dart';
import 'package:vifutbol/presentation/design_system/widgets/kick_pulse_card.dart';

/// Informational restriction content for [UserRole.fan].
class FanPanelRestrictedContent extends ConsumerWidget {
  const FanPanelRestrictedContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Center(
      key: const Key('fan_panel_restricted_content'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KickPulseRadiiSpacing.spaceLg),
        child: KickPulseCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: KickPulseRadiiSpacing.spaceLg,
              horizontal: KickPulseRadiiSpacing.spaceMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Illustrated Shield / Restriction Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: KickPulseColors.accentElectric.withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: KickPulseColors.accentElectric.withValues(
                        alpha: 0.35,
                      ),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: KickPulseColors.accentElectric,
                    size: 36,
                  ),
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceMd),

                // Title
                Text(
                  l10n.fanRestrictedTitle,
                  style: KickPulseTypography.screenTitle.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceSm),

                // Informative Message
                Text(
                  l10n.fanRestrictedMessage,
                  style: KickPulseTypography.bodyPrimary.copyWith(
                    color: KickPulseColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KickPulseRadiiSpacing.spaceXl),

                // Return to Matches Action Button
                KickPulseButton(
                  key: const Key('fan_restricted_return_matches_button'),
                  label: l10n.fanRestrictedReturnAction,
                  icon: const Icon(Icons.sports_soccer, size: 20),
                  isFullWidth: true,
                  onPressed: () async {
                    ref
                        .read(appShellControllerProvider.notifier)
                        .setSection(AppShellSection.matches);
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/matches', (route) => false);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
