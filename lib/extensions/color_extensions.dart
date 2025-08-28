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

extension IsColor on Color {
  ///meant to return if a color is blueish, the formula is arbitrary and can change and is just an approximation.
  bool isBluish() {
    final color = HSVColor.fromColor(this);
    final notToDark = color.value > .2;
    final saturatedEnough = color.saturation > .25;
    return color.hue >= 175 && color.hue <= 260 && notToDark && saturatedEnough;
  }
}

///takes a alpha that is a decimal between 0 and 1.0 and converts it to an int in the rage 0 to 255
int _decimalColorToIntColor(double color) {
  if (color < 0 || color > 1) {
    throw ArgumentError("color must be between 0 and 1.0 not $color");
  }
  return (255 * color).toInt();
}

extension DarkenBy on Color {
  ///factor should be in the range[0,1]
  ///darkens by multiplying each component by 1-[factor] does not consider actual lumonicity;
  Color darkenedBy(double factor) {
    assert(factor <= 1, "cannot darken by more then 100%");
    assert(factor >= 0, "cannot darken by less then 0%");
    factor = 1 - factor;
    return Color.from(
      red: r * factor,
      green: g * factor,
      blue: b * factor,
      alpha: a,
    );
  }
}
