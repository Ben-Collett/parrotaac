import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:parrotaac/ui/painters/painted_color_box.dart';

class GridNotifier<T extends Widget> extends ChangeNotifier {
  bool _draggable;
  bool get draggable => _draggable;
  T? Function(Object?)? _toWidget;
  T? Function(Object?)? get toWidget => _toWidget;
  ValueNotifier<Color> backgroundColorNotifier = ValueNotifier(Colors.white);

  void Function(int oldRow, int oldCol, int newRow, int newCol)? onSwap;

  set toWidget(T? Function(Object?)? toWid) {
    _toWidget = toWid;
    notifyListeners();
  }

  set draggable(bool draggable) {
    if (_draggable != draggable) {
      _draggable = draggable;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    backgroundColorNotifier.dispose();
    super.dispose();
  }

  void update() {
    notifyListeners();
  }

  List<List<Object?>> _data;

  Widget? _emptySpotWidget;
  bool _hideEmptySpotWidget = false;
  set hideEmptySpotWidget(bool value) {
    _hideEmptySpotWidget = value;
    notifyListeners();
  }

  Widget? get emptySpotWidget => _hideEmptySpotWidget ? null : _emptySpotWidget;
  set emptySpotWidget(Widget? widget) => _emptySpotWidget = widget;

  int get rows {
    return _data.length;
  }

  int get columns {
    return _data.isEmpty ? 0 : _data[0].length;
  }

  UnmodifiableListView<UnmodifiableListView<T?>> get widgets {
    return UnmodifiableListView(
      _data.map(
        (list) => UnmodifiableListView(list.map(toWidget!)),
      ),
    );
  }

  UnmodifiableListView<UnmodifiableListView<Object?>> get data {
    return UnmodifiableListView(
      _data.map(
        (list) => UnmodifiableListView(list),
      ),
    );
  }

  void Function(int, int)? onEmptyPressed;
  GridNotifier({
    required List<List<Object?>>
        data, //TODO: I need to make sure the list is of list<list<object?>> if they pass a list<list<child?>> then add row crashes
    bool draggable = true,
    T? Function(Object?)? toWidget,
    this.onEmptyPressed,
    this.onSwap,
  })  : _data = data,
        _draggable = draggable,
        _toWidget = toWidget;
  void addRow() {
    if (rows == 0) {
      _data.add([null]);
    } else {
      _data.add(List.generate(columns, (_) => null));
    }
    notifyListeners();
  }

  void swap(int oldRow, int oldCol, int newRow, int newCol) {
    final Object? old = _data[oldRow][oldCol];
    _data[oldRow][oldCol] = _data[newRow][newCol];
    _data[newRow][newCol] = old;
    notifyListeners();
  }

  void insertColumn(int colIndex, List<Object?> column) {
    assert(_data.isEmpty || column.length == _data.length,
        "Column length must match number of rows");

    for (int row = 0; row < column.length; row++) {
      _data[row].insert(colIndex, column[row]);
    }

    notifyListeners();
  }

  void insertRow(int rowIndex, List<Object?> row) {
    List<Object?> newRow = List<Object?>.from(row);
    _data.insert(rowIndex, newRow);
    notifyListeners();
  }

  void forEach(
    void Function(Object?) callback, {
    bool notify = false,
  }) {
    for (List<Object?> row in _data) {
      for (Object? obj in row) {
        callback(obj);
      }
    }
    if (notify) {
      notifyListeners();
    }
  }

  void forEachIndexed(
    void Function(Object?, int, int) callback, {
    bool notify = false,
  }) {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        callback(_data[i][j], i, j);
      }
    }
    if (notify) {
      notifyListeners();
    }
  }

  void addColumn() {
    if (rows == 0) {
      _data.add([null]);
    } else {
      for (List<Object?> row in _data) {
        row.add(null);
      }
    }
    notifyListeners();
  }

  void removeAt(int row, int col) {
    _data[row][col] = null;
    notifyListeners();
  }

  void removeRow(int row) {
    _data.removeAt(row);
    notifyListeners();
  }

  void removeCol(int col) {
    for (List<Object?> row in _data) {
      row.removeAt(col);
    }
    notifyListeners();
  }

  void setWidget({required int row, required int col, Object? data}) {
    _data[row][col] = data;
    notifyListeners();
  }

  T? getWidget(int row, int column) {
    return widgets[row][column];
  }

  void setData(List<List<Object?>> data) {
    _data = data;
    notifyListeners();
  }

  void move({
    required int oldRow,
    required int oldCol,
    required int newRow,
    required int newCol,
  }) {
    final old = _data[oldRow][oldCol];
    _data[oldRow][oldCol] = _data[newRow][newCol];
    _data[newRow][newCol] = old;

    if (onSwap != null && _data[newRow][newCol] != null) {
      onSwap!(oldRow, oldCol, newRow, newCol);
    }

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
  final GridNotifier gridNotfier;
  const DraggableGrid({
    super.key,
    required this.gridNotfier,
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
    //TODO:I should add a way for the user to make buttons bigger possible using a layoutbuider inside a container then allowng them to define widths and heights for each in the notfier. or thats a terrible idea
    //WARNING: while being dragged size won't change with window size changes, this will in all likelihood effect no one except possible linux users using tiling window mangers, i.e. the only way I can think to actually do this
    //if the grid adds a row or column mid drag the size won't change, again shouldn't happen and debatable if we should have it change when it does
    return CustomPaint(
      painter: ColorBoxPainter(
        colorNotifier: gridNotfier.backgroundColorNotifier,
      ),
      child: ListenableBuilder(
          listenable: gridNotfier,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final double height = constraints.maxHeight / gridNotfier.rows;
                final double width = constraints.maxWidth / gridNotfier.columns;
                List<List<Widget?>> widgets = gridNotfier.widgets;
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
                            dragHeight: height,
                            dragWidth: width,
                            child:
                                IndexedWidget(row: i, column: j, widget: val),
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
                              emptyWidget: IndexedWidget(
                                row: i,
                                column: j,
                                widget: gridNotfier.emptySpotWidget,
                              ),
                              dragWidth: width,
                              dragHeight: height,
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
          }),
    );
  }
}

