import 'package:flutter/widgets.dart';

class ColorBoxPainter extends CustomPainter {
  final ValueNotifier<Color> colorNotifier;
  Color? color;

  ColorBoxPainter({required this.colorNotifier})
      : super(repaint: colorNotifier);
  @override
  void paint(Canvas canvas, Size size) {
    color = colorNotifier.value;
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = color!
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant ColorBoxPainter oldDelegate) {
    return oldDelegate.color != colorNotifier.value;
  }
}
