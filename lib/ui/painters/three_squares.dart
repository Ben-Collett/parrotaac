import 'dart:math';

import 'package:flutter/material.dart';
import 'package:parrotaac/extensions/canvas_extensions.dart';

class ThreeSquarePainter extends CustomPainter {
  final RectangleOrientation orientation;
  final CircleType circleType;
  final Color foregroundColor;

  const ThreeSquarePainter({
    this.orientation = RectangleOrientation.vertical,
    this.circleType = CircleType.none,
    this.foregroundColor = Colors.black,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = foregroundColor;
    double left = orientation.leftPreportion * size.width;
    double top = orientation.topPreportion * size.height;
    double width = orientation.widthPreporiton * size.width;
    double height = orientation.heightPreportion * size.height;

    double circleCenterX = left + width;
    double circleCenterY = top + height;
    double radius = min(size.height - top - height, size.width - width - left);

    double horizontalLineLength = .5 * radius;
    double verticalLineLength = .55 * radius;

    canvas.drawRect(Rect.fromLTWH(left, top, width, height), paint);

    _paintInsideLines(canvas, paint, top, left, width, height);

    if (circleType != CircleType.none) {
      _paintCircle(
        canvas,
        paint,
        foregroundColor,
        circleCenterX,
        circleCenterY,
        radius,
        horizontalLineLength,
        verticalLineLength,
      );
    }
  }

  void _paintInsideLines(
    Canvas canvas,
    Paint paint,
    double top,
    double left,
    double width,
    double height,
  ) {
    const numberOfLinesToDraw = 2;
    if (orientation == RectangleOrientation.vertical) {
      for (int i = 1; i <= numberOfLinesToDraw; i++) {
        final double y = top + height * i / (numberOfLinesToDraw + 1);
        canvas.drawLine(
          Offset(
            left,
            y,
          ),
          Offset(left + width, y),
          paint,
        );
      }
    } else {
      for (int i = 1; i <= numberOfLinesToDraw; i++) {
        double x = left + width * i / (numberOfLinesToDraw + 1);
        canvas.drawLine(
          Offset(
            x,
            top,
          ),
          Offset(x, top + height),
          paint,
        );
      }
    }
  }

  void _paintCircle(
    Canvas canvas,
    Paint paint,
    Color outlineColor,
    double centerX,
    double centerY,
    double radius,
    double horizontalLineLength,
    double verticalLineLength,
  ) {
    canvas.paintCircle(
        paint: paint,
        centerX: centerX,
        centerY: centerY,
        radius: radius,
        fillColor: circleType.color,
        outlineColor: outlineColor);

    paint.color = Colors.white;
    paint.strokeWidth = 2;

    if (circleType == CircleType.add) {
      canvas.paintPlusSign(
          centerX: centerX,
          centerY: centerY,
          paint: paint,
          horizontalLength: horizontalLineLength,
          verticalLength: verticalLineLength);
    } else if (circleType == CircleType.subtract) {
      canvas.paintHorizontalLine(
        centerX: centerX,
        centerY: centerY,
        paint: paint,
        length: horizontalLineLength,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum CircleType {
  none(null),
  add(Color.from(alpha: 1, red: 0, green: .7, blue: 0)),
  subtract(Colors.red);

  final Color? color;
  const CircleType(this.color);
}

enum RectangleOrientation {
  vertical(
      leftPreportion: .1,
      topPreportion: 0.05,
      widthPreporiton: .6,
      heightPreportion: .8),
  horizontal(
      leftPreportion: 0.05,
      topPreportion: .1,
      widthPreporiton: .8,
      heightPreportion: .6);

  final double leftPreportion;
  final double topPreportion;
  final double heightPreportion;
  final double widthPreporiton;
  const RectangleOrientation({
    required this.leftPreportion,
    required this.topPreportion,
    required this.widthPreporiton,
    required this.heightPreportion,
  });
}
