import 'package:flutter/material.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/extensions/color_extensions.dart';

extension ObfExtensionKeys on Obf {
  static const _boardColorKey = "ext_parrot_board_color";
  set boardColor(ColorData color) =>
      extendedProperties[_boardColorKey] = color.toString();
  ColorData get boardColor {
    if (extendedProperties.containsKey(_boardColorKey)) {
      return ColorData.fromString(extendedProperties[_boardColorKey]);
    }
    return ColorDataCovertor.fromColorToColorData(Colors.white);
  }
}
