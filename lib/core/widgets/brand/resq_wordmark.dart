import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class ResQWordmark extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final bool showTagline;
  final bool isLightBackground;

  const ResQWordmark({
    super.key,
    this.fontSize = 32,
    this.color,
    this.showTagline = false,
    this.isLightBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ??
        (isLightBackground ? AppColors.lightTextNavy : Colors.white);
    final aquaColor = AppColors.aquaAccent;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Res',
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -1.2,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 2),
              CustomPaint(
                size: Size(fontSize * 0.95, fontSize * 0.95),
                painter: _ResQLogoPainter(
                  ringColor: aquaColor,
                  pinDotColor: aquaColor,
                  tailColor: aquaColor,
                ),
              ),
            ],
          ),
          if (showTagline) ...[
            const SizedBox(height: 6),
            Text(
              'Closer to Help, Closer to Hope.',
              style: GoogleFonts.inter(
                fontSize: (fontSize * 0.36).clamp(11.0, 14.0),
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: 0.8),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom painter for the ResQ "Q" symbol:
/// An aqua ring with a road-style highway tail and a centre map-pin dot.
class _ResQLogoPainter extends CustomPainter {
  final Color ringColor;
  final Color pinDotColor;
  final Color tailColor;

  _ResQLogoPainter({
    required this.ringColor,
    required this.pinDotColor,
    required this.tailColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.16;
    final center = Offset(size.width * 0.46, size.height * 0.46);
    final radius = (size.width * 0.42) - (strokeWidth / 2);

    // 1. Aqua outer circular ring
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, ringPaint);

    // 2. Center map pin dot
    final dotPaint = Paint()
      ..color = pinDotColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.32, dotPaint);

    // 3. Road-style highway tail extending from the bottom-right
    final tailPaint = Paint()
      ..color = tailColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.05
      ..strokeCap = StrokeCap.round;

    final tailPath = Path()
      ..moveTo(center.dx + radius * 0.65, center.dy + radius * 0.65)
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.86,
        size.width * 0.98,
        size.height * 0.98,
      );

    canvas.drawPath(tailPath, tailPaint);
  }

  @override
  bool shouldRepaint(covariant _ResQLogoPainter oldDelegate) => false;
}
