import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:parrotaac/backend/value_wrapper.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/state/my_anmiation_notifier.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';

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
  final double borderWidthPreportion;
  const ShapedButton({
    super.key,
    this.image,
    this.text,
    this.onPressed,
    this.onLongPress,
    this.borderWidthPreportion = .05,
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
    const bool paintPaintAreas = false;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final double textHeight;
        if (widget.text == null) {
          textHeight = 0;
        } else if (widget.image == null) {
          textHeight = 1;
        } else {
          //TODO: I really need to dynamically detersize.shortestSidemine this so the sentence bar look better on different size screens
          textHeight = 0.25;
        }
        final _ParrotButtonPainter painter;
        if (widget.shape == ParrotButtonShape.square) {
          painter = _SquareButtonPainter(
            animationController: _repaintNotifier,
            borderWidthPreportion: widget.borderWidthPreportion,
            backgroundColor: _backgroundColor,
            repaint: _repaintNotifier,
            paintPaintAreas: paintPaintAreas,
            borderColor: _borderColor,
            textHeightPreportion: textHeight,
          );
        } else {
          painter = _FolderButtonPainter(
            backgroundColor: _backgroundColor,
            borderWidthPreportion: widget.borderWidthPreportion,
            animationController: _repaintNotifier,
            paintPaintAreas: paintPaintAreas,
            repaint: _repaintNotifier,
            borderColor: _borderColor,
            textHeightPreportion: textHeight,
          );
        }

        final borderSize = painter.computeBorderSize(size);
        final imageRect = painter.imagePaintArea(size, borderSize);
        final textRect = painter.textPaintArea(size, borderSize);

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

  Rect circlePaintArea(Size size, double borderSize) => Rect.fromLTWH(
    borderSize,
    borderSize,
    size.shortestSide * .3,
    size.shortestSide * .3,
  );
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
  final double roundnessPreportion;
  final bool paintPaintAreas;
  final AnimationController animationController;
  _FolderButtonPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.animationController,
    super.repaint,
    this.borderWidthPreportion = 0.05,
    this.tabTopWidthPreportion = 0.25,
    this.tabBottomWidthPreportion = 0.34,
    this.tabHeightPreportion = 0.08,
    this.imageWidthPreportion = .85,
    this.roundnessPreportion = .1,
    this.paintPaintAreas = false,
    this.textHeightPreportion,
  });
  @override
  double computeBorderSize(Size size) =>
      computeBorderSizeFromPreportion(size, borderWidthPreportion);

  @override
  Rect imagePaintArea(Size size, double borderSize) {
    final tabHeight = size.height * tabHeightPreportion;
    size = Size(size.width, size.height - tabHeight);
    Rect rect = determineImagePaintAreaRect(
      size: size,
      borderSize: borderSize,
      borderWidthPreportion: borderWidthPreportion,
      imageWidthPreportion: imageWidthPreportion,
      roundnessPreportion: roundnessPreportion,
      textHeightPreportion: textHeightPreportion,
    );
    if (rect == Rect.zero) return rect;
    rect = rect.shift(Offset(0, tabHeight));

    return rect;
  }

  @override
  Rect textPaintArea(Size size, double borderSize) {
    if (textHeightPreportion == null) return Rect.zero;
    final radius = roundnessPreportion * min(size.width, size.height);
    final imageArea = imagePaintArea(size, borderSize);
    double top = imageArea.bottom;

    final height = min(
      textHeightPreportion! * size.height,
      size.height - top - borderSize,
    );
    return Rect.fromLTWH(
      borderSize + radius / 2,
      top,
      size.width - borderSize * 2 - radius,
      height,
    );
  }

  Path _folderPath(Size size, double strokeWidth) {
    size = Size(size.width - strokeWidth, size.height - strokeWidth);
    final tabHeight = tabHeightPreportion * size.height;
    final tabTopWidth = tabTopWidthPreportion * size.width;
    final bodyHeight = size.height - tabHeight;
    final bodyWidth = size.width;

    final tabSize = Size(tabTopWidth, tabHeight);
    final bodySize = Size(bodyWidth, bodyHeight);
    final tabBottomWidth = tabBottomWidthPreportion * size.width;
    final radius = roundnessPreportion * size.shortestSide;

    return _computeFolderPath(
      bodySize: bodySize,
      tabSize: tabSize,
      tabBottomWidth: tabBottomWidth,
      radius: radius,
    ).shift(Offset(strokeWidth / 2, strokeWidth / 2));
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
    final matrix = Matrix4.diagonal3Values(scale, scale, 1.0);
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
    final radius = Radius.circular(roundnessPreportion * size.shortestSide);
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
        roundnessPreportion: roundnessPreportion,
      );

  @override
  Rect textPaintArea(Size size, double borderSize) {
    if (textHeightPreportion == null) return Rect.zero;
    final radius = roundnessPreportion * size.shortestSide;
    return Rect.fromLTWH(
      borderSize + radius / 2,
      imagePaintArea(size, borderSize).bottom,
      size.width - borderSize * 2 - radius,
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
  double roundnessPreportion = 0,
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

  final radius = roundnessPreportion * size.shortestSide;

  final imageWidth = min(
    imageWidthPreportion * size.width,
    size.width - 2 * radius,
  );
  final imageHeight = imageHeightPreportion * size.height;

  final imageStart = size.width / 2 - imageWidth / 2;
  return Rect.fromLTWH(imageStart, borderSize, imageWidth, imageHeight);
}

double computeBorderSizeFromPreportion(
  Size size,
  double borderWidthPreportion,
) => size.shortestSide * borderWidthPreportion;

Path _computeFolderPath({
  required Size bodySize,
  required Size tabSize,
  required double tabBottomWidth,
  required double radius,
}) {
  final path = Path();
  final width = bodySize.width;
  final baseHeight = bodySize.height;
  final tabWidth = tabSize.width;
  final tabHeight = tabSize.height;
  final height = baseHeight + tabHeight;

  const forceCreateNewSubPath = false;

  path.moveTo(tabWidth, 0);

  Rect rect = Rect.fromLTWH(0, 0, radius * 2, radius * 2);
  path.arcTo(rect, 3 * pi / 2, -pi / 2, forceCreateNewSubPath);

  rect = Rect.fromLTWH(0, height - radius * 2, radius * 2, radius * 2);
  path.arcTo(rect, pi, -pi / 2, forceCreateNewSubPath);

  rect = Rect.fromLTWH(
    width - radius * 2,
    height - radius * 2,
    radius * 2,
    radius * 2,
  );
  path.arcTo(rect, pi / 2, -pi / 2, forceCreateNewSubPath);

  rect = Rect.fromLTWH(width - radius * 2, tabHeight, radius * 2, radius * 2);
  path.arcTo(rect, 2 * pi, -pi / 2, false);
  path.lineTo(tabBottomWidth, tabHeight);

  // Draw along the tab top to the start of the tab notch
  path.lineTo(tabBottomWidth, tabHeight);

  // Small rounding between tab bottom and top edge (optional for smoothing)
  path.quadraticBezierTo(tabBottomWidth - radius / 10, tabHeight, tabWidth, 0);

  path.close();

  return path;
}
