import 'package:flutter/material.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';

enum KickPulseButtonVariant { primary, secondary, outline }

/// Button component guaranteeing minimum 44x44px touch target (FR-005)
/// and anti-double-tap single-flight execution lock.
class KickPulseButton extends StatefulWidget {
  final String label;
  final Future<void> Function()? onPressed;
  final KickPulseButtonVariant variant;
  final Widget? icon;
  final bool isFullWidth;
  final bool isLoading;

  const KickPulseButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KickPulseButtonVariant.primary,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
  });

  @override
  State<KickPulseButton> createState() => _KickPulseButtonState();
}

class _KickPulseButtonState extends State<KickPulseButton> {
  bool _isExecuting = false;

  Future<void> _handlePress() async {
    if (widget.onPressed == null || _isExecuting || widget.isLoading) return;

    setState(() {
      _isExecuting = true;
    });

    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() {
          _isExecuting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = widget.isLoading || _isExecuting;

    final (bgColor, fgColor, borderSide) = switch (widget.variant) {
      KickPulseButtonVariant.primary => (
        widget.onPressed == null
            ? KickPulseColors.surfaceSubtle
            : KickPulseColors.accentPrimary,
        widget.onPressed == null ? KickPulseColors.textTertiary : Colors.black,
        BorderSide.none,
      ),
      KickPulseButtonVariant.secondary => (
        KickPulseColors.surfaceSubtle,
        KickPulseColors.textPrimary,
        const BorderSide(color: KickPulseColors.borderSubtle),
      ),
      KickPulseButtonVariant.outline => (
        Colors.transparent,
        KickPulseColors.accentPrimary,
        const BorderSide(color: KickPulseColors.accentPrimary),
      ),
    };

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isBusy) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: 8.0),
        ] else if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: 8.0),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w700,
            color: fgColor,
          ),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.isFullWidth
            ? double.infinity
            : KickPulseRadiiSpacing.minTouchTarget,
        minHeight: KickPulseRadiiSpacing.minTouchTarget,
      ),
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
          side: borderSide,
        ),
        child: InkWell(
          borderRadius: KickPulseRadiiSpacing.chipBorderRadius,
          onTap: (widget.onPressed == null || isBusy) ? null : _handlePress,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Center(
              widthFactor: widget.isFullWidth ? 1.0 : null,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
