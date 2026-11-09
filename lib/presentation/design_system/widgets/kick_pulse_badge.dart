import 'package:flutter/material.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

enum KickPulseBadgeVariant { live, warning, dev, info, neutral, success }

/// Pill badge for semantic status indicators (9999px radius).
class KickPulseBadge extends StatelessWidget {
  final String label;
  final KickPulseBadgeVariant variant;
  final Widget? leading;

  const KickPulseBadge({
    super.key,
    required this.label,
    this.variant = KickPulseBadgeVariant.neutral,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor, borderColor) = switch (variant) {
      KickPulseBadgeVariant.live => (
        KickPulseColors.accentLive.withAlpha(40),
        KickPulseColors.accentLive,
        KickPulseColors.accentLive.withAlpha(100),
      ),
      KickPulseBadgeVariant.warning => (
        KickPulseColors.accentWarning.withAlpha(40),
        KickPulseColors.accentWarning,
        KickPulseColors.accentWarning.withAlpha(100),
      ),
      KickPulseBadgeVariant.dev => (
        KickPulseColors.accentElectric.withAlpha(40),
        KickPulseColors.accentElectric,
        KickPulseColors.accentElectric.withAlpha(100),
      ),
      KickPulseBadgeVariant.info => (
        KickPulseColors.accentElectric.withAlpha(30),
        KickPulseColors.accentElectric,
        KickPulseColors.accentElectric.withAlpha(80),
      ),
      KickPulseBadgeVariant.neutral => (
        KickPulseColors.surfaceSubtle,
        KickPulseColors.textSecondary,
        KickPulseColors.borderSubtle,
      ),
      KickPulseBadgeVariant.success => (
        KickPulseColors.accentPrimary.withAlpha(40),
        KickPulseColors.accentPrimary,
        KickPulseColors.accentPrimary.withAlpha(100),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: KickPulseRadiiSpacing.badgeBorderRadius,
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4.0)],
          Flexible(
            child: Text(
              label,
              style: KickPulseTypography.microBadge.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
