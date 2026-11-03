import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

void main() {
  group('KickPulse Design System Tokens', () {
    test(
      'Color tokens match KickPulse Mobile specification from DESIGN.md',
      () {
        expect(KickPulseColors.canvasBackground, const Color(0xFF080B11));
        expect(KickPulseColors.surfaceBase, const Color(0xFF0E1422));
        expect(KickPulseColors.surfaceElevated, const Color(0xFF161F33));
        expect(KickPulseColors.surfaceSubtle, const Color(0xFF1D2840));
        expect(KickPulseColors.borderSubtle, const Color(0xFF1F2C44));
        expect(KickPulseColors.borderStrong, const Color(0xFF2D3F60));
        expect(KickPulseColors.accentPrimary, const Color(0xFF22C55E));
        expect(KickPulseColors.accentLive, const Color(0xFFEF4444));
        expect(KickPulseColors.accentWarning, const Color(0xFFF59E0B));
        expect(KickPulseColors.accentElectric, const Color(0xFF38BDF8));
        expect(KickPulseColors.textPrimary, const Color(0xFFF8FAFC));
        expect(KickPulseColors.textSecondary, const Color(0xFF94A3B8));
        expect(KickPulseColors.textTertiary, const Color(0xFF64748B));
      },
    );

    test('Radii, spacing and minimum touch target match specifications', () {
      expect(KickPulseRadiiSpacing.cardRadius, 16.0);
      expect(KickPulseRadiiSpacing.chipRadius, 12.0);
      expect(KickPulseRadiiSpacing.badgeRadius, 9999.0);
      expect(KickPulseRadiiSpacing.minTouchTarget, 44.0);
      expect(KickPulseRadiiSpacing.spaceXs, 4.0);
      expect(KickPulseRadiiSpacing.spaceSm, 8.0);
      expect(KickPulseRadiiSpacing.spaceMd, 16.0);
      expect(KickPulseRadiiSpacing.spaceLg, 24.0);
      expect(KickPulseRadiiSpacing.spaceXl, 32.0);
    });

    test('Typography uses tabular numerals and correct scaling', () {
      final statStyle = KickPulseTypography.displayScore;
      expect(statStyle.fontFeatures?.any((f) => f.feature == 'tnum'), isTrue);
      expect(statStyle.fontSize, 32.0);

      final bodyStyle = KickPulseTypography.bodyPrimary;
      expect(bodyStyle.fontSize, 14.0);
    });

    test('KickPulseTheme produces dark ThemeData with correct brightness', () {
      final theme = KickPulseTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, KickPulseColors.canvasBackground);
    });
  });
}
