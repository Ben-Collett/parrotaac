import 'package:flutter/material.dart';
import 'package:parrotaac/backend/history_stack.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/selection_history.dart';
import 'package:parrotaac/backend/settings_utils.dart';
import 'package:parrotaac/restorative_navigator.dart';
import 'package:parrotaac/ui/appbar_widgets/compute_contrasting_color.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/settings/labels.dart';
import 'package:parrotaac/ui/util_widgets/coditional_text_button.dart';
import 'package:parrotaac/ui/util_widgets/color_popup_button.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';
import 'package:parrotaac/ui/util_widgets/icon_button_on_notfier.dart';
import 'package:parrotaac/ui/widgets/empty_spot.dart';

import 'board_modes.dart';
import 'board_screen_constants.dart';
import 'popups/board_screen_popups/rename_title.dart';
import 'popups/lock_popups/admin_lock.dart';
import 'settings/settings_themed_appbar.dart';

SettingsThemedAppbar boardScreenAppbar({
  required BuildContext context,
  required ValueNotifier<BoardMode> boardMode,
  required TextEditingController titleController,
  required ProjectEventHandler eventHandler,
  required ParrotProject project,
  required ValueNotifier<bool> showSideBar,
  required WorkingSelectionHistory selectionHistory,
  BoardHistoryStack? boardHistory,
  GridNotifier? grid,
  Widget? leading,
}) {
  Widget? changeGridColorButton = grid != null && boardHistory != null
      ? ListenableBuilder(
          listenable: boardHistory,
          builder: (context, _) {
            return ColorPickerPopupButton(
              notifier: grid.backgroundColorNotifier,
              onPressed: () => grid.hideEmptySpotWidget = true,
              onClose: (initialColor, newColor) {
                if (initialColor == newColor) {
                  grid.hideEmptySpotWidget = false;
                  return;
                }

                grid.emptySpotWidget = EmptySpotWidget(
                  color: EmptySpotWidget.fromBackground(newColor),
                );
                grid.hideEmptySpotWidget = false;
                eventHandler.changeBoardColor(
                  boardHistory.currentBoard,
                  initialColor,
                  newColor,
                );
              },
            );
          },
        )
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

  final showSideBarButton = ShowSideBarButton(showSideBar: showSideBar);
  final deselectAllButton = _DeselectAllButton(
    history: selectionHistory,
    grid: grid,
    mode: boardMode,
  );
  final deleteSelectedButton = _DeleteSelectedButton(
    mode: boardMode,
    history: selectionHistory,
    handler: eventHandler,
  );

  return SettingsThemedAppbar(
    leading: leading,
    title: ValueListenableBuilder(
      valueListenable: boardMode,
      builder: (context, mode, child) {
        bool inNormalMode = mode == BoardMode.normalMode;
        IconData icon = inNormalMode ? Icons.handyman : Icons.close;
        final builderModeButton = IconButton(
          icon: Icon(icon),
          onPressed: () {
            if (inNormalMode) {
              showAdminLockPopup(
                context: context,
                onAccept: () {
                  boardMode.value = BoardMode.builderMode;
                  showSideBar.value = true;
                },
              );
            } else {
              boardMode.value = BoardMode.normalMode;
            }
          },
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _getTitle(boardMode, titleController, eventHandler),
            ),
            if (!inNormalMode)
              Flexible(child: Row(children: [undoButton, redoButton])),
            Row(
              children: [
                if (!inNormalMode) changeGridColorButton!,
                if (!inNormalMode) deleteSelectedButton,
                if (!inNormalMode) deselectAllButton,
                if (!inNormalMode) showSideBarButton,
                builderModeButton,
                settingsButton,
              ],
            ),
          ],
        );
      },
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
              eventHandler: eventHandler,
            ),
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
              if (editButtonShouldBeShown) editButton(),
              Flexible(flex: 2, child: Text(title)),
            ],
          );
        },
      );
    },
  );
}

class ShowSideBarButton extends StatelessWidget {
  final ValueNotifier<bool> showSideBar;
  const ShowSideBarButton({super.key, required this.showSideBar});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 75,
      child: ValueListenableBuilder(
        valueListenable: showSideBar,
        builder: (context, val, child) {
          final message = val ? "hide sidebar" : "show sidebar";
          return TextButton(
            onPressed: () => showSideBar.value = !val,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: computeContrastingColor(getAppbarColor()),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DeselectAllButton extends StatelessWidget {
  final ValueNotifier<BoardMode> mode;
  final WorkingSelectionHistory history;
  final GridNotifier? grid;

  const _DeselectAllButton({
    required this.mode,
    required this.history,
    required this.grid,
  });

  @override
  Widget build(BuildContext context) {
    final color = computeContrastingColor(Color(getSetting(appBarColorLabel)));
    return ConditionallyEnabledTextButton(
      listenable: history,
      condition: () => history.isNotEmpty,
      onPressed: clear,
      style: TextButton.styleFrom(foregroundColor: color),
      child: Column(
        children: [
          Text("deselect", textAlign: TextAlign.center),
          Text("all", textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void clear() {
    grid?.selectionController.clear();
    history.clear();
  }
}

class _DeleteSelectedButton extends StatelessWidget {
  final ValueNotifier<BoardMode> mode;
  final WorkingSelectionHistory history;
  final ProjectEventHandler handler;

  const _DeleteSelectedButton({
    required this.mode,
    required this.history,
    required this.handler,
  });

  @override
  Widget build(BuildContext context) {
    final color = computeContrastingColor(Color(getSetting(appBarColorLabel)));
    return ConditionallyEnabledTextButton(
      listenable: Listenable.merge([history, handler.gridNotfier]),
      onPressed: handler.removeSelected,
      style: TextButton.styleFrom(foregroundColor: color),
      condition: () => history.deletableIsSelected,
      child: Column(
        children: [
          Text("delete", textAlign: TextAlign.center),
          Text("selected", textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _HistoryListeningButton extends StatefulWidget {
  final WorkingSelectionHistory history;
  final VoidCallback onPressed;
  final Widget child;
  const _HistoryListeningButton({
    required this.history,
    required this.onPressed,
    required this.child,
  });

  @override
  State<_HistoryListeningButton> createState() =>
      _HistoryListeningButtonState();
}

class _HistoryListeningButtonState extends State<_HistoryListeningButton> {
  late final ValueNotifier<bool> notifier;
  @override
  void initState() {
    notifier = ValueNotifier(widget.history.isNotEmpty);
    widget.history.addListener(_updateNotifier);
    super.initState();
  }

  @override
  void dispose() {
    widget.history.removeListener(_updateNotifier);
    notifier.dispose();
    super.dispose();
  }

  void _updateNotifier() {
    notifier.value = widget.history.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final color = computeContrastingColor(Color(getSetting(appBarColorLabel)));
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (context, enabled, child) {
        return TextButton(
          onPressed: enabled ? widget.onPressed : null,
          style: TextButton.styleFrom(foregroundColor: color),
          child: widget.child,
        );
      },
    );
  }
}
