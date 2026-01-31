import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:parrotaac/backend/encoding/json_utils.dart';
import 'package:parrotaac/extensions/list_extensions.dart';
import 'package:parrotaac/extensions/num_extensions.dart';
import 'package:parrotaac/extensions/set_extensions.dart';

part 'selection_data.g.dart';

mixin SelectionDataInterface {
  void selectRow(int row);
  void toggleSelectionRow(int row);
  void toggleSelectionCol(int col);
  void toggleWidgetSelection(RowColPair pair);
  void selectWidget(RowColPair pair);
  void selectCol(int col);
  void removeRows(Iterable<int> rows);
  void removeCols(Iterable<int> cols);
  void setSelectionStatusRow(int row, bool newSelectionStatus);
  void setSelectionStatusCol(int col, bool newSelectionStatus);
  void setSelectionStatusWidget(RowColPair pair, bool newSelectionStatus);
  void removeRow(int row);
  void insertRow(int row);
  void insertCol(int col);
  void removeCol(int col);
  void bulkDeselect(Iterable<RowColPair> pairs);
  bool isSelectedWidget(RowColPair pair);
  bool isSemiSelectedWidget(RowColPair pair);
  bool isSelectedRow(int row);
  bool isSelectedCol(int col);
  void setTo(SelectionData data);
  void clear();
  void swapSelection(RowColPair p1, RowColPair p2);
  void deselectRow(int row);
  void deselectCol(int col);
  void deselectWidget(RowColPair pair);
  bool get isEmpty;
}

class SelectionDataController extends ChangeNotifier
    with SelectionDataInterface {
  final SelectionData data;
  SelectionDataController(this.data);

  @override
  bool get isEmpty => data.isEmpty;

  void updateData(Function(SelectionData) callback) {
    callback(data);
    notifyListeners();
  }

  @override
  void clear() {
    updateData((data) => data.clear());
  }

  @override
  void insertRow(int row) {
    updateData((data) => data.insertRow(row));
  }

  @override
  void selectRow(int row) {
    updateData((data) => data.selectRow(row));
  }

  @override
  void removeRow(int row) {
    updateData((data) => data.removeRow(row));
  }

  @override
  void bulkDeselect(Iterable<RowColPair> pairs) {
    updateData((data) => data.bulkDeselect(pairs));
  }

  @override
  void deselectCol(int col) {
    updateData((data) => data.deselectCol(col));
  }

  @override
  void deselectRow(int row) {
    updateData((data) => data.deselectRow(row));
  }

  @override
  void deselectWidget(RowColPair pair) {
    updateData((data) => data.deselectWidget(pair));
  }

  @override
  void insertCol(int col) {
    updateData((data) => data.insertCol(col));
  }

  @override
  void removeCol(int col) {
    updateData((data) => data.removeCol(col));
  }

  @override
  void removeCols(Iterable<int> cols) {
    updateData((data) => data.removeCols(cols));
  }

  @override
  void removeRows(Iterable<int> rows) {
    updateData((data) => data.removeRows(rows));
  }

  @override
  void selectCol(int col) {
    updateData((data) => data.selectCol(col));
  }

  @override
  void selectWidget(RowColPair pair) {
    updateData((data) => data.selectWidget(pair));
  }

  @override
  void setTo(SelectionData newData) {
    updateData((data) => data.setTo(newData));
  }

  @override
  void swapSelection(RowColPair p1, RowColPair p2) {
    updateData((data) => data.swapSelection(p1, p2));
  }

  @override
  void toggleSelectionCol(int col) {
    updateData((data) => data.toggleSelectionCol(col));
  }

  @override
  void toggleSelectionRow(int row) {
    updateData((data) => data.toggleSelectionRow(row));
  }

  @override
  void toggleWidgetSelection(RowColPair pair) {
    updateData((data) => data.toggleWidgetSelection(pair));
  }

  Map<String, dynamic> toJson() => data.toJson();

  @override
  bool isSelectedCol(int col) => data.isSelectedCol(col);

  @override
  bool isSelectedRow(int row) => data.isSelectedRow(row);

  @override
  bool isSelectedWidget(RowColPair pair) => data.isSelectedWidget(pair);

  @override
  void setSelectionStatusCol(int col, bool newSelectionStatus) {
    data.setSelectionStatusCol(col, newSelectionStatus);
    notifyListeners();
  }

  @override
  void setSelectionStatusRow(int row, bool newSelectionStatus) {
    data.setSelectionStatusRow(row, newSelectionStatus);
    notifyListeners();
  }

  @override
  void setSelectionStatusWidget(RowColPair pair, bool newSelectionStatus) {
    data.setSelectionStatusWidget(pair, newSelectionStatus);
    notifyListeners();
  }

  @override
  bool isSemiSelectedWidget(RowColPair pair) => data.isSemiSelectedWidget(pair);
}

