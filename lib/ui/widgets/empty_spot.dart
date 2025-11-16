import 'dart:math';

import 'package:flutter/material.dart';
import 'package:parrotaac/extensions/canvas_extensions.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';

class EmptySpotWidget extends StatelessWidget
    with SelectIndecatorStatusDimensions {
  final Color color;
  const EmptySpotWidget({super.key, this.color = Colors.lightBlue});

  static Color fromBackground(Color color) {
    //TODO: I need to make sure that there is still a contrast for colorblind people using luminosity
    return color.isBluish() ? Colors.red : Colors.lightBlue;
  }

  @override
  Offset selectIndecatorOffset(Size size) {
    final shortSide = size.shortestSide;
    final shift =
        _EmptyPainter.computePaddingSize(shortSide) +
        2 * _EmptyPainter.computeBorderStrokeSize(shortSide);
    return Offset(shift, shift);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _EmptyPainter(color: color));
  }
}

class _EmptyPainter extends CustomPainter {
  final Color color;

  _EmptyPainter({required this.color});

  static const maxBorderWidth = 6;
  static const paddingPreportion = .005;
  static const borderWidthPreportion = .03;

  static double computeBorderStrokeSize(double shortSide) =>
      min(borderWidthPreportion * shortSide, maxBorderWidth).toDouble();
  static double computePaddingSize(double shortSide) =>
      paddingPreportion * shortSide;

  @override
  void paint(Canvas canvas, Size size) {
    final smallerSide = size.shortestSide;
    final borderStrokeSize = computeBorderStrokeSize(size.shortestSide);
    final radius = Radius.circular(borderStrokeSize);

    final plusSignThinkness = borderStrokeSize * .7;

    final paddingSize = computePaddingSize(smallerSide);
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
