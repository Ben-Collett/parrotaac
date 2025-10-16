import 'package:parrotaac/ui/event_handler.dart';

import 'parrot_button.dart';
import 'util_widgets/draggable_grid.dart';

//this is functinally very similar to an enum, there is a private constractore the a bunch of static final instances you can reference so only those insteances should exist.
class BoardMode {
  final bool hideEmptySpotWidget;
  final bool configOnButtonHold;
  final bool draggableButtons;
  final void Function(GridNotifier grid, ProjectEventHandler handler)
  onPressedOverride;
  final String asString;

  const BoardMode._({
    required this.configOnButtonHold,
    required this.draggableButtons,
    required this.onPressedOverride,
    required this.asString,
    required this.hideEmptySpotWidget,
  });

  static final builderMode = BoardMode._(
    hideEmptySpotWidget: false,
    configOnButtonHold: true,
    draggableButtons: true,
    onPressedOverride: _setGridToDefaultOnPress,
    asString: "builder_mode",
  );
  static final deleteRowMode = BoardMode._(
    hideEmptySpotWidget: false,
    configOnButtonHold: true,
    draggableButtons: true,
    onPressedOverride: _setGridToDeleteRowMode,
    asString: "delete_row_mode",
  );
  static final deleteColMode = BoardMode._(
    hideEmptySpotWidget: false,
    configOnButtonHold: true,
    draggableButtons: true,
    onPressedOverride: _setGridToDeleteColMode,
    asString: "delete_col_mode",
  );
  static final normalMode = BoardMode._(
    hideEmptySpotWidget: true,
    configOnButtonHold: false,
    draggableButtons: false,
    onPressedOverride: _setGridToDefaultOnPress,
    asString: "normal_mode",
  );

  static List<BoardMode> get values => [
    builderMode,
    deleteRowMode,
    deleteColMode,
    normalMode,
  ];
}

void _setGridToDefaultOnPress(
  GridNotifier notfier,
  ProjectEventHandler handler,
) {
  notfier.forEach((obj) {
    if (obj is ParrotButtonNotifier) {
      obj.onPressOverride = null;
    }
  });
}

void _setButtonToDeleteRowMode(
  Object? object,
  int row,
  GridNotifier gridNotfier,
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

void _setGridToDeleteRowMode(GridNotifier grid, ProjectEventHandler handler) {
  grid.forEachIndexed((obj, row, col) {
    _setButtonToDeleteRowMode(obj, row, grid, handler);
  });
}

void _setGridToDeleteColMode(GridNotifier grid, ProjectEventHandler handler) {
  grid.forEachIndexed((obj, row, col) {
    _setButtonToDeleteColMode(obj, col, grid, handler);
  });
}

void _setButtonToDeleteColMode(
  Object? object,
  int col,
  GridNotifier gridNotfier,
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
