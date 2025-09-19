import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:parrotaac/backend/value_wrapper.dart';
import 'package:parrotaac/ui/painters/painted_color_box.dart';

class GridNotifier<T extends Widget> extends ChangeNotifier {
  bool _draggable;
  bool get draggable => _draggable;
  T? Function(Object?)? _toWidget;
  T? Function(Object?)? get toWidget => _toWidget;
  ValueNotifier<Color> backgroundColorNotifier = ValueNotifier(Colors.white);

  List<Widget>? _widgetListCache;
  void _invalidateWidgetListCache() {
    _widgetListCache = null;
  }

  void Function(int oldRow, int oldCol, int newRow, int newCol)? onSwap;

  ///this is exclusively used by the grid, and means that only one grid notfier can exist per grid if it want's to be  draggable.
  ValueWrapper<Size> childSize = ValueWrapper(Size.zero);

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
    _invalidateWidgetListCache();
    notifyListeners();
  }

  Widget? get emptySpotWidget => _hideEmptySpotWidget ? null : _emptySpotWidget;
  set emptySpotWidget(Widget? widget) {
    _emptySpotWidget = widget;
    _invalidateWidgetListCache();
    notifyListeners();
  }

  int get rows {
    return _data.length;
  }

  int get columns {
    return _data.isEmpty ? 0 : _data[0].length;
  }

  UnmodifiableListView<UnmodifiableListView<T?>> get widgets {
    return UnmodifiableListView(
      _data.map((list) => UnmodifiableListView(list.map(toWidget!))),
    );
  }

  UnmodifiableListView<UnmodifiableListView<Object?>> get data {
    return UnmodifiableListView(
      _data.map((list) => UnmodifiableListView(list)),
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
  }) : _data = data,
       _draggable = draggable,
       _toWidget = toWidget;
  void addRow() {
    if (rows == 0) {
      _data.add([null]);
    } else {
      _data.add(List.generate(columns, (_) => null));
    }
    _invalidateWidgetListCache();
    notifyListeners();
  }

  void swap(int oldRow, int oldCol, int newRow, int newCol) {
    final Object? old = _data[oldRow][oldCol];
    _data[oldRow][oldCol] = _data[newRow][newCol];
    _data[newRow][newCol] = old;

    _invalidateWidgetListCache();
    notifyListeners();
  }

  void insertColumn(int colIndex, List<Object?> column) {
    assert(
      _data.isEmpty || column.length == _data.length,
      "Column length must match number of rows",
    );

    for (int row = 0; row < column.length; row++) {
      _data[row].insert(colIndex, column[row]);
    }

    _invalidateWidgetListCache();
    notifyListeners();
  }

  void insertRow(int rowIndex, List<Object?> row) {
    List<Object?> newRow = List<Object?>.from(row);
    _data.insert(rowIndex, newRow);

    _invalidateWidgetListCache();
    notifyListeners();
  }

  void forEach(void Function(Object?) callback, {bool notify = false}) {
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
    _invalidateWidgetListCache();

    notifyListeners();
  }

  void removeAt(int row, int col) {
    _data[row][col] = null;

    _invalidateWidgetListCache();
    notifyListeners();
  }

  void removeRow(int row) {
    _data.removeAt(row);

    _invalidateWidgetListCache();
    notifyListeners();
  }

  void removeCol(int col) {
    for (List<Object?> row in _data) {
      row.removeAt(col);
    }

    _invalidateWidgetListCache();
    notifyListeners();
  }

  void setWidget({required int row, required int col, Object? data}) {
    _data[row][col] = data;

    _invalidateWidgetListCache();
    notifyListeners();
  }

  T? getWidget(int row, int column) {
    return widgets[row][column];
  }

  List<Widget> get widgetList {
    if (_widgetListCache != null) return _widgetListCache!;
    List<Widget> out = [];
    for (int row = 0; row < data.length; row++) {
      for (int col = 0; col < data[row].length; col++) {
        final val = _data[row][col];
        out.add(GridCell(Cell(row, col, val), this));
      }
    }

    _widgetListCache = out;

    return out;
  }

  void setData(List<List<Object?>> data) {
    _data = data;
    _invalidateWidgetListCache();
    notifyListeners();
  }

  void move({
    required int oldRow,
    required int oldCol,
    required int newRow,
    required int newCol,
  }) {
    _invalidateWidgetListCache();
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
  const DraggableGrid({super.key, required this.gridNotfier});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ColorBoxPainter(
        colorNotifier: gridNotfier.backgroundColorNotifier,
      ),
      child: ListenableBuilder(
        listenable: gridNotfier,
        builder: (context, _) {
          final children = gridNotfier.widgetList;
          return Flow(
            delegate: GridFlowDelegate(gridNotfier),
            children: children,
          );
        },
      ),
    );
  }
}

