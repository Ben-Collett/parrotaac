import 'package:flutter/material.dart';
import 'package:parrotaac/backend/selection_history.dart';
import 'package:parrotaac/backend/settings_utils.dart';
import 'package:parrotaac/ui/appbar_widgets/compute_contrasting_color.dart';
import 'package:parrotaac/ui/board_modes.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/painters/three_squares.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';
import 'package:parrotaac/ui/util_widgets/icon_button_on_notfier.dart';
import 'package:parrotaac/ui/util_widgets/paint_button.dart';

class BoardSidebar extends StatelessWidget {
  final ProjectEventHandler eventHandler;
  final ValueNotifier<BoardMode> boardMode;
  final WorkingSelectionHistory history;
  const BoardSidebar({
    super.key,
    required this.eventHandler,
    required this.boardMode,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = getAppbarColor();

    final foregroundColor = computeContrastingColor(backgroundColor);
    const longSideLength = 57.0;
    const shortSideLength = 30.0;
    final swapButton = _SwapButton(
      history: history,
      grid: eventHandler.gridNotfier,
      handler: eventHandler,
      color: foregroundColor,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final addColButton = PaintedButton(
          onPressed: eventHandler.addCol,
          width: shortSideLength,
          height: longSideLength,
          painter: MultiSquarePainter(
            circleType: CircleType.add,
            foregroundColor: foregroundColor,
          ),
        );

        final addRowButton = PaintedButton(
          onPressed: eventHandler.addRow,
          width: longSideLength,
          height: shortSideLength,
          painter: MultiSquarePainter(
            circleType: CircleType.add,
            orientation: RectangleOrientation.horizontal,
            foregroundColor: foregroundColor,
          ),
        );
        return ValueListenableBuilder(
          valueListenable: boardMode,
          builder: (context, mode, child) {
            final selectRowButton = AnimatedSelectButton(
              boardMode: boardMode,
              activeOn: BoardMode.selectRowMode,
              width: longSideLength,
              height: shortSideLength,
              orientation: RectangleOrientation.horizontal,
              foregroundColor: foregroundColor,
            );

            final selectButtonButton = AnimatedSelectButton(
              boardMode: boardMode,
              activeOn: BoardMode.selectWidgetMode,
              width: longSideLength * 2 / 3,
              height: longSideLength * 2 / 3,
              orientation: RectangleOrientation.square,
              foregroundColor: foregroundColor,
            );
            final selectColButton = AnimatedSelectButton(
              boardMode: boardMode,
              activeOn: BoardMode.selectColMode,
              width: shortSideLength,
              height: longSideLength,
              orientation: RectangleOrientation.vertical,
              foregroundColor: foregroundColor,
            );

            return ColoredBox(
              color: getAppbarColor(),
              child: Column(
                children: [
                  addColButton,
                  addRowButton,
                  selectButtonButton,
                  selectColButton,
                  selectRowButton,
                  swapButton,
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AnimatedSelectButton extends StatelessWidget {
  final ValueNotifier<BoardMode> boardMode;
  final BoardMode activeOn;
  final double width, height;
  final RectangleOrientation orientation;
  final Color foregroundColor;

  void _toggleBoardMode() => boardMode.value = boardMode.value == activeOn
      ? BoardMode.builderMode
      : activeOn;

  const AnimatedSelectButton({
    super.key,
    required this.boardMode,
    required this.activeOn,
    required this.width,
    required this.height,
    required this.orientation,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedButton(
      width: width,
      height: height,
      onPressed: _toggleBoardMode,
      child: AnimatedDashedRectangle(
        orientation: orientation,
        foregroundColor: foregroundColor,
        notifier: boardMode,
        squareCount: 1,
        valueToRunOn: activeOn,
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  final WorkingSelectionHistory history;
  final GridNotifier grid;
  final ProjectEventHandler handler;
  final Color color;
  const _SwapButton({
    required this.history,
    required this.handler,
    required this.grid,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConditionallyEnabledIconButton(
      icon: Icon(Icons.swap_horiz_rounded),
      color: color,
      listenable: Listenable.merge([history, grid]),
      conditional: () {
        final bool out = history.swapableSelection;
        return out;
      },
      onPressed: () {
        handler.swapSelected();
      },
    );
  }
}
