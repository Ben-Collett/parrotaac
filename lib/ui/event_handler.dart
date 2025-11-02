import 'package:flutter/widgets.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/backend/event_stack.dart';
import 'package:parrotaac/backend/history_stack.dart';
import 'package:parrotaac/backend/project/code_gen_allowed/event/project_events.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project/patch.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/list_extensions.dart';
import 'package:parrotaac/extensions/map_extensions.dart';
import 'package:parrotaac/extensions/obf_extensions.dart';
import 'package:parrotaac/ui/board_modes.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';

import '../backend/project_restore_write_stream.dart';
import 'parrot_button.dart';
import 'widgets/sentence_box.dart';

class ProjectEventHandler {
  final ParrotProject project;
  final GridNotifier<ParrotButton> gridNotfier;
  bool gridNeedsUpdate = false;
  bool autoUpdateUi = true;
  final BoardHistoryStack boardHistory;
  final Patch? currentPatch;

  final ValueNotifier<BoardMode> modeNotifier;

  final ValueNotifier<bool> canUndo;
  final ValueNotifier<bool> canRedo;
  final SentenceBoxController boxController;
  final TextEditingController titleController;
  final ProjectRestoreStream? restoreStream;
  Iterable<String> get updatedBoardsIds => _updatedBoardCount.keys;
  final Map<String, int> _updatedBoardCount = {};
  late final EventHistory history = EventHistory(
    executeEvent: (e, undoing) =>
        execute(e, addToHistory: false, undoing: undoing),
    onUndoStackChange: () {
      restoreStream?.updateUndoStack(history.undoList);
    },
    onRedoStackChange: () {
      restoreStream?.updateRedoStack(history.redoList);
    },
  );

  Obf get currentBoard => boardHistory.currentBoard;

  ProjectEventHandler({
    required this.project,
    required this.gridNotfier,
    required this.boardHistory,
    required this.canUndo,
    required this.canRedo,
    required this.modeNotifier,
    required this.titleController,
    required this.boxController,
    this.currentPatch,
    this.restoreStream,
  });

  void bulkExecute(Iterable<ProjectEvent> events, {bool updateUi = true}) {
    void playEvent(ProjectEvent event) => execute(event, updateUI: updateUi);
    events.forEach(playEvent);
  }

  void setRedoStack(Iterable<ProjectEvent> events) {
    history.updateRedoStack(events);
    canRedo.value = events.isNotEmpty;
  }

  void setUndoStack(Iterable<ProjectEvent> events) {
    history.updateUndoStack(events);
    canUndo.value = events.isNotEmpty;
  }

  List<ProjectEvent> currentlyExecutedEvents() => history.undoList;

  //TODO: I need to decide if adding and removing boards should go into the history and how to display those actions
  void execute(
    ProjectEvent event, {
    bool addToHistory = true,
    bool undoing = false,
    bool? updateUI,
  }) {
    bool originalAutoUpdate = autoUpdateUi;

    if (updateUI != null) {
      autoUpdateUi = updateUI;
    }

    if (event.returnToBoardId != null && autoUpdateUi) {
      Obf? board = project.findBoardById(event.returnToBoardId!);
      if (board != null) {
        boardHistory.push(board);
      }
    }

    if (!undoing) {
      _updatedBoardCount.increment(event.boardToWrite);
    } else {
      _updatedBoardCount.decrement(event.boardToWrite);
      _updatedBoardCount.removeKeyIfBelowThreshold(
        key: event.boardToWrite,
        threshold: 1,
      );
    }

    event.execute(this);

    if (addToHistory) {
      history.add(event);
      canUndo.value = true;
      canRedo.value = false;
    }

    autoUpdateUi = originalAutoUpdate;
  }

  void clear() {
    restoreStream?.updateRedoStack([]);
    restoreStream?.updateUndoStack([]);
    canUndo.value = false;
    canRedo.value = false;
    _updatedBoardCount.clear();
    history.clear();
  }

  void swapButtons(int oldRow, int oldCol, int newRow, int newCol) => execute(
    SwapButtons(
      boardId: currentBoard.id,
      oldRow: oldRow,
      newRow: newRow,
      oldCol: oldCol,
      newCol: newCol,
    ),
    updateUI: false,
  );

