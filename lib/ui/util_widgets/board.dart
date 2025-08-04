import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/history_stack.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project_restore_write_stream.dart';
import 'package:parrotaac/ui/board_modes.dart';
import 'package:parrotaac/ui/board_screen_popup_history.dart';
import 'package:parrotaac/ui/codgen/board_screen_popups.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/parrot_button.dart';
import 'package:parrotaac/ui/popups/button_config.dart';
import 'package:parrotaac/ui/restore_button_diff.dart';
import 'package:parrotaac/ui/sentence_bar.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';
import 'package:parrotaac/ui/widgets/sentence_box.dart';

class BoardWidget extends StatefulWidget {
  final ParrotProject project;
  final ValueNotifier<BoardMode>? boardMode;
  final ValueNotifier<Obf>? currentObfNotfier;
  final GridNotfier<ParrotButton>? gridNotfier;
  final ProjectEventHandler eventHandler;
  final SentenceBoxController? sentenceBoxController;
  final BoardHistoryStack? history;
  final bool showSentenceBar;
  final ProjectRestoreStream? restoreStream;
  final BoardScreenPopupHistory? popupHistory;
  final RestorableButtonDiff? restorableButtonDiff;
  const BoardWidget({
    super.key,
    required this.project,
    required this.eventHandler,
    this.boardMode,
    this.currentObfNotfier,
    this.gridNotfier,
    this.restoreStream,
    this.popupHistory,
    this.restorableButtonDiff,
    this.history,
    this.showSentenceBar =
        true, //TODO: better to pass in a sentence bar and disable the setnenceBoxController if null
    this.sentenceBoxController,
  });

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  static const String defaultBoardName = "default name";
  static const String defaultID = "board";
  static const int historySize = 100;
  late final GridNotfier<ParrotButton> _gridNotfier;
  late final SentenceBoxController _sentenceController;
  Set<ParrotButtonNotifier> buttonSet = {};
  late final ValueNotifier<BoardMode> _boardMode;
  late final ValueNotifier<Obf> _currentObfNotfier;
  Obf get currentObf => _currentObfNotfier.value;
  set currentObf(Obf obf) => _currentObfNotfier.value = obf;

