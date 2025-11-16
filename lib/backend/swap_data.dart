import 'package:json_annotation/json_annotation.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/selection_history.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/extensions/list_extensions.dart';
import 'package:parrotaac/extensions/null_extensions.dart';
import 'package:parrotaac/extensions/obf_extensions.dart';
import 'selection_data.dart';

part 'swap_data.g.dart';

@JsonSerializable()
class SwapData {
  final SingleSwapData s1, s2;
  Map<String, dynamic> toJson() => _$SwapDataToJson(this);
  factory SwapData.fromJson(Map<String, dynamic> json) =>
      _$SwapDataFromJson(json);

  ///if x was swelected and was swapped with y then x should no longer be selected and y should be
  static void swapSelection(
    SelectionDataInterface sel1,
    SelectionDataInterface sel2,
    SingleSwapData s1,
    SingleSwapData s2,
  ) {
    final bool? s1Selected = _isSelected(sel1, s1);
    if (s1Selected == null) {
      SimpleLogger().logError("couldn't get s1 selection status: ($s1, $sel1)");
      return;
    }

    final bool? s2Selected = _isSelected(sel2, s2);

    if (s2Selected == null) {
      SimpleLogger().logError("couldn't get s2 selection status: ($s2, $sel2)");
      return;
    }

    _updateSelection(s1, sel1, s2Selected);
    _updateSelection(s2, sel2, s1Selected);
  }

  static void _updateSelection(
    SingleSwapData s,
    SelectionDataInterface sel,
    bool status,
  ) {
    if (s.row != null) {
      sel.setSelectionStatusRow(s.row!, status);
    } else if (s.col != null) {
      sel.setSelectionStatusCol(s.col!, status);
    } else if (s.widget != null) {
      sel.setSelectionStatusWidget(s.widget!, status);
    }
  }

  ///returns null if couldn't extract status from SwapData
  static bool? _isSelected(SelectionDataInterface sel, SingleSwapData s) {
    if (s.row.isNotNull) {
      return sel.isSelectedRow(s.row!);
    } else if (s.col.isNotNull) {
      return sel.isSelectedCol(s.col!);
    } else if (s.widget.isNotNull) {
      return sel.isSelectedWidget(s.widget!) ||
          sel.isSemiSelectedWidget(s.widget!);
    }
    return null;
  }

  void performSwap(ParrotProject project) {
    final Obf? b1 = project.findBoardById(s1.id);
    final Obf? b2 = project.findBoardById(s2.id);
    if (b1 == null) {
      SimpleLogger().logError(
        "failds to perform swap because couldn't find board ${s1.id} in ${project.name}",
      );
      return;
    }
    if (b2 == null) {
      SimpleLogger().logError(
        "failds to perform swap because couldn't find board ${s2.id} in ${project.name}",
      );
      return;
    }

    if (s1.widget != null && s2.widget != null) {
      _performWidgetSwap(b1: b1, b2: b2, p1: s1.widget!, p2: s2.widget!);
      return;
    }

    List<ButtonData?>? b1SelectedData = _getRowOrCol(b1, s1);
    if (b1SelectedData == null) {
      SimpleLogger().logError("failed to get data from $s1 in $b1");
      return;
    }
    b1SelectedData = List.from(b1SelectedData);
    List<ButtonData?>? b2SelectedData = _getRowOrCol(b2, s2);

    if (b2SelectedData == null) {
      SimpleLogger().logError("failed to get data form $s2 in $b2");
      return;
    }

    b2SelectedData = List.from(b2SelectedData);

    _applyData(b1, b2SelectedData, s1);

    // if applying b1's data to b2 fails for what ever reason revert b1
    if (!_applyData(b2, b1SelectedData, s2)) {
      SimpleLogger().logWarning("swap failed");
      _applyData(b1, b1SelectedData, s1);
    }
  }

  bool _applyData(Obf board, List<ButtonData?> data, SingleSwapData s) {
    if (s.row.isNotNull) {
      return board.setRow(s.row!, data);
    } else if (s.col.isNotNull) {
      return board.setCol(s.col!, data);
    }
    SimpleLogger().logError("null row and col $s");
    return false;
  }

