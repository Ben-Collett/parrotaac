import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/obz.dart';
import 'package:parrotaac/backend/history_stack.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project_restore_write_stream.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/list_extensions.dart';
import 'package:parrotaac/extensions/obf_extensions.dart';
import 'package:parrotaac/ui/board_modes.dart';
import 'package:parrotaac/ui/board_screen_popup_history.dart';
import 'package:parrotaac/ui/codgen/board_screen_popups.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/parrot_button.dart';
import 'package:parrotaac/ui/popups/button_config.dart';
import 'package:parrotaac/ui/restore_button_diff.dart';
import 'package:parrotaac/ui/sentence_bar.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';
import 'package:parrotaac/ui/widgets/empty_spot.dart';
import 'package:parrotaac/ui/widgets/sentence_box.dart';

class BoardWidget extends StatefulWidget {
  final ParrotProject project;
  final ValueNotifier<BoardMode>? boardMode;
  final GridNotifier<ParrotButton>? gridNotifier;
  final ProjectEventHandler eventHandler;
  final SentenceBoxController? sentenceBoxController;
  final BoardHistoryStack? history;
  final bool? showSentenceBar;
  final ProjectRestoreStream? restoreStream;
  final BoardScreenPopupHistory? popupHistory;
  final RestorableButtonDiff? restorableButtonDiff;
  const BoardWidget({
    super.key,
    required this.project,
    required this.eventHandler,
    this.boardMode,
    this.gridNotifier,
    this.restoreStream,
    this.popupHistory,
    this.restorableButtonDiff,
    this.history,
    this.sentenceBoxController,
    this.showSentenceBar,
  });

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  static const String defaultBoardName = "default name";
  static const String defaultID = "board";
  static const int historySize = 100;
  late final GridNotifier<ParrotButton> _gridNotfier;
  late final SentenceBoxController _sentenceController;
  late final ValueNotifier<BoardMode> _boardMode;
  Obf get currentObf => history.currentBoard;
  set currentObf(Obf obf) => history.push(obf);

