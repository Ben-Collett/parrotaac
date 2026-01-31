import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/selection_data.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/list_extensions.dart';
import 'package:parrotaac/extensions/num_extensions.dart';

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

extension GeneralObfExtensions on Obf {
  bool hasButtonAtAny(Iterable<RowColPair> pairs) => pairs.any(hasButtonAt);

  bool hasButtonAt(RowColPair pair) {
    final row = pair.row;
    final col = pair.col;
    assert(
      row.exclusiveIsInBetween(-1, grid.numberOfRows),
      "pair row out of bounds",
    );
    assert(
      col.exclusiveIsInBetween(-1, grid.numberOfColumns),
      "pair col out of bounds",
    );

    return safeGetButtonData(pair) != null;
  }

  ButtonData? safeGetButtonData(RowColPair pair) {
    final row = pair.row;
    final col = pair.col;
    if (!row.exclusiveIsInBetween(-1, grid.numberOfRows)) {
      return null;
    }
    if (!col.exclusiveIsInBetween(-1, grid.numberOfColumns)) {
      return null;
    }
    return grid.getButtonData(pair.row, pair.col);
  }

  bool setRow(int row, List<ButtonData?> data) {
    final colCount = grid.numberOfColumns;
    if (row > grid.numberOfRows) {
      SimpleLogger().logError(
        "index out of bounds $row >= ${grid.numberOfRows}",
      );
      return false;
    }
    if (data.length != colCount) {
      SimpleLogger().logError("length miss match");
      return false;
    }

    for (int i = 0; i < colCount; i++) {
      grid.setButtonData(row: row, col: i, data: data[i]);
    }
    return true;
  }

  bool setCol(int col, List<ButtonData?> data) {
    final rowCount = grid.numberOfRows;

    if (col >= grid.numberOfColumns) {
      SimpleLogger().logError(
        "index out of bounds: $col >= ${grid.numberOfColumns}",
      );
      return false;
    }
    if (data.length != rowCount) {
      SimpleLogger().logError("length miss match");
      return false;
    }

    for (int i = 0; i < rowCount; i++) {
      grid.setButtonData(row: i, col: col, data: data[i]);
    }
    return true;
  }
}
