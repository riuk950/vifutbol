import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';

/// Native vector crest widget rendering athletic circular emblems, club colors,
/// optional circular club photograph (`crestUrl`), and uppercase shortCode monogram
/// fallback with 60 fps performance.
class KickPulseTeamCrest extends StatelessWidget {
  const KickPulseTeamCrest({
    super.key,
    required this.shortCode,
    this.crestShape = TeamCrestShape.circle,
    this.primaryColorHex = 0xFF00E676,
    this.secondaryColorHex = 0xFF0A0E17,
    this.crestUrl,
    this.size = 44.0,
  });

  final String shortCode;
  final TeamCrestShape crestShape;
  final int primaryColorHex;
  final int secondaryColorHex;
  final String? crestUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cleanCode = shortCode.trim().toUpperCase();
    final primary = Color(primaryColorHex);
    final secondary = Color(secondaryColorHex);

    final fallback = SizedBox(
      key: const Key('kick_pulse_team_crest_fallback'),
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CrestPainter(
          shape: TeamCrestShape.circle,
          primaryColor: primary,
          secondaryColor: secondary,
          shortCode: cleanCode,
        ),
      ),
    );

    final rawUrl = crestUrl?.trim();
    Widget content = fallback;

    if (rawUrl != null && rawUrl.isNotEmpty) {
      final isRemote =
          rawUrl.startsWith('http://') || rawUrl.startsWith('https://');
      Widget? imageWidget;
      if (isRemote) {
        imageWidget = Image.network(
          rawUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      } else {
        final file = File(rawUrl);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          );
        }
      }

      if (imageWidget != null) {
        content = Container(
          key: const Key('kick_pulse_team_crest_photo'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, secondary],
            ),
            border: Border.all(color: primary, width: 2.0),
          ),
          padding: const EdgeInsets.all(1.5),
          child: ClipOval(child: imageWidget),
        );
      }
    }

    return Semantics(
      label: 'Escudo $cleanCode',
      child: content,
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
    path.addOval(Rect.fromLTWH(0, 0, w, h));
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
