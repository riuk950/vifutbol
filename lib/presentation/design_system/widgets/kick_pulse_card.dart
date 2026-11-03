import 'package:flutter/material.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';

/// Reusable card component adhering to KickPulse Mobile specification (16px radius, subtle border).
class KickPulseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderSide? borderSide;

  const KickPulseCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder =
        borderSide ??
        const BorderSide(color: KickPulseColors.borderSubtle, width: 1.0);

    final cardContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? KickPulseColors.surfaceBase,
        borderRadius: KickPulseRadiiSpacing.cardBorderRadius,
        border: Border.fromBorderSide(effectiveBorder),
      ),
      padding: padding ?? const EdgeInsets.all(KickPulseRadiiSpacing.spaceMd),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: KickPulseRadiiSpacing.cardBorderRadius,
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
