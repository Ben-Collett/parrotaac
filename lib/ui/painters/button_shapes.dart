import 'dart:math';

import 'package:flutter/material.dart';
import 'package:parrotaac/ui/painters/path_from_points.dart';

enum ParrotButtonShape {
  folder("folder"),
  square("square");

  static ParrotButtonShape? fromString(String? label) {
    return values.where((val) => val.label == label).firstOrNull;
  }

  final String label;
  const ParrotButtonShape(this.label);
}

class ShapedButton extends StatelessWidget {
  final Widget? image;
  final Widget? text;
  final ParrotButtonShape shape;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  const ShapedButton(
      {super.key,
      this.image,
      this.text,
      this.onPressed,
      this.onLongPress,
      required this.backgroundColor,
      required this.shape,
      required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final double textHeight;
        if (text == null) {
          textHeight = 0;
        } else if (image == null) {
          textHeight = 1;
        } else {
          //TODO: I really need to dynamically determine this so the sentence bar look better on different size screens
          textHeight = 0.25;
        }
        final _ParrotButtonPainter painter;
        if (shape == ParrotButtonShape.square) {
          painter = _SquareButtonPainter(
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            textHeightPreportion: textHeight,
          );
        } else {
          painter = _FolderButtonPainter(
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            textHeightPreportion: textHeight,
          );
        }
        final imageRect =
            painter.imagePaintArea(size, painter.computeBorderSize(size));
        final textRect =
            painter.textPaintArea(size, painter.computeBorderSize(size));
        return GestureDetector(
          onTap: onPressed,
          onLongPress: onLongPress,
          child: Stack(
            children: [
              SizedBox(
                width: size.width,
                height: size.height,
                child: CustomPaint(
                  painter: painter,
                ),
              ),
              if (image != null)
                Positioned.fromRect(rect: imageRect, child: image!),
              if (text != null)
                Positioned.fromRect(rect: textRect, child: text!)
            ],
          ),
        );
      },
    );
  }
}

abstract class _ParrotButtonPainter extends CustomPainter {
  Rect imagePaintArea(Size size, double borderSize);
  Rect textPaintArea(Size size, double borderSize);
  double computeBorderSize(Size size);
}

class _FolderButtonPainter extends _ParrotButtonPainter {
  final Color backgroundColor;
  final Color borderColor;
  final double? textHeightPreportion;
  final double borderWidthPreportion;
  final double tabHeightPreportion;
  final double tabTopWidthPreportion;
  final double tabBottomWidthPreportion;
  final double imageWidthPreportion;
  final bool paintPaintAreas;
  _FolderButtonPainter(
      {required this.backgroundColor,
      required this.borderColor,
      this.borderWidthPreportion = 0.05,
      this.tabTopWidthPreportion = 0.25,
      this.tabBottomWidthPreportion = 0.3,
      this.tabHeightPreportion = 0.09,
      this.imageWidthPreportion = .85,
      this.paintPaintAreas = false,
      this.textHeightPreportion});
  @override
  double computeBorderSize(Size size) =>
      computeBorderSizeFromPreportion(size, borderWidthPreportion);

  @override
  Rect imagePaintArea(Size size, double borderSize) {
    size = Size(size.width, size.height * (1 - tabHeightPreportion));
    Rect rect = determineImagePaintAreaRect(
      size: size,
      borderSize: borderSize,
      borderWidthPreportion: borderWidthPreportion,
      imageWidthPreportion: imageWidthPreportion,
      textHeightPreportion: textHeightPreportion,
    );
    if (rect == Rect.zero) return rect;
    rect = rect.shift(Offset(0, tabHeightPreportion * size.height));

    return rect;
  }

  @override
  Rect textPaintArea(Size size, double borderSize) {
    if (textHeightPreportion == null) return Rect.zero;
    final imageArea = imagePaintArea(size, borderSize);
    double top = imageArea == Rect.zero
        ? size.height * tabHeightPreportion + computeBorderSize(size) / 2
        : imageArea.bottom;

    return Rect.fromLTWH(
      borderSize,
      top,
      size.width - borderSize * 2,
      textHeightPreportion! * size.height,
    );
  }