class GridCell extends StatefulWidget {
  final IndexedWidget? child;
  final IndexedWidget? emptyWidget;
  final int row, column;
  final double dragWidth, dragHeight;
  final GridNotifier notfier;
  const GridCell(
      {super.key,
      this.child,
      this.emptyWidget,
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
  IndexedWidget? emptyWidget;
  @override
  void initState() {
    currentWidget = widget.child;
    emptyWidget = widget.emptyWidget;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget tempEmptyWidget = emptyWidget?.widget ?? Container();

    if (widget.notfier.onEmptyPressed != null && emptyWidget != null) {
      tempEmptyWidget = InkWell(
        onTap: () {
          int row = emptyWidget!.row;
          int col = emptyWidget!.column;
          widget.notfier.onEmptyPressed!(row, col);
        },
        child: tempEmptyWidget,
      );
    }
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
              childWhenDragging: Container(color: Colors.grey),
              child: currentWidget!.widget,
            );
          }
          return currentWidget!.widget;
        }
        return InkWell(child: tempEmptyWidget);
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
  Widget? _widget;
  Widget get widget {
    return _widget ?? Container();
  }

  set widget(Widget widget) {
    _widget = widget;
  }

  IndexedWidget({this.row = 0, this.column = 0, Widget? widget})
      : _widget = widget;

  @override
  int get hashCode => Object.hash(row, column, widget);
  @override
  bool operator ==(Object other) {
    if (other is! IndexedWidget) return false;
    return row == other.row && column == other.column && widget == other.widget;
  }
}
