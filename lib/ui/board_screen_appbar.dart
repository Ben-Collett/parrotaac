import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:parrotaac/backend/history_stack.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/restorative_navigator.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/painters/add_col.dart';
import 'package:parrotaac/ui/util_widgets/color_popup_button.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';
import 'package:parrotaac/ui/util_widgets/icon_button_on_notfier.dart';
import 'package:parrotaac/ui/util_widgets/paint_button.dart';

import 'board_modes.dart';
import 'board_screen_constants.dart';
import 'popups/board_screen_popups/rename_title.dart';
import 'popups/lock_popups/admin_lock.dart';
import 'settings/settings_themed_appbar.dart';

SettingsThemedAppbar boardScreenAppbar({
  required BuildContext context,
  required ValueNotifier boardMode,
  required TextEditingController titleController,
  required ProjectEventHandler eventHandler,
  required ParrotProject project,
  BoardHistoryStack? boardHistory,
  GridNotfier? grid,
  Widget? leading,
}) {
  const longSideLength = 50.0;
  const shortSideLength = 27.0;
  final addColButton = PaintedButton(
    onPressed: eventHandler.addCol,
    width: shortSideLength,
    height: longSideLength,
    painter: ThreeSquarePainter(circleType: CircleType.add),
  );

  final addRowButton = PaintedButton(
    onPressed: eventHandler.addRow,
    width: longSideLength,
    height: shortSideLength,
    painter: ThreeSquarePainter(
        circleType: CircleType.add,
        orientation: RectangleOrientation.horizontal),
  );
  Widget? changeGridColorButton = grid != null && boardHistory != null
      ? ListenableBuilder(
          listenable: boardHistory,
          builder: (context, _) {
            return ColorPickerPopupButton(
                notifier: grid.backgroundColorNotifier,
                onPressed: () => grid.hideEmptySpotWidget = true,
                onClose: (initialColor, newColor) {
                  grid.hideEmptySpotWidget = false;
                  eventHandler.changeBoardColor(
                      boardHistory.currentBoard, initialColor, newColor);
                });
          })
      : null;

  final undoButton = IconButtonEnabledOnNotfier(
    enabledController: eventHandler.canUndo,
    onPressed: eventHandler.undo,
    icon: Icon(Icons.undo),
  );
  final redoButton = IconButtonEnabledOnNotfier(
    enabledController: eventHandler.canRedo,
    onPressed: eventHandler.redo,
    icon: Icon(Icons.redo),
  );

  final settingsButton = IconButton(
    icon: Icon(Icons.settings),
    onPressed: () => showAdminLockPopup(
      context: context,
      onAccept: () =>
          RestorativeNavigator().goToSettings(context, project: project),
    ),
  );

  return SettingsThemedAppbar(
    leading: leading,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: _getTitle(boardMode, titleController, eventHandler)),
        ValueListenableBuilder(
            valueListenable: boardMode,
            builder: (context, mode, _) {
              bool inNormalMode = mode == BoardMode.normalMode;
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
                      circleType: CircleType.subtract),
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
                  painter: ThreeSquarePainter(circleType: CircleType.subtract),
                ),
              );
              IconData icon = inNormalMode ? Icons.handyman : Icons.close;
              final builderModeButton = IconButton(
                  icon: Icon(icon),
                  onPressed: () {
                    if (inNormalMode) {
                      showAdminLockPopup(
                          context: context,
                          onAccept: () {
                            boardMode.value = BoardMode.builderMode;
                          });
                    } else {
                      boardMode.value = BoardMode.normalMode;
                    }
                  });

              final List<Widget> notInNormalModeWidgets;
              if (!inNormalMode) {
                notInNormalModeWidgets = [
                  undoButton,
                  redoButton,
                  removeColButton,
                  removeRowButton,
                  addRowButton,
                  addColButton,
                  if (changeGridColorButton != null) changeGridColorButton,
                ];
              } else {
                notInNormalModeWidgets = [];
              }
              return Row(
                children: [
                  ...notInNormalModeWidgets,
                  builderModeButton,
                  settingsButton,
                ],
              );
            })
      ],
    ),
  );
}

Widget _getTitle(
  ValueNotifier boardMode,
  TextEditingController titleController,
  ProjectEventHandler eventHandler,
) {
  return ValueListenableBuilder(
    valueListenable: titleController,
    builder: (context, val, _) {
      String title = titleController.text.trim();
      //so that it updates in the background while editing the title in the popup
      if (title == "") {
        title = untitledBoard;
      }
      Widget editButton() {
        return Flexible(
          child: IconButton(
            onPressed: () => showRenameTitlePopup(
                context: context,
                controller: titleController,
                eventHandler: eventHandler),
            icon: Icon(Icons.edit_outlined),
          ),
        );
      }

      return ValueListenableBuilder(
          valueListenable: boardMode,
          builder: (context, mode, _) {
            bool editButtonShouldBeShown = mode != BoardMode.normalMode;
            return Row(
              children: [
                Flexible(child: Text(title)),
                if (editButtonShouldBeShown) editButton()
              ],
            );
          });
    },
  );
}
