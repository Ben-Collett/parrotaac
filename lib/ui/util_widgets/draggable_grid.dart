import 'dart:collection';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parrotaac/backend/selection_data.dart';
import 'package:parrotaac/backend/value_wrapper.dart';
import 'package:parrotaac/extensions/list_extensions.dart';
import 'package:parrotaac/ui/painters/lines.dart';
import 'package:parrotaac/ui/painters/painted_color_box.dart';

///WARNING: only one grid notfier can exist per grid if it want's to be  draggable.
class GridNotifier<K, T extends Widget> extends ChangeNotifier {
  bool _draggable;
  bool _selectMode;
  void Function(int, int)? onEmptyPressed;
  bool get selectMode => _selectMode;
  set selectMode(bool val) {
    if (val != _selectMode) {
      _selectMode = val;
      selectionController.clear();
      notifyListeners();
    }
  }

  void rawUpdateSelectMode(bool val) => _selectMode = val;

  final SelectionDataController selectionController;
  bool get draggable => _draggable;
  T? Function(dynamic)? _toWidget;
  T? Function(dynamic)? get toWidget => _toWidget;
  ValueNotifier<Color> backgroundColorNotifier = ValueNotifier(Colors.white);

  List<Widget>? _widgetListCache;
  void _invalidateWidgetListCache() {
    _widgetListCache = null;
  }

  void Function(RowColPair p1, RowColPair p2)? onSwap;

  ///this is exclusively used by the grid, and means that only one grid notfier can exist per grid if it want's to be  draggable.
  final ValueWrapper<Size> _childSize = ValueWrapper(Size.zero);

  set toWidget(T? Function(dynamic)? toWid) {
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
    selectionController.dispose();
    super.dispose();
  }

  void fullUpdate() {
    _invalidateWidgetCacheAndNotifyListeners();
  }

  void update() {
    notifyListeners();
  }

  List<List<K?>> _data;

  Widget? _emptySpotWidget;
  bool _hideEmptySpotWidget = false;
  set hideEmptySpotWidget(bool value) {
    _hideEmptySpotWidget = value;
    _invalidateWidgetCacheAndNotifyListeners();
  }

