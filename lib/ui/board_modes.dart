import 'package:flutter/material.dart';
import 'package:parrotaac/ui/event_handler.dart';

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

//this is functinally very similar to an enum, there is a private constractore the a bunch of static final instances you can reference so only those insteances should exist.
class BoardMode {
  final Widget? emptySpotWidget;
  final bool configOnButtonHold;
  final bool draggableButtons;
  final void Function(GridNotfier grid, ProjectEventHandler handler)
      onPressedOverride;
  final String asString;

  const BoardMode._(
      {this.emptySpotWidget,
      required this.configOnButtonHold,
      required this.draggableButtons,
      required this.onPressedOverride,
      required this.asString});

  static final builderMode = BoardMode._(
      emptySpotWidget: _addButtonWidget,
      configOnButtonHold: true,
      draggableButtons: true,
      onPressedOverride: _setGridToDefaultOnPress,
      asString: "builder_mode");
  static final deleteRowMode = BoardMode._(
      emptySpotWidget: _addButtonWidget,
      configOnButtonHold: true,
      draggableButtons: true,
      onPressedOverride: _setGridToDeleteRowMode,
      asString: "delete_row_mode");
  static final deleteColMode = BoardMode._(
      emptySpotWidget: _addButtonWidget,
      configOnButtonHold: true,
      draggableButtons: true,
      onPressedOverride: _setGridToDeleteColMode,
      asString: "delete_col_mode");
  static final normalMode = BoardMode._(
      emptySpotWidget: null,
      configOnButtonHold: false,
      draggableButtons: false,
      onPressedOverride: _setGridToDefaultOnPress,
      asString: "normal_mode");

  static List<BoardMode> get values => [
        builderMode,
        deleteRowMode,
        deleteColMode,
        normalMode,
      ];
}

void _setGridToDefaultOnPress(
    GridNotfier notfier, ProjectEventHandler handler) {
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
  ProjectEventHandler handler,
) {
  if (object is ParrotButtonNotifier) {
    object.onPressOverride = () {
      handler.removeRow(row);
      //the line below updates the buttons indexes when the row is deleted, has to be used to allow deleting when pressing a button, doesn't when dealing with empty spaces though.
      gridNotfier.forEachIndexed((object, row, _) {
        _setButtonToDeleteRowMode(object, row, gridNotfier, handler);
      });
    };
  }
}

void _setGridToDeleteRowMode(GridNotfier grid, ProjectEventHandler handler) {
  grid.forEachIndexed((obj, row, col) {
    _setButtonToDeleteRowMode(obj, row, grid, handler);
  });
}

void _setGridToDeleteColMode(GridNotfier grid, ProjectEventHandler handler) {
  grid.forEachIndexed((obj, row, col) {
    _setButtonToDeleteColMode(obj, col, grid, handler);
  });
}

void _setButtonToDeleteColMode(
  Object? object,
  int col,
  GridNotfier gridNotfier,
  ProjectEventHandler handler,
) {
  if (object is ParrotButtonNotifier) {
    object.onPressOverride = () {
      handler.removeCol(col);
      //the line below updates the buttons indexes when the col is deleted, has to be used to allow deleting when pressing a button, doesn't when dealing with empty spaces though.
      gridNotfier.forEachIndexed((object, _, col) {
        _setButtonToDeleteColMode(object, col, gridNotfier, handler);
      });
    };
  }
}