@JsonSerializable()
class SelectionData with SelectionDataInterface {
  final Set<int> selectedRows;
  final Set<int> selectedCols;
  @JsonKey(toJson: _rowColSetToJson, fromJson: _rowColSetFromJson)
  final Set<RowColPair> selectedWidgets;

  ///widgets that where selected but are also in a row or a col
  @JsonKey(toJson: _rowColSetToJson, fromJson: _rowColSetFromJson)
  final Set<RowColPair> semiSelectedWidget = {};

  static List<Map<String, dynamic>> _rowColSetToJson(
    Iterable<RowColPair> pairs,
  ) => pairs.map((pair) => pair.toJson()).toList();

  static Set<RowColPair> _rowColSetFromJson(dynamic data) {
    if (data is Iterable) {
      return data.map((pair) => RowColPair.fromJson(pair)).nonNulls.toSet();
    }
    return {};
  }

  SelectionData({
    Set<int>? selectedRows,
    Set<int>? selectedCols,
    Set<RowColPair>? selectedWidgets,
  }) : selectedRows = selectedRows ?? {},
       selectedCols = selectedCols ?? {},
       selectedWidgets = selectedWidgets ?? {};

  ///selects a row and removes any thing selected in said row from the selectedWidgets
  @override
  void selectRow(int row) {
    _semiSelectWhere((pair) => pair.row == row);
    selectedRows.add(row);
  }

  @override
  void toggleSelectionRow(int row) {
    if (selectedRows.contains(row)) {
      deselectRow(row);
    } else {
      selectRow(row);
    }
  }

  @override
  void toggleSelectionCol(int col) {
    if (selectedCols.contains(col)) {
      deselectCol(col);
    } else {
      selectCol(col);
    }
  }

  @override
  void toggleWidgetSelection(RowColPair pair) {
    if (_selectedOrSemiSelected(pair)) {
      deselectWidget(pair);
    } else {
      selectWidget(pair);
    }
  }

  @override
  void selectWidget(RowColPair pair) {
    if (selectedRows.contains(pair.row) || selectedCols.contains(pair.col)) {
      semiSelectedWidget.add(pair);
    } else {
      selectedWidgets.add(pair);
    }
  }

  void _semiSelectWhere(bool Function(RowColPair) condition) {
    selectedWidgets.removeWhere((pair) {
      final shouldMove = condition(pair);
      if (shouldMove) semiSelectedWidget.add(pair);
      return shouldMove;
    });
  }

  void _reselectWhere(bool Function(RowColPair) condition) {
    semiSelectedWidget.removeWhere((pair) {
      final shouldMove = condition(pair);
      if (shouldMove) selectedWidgets.add(pair);
      return shouldMove;
    });
  }

  ///selects a col and removes any thing selected in said col from the selectedWidgets
  @override
  void selectCol(int col) {
    _semiSelectWhere((pair) => pair.col == col);
    selectedCols.add(col);
  }