  void addRow() =>
      execute(AddRow(id: boardHistory.currentBoard.id), updateUI: true);

  void removeRow(int row) =>
      execute(RemoveRow(id: currentBoard.id, row: row), updateUI: true);

  void addCol() => execute(AddColumn(id: currentBoard.id), updateUI: true);

  void removeCol(int col) =>
      execute(RemoveColumn(id: currentBoard.id, col: col), updateUI: true);

  void changeBoardColor(Obf board, Color oldColor, Color newColor) => execute(
    ChangeBoardColor(
      boardId: board.id,
      originalColor: ColorDataCovertor.fromColorToColorData(
        oldColor,
      ).toString(),
      newColor: ColorDataCovertor.fromColorToColorData(newColor).toString(),
    ),
    updateUI: false,
  );

  void fullUIUpdate() {
    _updateButtons();
    gridNotfier.update();
    gridNotfier.backgroundColorNotifier.value = currentBoard.boardColor
        .toColor();

    gridNotfier.setData(
      getButtonsFromObf(currentBoard),
      cleanUp: (oldData) => oldData.disposeNotifiers(),
    );
  }

  ///should only be called if history.getLastRemovedButton is not null, i.e. there has been a button removed to recover
  void recoverButton(int row, int col, {Obf? board}) {
    board = board ?? currentBoard;
    ButtonData lastRemoved = history.getLastRemovedButton()!;
    if (autoUpdateUi && board == currentBoard) {
      _addButton(board, lastRemoved, row, col);
    }
  }

  void removeButton(int row, int col, {Obf? board}) {
    board = board ?? boardHistory.currentBoard;
    execute(RemoveButton(boardId: board.id, row: row, col: col));
  }

  void addConfigureButtonToHistory(
    String buttonId,
    Map<String, dynamic> diff,
    Map<String, dynamic> undoDiff, {
    ImageData? originalImage,
    SoundData? originalSound,
    SoundData? newSound,
    ImageData? newImage,
  }) {
    Map<String, dynamic>? originalSoundJson = originalSound?.toJson();
    Map<String, dynamic>? newSoundJson;

    if (originalSoundJson == newSound?.toJson()) {
      newSoundJson = originalSoundJson;
    } else {
      newSoundJson = newSound?.toJson();
    }

    Map<String, dynamic>? originalImageJson = originalImage?.toJson();

    Map<String, dynamic>? newImageJson;

    if (newImage?.toJson() == originalImageJson) {
      newImageJson = originalImageJson;
    } else {
      newImageJson = newImage?.toJson();
    }

    _updatedBoardCount.increment(currentBoard.id);
    final event = ConfigButton(
      boardId: currentBoard.id,
      buttonId: buttonId,
      diff: diff,
      undoChanges: undoDiff,
      originalImage: originalImageJson,
      originalSound: originalSoundJson,
      newSound: newSoundJson,
      newImage: newImageJson,
    );
    history.add(event);
    event.updatePatch(this);
    canUndo.value = true;
    canRedo.value = false;
  }

  void addButton(int row, int col, ButtonData button) => execute(
    AddButton(
      row: row,
      col: col,
      boardId: boardHistory.currentBoard.id,
      imageData: button.image?.toJson(),
      soundData: button.sound?.toJson(),
      buttonData: button.toJson(),
    ),
  );

  void _addButton(
    Obf? board,
    ButtonData button,
    int row,
    int col, {
    ImageData? imageData,
    SoundData? soundData,
    bool updateUi = true,
  }) {
    board = board ?? boardHistory.currentBoard;
    button.image = button.image ?? imageData;
    button.sound = button.sound ?? soundData;
    if (board == currentBoard) {
      if (autoUpdateUi && updateUi) {
        gridNotfier.setWidget(
          row: row,
          col: col,
          data: makeButtonNotifier(button, row, col),
        );
      } else {
        gridNeedsUpdate = true;
      }
    }
    board.grid.setButtonData(row: row, col: col, data: button);
    board.buttons.add(button);
  }

  void renameBoard(String oldName, String newName) => execute(
    RenameBoard(name: newName, prevName: oldName, id: currentBoard.id),
    updateUI: false,
  );

