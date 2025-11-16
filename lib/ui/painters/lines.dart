import 'package:flutter/material.dart';
import 'package:parrotaac/extensions/canvas_extensions.dart';

enum SelectorType { vertical, horizontal, plusSign, checkMark }

class LinePaint extends StatelessWidget {
  final SelectorType type;
  const LinePaint({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: LinePainter(type: type));
  }
}

class LinePainter extends CustomPainter {
  final SelectorType type;

  LinePainter({super.repaint, required this.type});

  void _paintCheckmark(Canvas canvas, Size size, Paint paint) {
    final radius = size.width / 2; // width == height as you noted
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Ratios tuned to match a typical material-style checkmark
    final start = Offset(cx - radius * 0.45, cy + radius * 0.05);
    final mid = Offset(cx - radius * 0.10, cy + radius * 0.35);
    final end = Offset(cx + radius * 0.45, cy - radius * 0.35);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(mid.dx, mid.dy)
      ..lineTo(end.dx, end.dy);

    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..color = Colors.white;

    final center = Offset(size.width / 2, size.height / 2);
    if (type == SelectorType.vertical || type == SelectorType.plusSign) {
      canvas.paintVerticalLine(
        centerX: center.dx,
        centerY: center.dy,
        paint: paint,
        length: size.height * .8,
      );
    }
    if (type == SelectorType.horizontal || type == SelectorType.plusSign) {
      canvas.paintHorizontalLine(
        centerX: center.dx,
        centerY: center.dy,
        paint: paint,
        length: size.width * .8,
      );
    }

    if (type == SelectorType.checkMark) {
      _paintCheckmark(canvas, size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
