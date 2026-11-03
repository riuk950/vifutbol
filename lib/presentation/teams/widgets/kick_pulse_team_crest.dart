import 'package:flutter/material.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';

/// Native vector crest widget rendering athletic emblem shapes, club colors,
/// and uppercase shortCode monogram with 60 fps performance.
class KickPulseTeamCrest extends StatelessWidget {
  const KickPulseTeamCrest({
    super.key,
    required this.shortCode,
    this.crestShape = TeamCrestShape.shield,
    this.primaryColorHex = 0xFF00E676,
    this.secondaryColorHex = 0xFF0A0E17,
    this.size = 44.0,
  });

  final String shortCode;
  final TeamCrestShape crestShape;
  final int primaryColorHex;
  final int secondaryColorHex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cleanCode = shortCode.trim().toUpperCase();
    final primary = Color(primaryColorHex);
    final secondary = Color(secondaryColorHex);

    return Semantics(
      label: 'Escudo $cleanCode',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CrestPainter(
            shape: crestShape,
            primaryColor: primary,
            secondaryColor: secondary,
            shortCode: cleanCode,
          ),
        ),
      ),
    );
  }
}

class _CrestPainter extends CustomPainter {
  const _CrestPainter({
    required this.shape,
    required this.primaryColor,
    required this.secondaryColor,
    required this.shortCode,
  });

  final TeamCrestShape shape;
  final Color primaryColor;
  final Color secondaryColor;
  final String shortCode;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    // Subtle drop shadow / outer outline
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(path, shadowPaint);

    // Gradient fill using primary and secondary club colors
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, secondaryColor],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fillPaint);

    // Inner rim stroke
    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, strokePaint);

    // Centered monogram
    final fontSize = (size.width / (shortCode.length > 2 ? 3.2 : 2.5)).clamp(
      9.0,
      22.0,
    );
    final textSpan = TextSpan(
      text: shortCode,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: fontSize,
        letterSpacing: 0.5,
        shadows: const [
          Shadow(
            color: Colors.black87,
            offset: Offset(0.5, 1.0),
            blurRadius: 2.0,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.85);

    final textOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    switch (shape) {
      case TeamCrestShape.circle:
        path.addOval(Rect.fromLTWH(0, 0, w, h));
        break;

      case TeamCrestShape.diamond:
        path.moveTo(w / 2, 0);
        path.lineTo(w, h / 2);
        path.lineTo(w / 2, h);
        path.lineTo(0, h / 2);
        path.close();
        break;

      case TeamCrestShape.hexagon:
        path.moveTo(w * 0.25, 0);
        path.lineTo(w * 0.75, 0);
        path.lineTo(w, h * 0.5);
        path.lineTo(w * 0.75, h);
        path.lineTo(w * 0.25, h);
        path.lineTo(0, h * 0.5);
        path.close();
        break;

      case TeamCrestShape.shield:
        path.moveTo(0, h * 0.1);
        path.quadraticBezierTo(w * 0.5, 0, w, h * 0.1);
        path.lineTo(w, h * 0.58);
        path.quadraticBezierTo(w * 0.5, h, w * 0.5, h);
        path.quadraticBezierTo(0, h * 0.75, 0, h * 0.58);
        path.close();
        break;
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _CrestPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.shortCode != shortCode;
  }
}
