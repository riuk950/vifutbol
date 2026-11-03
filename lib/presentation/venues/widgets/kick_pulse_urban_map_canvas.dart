import 'package:flutter/material.dart';
import 'package:vifutbol/domain/entities/geo_coordinate.dart';
import 'package:vifutbol/domain/entities/sports_venue.dart';
import 'package:vifutbol/domain/entities/venue_enums.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';

/// Offline-ready, tactical urban map canvas designed to visualize sports venues,
/// proximity, and interactive coordinate selection without third-party API keys.
class KickPulseUrbanMapCanvas extends StatelessWidget {
  const KickPulseUrbanMapCanvas({
    super.key,
    required this.centerCoordinate,
    this.venues = const [],
    this.selectedVenueId,
    this.userCoordinate,
    this.pickedCoordinate,
    this.onVenueSelected,
    this.onCoordinatePicked,
    this.height = 220,
    this.isPickerMode = false,
  });

  final GeoCoordinate centerCoordinate;
  final List<SportsVenue> venues;
  final String? selectedVenueId;
  final GeoCoordinate? userCoordinate;
  final GeoCoordinate? pickedCoordinate;
  final ValueChanged<SportsVenue>? onVenueSelected;
  final ValueChanged<GeoCoordinate>? onCoordinatePicked;
  final double height;
  final bool isPickerMode;

  // Coordinate projection constant: degrees to pixels at default zoom
  static const double _coordScale = 1200.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceBase,
        borderRadius: KickPulseRadiiSpacing.cardBorderRadius,
        border: Border.all(color: KickPulseColors.borderSubtle, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final localPos = details.localPosition;
              final picked = _pixelToCoordinate(localPos, size);

              if (isPickerMode) {
                onCoordinatePicked?.call(picked);
                return;
              }

              // Check if any venue marker was tapped (hit-test radius 24px)
              for (final venue in venues) {
                final venuePos = _coordinateToPixel(venue.coordinate, size);
                final distance = (localPos - venuePos).distance;
                if (distance <= 24.0) {
                  onVenueSelected?.call(venue);
                  return;
                }
              }

              // If tapped outside a venue in exploration mode, optionally report coordinate
              onCoordinatePicked?.call(picked);
            },
            child: CustomPaint(
              size: size,
              painter: _UrbanMapPainter(
                centerCoordinate: centerCoordinate,
                venues: venues,
                selectedVenueId: selectedVenueId,
                userCoordinate: userCoordinate,
                pickedCoordinate: pickedCoordinate,
                isPickerMode: isPickerMode,
              ),
            ),
          );
        },
      ),
    );
  }

  Offset _coordinateToPixel(GeoCoordinate coord, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    final double deltaLng = coord.longitude - centerCoordinate.longitude;
    final double deltaLat = coord.latitude - centerCoordinate.latitude;

    final double x = centerX + deltaLng * _coordScale;
    final double y = centerY - deltaLat * _coordScale;

    return Offset(x, y);
  }

  GeoCoordinate _pixelToCoordinate(Offset pixel, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    final double deltaX = pixel.dx - centerX;
    final double deltaY = pixel.dy - centerY;

    final double lng = centerCoordinate.longitude + (deltaX / _coordScale);
    final double lat = centerCoordinate.latitude - (deltaY / _coordScale);

    // Clamped to valid domain range
    final double clampedLat = lat.clamp(-90.0, 90.0);
    final double clampedLng = lng.clamp(-180.0, 180.0);

    return GeoCoordinate(
      latitude: double.parse(clampedLat.toStringAsFixed(4)),
      longitude: double.parse(clampedLng.toStringAsFixed(4)),
    );
  }
}

class _UrbanMapPainter extends CustomPainter {
  const _UrbanMapPainter({
    required this.centerCoordinate,
    required this.venues,
    required this.selectedVenueId,
    required this.userCoordinate,
    required this.pickedCoordinate,
    required this.isPickerMode,
  });

  final GeoCoordinate centerCoordinate;
  final List<SportsVenue> venues;
  final String? selectedVenueId;
  final GeoCoordinate? userCoordinate;
  final GeoCoordinate? pickedCoordinate;
  final bool isPickerMode;

