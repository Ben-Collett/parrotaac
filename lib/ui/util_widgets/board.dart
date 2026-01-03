import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/obz.dart';
import 'package:parrotaac/backend/history_stack.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project_restore_write_stream.dart';
import 'package:parrotaac/backend/selection_data.dart';
import 'package:parrotaac/backend/selection_history.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/list_extensions.dart';
import 'package:parrotaac/extensions/notifier_extensions.dart';
import 'package:parrotaac/extensions/null_extensions.dart';
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

  final GridNotifier<ParrotButtonNotifier, ParrotButton>? gridNotifier;
  final ProjectEventHandler eventHandler;
  final SentenceBoxController? sentenceBoxController;
  final BoardHistoryStack? history;
  final bool? showSentenceBar;
  final ProjectRestoreStream? restoreStream;
  final BoardScreenPopupHistory? popupHistory;
  final RestorableButtonDiff? restorableButtonDiff;
  final WorkingSelectionHistory? selectionHistory;
  const BoardWidget({
    super.key,
    required this.project,
    required this.eventHandler,
    required this.selectionHistory,
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
  late final GridNotifier<ParrotButtonNotifier, ParrotButton> _gridNotifier;
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
        SentenceBoxController(project: widget.project);

    _gridNotifier =
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
          onSwap: (p1, p2) => _updateButtonNotfierOnDelete(
            _gridNotifier.getWidget(p2.row, p2.col)!,
            widget.eventHandler,
            p2.row,
            p2.col,
          ),
        );

    _gridNotifier.setData(
      getButtonsFromObf(currentObf),
      cleanUp: _disposeNotifiers,
    );

    _gridNotifier.rawUpdateSelectMode(
      widget.selectionHistory?.isNotEmpty ?? false,
    );

    _boardMode.executeAndAddListener(_updateGridSettingsFromBoardMode);

    history.beforeChange = _updateObfData;
    history.addListener(() {
      widget.restoreStream?.updateHistory(history.toIdList());
      _gridNotifier.setData(
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
      notifier.existThen((notifier) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => showConfigExistingPopup(
            context: context,
            controller: notifier,
            restorableButtonDiff: widget.restorableButtonDiff,
            popupHistory: widget.popupHistory,
            writeHistory: false,
          ),
        );
      });
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

    widget.selectionHistory.existThen((val) {
      _gridNotifier.selectionController.addListener(_writeSelectionChange);
      history.executeAndAddListener(_updateSelection);
      _boardMode.addListener(_clearSelectionIfNormalMode);
      val.addListener(_updateSelectMode);
    });

    super.initState();
  }

  void _writeSelectionChange() async {
    assert(
      widget.selectionHistory != null,
      "should not call  _writeSelectionChange with a null selection history",
    );
    assert(
      widget.gridNotifier != null,
      "should not call  _writeSelectionChange with a null grid notifier",
    );

    final selectionController = widget.gridNotifier!.selectionController;
    await widget.selectionHistory!.updateData(
      currentObf.id,
      (oldData) => oldData.setTo(selectionController.data),
    );
  }

  void _updateSelection() {
    assert(
      widget.selectionHistory != null,
      "should not call _updateSelection with a null selection history",
    );

    final selectionHistory = widget.selectionHistory!;
    final SelectionData selectionData = selectionHistory
        .findSelectionFromId(currentObf.id)
        .ifNotFoundDefaultTo(SelectionData());

    widget.gridNotifier?.selectionController.data.setTo(selectionData);
  }

  void _disposeNotifiers(Iterable<dynamic> toDispose) =>
      toDispose.disposeNotifiers();

  void _updateGridNoifierColor() {
    _gridNotifier.backgroundColorNotifier.value = history
        .currentBoard
        .boardColor
        .toColor();
    _gridNotifier.emptySpotWidget = EmptySpotWidget(
      color: EmptySpotWidget.fromBackground(
        _gridNotifier.backgroundColorNotifier.value,
      ),
    );
  }

  void _updateObfData() {
    if (_boardMode.value != BoardMode.normalMode) {
      _updateButtonPositionsInObf(currentObf);
    }
  }

  ParrotButtonNotifier? findNotifierById(String id) {
    for (int i = 0; i < _gridNotifier.rows; i++) {
      for (int j = 0; j < _gridNotifier.columns; j++) {
        final notifier = _gridNotifier.data[i][j];
        if (notifier is ParrotButtonNotifier && notifier.data.id == id) {
          return notifier;
        }
      }
    }
    return null;
  }

  void _updateGridSettingsFromBoardMode() {
    BoardMode mode = _boardMode.value;
    _gridNotifier.draggable = mode.draggableButtons;
    _gridNotifier.hideEmptySpotWidget = mode.hideEmptySpotWidget;
    _gridNotifier.toWidget = (button) => _toParrotButton(
      button,
      widget.eventHandler,
      restorableButtonDiff: widget.restorableButtonDiff,
      obf: history.currentBoard,
    );
    mode.updateOnPressed(_gridNotifier);

    if (mode == BoardMode.builderMode) {
      _gridNotifier.onEmptyPressed = (row, col) => _showCreateNewButtonDialog(
        row,
        col,
        widget.eventHandler,
        restorableButtonDiff: widget.restorableButtonDiff,
      );

      widget.selectionHistory.existThen((selectionHistory) {
        _gridNotifier.selectMode = selectionHistory.isNotEmpty;
      });
    }
  }

  Future<void> _clearSelectionIfNormalMode() async {
    assert(
      widget.selectionHistory != null,
      "should not call _clearSelectionIfNormalMode when the selectionHistory is null",
    );
    if (_boardMode.value == BoardMode.normalMode) {
      await widget.selectionHistory!.clear();
    }
  }

  void _updateSelectMode() {
    if (widget.selectionHistory?.isNotEmpty ?? false) {
      _gridNotifier.selectMode = true;
      return;
    }
    final val = _boardMode.value;
    if (val == BoardMode.builderMode || val == BoardMode.normalMode) {
      _gridNotifier.selectMode = false;
      return;
    }
    _gridNotifier.selectMode = true;
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
        alwaysShowLabel: widget.project.settings?.showButtonLabels ?? true,
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

  List<List<ParrotButtonNotifier?>> getButtonsFromObf(Obf obf) =>
      widget.eventHandler.getButtonsFromObf(obf);

  @override
  void dispose() {
    if (widget.gridNotifier == null) {
      _gridNotifier.data.flatten().disposeNotifiers();
      _gridNotifier.dispose();
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

    widget.selectionHistory.existThen((val) {
      val.removeListener(_updateSelectMode);
    });

    super.dispose();
  }

  void _updateButtonPositionsInObf(Obf obf) {
    List<List<ButtonData?>> order = [];
    for (List<ParrotButton?> row in _gridNotifier.widgets) {
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
          Expanded(child: DraggableGrid(gridNotfier: _gridNotifier)),
        ];
        return Column(children: children);
      },
    );
  }
}
