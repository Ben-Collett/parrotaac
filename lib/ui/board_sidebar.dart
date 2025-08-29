import 'package:flutter/material.dart';
import 'package:parrotaac/backend/settings_utils.dart';
import 'package:parrotaac/ui/appbar_widgets/compute_contrasting_color.dart';
import 'package:parrotaac/ui/board_modes.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/painters/three_squares.dart';
import 'package:parrotaac/ui/settings/labels.dart';
import 'package:parrotaac/ui/util_widgets/paint_button.dart';

class BoardSidebar extends StatelessWidget {
  final ProjectEventHandler eventHandler;
  final ValueNotifier<BoardMode> boardMode;
  const BoardSidebar(
      {super.key, required this.eventHandler, required this.boardMode});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Color(getSetting(appBarColorLabel));

    Color foregroundColor = computeContrastingColor(backgroundColor);
    const longSideLength = 57.0;
    const shortSideLength = 30.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final addColButton = PaintedButton(
          onPressed: eventHandler.addCol,
          width: shortSideLength,
          height: longSideLength,
          painter: ThreeSquarePainter(
              circleType: CircleType.add, foregroundColor: foregroundColor),
        );

        final addRowButton = PaintedButton(
          onPressed: eventHandler.addRow,
          width: longSideLength,
          height: shortSideLength,
          painter: ThreeSquarePainter(
              circleType: CircleType.add,
              orientation: RectangleOrientation.horizontal,
              foregroundColor: foregroundColor),
        );
        return ValueListenableBuilder(
            valueListenable: boardMode,
            builder: (context, mode, child) {
              final removeRowButton = Container(
                color: boardMode.value == BoardMode.deleteRowMode
                    ? Colors.grey
                    : Colors.transparent,
                child: PaintedButton(
                  width: longSideLength,
                  height: shortSideLength,
                  onPressed: () {
                    boardMode.value = mode == BoardMode.deleteRowMode
                        ? BoardMode.builderMode
                        : BoardMode.deleteRowMode;
                  },
                  painter: ThreeSquarePainter(
                    orientation: RectangleOrientation.horizontal,
                    circleType: CircleType.subtract,
                    foregroundColor: foregroundColor,
                  ),
                ),
              );
              final removeColButton = Container(
                color: boardMode.value == BoardMode.deleteColMode
                    ? Colors.grey
                    : Colors.transparent,
                child: PaintedButton(
                  onPressed: () {
                    boardMode.value = mode == BoardMode.deleteColMode
                        ? BoardMode.builderMode
                        : BoardMode.deleteColMode;
                  },
                  height: longSideLength,
                  width: shortSideLength,
                  painter: ThreeSquarePainter(
                    circleType: CircleType.subtract,
                    foregroundColor: foregroundColor,
                  ),
                ),
              );

              return ColoredBox(
                color: Color(getSetting(appBarColorLabel)),
                child: Column(
                  children: [
                    addColButton,
                    addRowButton,
                    removeColButton,
                    removeRowButton
                  ],
                ),
              );
            });
      },
    );
  }
}