  static const double _coordScale = 1200.0;

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // 1. Draw canvas background and urban grid
    final bgPaint = Paint()..color = KickPulseColors.canvasBackground;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final gridPaint = Paint()
      ..color = KickPulseColors.surfaceElevated.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;

    const double step = 32.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Tactical radar rings around center
    final radarPaint = Paint()
      ..color = KickPulseColors.accentElectric.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset(centerX, centerY), 40.0, radarPaint);
    canvas.drawCircle(Offset(centerX, centerY), 90.0, radarPaint);
    canvas.drawCircle(Offset(centerX, centerY), 150.0, radarPaint);

    // Subtle crosshair at center
    final crossPaint = Paint()
      ..color = KickPulseColors.borderStrong.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(centerX - 12, centerY),
      Offset(centerX + 12, centerY),
      crossPaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - 12),
      Offset(centerX, centerY + 12),
      crossPaint,
    );

    // 3. Draw venue markers
    for (final venue in venues) {
      final isSelected = venue.id == selectedVenueId;
      final pos = _toPixel(venue.coordinate, size);

      // Skip drawing if outside canvas boundaries + padding
      if (pos.dx < -20 ||
          pos.dx > size.width + 20 ||
          pos.dy < -20 ||
          pos.dy > size.height + 20) {
        continue;
      }

      final Color markerColor = venue.status == VenueOperationalStatus.active
          ? KickPulseColors.accentPrimary
          : KickPulseColors.accentWarning;

      // Glow / outer ring for selected venue
      if (isSelected) {
        final glowPaint = Paint()
          ..color = markerColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, 16.0, glowPaint);

        final ringPaint = Paint()
          ..color = markerColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(pos, 12.0, ringPaint);
      }

      // Marker base
      final dotPaint = Paint()..color = markerColor;
      canvas.drawCircle(pos, isSelected ? 8.0 : 6.0, dotPaint);

      // Inner tactical center dot
      final innerPaint = Paint()..color = KickPulseColors.surfaceBase;
      canvas.drawCircle(pos, 2.5, innerPaint);
    }

    // 4. Draw User location marker (if granted)
    if (userCoordinate != null) {
      final userPos = _toPixel(userCoordinate!, size);

      final pulsePaint = Paint()
        ..color = KickPulseColors.accentElectric.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(userPos, 14.0, pulsePaint);

      final userDotPaint = Paint()..color = KickPulseColors.accentElectric;
      canvas.drawCircle(userPos, 6.0, userDotPaint);

      final innerUserPaint = Paint()..color = Colors.white;
      canvas.drawCircle(userPos, 2.0, innerUserPaint);
    }

    // 5. Draw Picked coordinate marker (in picker mode or form)
    if (pickedCoordinate != null) {
      final pickedPos = _toPixel(pickedCoordinate!, size);

      final crosshairPaint = Paint()
        ..color = KickPulseColors.accentElectric
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(pickedPos, 10.0, crosshairPaint);
      canvas.drawLine(
        Offset(pickedPos.dx - 16, pickedPos.dy),
        Offset(pickedPos.dx + 16, pickedPos.dy),
        crosshairPaint,
      );
      canvas.drawLine(
        Offset(pickedPos.dx, pickedPos.dy - 16),
        Offset(pickedPos.dx, pickedPos.dy + 16),
        crosshairPaint,
      );
    }
  }

  Offset _toPixel(GeoCoordinate coord, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    final double deltaLng = coord.longitude - centerCoordinate.longitude;
    final double deltaLat = coord.latitude - centerCoordinate.latitude;

    final double x = centerX + deltaLng * _coordScale;
    final double y = centerY - deltaLat * _coordScale;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _UrbanMapPainter oldDelegate) {
    return oldDelegate.centerCoordinate != centerCoordinate ||
        oldDelegate.selectedVenueId != selectedVenueId ||
        oldDelegate.userCoordinate != userCoordinate ||
        oldDelegate.pickedCoordinate != pickedCoordinate ||
        oldDelegate.isPickerMode != isPickerMode ||
        oldDelegate.venues != venues;
  }
}