  Widget? get emptySpotWidget => _hideEmptySpotWidget ? null : _emptySpotWidget;
  set emptySpotWidget(Widget? widget) {
    _emptySpotWidget = widget;
    _invalidateWidgetCacheAndNotifyListeners();
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

  UnmodifiableListView<UnmodifiableListView<K?>> get data {
    return UnmodifiableListView(
      _data.map((list) => UnmodifiableListView(list)),
    );
  }

  GridNotifier({
    required List<List<K?>> data,
    bool draggable = true,
    bool selectMode = false,
    T? Function(dynamic)? toWidget,
    this.onEmptyPressed,
    this.onSwap,
  }) : _data = data,
       _draggable = draggable,
       _selectMode = selectMode,
       selectionController = SelectionDataController(SelectionData()),
       _toWidget = toWidget;
  void addRow() {
    if (rows == 0) {
      _data.add([null]);
    } else {
      _data.add(List.generate(columns, (_) => null));
    }
    _invalidateWidgetCacheAndNotifyListeners();
  }

  void swap(RowColPair p1, RowColPair p2, {bool swapSelection = false}) {
    if (swapSelection) {
      selectionController.swapSelection(p1, p2);
    }
    _invalidateWidgetCacheAndNotifyListeners();
    if (onSwap != null) {
      onSwap?.call(p1, p2);
    }
  }

  void insertColumn(int colIndex, List<K?> column, {bool updateUi = true}) {
    assert(
      _data.isEmpty || column.length == _data.length,
      "Column length must match number of rows",
    );

    _data.insertCol(colIndex, column);
    _invalidateWidgetCacheAndNotifyListeners();
  }

  void insertRow(int rowIndex, List<K?> row) {
    List<K?> newRow = List<K?>.from(row);
    _data.insertRow(rowIndex, newRow);

    _invalidateWidgetCacheAndNotifyListeners();
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
    _invalidateWidgetCacheAndNotifyListeners();
  }

  void removeRows(Iterable<int> rows) {
    _data.removeRows(rows);
    selectionController.removeRows(rows);
    _invalidateWidgetCacheAndNotifyListeners();
  }

  void removeCols(Iterable<int> cols) {
    _data.removeCols(cols);
    selectionController.removeCols(cols);
    _invalidateWidgetCacheAndNotifyListeners();
  }

  void bulkRemoveData(Iterable<RowColPair> pairs) {
    _data.bulkUpdate(positions: pairs, val: null);
    selectionController.bulkDeselect(pairs);
    _invalidateWidgetCacheAndNotifyListeners();
  }

  void removeAt(int row, int col) {
    _data[row][col] = null;
    selectionController.deselectWidget(RowColPair(row, col));

    _invalidateWidgetCacheAndNotifyListeners();
  }

  void removeRow(int row) {
    _data.removeRow(row);
    selectionController.removeRow(row);
    _invalidateWidgetCacheAndNotifyListeners();
  }

  void removeCol(int col) {
    _data.removeCol(col);
    selectionController.removeCol(col);

    _invalidateWidgetCacheAndNotifyListeners();
  }

  void setWidget({required int row, required int col, K? data}) {
    _data[row][col] = data;
    _invalidateWidgetCacheAndNotifyListeners();
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

  void _invalidateWidgetCacheAndNotifyListeners() {
    _invalidateWidgetListCache();
    notifyListeners();
  }

  ///cleanUp allows you to modify the old data before it is lost primarily intended for disposing of notifiers
  void setData(
    List<List<K?>> data, {
    Function(Iterable<K?> originalData)? cleanUp,
  }) {
    Iterable<K> originalData = [];
    if (cleanUp != null) {
      originalData = this.data.flatten<K?>().nonNulls.cast<K>();
    }
    _data = data;
    _invalidateWidgetCacheAndNotifyListeners();
    cleanUp?.call(originalData);
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

mixin SelectIndecatorStatusDimensions {
  static Widget _wrapWidgetIfNeeded(
    Widget widget,
    GridNotifier grid,
    int row,
    int col,
  ) {
    return ListenableBuilder(
      listenable: grid.selectionController,
      builder: (context, child) {
        final data = _SelectionIndicatorData.fromGrid(grid, row, col);
        final backgroundColor = data.backgroundColor;
        final child = data.widget;
        if (grid.selectMode) {
          return LayoutBuilder(
            builder: (context, constrains) {
              Size size = Size(constrains.maxWidth, constrains.maxHeight);
              final Rect rect;
              if (widget is SelectIndecatorStatusDimensions) {
                final dim = widget as SelectIndecatorStatusDimensions;
                rect = dim._selectIndecatorDimensions(size);
              } else {
                final radius = _defaultComputeIndicatorSize(size);
                rect = Rect.fromLTWH(0, 0, radius, radius);
              }

              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: size.width,
                    height: size.height,
                    child: widget,
                  ),
                  Positioned.fromRect(
                    rect: rect,
                    child: IgnorePointer(
                      child: Container(
                        width: rect.width,
                        height: rect.height,
                        decoration: BoxDecoration(
                          //border: Border.all(color: Colors.black),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(blurRadius: 1, spreadRadius: 1),
                          ],
                          color: backgroundColor,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
        return widget;
      },
    );
  }

  Rect _selectIndecatorDimensions(Size size) {
    final double indicatorSize = selectIndecatorSize(size);
    final Offset indicatorOffset = selectIndecatorOffset(size);

    return Rect.fromLTWH(
      indicatorOffset.dx,
      indicatorOffset.dy,
      indicatorSize,
      indicatorSize,
    );
  }

  Offset selectIndecatorOffset(Size size) => Offset.zero;
  double selectIndecatorSize(Size size) => _defaultComputeIndicatorSize(size);

  static double _defaultComputeIndicatorSize(Size size) =>
      0.2 * size.shortestSide;
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
    if (rowCount == 0 || colCount == 0) {
      return;
    }
    final size = context.size;

    final dpr = PlatformDispatcher.instance.views.first.devicePixelRatio;
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

        const z = 0.0;
        const w = 1.0;

        context.paintChild(
          childIndex,
          transform: Matrix4.identity()..translateByDouble(x, y, z, w),
        );

        x += logicalW;
        childIndex++;
      }

      y += logicalH;
    }
  }

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    if (rowCount == 0 || colCount == 0) {
      return BoxConstraints(maxHeight: 0, maxWidth: 0);
    }
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

    // update notifier with the actual (logical) childgrid size for this index
    notifier._childSize.value = Size(logicalW, logicalH);

    return BoxConstraints.tightFor(width: logicalW, height: logicalH);
  }

  @override
  bool shouldRepaint(covariant FlowDelegate oldDelegate) {
    oldDelegate = oldDelegate as GridFlowDelegate;
    return oldDelegate.rowCount != rowCount || oldDelegate.colCount != colCount;
  }
}

class GridCell extends StatefulWidget {
  final Cell cell;
  final GridNotifier gridNotifier;

  const GridCell(this.cell, this.gridNotifier, {super.key});

  @override
  State<GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<GridCell> {
  @override
  Widget build(BuildContext context) {
    Widget child;

    final row = widget.cell.row;
    final col = widget.cell.col;

    if (widget.cell.value == null &&
        widget.gridNotifier.emptySpotWidget != null) {
      child = EmptySpotDragTarget(cellWidget: widget);
    } else if (widget.cell.value != null &&
        widget.gridNotifier.toWidget != null &&
        widget.gridNotifier.draggable) {
      final currentWidget = widget.gridNotifier.toWidget!(widget.cell.value)!;
      child = Draggable<Cell>(
        data: Cell(widget.cell.row, widget.cell.col, widget.cell),
        //WARNING: resizing will not update
        feedback: ValueWrapperSizedBox(
          size: widget.gridNotifier._childSize,
          child: currentWidget,
        ),
        childWhenDragging: ColoredBox(color: Colors.grey),
        child: SelectIndecatorStatusDimensions._wrapWidgetIfNeeded(
          currentWidget,
          widget.gridNotifier,
          row,
          col,
        ),
      );
    } else if (widget.cell.value != null &&
        widget.gridNotifier.toWidget != null) {
      child = SelectIndecatorStatusDimensions._wrapWidgetIfNeeded(
        widget.gridNotifier.toWidget!(widget.cell.value) as Widget,
        widget.gridNotifier,
        row,
        col,
      );
    } else {
      child = Container();
    }

    return child;
  }
}

class EmptySpotDragTarget extends StatefulWidget {
  const EmptySpotDragTarget({super.key, required this.cellWidget});

  final GridCell cellWidget;

  @override
  State<EmptySpotDragTarget> createState() => _EmptySpotDragTargetState();
}

class _EmptySpotDragTargetState extends State<EmptySpotDragTarget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Cell>(
      onWillAcceptWithDetails: (data) {
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (_) {
        setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        widget.cellWidget.gridNotifier.swap(
          RowColPair(details.data.row, details.data.col),
          RowColPair(widget.cellWidget.cell.row, widget.cellWidget.cell.col),
          swapSelection: false, //handled by the event handler
        );
      },
      builder: (context, List<Cell?> accepted, List<Object?> rejected) {
        if (_isHovering) {
          return ColoredBox(color: Colors.lightGreenAccent);
        }

        final row = widget.cellWidget.cell.row;
        final col = widget.cellWidget.cell.col;
        final grid = widget.cellWidget.gridNotifier;

        return SelectIndecatorStatusDimensions._wrapWidgetIfNeeded(
          InteractiveEmptySpotWidget(cell: widget.cellWidget),
          grid,
          row,
          col,
        );
      },
    );
  }
}

class InteractiveEmptySpotWidget extends StatefulWidget
    with SelectIndecatorStatusDimensions {
  const InteractiveEmptySpotWidget({super.key, required this.cell});

  final GridCell cell;
  Widget? get _emptySpotWidget => cell.gridNotifier.emptySpotWidget;

  @override
  Offset selectIndecatorOffset(Size size) {
    if (_emptySpotWidget is SelectIndecatorStatusDimensions) {
      final data = _emptySpotWidget as SelectIndecatorStatusDimensions;
      return data.selectIndecatorOffset(size);
    }
    return super.selectIndecatorOffset(size);
  }

  @override
  double selectIndecatorSize(Size size) {
    if (_emptySpotWidget is SelectIndecatorStatusDimensions) {
      final data = _emptySpotWidget as SelectIndecatorStatusDimensions;
      return data.selectIndecatorSize(size);
    }
    return super.selectIndecatorSize(size);
  }

  @override
  State<InteractiveEmptySpotWidget> createState() =>
      _InteractiveEmptySpotWidgetState();
}

class _InteractiveEmptySpotWidgetState
    extends State<InteractiveEmptySpotWidget> {
  late final ValueNotifier<Color> backgroundColorNotifier;
  @override
  void initState() {
    backgroundColorNotifier = ValueNotifier(Colors.white);
    super.initState();
  }

  @override
  void dispose() {
    backgroundColorNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.cell.gridNotifier.backgroundColorNotifier,
      builder: (context, value, child) {
        return Material(
          color: value,
          child: InkWell(
            onTap: () => widget.cell.gridNotifier.onEmptyPressed?.call(
              widget.cell.cell.row,
              widget.cell.cell.col,
            ),
            child: widget._emptySpotWidget!,
          ),
        );
      },
    );
  }
}

class _SelectionIndicatorData {
  final Color backgroundColor;
  final Widget? widget;
  const _SelectionIndicatorData(this.backgroundColor, this.widget);

  factory _SelectionIndicatorData.fromGrid(
    GridNotifier grid,
    int row,
    int col,
  ) {
    if (!grid.selectMode) {
      return _SelectionIndicatorData(Colors.white, null);
    }
    final selectController = grid.selectionController;
    final selectedRow = selectController.data.selectedRows.contains(row);
    final selectedCol = selectController.data.selectedCols.contains(col);
    final selectedWidget = selectController.data.selectedWidgets.contains(
      RowColPair(row, col),
    );

    final Color backgroundColor;
    final Widget? selectedWidgetIcon;
    if (selectedRow && selectedCol) {
      backgroundColor = Colors.green;

      selectedWidgetIcon = LinePaint(type: SelectorType.plusSign);
    } else if (selectedRow) {
      backgroundColor = Colors.purple;
      selectedWidgetIcon = LinePaint(type: SelectorType.horizontal);
    } else if (selectedCol) {
      backgroundColor = Colors.orange;
      selectedWidgetIcon = LinePaint(type: SelectorType.vertical);
    } else if (selectedWidget) {
      backgroundColor = Colors.blue;
      selectedWidgetIcon = LinePaint(type: SelectorType.checkMark);
    } else {
      backgroundColor = Colors.white;
      selectedWidgetIcon = null;
    }
    return _SelectionIndicatorData(backgroundColor, selectedWidgetIcon);
  }
}

///WARNING: doesn't resize when notifier changes
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
