import 'package:flutter/material.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

/// Dark-first ThemeData for KickPulse Mobile (DESIGN.md).
class KickPulseTheme {
  KickPulseTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: KickPulseColors.canvasBackground,
      colorScheme: const ColorScheme.dark(
        primary: KickPulseColors.accentPrimary,
        secondary: KickPulseColors.accentElectric,
        surface: KickPulseColors.surfaceBase,
        error: KickPulseColors.accentLive,
        onPrimary: Colors.black,
        onSurface: KickPulseColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: KickPulseColors.surfaceBase,
        foregroundColor: KickPulseColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: KickPulseTypography.screenTitle,
      ),
      cardTheme: CardThemeData(
        color: KickPulseColors.surfaceBase,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: KickPulseRadiiSpacing.cardBorderRadius,
          side: const BorderSide(
            color: KickPulseColors.borderSubtle,
            width: 1.0,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: KickPulseColors.surfaceBase,
        indicatorColor: KickPulseColors.surfaceSubtle,
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: KickPulseColors.accentPrimary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: KickPulseColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: KickPulseColors.accentPrimary);
          }
          return const IconThemeData(color: KickPulseColors.textSecondary);
        }),
      ),
    );
  }
}