  Obf fromIdOrCurrent(String boardId) {
    return project.findBoardById(boardId) ?? currentBoard;
  }

  void _updateButtons() {
    gridNotfier.forEach((obj) {
      if (obj is ParrotButtonNotifier) {
        obj.update();
      }
    });
  }

  void recoverCol(int? col, {Obf? board}) {
    board = board ?? currentBoard;
    col = col ?? board.grid.numberOfColumns;
    List<ButtonData?> toRecover = history.getLastRemovedRowOrCol()!;

    List<ParrotButtonNotifier?> notifiers = [];

    for (int row = 0; row < toRecover.length; row++) {
      ButtonData? data = toRecover[row];
      if (data == null) {
        notifiers.add(null);
      } else {
        notifiers.add(makeButtonNotifier(data, row, col));
      }
    }

    if (autoUpdateUi && board == currentBoard) {
      gridNotfier.insertColumn(col, notifiers);
    }

    updateOnPressed();
    board.grid.insertColumnAt(col, newCol: toRecover);
  }

  void updateOnPressed() {
    gridNotfier.forEachIndexed((obj, row, col) {
      if (modeNotifier.value == BoardMode.deleteColMode &&
          obj is ParrotButtonNotifier) {
        obj.onPressOverride = () {
          removeCol(col);
        };
      } else if (modeNotifier.value == BoardMode.deleteRowMode &&
          obj is ParrotButtonNotifier) {
        obj.onPressOverride = () {
          removeRow(row);
        };
      }
    });
  }

  ParrotButtonNotifier makeButtonNotifier(ButtonData bd, int row, int col) {
    VoidCallback? onPressOverride;
    if (modeNotifier.value == BoardMode.deleteColMode) {
      onPressOverride = () => removeCol(col);
    } else if (modeNotifier.value == BoardMode.deleteRowMode) {
      onPressOverride = () => removeRow(row);
    }

    return ParrotButtonNotifier(
      data: bd,
      goToLinkedBoard: (obf) {
        boardHistory.push(obf);
      },
      goHome: () {
        if (project.root != null) {
          boardHistory.push(project.root!);
        }
      },
      project: project,
      boxController: boxController,
      onPressOverride: onPressOverride,
      eventHandler: this,
      onDelete: () => removeButton(row, col),
    );
  }

  void recoverRow(int? row, {Obf? board}) {
    board = board ?? currentBoard;
    row = row ?? board.grid.numberOfRows;
    List<ButtonData?> toRecover = history.getLastRemovedRowOrCol()!;

    List<ParrotButtonNotifier?> notifiers = [];
    for (int col = 0; col < toRecover.length; col++) {
      if (toRecover[col] == null) {
        notifiers.add(null);
      } else {
        notifiers.add(makeButtonNotifier(toRecover[col]!, row, col));
      }
    }

    if (autoUpdateUi && board == currentBoard) {
      gridNotfier.insertRow(row, notifiers);
      updateOnPressed();
    }

    board.grid.insertRowAt(row, newRow: toRecover);
  }

  void undo() {
    history.undo();
    canUndo.value = history.canUndo;
    canRedo.value = true;
  }

  void redo() {
    history.redo();
    canUndo.value = true;
    canRedo.value = history.canRedo;
  }

  void addBoard(Obf board) => execute(
    AddBoard(
      id: board.id,
      name: board.name,
      rowCount: board.grid.numberOfRows,
      colCount: board.grid.numberOfColumns,
    ),
  );
  List<List<Object?>> getButtonsFromObf(Obf obf) {
    List<List<Object?>> buttons = [];
    final int rowCount = obf.grid.numberOfRows;
    final int colCount = obf.grid.numberOfColumns;
    for (int i = 0; i < rowCount; i++) {
      buttons.add([]);
      for (int j = 0; j < colCount; j++) {
        ButtonData? button = obf.grid.getButtonData(i, j);
        if (button != null) {
          buttons.last.add(makeButtonNotifier(button, i, j));
        } else {
          buttons.last.add(null);
        }
      }
    }
    return buttons;
  }

  void removeBoard(Obf board) => execute(RemoveBoard(board.id));

  void restoreBoard() => project.addBoard(history.getLastRemovedBoard()!);
}
