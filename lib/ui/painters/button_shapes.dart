import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:parrotaac/backend/value_wrapper.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/state/my_anmiation_notifier.dart';
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

//WARNING: in the case the duration is tweed the animation's will also need tweaked as the extend past there normal confines into the borders to make the animation feel "smoother"
const animationDuration = Duration(milliseconds: 600);
const animationStartThreshold =
    .11; //start animation want 11% done, this avoids playing the animation when user just taps

class ShapedButton extends StatefulWidget {
  final Widget? image;
  final Widget? text;
  final ParrotButtonShape shape;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  const ShapedButton({
    super.key,
    this.image,
    this.text,
    this.onPressed,
    this.onLongPress,
    required this.backgroundColor,
    required this.shape,
    required this.borderColor,
  });

  @override
  State<ShapedButton> createState() => _ShapedButtonState();
}

class _ShapedButtonState extends State<ShapedButton>
    with SingleTickerProviderStateMixin {
  late final ValueWrapper<Color> _backgroundColor;
  late final ValueWrapper<Color> _borderColor;
  late final AnimationNotifier _repaintNotifier;
  final Queue<Color> _backgroundColorHistory = Queue();
  final Queue<Color> _borderColorHistory = Queue();
  bool _mouseInside = false;

  @override
  void initState() {
    _backgroundColor = ValueWrapper(widget.backgroundColor);
    _borderColor = ValueWrapper(widget.borderColor);
    _repaintNotifier = AnimationNotifier(
      vsync: this,
      duration: animationDuration,
    );
    _repaintNotifier.addListener(() {
      if (_repaintNotifier.value == 1 && _mouseInside) {
        widget.onLongPress?.call();
        _repaintNotifier.reset();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _repaintNotifier.dispose();
    super.dispose();
  }

  void _resetColors() {
    _borderColorHistory.clear();
    _borderColorHistory.clear();
    _backgroundColor.value = widget.backgroundColor;
    _borderColor.value = widget.borderColor;

    _repaintNotifier.notify();
  }

  void _restorePreviousColors() {
    _backgroundColor.value = _backgroundColorHistory.removeLast();
    _borderColor.value = _borderColorHistory.removeLast();

    _repaintNotifier.notify();
  }

  void _darkenButtonBy(double percent) {
    _backgroundColorHistory.add(_backgroundColor.value);
    _borderColorHistory.add(_borderColor.value);

    _backgroundColor.value = widget.backgroundColor.darkenedBy(percent);
    _borderColor.value = widget.borderColor.darkenedBy(percent);

    _repaintNotifier.notify();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final double textHeight;
        if (widget.text == null) {
          textHeight = 0;
        } else if (widget.image == null) {
          textHeight = 1;
        } else {
          //TODO: I really need to dynamically determine this so the sentence bar look better on different size screens
          textHeight = 0.25;
        }
        final _ParrotButtonPainter painter;
        if (widget.shape == ParrotButtonShape.square) {
          painter = _SquareButtonPainter(
            animationController: _repaintNotifier,
            backgroundColor: _backgroundColor,
            repaint: _repaintNotifier,
            borderColor: _borderColor,
            textHeightPreportion: textHeight,
          );
        } else {
          painter = _FolderButtonPainter(
            backgroundColor: _backgroundColor,
            animationController: _repaintNotifier,
            repaint: _repaintNotifier,
            borderColor: _borderColor,
            textHeightPreportion: textHeight,
          );
        }
        final imageRect = painter.imagePaintArea(
          size,
          painter.computeBorderSize(size),
        );
        final textRect = painter.textPaintArea(
          size,
          painter.computeBorderSize(size),
        );
        const tenPercent = 0.1;
        const fifteenPercent = 0.15;
        return MouseRegion(
          onEnter: (_) {
            _mouseInside = true;
            if (widget.onPressed != null) {
              _darkenButtonBy(tenPercent);
            }
          },
          onExit: (_) {
            _mouseInside = false;
            if (widget.onPressed != null) {
              _resetColors();
            }
          },
          child: GestureDetector(
            onTapDown: (details) {
              if (widget.onPressed != null) {
                _darkenButtonBy(fifteenPercent);
              }
              if (widget.onLongPress != null) {
                _repaintNotifier.forward();
              }
            },
            onTapUp: (details) async {
              if (widget.onPressed != null) {
                //create artificial delay so button looks darkend on press

                _repaintNotifier.reverse();
                await Future.delayed(Duration(milliseconds: 60));
                _restorePreviousColors();
                widget.onPressed?.call();
              }
            },
            child: Stack(
              children: [
                SizedBox(
                  width: size.width,
                  height: size.height,
                  child: CustomPaint(painter: painter as CustomPainter),
                ),
                if (widget.image != null)
                  Positioned.fromRect(rect: imageRect, child: widget.image!),
                if (widget.text != null)
                  Positioned.fromRect(rect: textRect, child: widget.text!),
              ],
            ),
          ),
        );
      },
    );
  }
}

//I could add a method to check if a gesture is inside the painter but for now I think the imprecsision is better for users
mixin _ParrotButtonPainter {
  Rect imagePaintArea(Size size, double borderSize);
  Rect textPaintArea(Size size, double borderSize);
  double computeBorderSize(Size size);
}

class _FolderButtonPainter extends CustomPainter with _ParrotButtonPainter {
  final ValueWrapper<Color> backgroundColor;
  final ValueWrapper<Color> borderColor;
  final double? textHeightPreportion;
  final double borderWidthPreportion;
  final double tabHeightPreportion;
  final double tabTopWidthPreportion;
  final double tabBottomWidthPreportion;
  final double imageWidthPreportion;
  final bool paintPaintAreas;
  final AnimationController animationController;
  _FolderButtonPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.animationController,
    super.repaint,
    this.borderWidthPreportion = 0.05,
    this.tabTopWidthPreportion = 0.25,
    this.tabBottomWidthPreportion = 0.3,
    this.tabHeightPreportion = 0.09,
    this.imageWidthPreportion = .85,
    this.paintPaintAreas = false,
    this.textHeightPreportion,
  });
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
    final points = [
      topLeft,
      bottomLeft,
      bottomRight,
      topRight,
      tabRightBottom,
      tabRightTop,
      finish,
    ];

    return pathFromPoints(points);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final borderSize = computeBorderSize(size);
    Paint paint = Paint()
      ..color = backgroundColor.value
      ..strokeWidth = borderSize
      ..style = PaintingStyle.fill;
    Path path = _folderPath(size, borderSize);
    canvas.drawPath(path, paint);
    _drawAnimation(canvas, size, paint, path);
    paint.color = borderColor.value;
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

  void _drawAnimation(Canvas canvas, Size size, Paint paint, Path path) {
    paint.style = PaintingStyle.fill;
    paint.color = Color.fromARGB(150, 255, 255, 255);
    final scale = animationController.value;
    if (scale < animationStartThreshold) return;
    final matrix = Matrix4.identity()..scale(scale);
    path = path.transform(matrix.storage);
    path = path.shift(
      Offset(
        size.width / 2 - size.width / 2 * scale,
        size.height / 2 - size.height / 2 * scale,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SquareButtonPainter extends CustomPainter with _ParrotButtonPainter {
  final AnimationController animationController;
  final ValueWrapper<Color> backgroundColor;
  final ValueWrapper<Color> borderColor;
  final double borderWidthPreportion;
  final double imageWidthPreportion;
  double? textHeightPreportion;
  final bool paintPaintAreas;
  final double roundnessPreportion;

  ///[textHeightPreportion] and [imageHeightPreportion] are only respected if there is an image and text.
  _SquareButtonPainter({
    super.repaint,
    required this.backgroundColor,
    required this.borderColor,
    required this.animationController,
    this.borderWidthPreportion = .05,
    this.imageWidthPreportion = .85,
    this.roundnessPreportion = .1,
    this.textHeightPreportion,
    this.paintPaintAreas = false,
  });
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = backgroundColor.value;
    final double borderSize = computeBorderSize(size);
    final radius = Radius.circular(
      roundnessPreportion * min(size.width, size.height),
    );
    final RRect rrect = computeRRect(size, borderSize, radius);
    _drawBackground(canvas, rrect, paint);
    _drawAnimation(canvas, size, radius, paint);
    _drawBorder(paint, canvas, borderSize, rrect, size);
    if (paintPaintAreas) {
      paint.color = Colors.green;
      canvas.drawRect(imagePaintArea(size, borderSize), paint);
      paint.color = Colors.purple;
      canvas.drawRect(textPaintArea(size, borderSize), paint);
    }
  }

  void _drawAnimation(Canvas canvas, Size size, Radius radius, Paint paint) {
    final scale = animationController.value;
    if (scale < animationStartThreshold) return;
    final borderSize = computeBorderSize(size);

    final scaledRadius = Radius.circular(radius.x * scale);
    //width and height overshoot by 1.2 borderSize as that makes the animation look smoother and it gets covered up border, plus it avoids having to worry about the corners to much
    final width = (size.width - borderSize * .8) * scale;
    final height = (size.height - borderSize * .8) * scale;
    final center = Offset(size.width / 2, size.height / 2);

    final rect = Rect.fromCenter(center: center, width: width, height: height);

    final scaledRect = RRect.fromRectAndRadius(rect, scaledRadius);
    paint
      ..color = const Color.fromARGB(150, 255, 255, 255)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawRRect(scaledRect, paint);
  }

  RRect scaleRRect(RRect rrect, double scale) {
    final Rect rect = rrect.outerRect;
    final Offset center = rect.center;
    final double newWidth = rect.width * scale;
    final double newHeight = rect.height * scale;

    // scale the radius (assuming circular corners)
    final Radius newRadius = Radius.elliptical(
      rrect.blRadiusX * scale,
      rrect.blRadiusY * scale,
    );

    final Rect newRect = Rect.fromCenter(
      center: center,
      width: newWidth,
      height: newHeight,
    );

    return RRect.fromRectAndRadius(newRect, newRadius);
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
        textHeightPreportion: textHeightPreportion,
      );

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

  RRect computeRRect(Size size, double borderWidth, Radius radius) {
    //have to subtract one borderWidth from the width and height to offset the borders
    final width = size.width - borderWidth;
    final height = size.height - borderWidth;

    return RRect.fromRectAndRadius(
      Rect.fromLTWH(borderWidth / 2, borderWidth / 2, width, height),
      radius,
    );
  }

  void _drawBackground(Canvas canvas, RRect rrect, Paint paint) {
    canvas.drawRRect(rrect, paint);
  }

  void _drawBorder(
    Paint paint,
    Canvas canvas,
    double borderWidth,
    RRect rrect,
    Size size,
  ) {
    final startingWidth = paint.strokeWidth;
    final style = paint.style;
    final startingColor = paint.color;

    paint.strokeWidth = borderWidth;
    paint.color = borderColor.value;
    paint.style = PaintingStyle.stroke;

    canvas.drawRRect(rrect, paint);

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
  return Rect.fromLTWH(imageStart, borderSize, imageWidth, imageHeight);
}

double computeBorderSizeFromPreportion(
  Size size,
  double borderWidthPreportion,
) => min(size.width, size.height) * borderWidthPreportion;
