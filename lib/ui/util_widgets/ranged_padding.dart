import 'package:flutter/cupertino.dart';
import 'dart:math';

class PreportinalPadding extends StatelessWidget {
  final double preportion;
  final Widget child;
  const PreportinalPadding({
    super.key,
    required this.preportion,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contrainst) {
        return Padding(
          padding: EdgeInsets.all(
            preportion * min(contrainst.minWidth, contrainst.minHeight),
          ),
          child: child,
        );
      },
    );
  }
}
