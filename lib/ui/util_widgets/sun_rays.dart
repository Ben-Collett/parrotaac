import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class SunRaysPainter extends CustomPainter {
  final double rotation;

  SunRaysPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.6;

    final paint = Paint()
      ..color = const Color(0xFFFFF3B0)
          .withOpacity(0.35) // white-yellow glow
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    const rays = 12;
    final angleStep = 2 * 3.1415926535 / rays;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    for (int i = 0; i < rays; i++) {
      final angle = i * angleStep;
      final dx = radius * math.cos(angle);
      final dy = radius * math.sin(angle);
      canvas.drawLine(Offset.zero, Offset(dx, dy), paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SunRaysPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}