  late final BoardHistoryStack history;
  bool get showSentenceBar =>
      widget.showSentenceBar ??
      widget.project.settings?.showSentenceBar ??
      true;
  @override
  void initState() {
    _boardMode = widget.boardMode ?? ValueNotifier(BoardMode.normalMode);

    Obf currentBoard =
        widget.project.root ??
        Obf(locale: "en", name: defaultBoardName, id: defaultID);

    history =
        widget.history ??
        BoardHistoryStack(
          maxHistorySize: historySize,
          currentBoard: currentBoard,
        );

    _sentenceController =
        widget.sentenceBoxController ??
        SentenceBoxController(projectPath: widget.project.path);

    _gridNotfier =
        widget.gridNotifier ??
        GridNotifier(
          data: [],
          toWidget: (obj) {
            if (obj is ParrotButtonNotifier) {
              return ParrotButton(
                controller: obj,
                restorableButtonDiff: widget.restorableButtonDiff,
                currentBoard: history.currentBoard,
                popupHistory: widget.popupHistory,
              );
            }
            return null;
          },
          draggable: false,
          onSwap: (_, __, row, col) => _updateButtonNotfierOnDelete(
            _gridNotfier.getWidget(row, col)!,
            widget.eventHandler,
            row,
            col,
          ),
        );

    _gridNotfier.setData(
      getButtonsFromObf(currentObf),
      cleanUp: _disposeNotifiers,
    );

    _updateGridSettingsFromBoardMode();
    _boardMode.addListener(_updateGridSettingsFromBoardMode);

    history.beforeChange = _updateObfData;
    history.addListener(() {
      widget.restoreStream?.updateHistory(history.toIdList());
      _gridNotfier.setData(
        getButtonsFromObf(currentObf),
        cleanUp: _disposeNotifiers,
      );
    });

    BoardScreenPopup? popupToRecover = widget.popupHistory
        ?.removeNextToRecover();
    if (popupToRecover is ButtonConfig) {
      ParrotButtonNotifier? notifier = findNotifierById(
        popupToRecover.buttonId,
      );
      if (notifier != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => showConfigExistingPopup(
            context: context,
            controller: notifier,
            restorableButtonDiff: widget.restorableButtonDiff,
            popupHistory: widget.popupHistory,
            writeHistory: false,
          ),
        );
      }
    } else if (popupToRecover is ButtonCreate) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showCreateNewButtonDialog(
          popupToRecover.row,
          restorableButtonDiff: widget.restorableButtonDiff,
          popupToRecover.col,
          widget.eventHandler,
          writePopupHistory: false,
        ),
      );
    }

    history.addListener(_updateGridNoifierColor);

    //has to be a post framecallback to avoid updating notifier before building with it as that causes an error.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateGridNoifierColor(),
    );

    super.initState();
  }

  void _disposeNotifiers(Iterable<dynamic> toDispose) =>
      toDispose.disposeNotifiers();

  void _updateGridNoifierColor() {
    _gridNotfier.backgroundColorNotifier.value = history.currentBoard.boardColor
        .toColor();
    _gridNotfier.emptySpotWidget = EmptySpotWidget(
      color: EmptySpotWidget.fromBackground(
        _gridNotfier.backgroundColorNotifier.value,
      ),
    );
  }

  void _updateObfData() {
    if (_boardMode.value != BoardMode.normalMode) {
      _updateButtonPositionsInObf(currentObf);
    }
  }

  ParrotButtonNotifier? findNotifierById(String id) {
    for (int i = 0; i < _gridNotfier.rows; i++) {
      for (int j = 0; j < _gridNotfier.columns; j++) {
        final notifier = _gridNotfier.data[i][j];
        if (notifier is ParrotButtonNotifier && notifier.data.id == id) {
          return notifier;
        }
      }
    }
    return null;
  }

  void _updateGridSettingsFromBoardMode() {
    BoardMode mode = _boardMode.value;
    _gridNotfier.draggable = mode.draggableButtons;
    _gridNotfier.hideEmptySpotWidget = mode.hideEmptySpotWidget;
    _gridNotfier.toWidget = (button) => _toParrotButton(
      button,
      widget.eventHandler,
      restorableButtonDiff: widget.restorableButtonDiff,
      obf: history.currentBoard,
    );
    mode.onPressedOverride(_gridNotfier, widget.eventHandler);

    if (mode == BoardMode.builderMode) {
      _gridNotfier.onEmptyPressed = (row, col) => _showCreateNewButtonDialog(
        row,
        col,
        widget.eventHandler,
        restorableButtonDiff: widget.restorableButtonDiff,
      );
    } else if (mode == BoardMode.deleteRowMode) {
      _gridNotfier.onEmptyPressed = (row, _) {
        widget.eventHandler.removeRow(row);
        mode.onPressedOverride(
          _gridNotfier,
          widget.eventHandler,
        ); //updates the grid notifier to tell the buttons inside of it to delete the new row
        _gridNotfier.forEachIndexed((obj, int row, int col) {
          if (obj is ParrotButtonNotifier) {
            _updateButtonNotfierOnDelete(obj, widget.eventHandler, row, col);
          }
        });
      };
    } else if (mode == BoardMode.deleteColMode) {
      _gridNotfier.onEmptyPressed = (_, col) {
        widget.eventHandler.removeCol(col);
        mode.onPressedOverride(
          _gridNotfier,
          widget.eventHandler,
        ); //updates the grid notifier to tell the buttons inside of it to delete the new col.
        _gridNotfier.forEachIndexed((obj, int row, int col) {
          if (obj is ParrotButtonNotifier) {
            _updateButtonNotfierOnDelete(obj, widget.eventHandler, row, col);
          }
        });
      };
    } else {
      _gridNotfier.onEmptyPressed = null;
    }
  }

  void _updateButtonNotfierOnDelete(
    Object data,
    ProjectEventHandler eventHandler,
    int row,
    int col,
  ) {
    if (data is ParrotButtonNotifier) {
      data.onDelete = () {
        eventHandler.removeButton(row, col);
      };
    }
  }

  void _showCreateNewButtonDialog(
    int row,
    int col,
    ProjectEventHandler eventHandler, {
    bool writePopupHistory = true,
    RestorableButtonDiff? restorableButtonDiff,
  }) {
    {
      ParrotButtonNotifier notifier = ParrotButtonNotifier(
        project: widget.project,
        eventHandler: eventHandler,
      );
      restorableButtonDiff?.apply(notifier.data, project: widget.project);
      notifier.goToLinkedBoard = (_) {};
      widget.popupHistory?.pushScreen(
        ButtonCreate(row, col),
        writeHistory: writePopupHistory,
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            content: SizedBox(
              child: ButtonConfigPopup(
                restorableButtonDiff: restorableButtonDiff,
                buttonController: notifier,
                popupHistory: widget.popupHistory,
                eventHandler: eventHandler,
              ),
            ),
            actions: [
              IconButton(
                color: Colors.red,
                icon: Icon(Icons.cancel),
                onPressed: () {
                  notifier.dispose();
                  Navigator.of(context).pop();
                },
              ),
              IconButton(
                color: Colors.green,
                icon: Icon(Icons.check),
                onPressed: () {
                  notifier.goToLinkedBoard = _changeObf;
                  notifier.onDelete = () => eventHandler.removeButton(row, col);
                  notifier.goHome = _goToRootBoard;
                  notifier.boxController = _sentenceController;
                  notifier.data.id = Obz.generateButtonId(widget.project);
                  notifier.data.backgroundColor =
                      notifier.data.backgroundColor ??
                      ColorData(red: 255, green: 255, blue: 255);
                  notifier.data.borderColor =
                      notifier.data.borderColor ??
                      ColorData(red: 255, green: 255, blue: 255);

                  eventHandler.addButton(row, col, notifier.data);
                  notifier.dispose();

                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ).then((_) {
        widget.popupHistory?.popScreen();
        widget.restorableButtonDiff?.clear();
      });
    }
  }

  ParrotButton? _toParrotButton(
    Object? object,
    ProjectEventHandler eventHandler, {
    Obf? obf,
    RestorableButtonDiff? restorableButtonDiff,
  }) {
    if (object is ParrotButtonNotifier) {
      return ParrotButton(
        controller: object,
        currentBoard: obf,
        popupHistory: widget.popupHistory,
        restorableButtonDiff: restorableButtonDiff,
        holdToConfig: _boardMode.value.configOnButtonHold,
      );
    }
    return null;
  }

  void _changeObf(Obf obf) {
    currentObf = obf;
  }

  void _goToRootBoard() {
    Obf? root = widget.project.root;
    if (root != null) {
      _changeObf(root);
    }
  }

  List<List<Object?>> getButtonsFromObf(Obf obf) =>
      widget.eventHandler.getButtonsFromObf(obf);

  @override
  void dispose() {
    if (widget.gridNotifier == null) {
      _gridNotfier.data.flatten().disposeNotifiers();
      _gridNotfier.dispose();
    }
    if (widget.boardMode == null) {
      _boardMode.dispose();
    }
    if (widget.sentenceBoxController == null) {
      _sentenceController.dispose();
    }
    if (widget.history == null) {
      history.dispose();
    }

    super.dispose();
  }

  void _updateButtonPositionsInObf(Obf obf) {
    List<List<ButtonData?>> order = [];
    for (List<ParrotButton?> row in _gridNotfier.widgets) {
      order.add(row.map((b) => b?.buttonData).toList());
      for (ParrotButton? button in row) {
        if (button != null && !obf.buttons.contains(button.buttonData)) {
          obf.buttons.add(button.buttonData);
        }
      }
    }
    obf.grid.setOrder(order);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _boardMode,
      builder: (context, inBuilderMode, _) {
        List<Widget> children = [
          if (showSentenceBar)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 70,
              ), //TODO I should make a system where the size gives some but not as much as a flexible
              child: SentenceBar(
                sentenceBoxController: _sentenceController,
                goBack: () {
                  if (history.length > 1) {
                    history.pop();
                    widget.restoreStream?.updateHistory(history.toIdList());
                  }
                },
              ),
            ),
          Expanded(child: DraggableGrid(gridNotfier: _gridNotfier)),
        ];
        return Column(children: children);
      },
    );
  }
}