  @override
  void removeRows(Iterable<int> rows) {
    final descending = rows.descendingOrder;
    for (int row in descending) {
      removeRow(row, notify: false);
    }
  }

  @override
  void removeCols(Iterable<int> cols) {
    final descending = cols.descendingOrder;
    for (int col in descending) {
      removeCol(col);
    }
  }

  @override
  void removeRow(int row, {bool notify = true}) {
    selectedRows.removeWhere((r) => r == row);
    selectedRows.inPlaceMap((r) => r.decrementedIf(r > row));

    bool inDeletedRow(RowColPair pair) => pair.row == row;
    _onSelectedAndSemiSelectedWidgets(
      (pairs) => pairs.removeWhere(inDeletedRow),
    );

    RowColPair decrementIfNeeded(RowColPair pair) =>
        pair.decementRowIf(pair.row > row);

    _onSelectedAndSemiSelectedWidgets(
      (pairs) => pairs.inPlaceMap(decrementIfNeeded),
    );
  }

  @override
  void insertRow(int row) {
    selectedRows.inPlaceMap((r) => r.incrementedIf(r >= row));

    RowColPair incrementIfNeeded(RowColPair pair) =>
        pair.incrementRowIf(pair.row >= row);

    _onSelectedAndSemiSelectedWidgets(
      (pairs) => pairs.inPlaceMap(incrementIfNeeded),
    );
  }

  @override
  void insertCol(int col, {bool notify = true}) {
    selectedCols.inPlaceMap((c) => c.incrementedIf(c >= col));

    RowColPair incrementIfNeeded(RowColPair pair) =>
        pair.incrementColIf(pair.col >= col);

    _onSelectedAndSemiSelectedWidgets(
      (pairs) => pairs.inPlaceMap(incrementIfNeeded),
    );
  }

  @override
  void removeCol(int col) {
    selectedCols.removeWhere((c) => c == col);
    selectedCols.inPlaceMap((c) => c.decrementedIf(c > col));

    bool inDeletedCol(RowColPair pair) => pair.col == col;
    _onSelectedAndSemiSelectedWidgets(
      (pairs) => pairs.removeWhere(inDeletedCol),
    );

    RowColPair decrementIfNeeded(RowColPair pair) =>
        pair.decrementColIf(pair.col > col);

    _onSelectedAndSemiSelectedWidgets(
      (pairs) => pairs.inPlaceMap(decrementIfNeeded),
    );
  }

  void _onSelectedAndSemiSelectedWidgets(Function(Set<RowColPair>) callback) {
    callback(selectedWidgets);
    callback(semiSelectedWidget);
  }

  @override
  void bulkDeselect(Iterable<RowColPair> pairs) {
    for (RowColPair pair in pairs) {
      deselectWidget(pair);
    }
  }

  @override
  void setTo(SelectionData data) {
    clear();
    selectedWidgets.addAll(data.selectedWidgets);
    selectedRows.addAll(data.selectedRows);
    selectedCols.addAll(data.selectedCols);
    semiSelectedWidget.addAll(data.semiSelectedWidget);
  }

  bool _selectedOrSemiSelected(RowColPair pair) {
    return selectedWidgets.contains(pair) || semiSelectedWidget.contains(pair);
  }

  @override
  void clear() {
    selectedRows.clear();
    selectedCols.clear();
    selectedWidgets.clear();
    semiSelectedWidget.clear();
  }

  @override
  void swapSelection(RowColPair p1, RowColPair p2) {
    final selectedP1 = _selectedOrSemiSelected(p1);
    final selectedP2 = _selectedOrSemiSelected(p2);

    //swaps the selection if they are different
    if (selectedP1 && !selectedP2) {
      deselectWidget(p1);
      selectWidget(p2);
    } else if (!selectedP1 && selectedP2) {
      selectWidget(p1);
      deselectWidget(p2);
    }
  }

