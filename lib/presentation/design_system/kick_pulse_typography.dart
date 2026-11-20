import 'package:material_ui/material_ui.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';

/// Typography scale for KickPulse Mobile with mandatory tabular numerals (FR-004).
class KickPulseTypography {
  KickPulseTypography._();

  static const List<FontFeature> tabularFontFeatures = [
    FontFeature.tabularFigures(),
    FontFeature.liningFigures(),
  ];

  static const TextStyle displayScore = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: KickPulseColors.textPrimary,
    fontFeatures: tabularFontFeatures,
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: KickPulseColors.textPrimary,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: KickPulseColors.textSecondary,
    letterSpacing: 0.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    color: KickPulseColors.textPrimary,
  );

  static const TextStyle bodyPrimary = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: KickPulseColors.textPrimary,
  );

  static const TextStyle captionMeta = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: KickPulseColors.textSecondary,
    fontFeatures: tabularFontFeatures,
  );

  static const TextStyle microBadge = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: KickPulseColors.textPrimary,
  );

  /// Returns a tabular-nums (`FontFeature.tabularFigures()`) text style for
  /// standings tables, scores, and sports rankings (`FR-010`).
  static TextStyle statMetric({
    double size = 13.0,
    FontWeight weight = FontWeight.w600,
    Color color = KickPulseColors.textPrimary,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFeatures: tabularFontFeatures,
    );
  }
}
