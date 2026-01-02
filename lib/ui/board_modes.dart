import 'package:flutter/widgets.dart';
import 'package:parrotaac/backend/selection_data.dart';
import 'parrot_button.dart';
import 'util_widgets/draggable_grid.dart';

typedef OnPressOverride = void Function(GridNotifier, int row, int col);

//this is functinally very similar to an enum, there is a private constractore the a bunch of static final instances you can reference so only those insteances should exist.
class BoardMode {
  final bool hideEmptySpotWidget;
  final bool configOnButtonHold;
  final bool draggableButtons;
  // final void Function(GridNotifier grid, ProjectEventHandler handler)
  // onPressedOverrides;

  final OnPressOverride? onPressedOverride;

  VoidCallback? makePressedCallback(GridNotifier grid, int row, int col) {
    final pressOverride = onPressedOverride;
    if (pressOverride != null) {
      return () => onPressedOverride!(grid, row, col);
    }
    return null;
  }

  final String asString;

  const BoardMode._({
    required this.configOnButtonHold,
    required this.draggableButtons,
    required this.onPressedOverride,
    required this.asString,
    required this.hideEmptySpotWidget,
  });

  //this doesn't handle changing the empty widget into builderMode because there is no "clean" way to have the logic for showing the create screen popup that I can think of.
  //you will find that code in the board.dart file
  static final builderMode = BoardMode._(
    hideEmptySpotWidget: false,
    configOnButtonHold: true,
    draggableButtons: true,
    onPressedOverride: null,
    asString: "builder_mode",
  );
  static final selectRowMode = BoardMode._(
    configOnButtonHold: true,
    draggableButtons: true,
    onPressedOverride: _selectRow,
    asString: "select_row_mode",
    hideEmptySpotWidget: false,
  );

  static final selectColMode = BoardMode._(
    configOnButtonHold: true,
    draggableButtons: true,
    onPressedOverride: _selectCol,
    asString: "select_col_mode",
    hideEmptySpotWidget: false,
  );

  static final selectWidgetMode = BoardMode._(
    configOnButtonHold: true,
    draggableButtons: true,
    onPressedOverride: _selectWidget,
    asString: "select_widget_mode",
    hideEmptySpotWidget: false,
  );
  static final normalMode = BoardMode._(
    hideEmptySpotWidget: true,
    configOnButtonHold: false,
    draggableButtons: false,
    onPressedOverride: null,
    asString: "normal_mode",
  );

  void updateOnPressed(GridNotifier grid) {
    if (this == normalMode) {
      grid.selectMode = false;
    } else {
      grid.selectMode = true;
    }

    if (onPressedOverride != null) {
      grid.onEmptyPressed = (row, col) {
        onPressedOverride!(grid, row, col);
      };
    }
    grid.forEachIndexed((data, row, col) {
      if (data is ParrotButtonNotifier) {
        if (onPressedOverride == null) {
          data.onPressOverride = null;
        } else {
          data.onPressOverride = () => onPressedOverride!(grid, row, col);
        }
      }
    });
  }

  static List<BoardMode> get values => [
    builderMode,
    selectRowMode,
    selectColMode,
    selectWidgetMode,
    normalMode,
  ];
}

void _selectRow(GridNotifier grid, int row, _) =>
    grid.selectionController.toggleSelectionRow(row);
void _selectCol(GridNotifier grid, _, int col) =>
    grid.selectionController.toggleSelectionCol(col);
void _selectWidget(GridNotifier grid, int row, int col) =>
    grid.selectionController.toggleWidgetSelection(RowColPair(row, col));
