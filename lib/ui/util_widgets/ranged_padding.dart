import 'dart:math';
import 'package:flutter/material.dart';

class ProportionalPadding extends StatelessWidget {
  final double proportion;
  final Widget child;

  // Glow parameters (optional)
  final Color? glowColor;

  const ProportionalPadding({
    super.key,
    required this.proportion,
    required this.child,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        final pad = proportion * size;

        final double glowBlurRadius = 32;
        final double glowSpreadRadius = 0;

        final content = Padding(padding: EdgeInsets.all(pad), child: child);

        // No glow → return standard padded content
        if (glowColor == null) return content;

        // Glow wrapper
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: glowColor!.withOpacity(1.0),
                blurRadius: glowBlurRadius,
                spreadRadius: glowSpreadRadius,
              ),
            ],
          ),
          child: content,
        );
      },
    );
  }
}
