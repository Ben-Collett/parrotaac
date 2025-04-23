import 'package:flutter/material.dart';
import 'package:openboard_wrapper/color_data.dart';

extension ColorDataCovertor on ColorData {
  Color toColor() {
    int alpha = _decimalColorToIntColor(this.alpha);
    return Color.fromARGB(alpha, red, green, blue);
  }

  static ColorData fromColorToColorData(Color color) {
    return ColorData(
      red: _decimalColorToIntColor(color.r),
      green: _decimalColorToIntColor(color.g),
      blue: _decimalColorToIntColor(color.b),
      alpha: color.a,
    );
  }
}

///takes a alpha that is a decimal between 0 and 1.0 and converts it to an int in the rage 0 to 255
int _decimalColorToIntColor(double color) {
  if (color < 0 || color > 1) {
    throw ArgumentError("color must be between 0 and 1.0 not $color");
  }
  return (255 * color).toInt();
}
