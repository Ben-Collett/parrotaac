import 'package:flutter/material.dart';

class HeartPainter extends CustomPainter {
  final Color color;

  const HeartPainter({this.color = Colors.red});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw a subtle drop shadow behind the heart
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha((0.12 * 255).truncate())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..isAntiAlias = true;

    final path = Path();

    // Build a heart using cubic Bezier curves scaled to the size
    // Path points are relative to the bounding box, so heart scales nicely.
    final w = size.width;
    final h = size.height;

    // Move to bottom center
    path.moveTo(w * 0.5, h * 0.9);

    // Right half
    path.cubicTo(
      w * 1.05,
      h * 0.6, // control point 1
      w * 0.85,
      h * 0.1, // control point 2
      w * 0.5,
      h * 0.3, // end point (top center-ish)
    );

    // Left half (mirror)
    path.cubicTo(
      w * 0.15,
      h * 0.1, // control point 3
      w * -0.05,
      h * 0.6, // control point 4
      w * 0.5,
      h * 0.9, // back to bottom center
    );

    // Draw shadow slightly offset
    final shadowPath = path.shift(Offset(0, h * 0.03));
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw the heart
    canvas.drawPath(path, paint);

    // Optional: subtle highlight along the top-left lobe
    final highlightPaint = Paint()
      ..color = Colors.white.withAlpha((0.12 * 255).truncate())
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final highlight = Path()
      ..moveTo(w * 0.5, h * 0.32)
      ..cubicTo(w * 0.7, h * 0.18, w * 0.85, h * 0.22, w * 0.68, h * 0.36)
      ..arcToPoint(Offset(w * 0.58, h * 0.38), radius: Radius.circular(w * 0.1))
      ..close();
    canvas.drawPath(highlight, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant HeartPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
