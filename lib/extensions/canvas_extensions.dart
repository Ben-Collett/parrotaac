import 'dart:ui';

extension CanvasExtension on Canvas {
  void paintCircle({
    required Paint paint,
    double centerX = 0,
    double centerY = 0,
    double radius = 1,
    bool fill = true,
    bool outline = true,
    Color? fillColor,
    Color? outlineColor,
  }) {
    final startingColor = paint.color;
    final startingStyle = paint.style;

    if (fill) {
      paint.color = fillColor ?? startingColor;
      paint.style = PaintingStyle.fill;
      drawCircle(Offset(centerX, centerY), radius, paint);
    }
    if (outline) {
      paint.color = outlineColor ?? startingColor;
      paint.style = PaintingStyle.stroke;
      drawCircle(Offset(centerX, centerY), radius, paint);
    }
    paint.color = startingColor;
    paint.style = startingStyle;
  }

  void paintPlusSign(
      {required double centerX,
      required double centerY,
      required Paint paint,
      required double horizontalLength,
      required double verticalLength}) {
    paintHorizontalLine(
      centerX: centerX,
      centerY: centerY,
      paint: paint,
      length: horizontalLength,
    );

    paintVerticalLine(
        centerX: centerX,
        centerY: centerY,
        paint: paint,
        length: verticalLength);
  }

  void paintHorizontalLine({
    required double centerX,
    required double centerY,
    required Paint paint,
    required double length,
  }) {
    final p1 = Offset(centerX - length, centerY);
    final p2 = Offset(centerX + length, centerY);
    drawLine(p1, p2, paint);
  }

  void paintVerticalLine({
    required double centerX,
    required double centerY,
    required Paint paint,
    required double length,
  }) {
    final p1 = Offset(centerX, centerY - length);
    final p2 = Offset(centerX, centerY + length);
    drawLine(p1, p2, paint);
  }
}