  @override
  void deselectRow(int row) {
    _reselectWhere((pair) => pair.row == row);
    selectedRows.remove(row);
  }

  @override
  void deselectCol(int col) {
    _reselectWhere((pair) => pair.col == col);
    selectedCols.remove(col);
  }

  @override
  void deselectWidget(RowColPair pair) {
    selectedWidgets.remove(pair);
    semiSelectedWidget.remove(pair);
  }

  Map<String, dynamic> toJson() => _$SelectionDataToJson(this);

  factory SelectionData.fromJson(dynamic json) {
    if (json is Map) {
      return _$SelectionDataFromJson(json.cast<String, dynamic>());
    }
    return SelectionData();
  }

  SelectionData copy() => SelectionData(
    selectedRows: Set.from(selectedRows),
    selectedCols: Set.from(selectedCols),
    selectedWidgets: Set.from(selectedWidgets),
  );

  @override
  String toString() {
    return toJson().toString();
  }

  @override
  bool get isEmpty {
    final noSelectedRows = selectedRows.isEmpty;
    final noSelectedCols = selectedCols.isEmpty;
    final noSelectedWidget = selectedWidgets.isEmpty;
    final out = noSelectedWidget && noSelectedRows && noSelectedCols;
    assert(
      !(noSelectedRows && noSelectedCols) || semiSelectedWidget.isEmpty,
      """there should never be a semi selected widget if there are no selected rows or cols 
      rows = $selectedRows, cols = $selectedCols, widgets = $selectedWidgets, semi = $semiSelectedWidget""",
    );
    return out;
  }

  @override
  bool isSelectedCol(int col) => selectedCols.contains(col);

  @override
  bool isSelectedRow(int row) => selectedRows.contains(row);

  @override
  bool isSelectedWidget(RowColPair pair) => selectedWidgets.contains(pair);

  @override
  void setSelectionStatusCol(int col, bool newSelectionStatus) {
    if (newSelectionStatus) {
      selectCol(col);
    } else {
      deselectCol(col);
    }
  }

  @override
  void setSelectionStatusRow(int row, bool newSelectionStatus) {
    if (newSelectionStatus) {
      selectRow(row);
    } else {
      deselectRow(row);
    }
  }

  @override
  void setSelectionStatusWidget(RowColPair pair, bool newSelectionStatus) {
    if (newSelectionStatus) {
      selectWidget(pair);
    } else {
      deselectWidget(pair);
    }
  }

  @override
  bool isSemiSelectedWidget(RowColPair pair) =>
      semiSelectedWidget.contains(pair);
}

@JsonSerializable()
class RowColPair with JsonEncodable {
  final int row;
  final int col;

  RowColPair(this.row, this.col);
  @override
  int get hashCode => Object.hash(row, col);

  @override
  Map<String, dynamic> toJson() => _$RowColPairToJson(this);
  static RowColPair? fromJson(dynamic json) {
    if (json is Map) {
      return _$RowColPairFromJson(json.cast<String, dynamic>());
    }
    return null;
  }

  RowColPair decrementColIf(bool conditional) =>
      conditional ? withDecrementedCol : this;

  RowColPair decementRowIf(bool conditional) =>
      conditional ? withDecrementedRow : this;

  RowColPair incrementRowIf(bool conditional) =>
      conditional ? withIncrementedRow : this;

  RowColPair incrementColIf(bool conditional) =>
      conditional ? withIncrementedCol : this;
  RowColPair get withDecrementedRow => RowColPair(row - 1, col);
  RowColPair get withDecrementedCol => RowColPair(row, col - 1);

  RowColPair get withIncrementedRow => RowColPair(row + 1, col);
  RowColPair get withIncrementedCol => RowColPair(row, col + 1);

  @override
  bool operator ==(Object other) {
    if (other is! RowColPair) {
      return false;
    }
    return other.row == row && other.col == col;
  }
}