  List<ButtonData?>? _getRowOrCol(Obf board, SingleSwapData s) {
    if (s.col.isNotNull) {
      return board.grid.getCol(s.col!);
    } else if (s.row.isNotNull) {
      return board.grid.getRow(s.row!);
    }
    return null;
  }

  void _performWidgetSwap({
    required Obf b1,
    required Obf b2,
    required RowColPair p1,
    required RowColPair p2,
  }) {
    final temp = b1.safeGetButtonData(p1);
    b1.grid.setButtonData(
      row: p1.row,
      col: p1.col,
      data: b2.safeGetButtonData(p2),
    );

    b2.grid.setButtonData(row: p2.row, col: p2.col, data: temp);
  }

  SwapData(this.s1, this.s2);

  static SwapData? getSwapData(WorkingSelectionHistory history) {
    //early return if there is no data or there are two many selected data as they get removed when the selection history
    if (history.getSelectionDataCount > 2 || history.isEmpty) {
      return null;
    }

    final rows = history.selectedRows();
    final cols = history.selectedCols();
    final widgets = history.selectedWidgets();

    final rowCount = rows.values.flatten().length;
    final colCount = cols.values.flatten().length;
    final widgetCount = widgets.values.flatten().length;

    //must be two and only two things selected
    if (rowCount + colCount + widgetCount != 2) {
      return null;
    }

    //handle case where two widgets selected
    if (widgetCount == 2 && rowCount == 0 && colCount == 0) {
      final List<SingleSwapData> out = [];

      int nullCount = 0;
      for (final e in widgets.entries) {
        final Obf? board = history.project.findBoardById(e.key);
        assert(board != null, "failed to find board id: ${e.key}");
        for (final pair in e.value) {
          if (board?.safeGetButtonData(pair) == null) {
            nullCount++;
          }
          //at least one pair has to have a button to do a swap
          if (nullCount == 2) {
            return null;
          }
          out.add(SingleSwapData(id: e.key, widget: pair));
        }
      }

      assert(out.length > 1, "to few widgets to swap somehow");
      assert(out.length < 3, "to many widgets to swap somehow");
      return SwapData(out[0], out[1]);
    }

    //if we can't swap widgets but one is selected then swapping becomes impossible
    if (widgetCount > 0) {
      return null;
    }

    final List<SingleSwapData> out = [];
    int? expectedLength;
    final data = history.data;
    for (final MapEntry<String, SelectionData> e in data.entries) {
      final id = e.key;
      final data = e.value;
      Obf? board = history.project.findBoardById(id);
      assert(board != null, "didn't find board in swap_data");
      if (board == null) {
        return null;
      }
      final rows = data.selectedRows;
      for (final int row in rows) {
        final numberOfRows = board.grid.numberOfRows;
        expectedLength ??= numberOfRows;
        if (expectedLength == numberOfRows) {
          out.add(SingleSwapData(id: id, row: row));
        } else {
          return null;
        }
      }

      final cols = data.selectedCols;
      for (final int col in cols) {
        final numberOfCols = board.grid.numberOfColumns;
        expectedLength ??= numberOfCols;
        if (expectedLength == numberOfCols) {
          out.add(SingleSwapData(id: id, col: col));
        } else {
          return null;
        }
      }
    }

    assert(out.length > 1, "to few rows/cols to swap somehow");
    assert(out.length < 3, "to many rows/cols to swap somehow");
    return SwapData(out[0], out[1]);
  }
}

@JsonSerializable()
class SingleSwapData {
  final String id;
  final int? row;
  final int? col;
  final RowColPair? widget;

  Map<String, dynamic> toJson() => _$SingleSwapDataToJson(this);
  factory SingleSwapData.fromJson(Map<String, dynamic> json) =>
      _$SingleSwapDataFromJson(json);
  @override
  String toString() {
    return toJson().toString();
  }

  SingleSwapData({required this.id, this.row, this.col, this.widget})
    : assert(
        [row, col, widget].nonNulls.isNotEmpty,
        "no value set in SingleSwapData",
      ),
      assert(
        [row, col, widget].nonNulls.length < 2,
        "to many fields set in SingleSwapData = {row:$row, col:$col, pair:$widget}",
      );
}
