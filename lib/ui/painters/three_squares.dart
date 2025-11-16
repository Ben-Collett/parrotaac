import 'dart:math';

import 'package:flutter/material.dart';
import 'package:parrotaac/extensions/canvas_extensions.dart';

class AnimatedDashedRectangle extends StatefulWidget {
  final ValueNotifier notifier;
  final dynamic valueToRunOn;
  final RectangleOrientation orientation;
  final int squareCount;
  final Color foregroundColor;
  const AnimatedDashedRectangle({
    super.key,
    required this.notifier,
    required this.valueToRunOn,
    required this.orientation,
    required this.foregroundColor,
    this.squareCount = 3,
  });

  @override
  State<AnimatedDashedRectangle> createState() =>
      _AnimatedDashedRectangleState();
}

class _AnimatedDashedRectangleState extends State<AnimatedDashedRectangle>
    with TickerProviderStateMixin {
  late final AnimationController animationController;

  void _updateIsRunning() {
    if (widget.notifier.value == widget.valueToRunOn) {
      animationController.repeat();
    } else {
      animationController.stop();
    }
  }

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    widget.notifier.addListener(_updateIsRunning);
    _updateIsRunning();
    super.initState();
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_updateIsRunning);
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedMultiSquarePainter(
        controller: animationController,
        foregroundColor: widget.foregroundColor,
        squareCount: widget.squareCount,
        orientation: widget.orientation,
      ),
    );
  }
}

/// Base class that handles all geometry, circle logic,
/// square subdivision, etc.
/// Subclasses customize only how a line is drawn.
abstract class BaseMultiSquarePainter extends CustomPainter {
  final RectangleOrientation orientation;
  final CircleType circleType;
  final Color foregroundColor;
  final int squareCount;

  const BaseMultiSquarePainter({
    super.repaint,
    this.orientation = RectangleOrientation.vertical,
    this.circleType = CircleType.none,
    this.foregroundColor = Colors.black,
    this.squareCount = 3,
  });

  /// Subclasses override this to implement:
  /// - solid lines
  /// - dashed lines
  /// - animated dashed lines
  void drawOuterline(Canvas canvas, Offset a, Offset b, Paint paint);

  void drawOutline(Canvas canvas, Size size, Paint paint) {
    final left = orientation.leftPreportion * size.width;
    final top = orientation.topPreportion * size.height;
    final width = orientation.widthPreporiton * size.width;
    final height = orientation.heightPreportion * size.height;

    drawOuterline(canvas, Offset(left, top), Offset(left + width, top), paint);
    drawOuterline(
      canvas,
      Offset(left + width, top),
      Offset(left + width, top + height),
      paint,
    );
    drawOuterline(
      canvas,
      Offset(left + width, top + height),
      Offset(left, top + height),
      paint,
    );
    drawOuterline(canvas, Offset(left, top + height), Offset(left, top), paint);
  }

  void drawInternalLine(Canvas canvas, Offset a, Offset b, Paint paint);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = foregroundColor;

    // Core rectangle geometry
    final left = orientation.leftPreportion * size.width;
    final top = orientation.topPreportion * size.height;
    final width = orientation.widthPreporiton * size.width;
    final height = orientation.heightPreportion * size.height;

    // Circle geometry
    final circleCenterX = left + width;
    final circleCenterY = top + height;
    final radius = min(size.height - top - height, size.width - width - left);

    final horizontalLineLength = .5 * radius;
    final verticalLineLength = .55 * radius;

    // Outer rectangle
    drawOutline(canvas, size, paint);

    // Internal subdivisions
    _paintInsideLines(canvas, paint, left, top, width, height);

