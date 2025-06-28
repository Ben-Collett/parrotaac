import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/history_stack.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/ui/board_modes.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/parrot_button.dart';
import 'package:parrotaac/ui/popups/button_config.dart';
import 'package:parrotaac/ui/sentence_bar.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';
import 'package:parrotaac/ui/widgets/sentence_box.dart';

class BoardWidget extends StatefulWidget {
  final ParrotProject project;
  //WARNING: storing the path will only work if I wait to rename a project somehow
  final String? path;
  final ValueNotifier<BoardMode>? boardMode;
  final ValueNotifier<Obf>? currentObfNotfier;
  final GridNotfier<ParrotButton>? gridNotfier;
  final ProjectEventHandler eventHandler;
  final SentenceBoxController? sentenceBoxController;
  final bool showSentenceBar;
  const BoardWidget({
    super.key,
    required this.project,
    required this.eventHandler,
    this.path,
    this.boardMode,
    this.currentObfNotfier,
    this.gridNotfier,
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

    history = BoardHistoryStack(
      maxHistorySize: historySize,
      currentBoard: _currentObfNotfier.value,
    );

    _sentenceController = widget.sentenceBoxController ??
        SentenceBoxController(projectPath: widget.path);
    _gridNotfier = widget.gridNotfier ??
        GridNotfier(
          data: [],
          toWidget: (obj) {
            if (obj is ParrotButtonNotifier) {
              return ParrotButton(
                controller: obj,
                eventHandler: widget.eventHandler,
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

    _boardMode.addListener(
      () {
        BoardMode mode = _boardMode.value;
        _gridNotfier.draggable = mode.draggableButtons;
        _gridNotfier.emptySpotWidget = mode.emptySpotWidget;
        _gridNotfier.toWidget =
            (obf) => _toParrotButton(obf, widget.eventHandler);
        mode.onPressedOverride(_gridNotfier, widget.eventHandler);

        if (mode == BoardMode.builderMode) {
          _gridNotfier.onEmptyPressed = (row, col) =>
              _showCreateNewButtonDialog(row, col, widget.eventHandler);
        } else if (mode == BoardMode.deleteRowMode) {
          _gridNotfier.onEmptyPressed = (row, _) {
            widget.eventHandler.removeRow(row);
            mode.onPressedOverride(
                _gridNotfier,
                widget
                    .eventHandler); //updates the grid notifier to tell the buttons inside of it to delete the new row
            _gridNotfier.forEachIndexed((obj, int row, int col) {
              if (obj is ParrotButtonNotifier) {
                _updateButtonNotfierOnDelete(
                    obj, widget.eventHandler, row, col);
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
                _updateButtonNotfierOnDelete(
                    obj, widget.eventHandler, row, col);
              }
            });
          };
        } else {
          _gridNotfier.onEmptyPressed = null;
        }
      },
    );
    _currentObfNotfier.addListener(() {
      if (_boardMode.value != BoardMode.normalMode) {
        _updateButtonPositionsInObf(history.currentBoard);
      }
      history.push(currentObf);
      _gridNotfier.setData(_getButtonsFromObf(currentObf));
    });

    super.initState();
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
      int row, int col, ProjectEventHandler eventHandler) {
    {
      ParrotButtonNotifier notifier = ParrotButtonNotifier(
        project: widget.project,
      );
      notifier.goToLinkedBoard = (_) {};
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            content: SizedBox(
              child: ButtonConfigPopup(
                buttonController: notifier,
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
      );
    }
  }

  ParrotButton? _toParrotButton(
      Object? object, ProjectEventHandler eventHandler) {
    if (object is ParrotButtonNotifier) {
      return ParrotButton(
        controller: object,
        eventHandler: eventHandler,
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
              child: SentenceBar(sentenceBoxController: _sentenceController),
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
