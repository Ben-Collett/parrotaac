import 'package:flutter/material.dart';

import 'parrot_button.dart';
import 'util_widgets/draggable_grid.dart';

final Widget _addButtonWidget = Padding(
  padding: EdgeInsets.all(4.0),
  child: Container(
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.lightBlue, width: 5)),
    child: Center(
      child: Icon(Icons.add, color: Colors.lightBlue),
    ),
  ),
);

class BoardMode {
  final Widget? emptySpotWidget;
  final bool configOnButtonHold;
  final bool draggableButtons;
  final void Function(GridNotfier grid) onPressedOverride;

  const BoardMode._(
      {this.emptySpotWidget,
      required this.configOnButtonHold,
      required this.draggableButtons,
      required this.onPressedOverride});

  static final builderMode = BoardMode._(
      emptySpotWidget: _addButtonWidget,
      configOnButtonHold: true,
      draggableButtons: true,
      onPressedOverride: _setGridToDefaultOnPress);
  static final deleteRowMode = BoardMode._(
      emptySpotWidget: _addButtonWidget,
      configOnButtonHold: true,
      draggableButtons: true,
      onPressedOverride: _setGridToDeleteRowMode);
  static final deleteColMode = BoardMode._(
      emptySpotWidget: _addButtonWidget,
      configOnButtonHold: true,
      draggableButtons: true,
      onPressedOverride: _setGridToDeleteColMode);
  static final normalMode = BoardMode._(
      emptySpotWidget: null,
      configOnButtonHold: false,
      draggableButtons: false,
      onPressedOverride: _setGridToDefaultOnPress);
}

void _setGridToDefaultOnPress(GridNotfier notfier) {
  notfier.forEach((obj) {
    if (obj is ParrotButtonNotifier) {
      obj.onPressOverride = null;
    }
  });
}

void _setButtonToDeleteRowMode(
  Object? object,
  int row,
  GridNotfier gridNotfier,
) {
  if (object is ParrotButtonNotifier) {
    object.onPressOverride = () {
      gridNotfier.removeRow(row);
      //the line below updates the buttons indexes when the row is deleted, has to be used to allow deleting when pressing a button, doesn't when dealing with empty spaces though.
      gridNotfier.forEachIndexed((object, row, _) {
        _setButtonToDeleteRowMode(object, row, gridNotfier);
      });
    };
  }
}

void _setGridToDeleteRowMode(GridNotfier grid) {
  grid.forEachIndexed((obj, row, col) {
    _setButtonToDeleteRowMode(obj, row, grid);
  });
}

void _setGridToDeleteColMode(GridNotfier grid) {
  grid.forEachIndexed((obj, row, col) {
    _setButtonToDeleteColMode(obj, col, grid);
  });
}

void _setButtonToDeleteColMode(
  Object? object,
  int col,
  GridNotfier gridNotfier,
) {
  if (object is ParrotButtonNotifier) {
    object.onPressOverride = () {
      gridNotfier.removeCol(col);
      //the line below updates the buttons indexes when the col is deleted, has to be used to allow deleting when pressing a button, doesn't when dealing with empty spaces though.
      gridNotfier.forEachIndexed((object, _, col) {
        _setButtonToDeleteColMode(object, col, gridNotfier);
      });
    };
  }
}