  Path _folderPath(Size size, double strokeWidth) {
    final tabHeight = tabHeightPreportion * size.height;
    final tabBottomWidth = tabBottomWidthPreportion * size.width;
    final tabTopWidth = tabTopWidthPreportion * size.width;

    final shift = strokeWidth / 2;

    final topLeft = Offset(shift, shift);
    final bottomLeft = Offset(shift, size.height - shift);
    final bottomRight = Offset(size.width - shift, size.height - shift);
    final topRight = Offset(size.width - shift, tabHeight);
    final tabRightBottom = Offset(tabBottomWidth, tabHeight);
    final tabRightTop = Offset(tabTopWidth - shift, shift);
    final finish = Offset(0, shift);

    return pathFromPoints([
      topLeft,
      bottomLeft,
      bottomRight,
      topRight,
      tabRightBottom,
      tabRightTop,
      finish
    ]);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final borderSize = computeBorderSize(size);
    Paint paint = Paint()
      ..color = backgroundColor
      ..strokeWidth = borderSize
      ..style = PaintingStyle.fill;
    Path path = _folderPath(size, borderSize);
    canvas.drawPath(path, paint);

    paint.color = borderColor;
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);

    if (paintPaintAreas) {
      paint.style = PaintingStyle.fill;
      paint.color = Colors.green;
      canvas.drawRect(imagePaintArea(size, borderSize), paint);
      paint.color = Colors.purple;
      canvas.drawRect(textPaintArea(size, borderSize), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SquareButtonPainter extends _ParrotButtonPainter {
  final Color? borderColor;
  final double borderWidthPreportion;
  final double imageWidthPreportion;
  double? textHeightPreportion;
  final Color backgroundColor;
  final bool paintPaintAreas;

  ///[textHeightPreportion] and [imageHeightPreportion] are only respected if there is an image and text.
  _SquareButtonPainter({
    required this.backgroundColor,
    this.borderColor,
    this.borderWidthPreportion = .05,
    this.imageWidthPreportion = .85,
    this.textHeightPreportion,
    this.paintPaintAreas = false,
  });
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = backgroundColor;
    final double borderSize = computeBorderSize(size);
    _drawBackground(canvas, size, paint);
    _drawBorder(paint, canvas, borderSize, size);

    if (paintPaintAreas) {
      paint.color = Colors.green;
      canvas.drawRect(imagePaintArea(size, borderSize), paint);
      paint.color = Colors.purple;
      canvas.drawRect(textPaintArea(size, borderSize), paint);
    }
  }

  @override
  double computeBorderSize(Size size) =>
      computeBorderSizeFromPreportion(size, borderWidthPreportion);

  @override
  Rect imagePaintArea(Size size, double borderSize) =>
      determineImagePaintAreaRect(
          size: size,
          borderSize: borderSize,
          imageWidthPreportion: imageWidthPreportion,
          borderWidthPreportion: borderWidthPreportion,
          textHeightPreportion: textHeightPreportion);

  @override
  Rect textPaintArea(Size size, double borderSize) {
    if (textHeightPreportion == null) return Rect.zero;
    return Rect.fromLTWH(
      borderSize,
      imagePaintArea(size, borderSize).bottom,
      size.width - borderSize * 2,
      textHeightPreportion! * size.height,
    );
  }

  void _drawBackground(Canvas canvas, Size size, Paint paint) {
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawBorder(
    Paint paint,
    Canvas canvas,
    double borderWidth,
    Size size,
  ) {
    final startingWidth = paint.strokeWidth;
    final style = paint.style;
    final startingColor = paint.color;

    paint.strokeWidth = borderWidth;
    paint.color = borderColor ?? backgroundColor;
    paint.style = PaintingStyle.stroke;

    //have to subtract one borderWidth from the width and height to offset the borders
    final width = size.width - borderWidth;
    final height = size.height - borderWidth;

    canvas.drawRect(
      Rect.fromLTWH(borderWidth / 2, borderWidth / 2, width, height),
      paint,
    );

    paint.color = startingColor;
    paint.strokeWidth = startingWidth;
    paint.style = style;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

Rect determineImagePaintAreaRect({
  required Size size,
  required double borderSize,
  required double borderWidthPreportion,
  double? imageWidthPreportion,
  double? textHeightPreportion,
}) {
  if (imageWidthPreportion == null) return Rect.zero;
  if (textHeightPreportion == 1) return Rect.zero;
  final double imageHeightPreportion;
  if (textHeightPreportion == null) {
    imageHeightPreportion = 1 - (borderWidthPreportion * 2);
  } else {
    imageHeightPreportion =
        1 - borderWidthPreportion * 2 - textHeightPreportion;
  }
  final imageWidth = imageWidthPreportion * size.width;
  final imageHeight = imageHeightPreportion * size.height;

  final imageStart = size.width / 2 - imageWidth / 2;
  return Rect.fromLTWH(
    imageStart,
    borderSize,
    imageWidth,
    imageHeight,
  );
}

double computeBorderSizeFromPreportion(
        Size size, double borderWidthPreportion) =>
    min(size.width, size.height) * borderWidthPreportion;
