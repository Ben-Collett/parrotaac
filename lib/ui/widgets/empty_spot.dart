import 'dart:math';

import 'package:flutter/material.dart';
import 'package:parrotaac/extensions/canvas_extensions.dart';
import 'package:parrotaac/extensions/color_extensions.dart';

class EmptySpotWidget extends StatelessWidget {
  final Color color;
  const EmptySpotWidget({super.key, this.color = Colors.lightBlue});

  static Color fromBackground(Color color) {
    //TODO: I need to make sure that there is still a contrast for colorblind people using luminosity
    return color.isBluish() ? Colors.red : Colors.lightBlue;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _EmptyPainter(color: color));
  }
}

class _EmptyPainter extends CustomPainter {
  final Color color;

  _EmptyPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    const borderWidth = .03;
    const maxBorderWidth = 6;
    const padding = .005;

    final smallerSide = min(size.width, size.height);
    final borderStrokeSize = min(
      borderWidth * smallerSide,
      maxBorderWidth,
    ).toDouble();

    final radius = Radius.circular(borderStrokeSize);

    final plusSignThinkness = borderStrokeSize * .7;

    final paddingSize = padding * smallerSide;
    final paint = Paint()
      ..strokeWidth = borderStrokeSize
      ..color = color
      ..style = PaintingStyle.stroke;

    final shift = paddingSize + borderStrokeSize;
    final sizeShift = paddingSize + borderStrokeSize * 2;
    final Rect rect = Rect.fromLTWH(
      shift,
      shift,
      size.width - sizeShift,
      size.height - sizeShift,
    );

    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);

    paint.strokeWidth = plusSignThinkness;

    final plusSignLength = .3 * smallerSide;
    canvas.paintPlusSign(
      centerX: size.width / 2,
      centerY: size.height / 2,
      paint: paint,
      horizontalLength: plusSignLength,
      verticalLength: plusSignLength,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
