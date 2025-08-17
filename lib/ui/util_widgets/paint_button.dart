import 'package:flutter/material.dart';

class PaintedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double? width, height;
  final CustomPainter painter;
  const PaintedButton(
      {super.key,
      required this.painter,
      this.onPressed,
      this.width,
      this.height});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: painter,
          ),
        ),
      ),
    );
  }
}