  late final BoardHistoryStack history;
  @override
  void initState() {
    _boardMode = widget.boardMode ?? ValueNotifier(BoardMode.normalMode);
    _currentObfNotfier = widget.currentObfNotfier ??
        ValueNotifier(
          widget.project.root ??
              Obf(
                locale: "en",
                name: defaultBoardName,
                id: defaultID,
              ),
        );

    history = widget.history ??
        BoardHistoryStack(
          maxHistorySize: historySize,
          currentBoard: _currentObfNotfier.value,
        );

    _sentenceController = widget.sentenceBoxController ??
        SentenceBoxController(projectPath: widget.project.path);

    _gridNotfier = widget.gridNotfier ??
        GridNotfier(
          data: [],
          toWidget: (obj) {
            if (obj is ParrotButtonNotifier) {
              return ParrotButton(
                controller: obj,
                restorableButtonDiff: widget.restorableButtonDiff,
                currentBoard: _currentObfNotfier.value,
                popupHistory: widget.popupHistory,
              );
            }
            return null;
          },
          draggable: false,
          onSwap: (_, __, row, col) => _updateButtonNotfierOnDelete(
              _gridNotfier.getWidget(row, col)!, widget.eventHandler, row, col),
        );

    _gridNotfier.setData(_getButtonsFromObf(currentObf));
    _updateButtonSet();

    _updateGridSettingsFromBoardMode();
    _boardMode.addListener(_updateGridSettingsFromBoardMode);

    _currentObfNotfier.addListener(() {
      if (_boardMode.value != BoardMode.normalMode) {
        _updateButtonPositionsInObf(history.currentBoard);
      }
      history.push(currentObf);
      widget.restoreStream?.updateHistory(history.toIdList());
      _gridNotfier.setData(_getButtonsFromObf(currentObf));
    });

    BoardScreenPopup? popupToRecover =
        widget.popupHistory?.removeNextToRecover();
    if (popupToRecover is ButtonConfig) {
      ParrotButtonNotifier? notifier =
          findNotifierById(popupToRecover.buttonId);
      if (notifier != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => showConfigExistingPopup(
              context: context,
              controller: notifier,
              restorableButtonDiff: widget.restorableButtonDiff,
              popupHistory: widget.popupHistory,
              writeHistory: false),
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

    super.initState();
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
    _gridNotfier.emptySpotWidget = mode.emptySpotWidget;
    _gridNotfier.toWidget = (button) => _toParrotButton(
          button,
          widget.eventHandler,
          restorableButtonDiff: widget.restorableButtonDiff,
          obf: _currentObfNotfier.value,
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
            widget
                .eventHandler); //updates the grid notifier to tell the buttons inside of it to delete the new row
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
      Object data, ProjectEventHandler eventHandler, int row, int col) {
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
          project: widget.project, eventHandler: eventHandler);
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
                  notifier.data.id =
                      eventHandler.project.generateGloballyUniqueId(
                    prefix: "bd",
                  );
                  notifier.data.backgroundColor =
                      notifier.data.backgroundColor ??
                          ColorData(
                            red: 255,
                            green: 255,
                            blue: 255,
                          );
                  notifier.data.borderColor = notifier.data.borderColor ??
                      ColorData(
                        red: 255,
                        green: 255,
                        blue: 255,
                      );

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

  List<List<Object?>> _getButtonsFromObf(Obf obf) {
    List<List<Object?>> buttons = [];
    final int rowCount = obf.grid.numberOfRows;
    final int colCount = obf.grid.numberOfColumns;
    for (int i = 0; i < rowCount; i++) {
      buttons.add([]);
      for (int j = 0; j < colCount; j++) {
        ButtonData? button = obf.grid.getButtonData(i, j);
        if (button != null) {
          buttons.last.add(
            ParrotButtonNotifier(
              data: button,
              eventHandler: widget.eventHandler,
              boxController: _sentenceController,
              goToLinkedBoard: _changeObf,
              goHome: _goToRootBoard,
              onDelete: () {
                widget.eventHandler.removeButton(i, j);
              },
              project: widget.project,
            ),
          );
        } else {
          buttons.last.add(null);
        }
      }
    }
    return buttons;
  }

  @override
  void dispose() {
    _updateButtonSet();
    void disposeNotfier(n) => n.dispose;

    if (widget.gridNotfier == null) {
      _gridNotfier.dispose();
    }
    buttonSet.forEach(disposeNotfier);
    if (widget.boardMode == null) {
      _boardMode.dispose();
    }
    if (widget.sentenceBoxController == null) {
      _sentenceController.dispose();
    }
    if (widget.currentObfNotfier == null) {
      _currentObfNotfier.dispose();
    }

    super.dispose();
  }

  void _updateButtonSet() {
    void disposeNotfier(n) => n.dispose;
    final buttonSetFromGrid = _buttonSetFromGrid(_gridNotfier.data);
    buttonSet.difference(buttonSetFromGrid).forEach(disposeNotfier);
    buttonSet = buttonSetFromGrid;
  }

  Set<ParrotButtonNotifier> _buttonSetFromGrid(List<List<Object?>> buttons) {
    Set<ParrotButtonNotifier> out = {};
    for (List<Object?> row in buttons) {
      for (Object? button in row) {
        if (button is ParrotButtonNotifier) {
          out.add(button);
        }
      }
    }
    return out;
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
        List<Flexible> children = [
          if (widget.showSentenceBar)
            Flexible(
              flex: 2,
              child: SentenceBar(
                sentenceBoxController: _sentenceController,
                goBack: () {
                  history.pop();
                  _currentObfNotfier.value = history.currentBoard;
                  widget.restoreStream?.updateHistory(history.toIdList());
                },
              ),
            ),
          Flexible(
            flex: 25,
            child: DraggableGrid(gridNotfier: _gridNotfier),
          ),
        ];
        return Column(
          children: children,
        );
      },
    );
  }
}
