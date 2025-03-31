import 'dart:collection';

import 'package:flutter/material.dart';

class GridNotfier<T extends Widget> extends ChangeNotifier {
  bool _draggable;
  bool get draggable => _draggable;
  set draggable(bool draggable) {
    if (_draggable != draggable) {
      _draggable = draggable;
    }
    notifyListeners();
  }

  List<List<T?>> _widgets;

  int get rows {
    return _widgets.length;
  }

  int get columns {
    return _widgets.isEmpty ? 0 : _widgets[0].length;
  }

  UnmodifiableListView<UnmodifiableListView<T?>> get widgets {
    return UnmodifiableListView(
      _widgets.map(
        (list) => UnmodifiableListView(list),
      ),
    );
  }

  void setWidgets(List<List<T?>> widgets) {
    _widgets = widgets;
    notifyListeners();
  }

  GridNotfier({required List<List<T?>> widgets, bool draggable = true})
      : _widgets = widgets,
        _draggable = draggable;
  void addRow() {
    _widgets.add(List.generate(columns, (_) => null));
    notifyListeners();
  }

  void addColumn() {
    for (List<T?> row in _widgets) {
      row.add(null);
    }
    notifyListeners();
  }

  void setWidget({required int row, required int col, T? widget}) {
    _widgets[row][col] = widget;
    notifyListeners();
  }

  T? getWidget(int row, int column) {
    return _widgets[row][column];
  }

  void move({
    required int oldRow,
    required int oldCol,
    required int newRow,
    required int newCol,
  }) {
    _widgets[newRow][newCol] = _widgets[oldRow][oldCol];
    _widgets[oldRow][oldCol] = null;
    notifyListeners();
  }

  void makeChildrenDraggable() {
    draggable = true;
    notifyListeners();
  }

  void makeChildrenUndraggable() {
    draggable = false;
    notifyListeners();
  }
}

class DraggableGrid extends StatelessWidget {
  final GridNotfier gridNotfier;
  final double dragWidth, dragHeight;
  const DraggableGrid({
    super.key,
    required this.gridNotfier,
    this.dragWidth = 250,
    this.dragHeight = 250,
  });

  List<List<IndexedWidget?>> indexedWidgetsToGrid(Set<IndexedWidget> widgets) {
    List<List<IndexedWidget?>> out = List.generate(
        gridNotfier.rows, (_) => List.filled(gridNotfier.columns, null));
    for (IndexedWidget widget in widgets) {
      out[widget.row][widget.column] = widget;
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gridNotfier,
      builder: (context, _) {
        List<List<Widget?>> widgets = gridNotfier._widgets;
        List<List<Widget>> toDisplay = [];
        for (int i = 0; i < widgets.length; i++) {
          toDisplay.add([]);
          for (int j = 0; j < widgets[0].length; j++) {
            Widget? val = widgets[i][j];
            if (val != null) {
              toDisplay.last.add(
                Expanded(
                  key: UniqueKey(),
                  child: GridCell(
                    row: i,
                    column: j,
                    dragHeight: dragHeight,
                    dragWidth: dragWidth,
                    child: IndexedWidget(row: i, column: j, widget: val),
                    notfier: gridNotfier,
                  ),
                ),
              );
            } else {
              toDisplay.last.add(
                Expanded(
                  key: UniqueKey(),
                  child: GridCell(
                      row: i,
                      column: j,
                      dragWidth: dragWidth,
                      dragHeight: dragHeight,
                      notfier: gridNotfier),
                ),
              );
            }
          }
        }
        List<Widget> rows = [];
        for (List<Widget> row in toDisplay) {
          rows.add(Expanded(child: Row(children: row)));
        }
        return SafeArea(child: Column(children: rows));
      },
    );
  }
}

class GridCell extends StatefulWidget {
  final IndexedWidget? child;
  final int row, column;
  final double dragWidth, dragHeight;
  final GridNotfier notfier;
  const GridCell(
      {super.key,
      this.child,
      required this.dragWidth,
      required this.dragHeight,
      required this.row,
      required this.column,
      required this.notfier});

  @override
  State<GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<GridCell> {
  IndexedWidget? currentWidget;
  @override
  void initState() {
    currentWidget = widget.child;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget(
      builder: (BuildContext context, List<IndexedWidget?> candidateData,
          List<dynamic> rejectedData) {
        if (currentWidget != null) {
          if (widget.notfier.draggable) {
            return Draggable<IndexedWidget>(
              feedback: SizedBox(
                width: widget.dragWidth,
                height: widget.dragHeight,
                child: currentWidget!.widget,
              ),
              data: currentWidget,
              child: currentWidget!.widget,
            );
          }
          return currentWidget!.widget;
        }
        return Container();
      },
      onAcceptWithDetails: (d) {
        setState(() {
          var data = d.data;
          if (data is IndexedWidget) {
            widget.notfier.move(
                oldRow: data.row,
                oldCol: data.column,
                newRow: widget.row,
                newCol: widget.column);

            currentWidget = data;
          }
        });
      },
      onWillAcceptWithDetails: (_) => currentWidget == null,
    );
  }
}

class IndexedWidget {
  int row, column;
  Widget widget;

  IndexedWidget({this.row = 0, this.column = 0, required this.widget});

  @override
  int get hashCode => Object.hash(row, column, widget);
  @override
  bool operator ==(Object other) {
    if (other is! IndexedWidget) return false;
    return row == other.row && column == other.column && widget == other.widget;
  }
}
