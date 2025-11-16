import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/quick_store.dart';
import 'package:parrotaac/backend/selection_data.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/backend/swap_data.dart';
import 'package:parrotaac/extensions/map_extensions.dart';
import 'package:parrotaac/extensions/obf_extensions.dart';

class WorkingSelectionHistory extends ChangeNotifier {
  ///boardId -> SelectionData
  ///if a SelectionData is emptied it should be immediately removed from data
  final Map<String, SelectionData> _data = {};

  UnmodifiableMapView<String, SelectionData> get data =>
      UnmodifiableMapView(_data);

  int get getSelectionDataCount {
    assert(
      !_data.values.any((data) => data.isEmpty),
      "empty selection data should have been removed",
    );
    return _data.length;
  }

  final ParrotProject project;
  final QuickStore _store;
  bool enabled = true;
  WorkingSelectionHistory._(this._store, this.project);

  Future<void> clear() async {
    final Future future = _store.clear();
    _data.clear();
    notifyListeners();
    await future;
  }

  Map<String, Set<int>> selectedRows() => _data
      .mapValue<Set<int>>((v) => v.selectedRows)
      .where((key, val) => val.isNotEmpty);

  Map<String, Set<int>> selectedCols() => _data
      .mapValue<Set<int>>((v) => v.selectedCols)
      .where((key, val) => val.isNotEmpty);

  Map<String, Set<RowColPair>> selectedWidgets() => _data
      .mapValue<Set<RowColPair>>((v) => v.selectedWidgets)
      .where((key, val) => val.isNotEmpty);

  ///filters out any selectedWidgets with a null value in that board position(i.e. all empty spots)
  Map<String, Set<RowColPair>> get selectedButtons {
    final Map<String, Set<RowColPair>> out = {};
    for (final e in _data.entries) {
      if (e.value.isEmpty) {
        continue;
      }
      final boardId = e.key;
      final Obf? board = project.findBoardById(boardId);
      if (board == null) {
        SimpleLogger().logWarning("couldn't find board: $boardId");
        continue;
      }
      final buttons = e.value.selectedWidgets
          .where((pair) => board.safeGetButtonData(pair) != null)
          .toSet();

      out[boardId] = buttons;
    }
    return out;
  }

  SelectionData? findSelectionFromId(String id) => _data[id];

  bool get isNotEmpty => _data.isNotEmpty;
  bool get isEmpty => _data.isEmpty;

  ///returns true if a row and col of equal length with no widgets selected
  ///or if two rows of equal length are selected and no widgets are selected
  ///or if two cols of equal length are selected and no widgets are selected
  ///or if two widgets are selected but no rows or columns are.
  ///note: the widgets can be selected even if they do not exist(there null)
  bool get swapableSelection => swapData != null;

  SwapData? get swapData => SwapData.getSwapData(this);

  bool get deletableIsSelected {
    for (final entry in data.entries) {
      final SelectionData data = entry.value;
      if (data.selectedRows.isNotEmpty) {
        return true;
      }

      if (data.selectedCols.isNotEmpty) {
        return true;
      }

      if (data.selectedWidgets.isNotEmpty) {
        final id = entry.key;
        final Obf? board = project.findBoardById(id);
        assert(board != null, "failed to find board in selection history");
        if (board != null) {
          final positions = data.selectedWidgets;
          if (board.hasButtonAtAny(positions)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> updateData(String id, Function(SelectionData) change) async {
    if (!enabled) {
      return;
    }
    if (!_data.containsKey(id)) {
      _data[id] = SelectionData();
    }
    final data = _data[id]!;
    change(data);
    final Future future;
    if (data.isEmpty) {
      _data.remove(id);
      future = _store.removeFromKey(id);
    } else {
      future = _store.writeData(id, data.toJson());
    }
    notifyListeners();
    await future;
  }

  factory WorkingSelectionHistory.from(
    QuickStore quickstore, {
    required ParrotProject project,
  }) {
    final selections = WorkingSelectionHistory._(quickstore, project);

    final keys = quickstore.keys;

    for (final key in keys) {
      if (key is String) {
        final SelectionData data = SelectionData.fromJson(quickstore[key]);
        selections._data[key] = data;
      }
    }

    return selections;
  }
  @override
  String toString() {
    return _data.toString();
  }
}