    if (circleType != CircleType.none) {
      _paintCircle(
        canvas,
        paint,
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
    double left,
    double top,
    double width,
    double height,
  ) {
    final numberOfLines = squareCount - 1;

    if (orientation == RectangleOrientation.vertical) {
      for (int i = 1; i <= numberOfLines; i++) {
        final y = top + height * i / (numberOfLines + 1);
        drawInternalLine(
          canvas,
          Offset(left, y),
          Offset(left + width, y),
          paint,
        );
      }
    } else if (orientation == RectangleOrientation.horizontal) {
      for (int i = 1; i <= numberOfLines; i++) {
        final x = left + width * i / (numberOfLines + 1);
        drawInternalLine(
          canvas,
          Offset(x, top),
          Offset(x, top + height),
          paint,
        );
      }
    }
  }

  void _paintCircle(
    Canvas canvas,
    Paint paint,
    double cx,
    double cy,
    double radius,
    double hLen,
    double vLen,
  ) {
    canvas.paintCircle(
      paint: paint,
      centerX: cx,
      centerY: cy,
      radius: radius,
      fillColor: circleType.color,
      outlineColor: foregroundColor,
    );

    paint
      ..color = Colors.white
      ..strokeWidth = 2;

    if (circleType == CircleType.add) {
      canvas.paintPlusSign(
        centerX: cx,
        centerY: cy,
        paint: paint,
        horizontalLength: hLen * 2,
        verticalLength: vLen * 2,
      );
    } else if (circleType == CircleType.subtract) {
      canvas.paintHorizontalLine(
        centerX: cx,
        centerY: cy,
        paint: paint,
        length: hLen * 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MultiSquarePainter extends BaseMultiSquarePainter {
  const MultiSquarePainter({
    super.orientation,
    super.circleType,
    super.foregroundColor,
    super.squareCount,
  });

  @override
  void drawOuterline(Canvas canvas, Offset a, Offset b, Paint paint) {
    canvas.drawLine(a, b, paint);
  }

  @override
  void drawInternalLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    canvas.drawLine(a, b, paint);
  }
}

class DashedMultiSquarePainter extends BaseMultiSquarePainter {
  final double dashLength;
  final double gapLength;
  final AnimationController controller;
  double get animationValue => controller.value;

  const DashedMultiSquarePainter({
    super.orientation,
    super.circleType,
    super.foregroundColor,
    super.squareCount,
    required this.controller,
    this.dashLength = 4,
    this.gapLength = 3,
  }) : super(repaint: controller);

  void _paintDash(
    Canvas canvas,
    Paint paint,
    Rect rect,
    double start,
    double end,
  ) {
    final double left = rect.left;
    final double top = rect.top;
    final double W = rect.width;
    final double H = rect.height;

    Offset pointAt(double d) {
      if (d <= W) {
        return Offset(left + d, top); // top
      } else if (d <= W + H) {
        return Offset(left + W, top + (d - W)); // right
      } else if (d <= 2 * W + H) {
        return Offset(left + W - (d - (W + H)), top + H); // bottom
      } else {
        return Offset(left, top + H - (d - (2 * W + H))); // left
      }
    }

    void paintSegment(double s, double e) {
      final p1 = pointAt(s);
      final p2 = pointAt(e);
      canvas.drawLine(p1, p2, paint);
    }

    final double c1 = W;
    final double c2 = W + H;
    final double c3 = 2 * W + H;
    final double c4 = 2 * W + 2 * H;

    double s = start;
    double e = end;

    if (s < c1) {
      final segEnd = min(e, c1);
      paintSegment(s, segEnd);
      s = segEnd;
    }
    if (s >= e) return;

    if (s < c2) {
      final segEnd = min(e, c2);
      paintSegment(s, segEnd);
      s = segEnd;
    }
    if (s >= e) return;

    if (s < c3) {
      final segEnd = min(e, c3);
      paintSegment(s, segEnd);
      s = segEnd;
    }
    if (s >= e) return;

    if (s < c4) {
      final segEnd = min(e, c4);
      paintSegment(s, segEnd);
      s = segEnd;
    }
  }

  @override
  void drawOutline(Canvas canvas, Size size, Paint paint) {
    final double left = orientation.leftPreportion * size.width;
    final double top = orientation.topPreportion * size.height;

    final double W = orientation.widthPreporiton * size.width;
    final double H = orientation.heightPreportion * size.height;

    // Rectangle origin
    final Rect rect = Rect.fromLTWH(left, top, W, H);

    final double perimeter = 2 * (W + H);
    final double period = dashLength + gapLength;

    // marching ants offset (wraps cleanly)
    final double offset = (animationValue * period) % period;

    // iterate over every dash until fully around the rectangle
    double position = -offset;

    while (position < perimeter) {
      final start = position;
      final end = position + dashLength;

      if (end > 0 && start < perimeter) {
        _paintDash(
          canvas,
          paint,
          rect, // ⬅ pass offset rect instead of size
          max(0, start),
          min(perimeter, end),
        );
      }

      position += period;
    }
  }

  @override
  void drawOuterline(Canvas canvas, Offset a, Offset b, Paint paint) {
    final totalLength = (b - a).distance;
    final direction = (b - a) / totalLength;

    double distance = 0;
    while (distance < totalLength) {
      final start = a + direction * distance;
      final end = a + direction * min(distance + dashLength, totalLength);
      canvas.drawLine(start, end, paint);
      distance += dashLength + gapLength;
    }
  }

  @override
  void drawInternalLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    canvas.drawLine(a, b, paint);
  }
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
    heightPreportion: .8,
  ),

  square(
    leftPreportion: .1,
    topPreportion: .1,
    widthPreporiton: .8,
    heightPreportion: .8,
  ),
  horizontal(
    leftPreportion: 0.05,
    topPreportion: .1,
    widthPreporiton: .8,
    heightPreportion: .6,
  );

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