class GridFlowDelegate extends FlowDelegate {
  final GridNotifier notifier;
  final int rowCount;
  final int colCount;

  GridFlowDelegate(this.notifier)
    : rowCount = notifier.rows,
      colCount = notifier.columns;

  @override
  void paintChildren(FlowPaintingContext context) {
    final size = context.size;
    final dpr = WidgetsBinding.instance.window.devicePixelRatio;

    // total physical pixels
    final totalPhysW = (size.width * dpr).round();
    final totalPhysH = (size.height * dpr).round();

    final basePhysW = totalPhysW ~/ colCount;
    final remW = totalPhysW - basePhysW * colCount; // leftover physical pixels

    final basePhysH = totalPhysH ~/ rowCount;
    final remH = totalPhysH - basePhysH * rowCount;

    int childIndex = 0;
    double y = 0.0;

    for (int r = 0; r < rowCount; r++) {
      final physH = basePhysH + (r < remH ? 1 : 0);
      final logicalH = physH / dpr;

      double x = 0.0;
      for (int c = 0; c < colCount; c++) {
        final physW = basePhysW + (c < remW ? 1 : 0);
        final logicalW = physW / dpr;

        context.paintChild(
          childIndex,
          transform: Matrix4.identity()..translate(x, y),
        );

        x += logicalW;
        childIndex++;
      }

      y += logicalH;
    }
  }

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    final dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final totalPhysW = (constraints.maxWidth * dpr).round();
    final totalPhysH = (constraints.maxHeight * dpr).round();

    final basePhysW = totalPhysW ~/ colCount;
    final remW = totalPhysW - basePhysW * colCount;

    final basePhysH = totalPhysH ~/ rowCount;
    final remH = totalPhysH - basePhysH * rowCount;

    final col = i % colCount;
    final row = i ~/ colCount;

    final physW = basePhysW + (col < remW ? 1 : 0);
    final physH = basePhysH + (row < remH ? 1 : 0);

    final logicalW = physW / dpr;
    final logicalH = physH / dpr;

    // update notifier with the actual (logical) child size for this index
    notifier.childSize.value = Size(logicalW, logicalH);

    return BoxConstraints.tightFor(width: logicalW, height: logicalH);
  }

  @override
  bool shouldRepaint(covariant FlowDelegate oldDelegate) {
    oldDelegate = oldDelegate as GridFlowDelegate;
    return oldDelegate.rowCount != rowCount || oldDelegate.colCount != colCount;
  }
}

class GridCell extends StatefulWidget {
  final Cell value;
  final GridNotifier gridNotifier;

  const GridCell(this.value, this.gridNotifier, {super.key});

  @override
  State<GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<GridCell> {
  @override
  Widget build(BuildContext context) {
    Widget child;

    if (widget.value.value == null &&
        widget.gridNotifier.emptySpotWidget != null) {
      child = DragTarget<Cell>(
        builder: (context, List<Cell?> acceptData, List<Object?> rejectData) =>
            Listener(
              onPointerDown: (_) => widget.gridNotifier.onEmptyPressed?.call(
                widget.value.row,
                widget.value.col,
              ),
              child: widget.gridNotifier.emptySpotWidget!,
            ),
        onAcceptWithDetails: (d) => widget.gridNotifier.move(
          oldRow: d.data.row,
          oldCol: d.data.col,
          newRow: widget.value.row,
          newCol: widget.value.col,
        ),
      );
    } else if (widget.value.value != null &&
        widget.gridNotifier.toWidget != null &&
        widget.gridNotifier.draggable) {
      final currentWidget = widget.gridNotifier.toWidget!(widget.value.value)!;
      child = Draggable<Cell>(
        data: Cell(widget.value.row, widget.value.col, widget.value),
        //WARNING: resizing will not update
        feedback: ValueWrapperSizedBox(
          size: widget.gridNotifier.childSize,
          child: currentWidget,
        ),
        childWhenDragging: ColoredBox(color: Colors.grey),
        child: currentWidget,
      );
    } else if (widget.value.value != null &&
        widget.gridNotifier.toWidget != null) {
      child = widget.gridNotifier.toWidget!(widget.value.value)!;
    } else {
      child = Container();
    }

    return child;
  }
}

class ValueWrapperSizedBox extends StatelessWidget {
  final Widget child;
  final ValueWrapper<Size> size;
  const ValueWrapperSizedBox({
    super.key,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.value.width,
      height: size.value.height,
      child: child,
    );
  }
}

class Cell {
  int row, col;
  Object? value;
  Cell(this.row, this.col, this.value);
}
