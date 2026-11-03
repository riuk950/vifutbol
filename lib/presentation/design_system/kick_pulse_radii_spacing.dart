import 'package:flutter/material.dart';

/// Geometry, radii, spacing and ergonomic constraints for KickPulse Mobile (DESIGN.md).
class KickPulseRadiiSpacing {
  KickPulseRadiiSpacing._();

  // Radii
  static const double cardRadius = 16.0;
  static const double chipRadius = 12.0;
  static const double badgeRadius = 9999.0; // Full pill

  // Spacing (8pt base system)
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;

  // Minimum interactive touch target (WCAG 2.1 / docs/MOBILE_GUIDELINES.md)
  static const double minTouchTarget = 44.0;

  // BorderRadius helpers
  static final BorderRadius cardBorderRadius = BorderRadius.circular(
    cardRadius,
  );
  static final BorderRadius chipBorderRadius = BorderRadius.circular(
    chipRadius,
  );
  static final BorderRadius badgeBorderRadius = BorderRadius.circular(
    badgeRadius,
  );
}
