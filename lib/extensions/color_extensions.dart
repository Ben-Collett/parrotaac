import 'package:flutter/material.dart';
import 'package:openboard_wrapper/color_data.dart';

extension ColorDataCovertor on ColorData {
  Color toColor() {
    int alpha = _decimalAlphaToIntAlpha(this.alpha);
    return Color.fromARGB(alpha, red, green, blue);
  }
}

///takes a alpha that is a decimal between 0 and 1.0 and converts it to an int in the rage 0 to 255
int _decimalAlphaToIntAlpha(double alpha) {
  if (alpha < 0 || alpha > 1) {
    throw ArgumentError("alpha must be between 0 and 1.0 not $alpha");
  }
  return (255 * alpha).toInt();
}
