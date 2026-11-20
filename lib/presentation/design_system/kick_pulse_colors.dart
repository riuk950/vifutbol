import 'package:material_ui/material_ui.dart';

/// Semantic colors for KickPulse Mobile (DESIGN.md).
/// Dark-first high-contrast athletic theme.
class KickPulseColors {
  KickPulseColors._();

  // Background surfaces
  static const Color canvasBackground = Color(0xFF080B11);
  static const Color surfaceBase = Color(0xFF0E1422);
  static const Color surfaceElevated = Color(0xFF161F33);
  static const Color surfaceSubtle = Color(0xFF1D2840);
  static const Color glassOverlay = Color(0xCC0E1422);

  // Borders
  static const Color borderSubtle = Color(0xFF1F2C44);
  static const Color borderStrong = Color(0xFF2D3F60);

  // Accents and Signals
  static const Color accentPrimary = Color(0xFF22C55E); // Pitch green
  static const Color accentLive = Color(
    0xFFEF4444,
  ); // Live match pulse / Danger
  static const Color accentWarning = Color(
    0xFFF59E0B,
  ); // Offline warning / Caution
  static const Color accentElectric = Color(
    0xFF38BDF8,
  ); // Analytics / Informational

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF475569);
}
