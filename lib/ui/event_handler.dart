import 'package:flutter/widgets.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/grid_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/backend/event_stack.dart';
import 'package:parrotaac/backend/history_stack.dart';
import 'package:parrotaac/backend/project/code_gen_allowed/event/project_events.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/extensions/button_data_extensions.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/map_extensions.dart';
import 'package:parrotaac/extensions/obf_extensions.dart';
import 'package:parrotaac/ui/board_modes.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';

import '../backend/project_restore_write_stream.dart';
import 'parrot_button.dart';
import 'widgets/sentence_box.dart';

class ProjectEventHandler {
  final ParrotProject project;
  final GridNotfier gridNotfier;
  bool gridNeedsUpdate = false;
  bool autoUpdateUi = true;
  final BoardHistoryStack boardHistory;

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
      });

  Obf get _obf => boardHistory.currentBoard;

  ProjectEventHandler({
    required this.project,
    required this.gridNotfier,
    required this.boardHistory,
    required this.canUndo,
    required this.canRedo,
    required this.modeNotifier,
    required this.titleController,
    required this.boxController,
    this.restoreStream,
  });

  void bulkExecute(Iterable<ProjectEvent> events, {bool updateUi = true}) {
    void playEvent(ProjectEvent event) => execute(event, updateUi: updateUi);

    events.forEach(playEvent);
  }

  void setRedoStack(Iterable<ProjectEvent> events) {
    history.updateRedoStack(events);
    canRedo.value = events.isNotEmpty;
  }

  //TODO: I need to decide if adding and removing boards should go into the history and how to display those actions
  void execute(
    ProjectEvent event, {
    bool addToHistory = true,
    bool updateUi = true,
    bool undoing = false,
  }) {
    Obf? pfi(String id) => project.findBoardById(id);
    ButtonData? removedButton;
    List<ButtonData?>? removedButtons;
    if (event.returnToBoardId != null) {
      Obf? board = pfi(event.returnToBoardId!);
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

    switch (event) {
      case AddRow event:
        _addRow(board: pfi(event.id));
      case RemoveRow event:
        Obf board = pfi(event.id)!;
        if (!undoing) {
          removedButtons = board.grid.getRow(
            event.row ?? (board.grid.numberOfRows - 1),
          );
        }

        _removeRow(board: board, event.row);
      case AddColumn event:
        _addCol(board: pfi(event.id));
      case RemoveColumn event:
        Obf board = pfi(event.id)!;
        if (!undoing) {
          removedButtons = board.grid.getCol(
            (event.col ?? (board.grid.numberOfColumns - 1)),
          );
        }
        _removeCol(board: board, event.col);
      case RemoveButton event:
        Obf board = pfi(event.boardId)!;
        removedButton = board.grid.getButtonData(event.row, event.col);
        _removeButton(board: pfi(event.boardId), event.row, event.col);
      case RenameBoard event:
        _renameBoard(event.name, pfi(event.id), updateUi: updateUi);
      case AddButton event:
        Obf? board = pfi(event.boardId);
        assert(board != null);
        ButtonData button = ButtonData.decode(json: event.buttonData);
        ImageData? image;
        if (event.imageData != null) {
          image = ImageData.decodeJson(event.imageData!);
        }
        SoundData? sound;
        if (event.soundData != null) {
          sound = SoundData.decode(event.soundData!);
        }

        _addButton(
          board,
          button,
          event.row,
          event.col,
          updateUi: updateUi,
          imageData: image,
          soundData: sound,
        );
      case SwapButtons event:
        Obf? board = pfi(event.boardId);
        assert(board != null);
        _swapButtons(
          event.oldRow,
          event.oldCol,
          event.newRow,
          event.newCol,
          board: board,
          updateUi: updateUi,
        );
      case RecoverButton event:
        _recoverButton(event.row, event.col, board: pfi(event.boardId));
      case RecoverColumn event:
        _recoverCol(event.col, board: pfi(event.id));
      case RecoverRow event:
        _recoverRow(event.row, board: pfi(event.id));
      case ConfigButton event:
        SoundData? sound;
        if (event.newSound != null) {
          sound = SoundData.decode(event.newSound!);
        }
        ImageData? image;
        if (event.newImage != null) {
          image = ImageData.decodeJson(event.newImage!);
        }
        _configButton(
          event.diff,
          event.buttonId,
          event.boardId,
          image: image,
          sound: sound,
        );
      case AddBoard event:
        _addBoard(event.id, event.name, event.rowCount, event.colCount);
      case ChangeBoardColor event:
        Obf? board = pfi(event.boardId);
        assert(board != null, "can't change color of null board");
        _changeBoardColor(event.newColor, board!, updateUi: updateUi);
      case RemoveBoard event:
        _removeBoard(pfi(event.id)!);
      case RestoreBoard _:
        _restoreBoard();
      case Undo _:
        undo();
      case Redo _:
        redo();
    }

    if (addToHistory && event is! Undo && event is! Redo) {
      history.add(event);
      canUndo.value = true;
      canRedo.value = false;
    }
    if (removedButton != null) {
      history.addToRemovedButtons(removedButton);
    }

    if (removedButtons != null) {
      history.addRemovedRowOrCol(removedButtons);
    }
  }

  void clear() {
    restoreStream?.updateRedoStack([]);
    restoreStream?.updateUndoStack([]);
    canUndo.value = false;
    canRedo.value = false;
    _updatedBoardCount.clear();
    history.clear();
  }

  void swapButtons(
    int oldRow,
    int oldCol,
    int newRow,
    int newCol,
  ) =>
      execute(
        SwapButtons(
          boardId: _obf.id,
          oldRow: oldRow,
          newRow: newRow,
          oldCol: oldCol,
          newCol: newCol,
        ),
        updateUi: false,
      );
  void _swapButtons(
    int oldRow,
    int oldCol,
    int newRow,
    int newCol, {
    bool updateUi = false,
    Obf? board,
  }) {
    board = board ?? _obf;
    if (board == _obf) {
      if (updateUi) {
        gridNotfier.swap(oldRow, oldCol, newRow, newCol);
      } else {
        gridNeedsUpdate = true;
      }
    }

    ButtonData? b1 = board.grid.getButtonData(oldRow, oldCol);
    board.grid.setButtonData(
      row: oldRow,
      col: oldCol,
      data: board.grid.getButtonData(newRow, newCol),
    );
    board.grid.setButtonData(row: newRow, col: newCol, data: b1);
  }

  void addRow() => execute(AddRow(id: boardHistory.currentBoard.id));

  void _addRow({Obf? board, bool updateUi = true}) {
    board = board ?? boardHistory.currentBoard;
    if (board == _obf) {
      if (updateUi) {
        gridNotfier.addRow();
      } else {
        gridNeedsUpdate = true;
      }
    }

    board.grid.addRowToTheBottom();
  }

  void removeRow(int row) => execute(RemoveRow(id: _obf.id, row: row));

  void _removeRow(int? row, {Obf? board, bool updateUi = true}) {
    board = board ?? boardHistory.currentBoard;
    row = row ?? (board.grid.numberOfRows - 1);
    if (board == _obf) {
      if (updateUi) {
        gridNotfier.removeRow(row);
        _updateOnPressed();
      } else {
        gridNeedsUpdate = true;
      }
    }
    board.grid.removeRow(row);
  }

  void addCol() => execute(AddColumn(id: _obf.id));
  void _addCol({Obf? board, bool updateUi = true}) {
    board = board ?? boardHistory.currentBoard;
    if (board == _obf) {
      if (updateUi) {
        gridNotfier.addColumn();
      } else {
        gridNeedsUpdate = true;
      }
    }
    board.grid.addColumnToTheRight();
  }

  void removeCol(int col) => execute(RemoveColumn(id: _obf.id, col: col));
  void _removeCol(int? col, {Obf? board, bool updateUi = true}) {
    board = board ?? boardHistory.currentBoard;
    col = col ?? (board.grid.numberOfColumns - 1);
    if (board == _obf) {
      if (updateUi) {
        gridNotfier.removeCol(col);
        _updateOnPressed();
      } else {
        gridNeedsUpdate = true;
      }
    }
    board.grid.removeCol(col);
  }

  void changeBoardColor(Obf board, Color oldColor, Color newColor) => execute(
        ChangeBoardColor(
          boardId: board.id,
          originalColor:
              ColorDataCovertor.fromColorToColorData(oldColor).toString(),
          newColor: ColorDataCovertor.fromColorToColorData(newColor).toString(),
        ),
        updateUi: false,
      );
  void _changeBoardColor(String newColor, Obf board, {required bool updateUi}) {
    board.boardColor = ColorData.fromString(newColor);
    if (updateUi) {
      gridNotfier.backgroundColorNotifier.value = board.boardColor.toColor();
    }
  }

  ///should only be called if history.getLastRemovedButton is not null, i.e. there has been a button removed to recover
  void _recoverButton(int row, int col, {bool updateUi = true, Obf? board}) {
    board = board ?? _obf;
    ButtonData lastRemoved = history.getLastRemovedButton()!;
    if (updateUi && board == _obf) {
      _addButton(board, lastRemoved, row, col);
    }

    board.grid.setButtonData(row: row, col: col, data: lastRemoved);
  }

  void removeButton(int row, int col, {Obf? board}) {
    board = board ?? boardHistory.currentBoard;
    execute(
      RemoveButton(
        boardId: board.id,
        row: row,
        col: col,
      ),
    );
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

    _updatedBoardCount.increment(_obf.id);
    history.add(
      ConfigButton(
          boardId: _obf.id,
          buttonId: buttonId,
          diff: diff,
          undoChanges: undoDiff,
          originalImage: originalImageJson,
          originalSound: originalSoundJson,
          newSound: newSoundJson,
          newImage: newImageJson),
    );
    canUndo.value = true;
    canRedo.value = false;
  }

  void _removeButton(int row, int col, {Obf? board, bool updateUi = true}) {
    board = board ?? boardHistory.currentBoard;
    if (board == _obf) {
      if (updateUi) {
        gridNotfier.removeAt(row, col);
      } else {
        gridNeedsUpdate = true;
      }
    }
    board.grid.setButtonData(row: row, col: col, data: null);
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
    if (board == _obf) {
      if (autoUpdateUi && updateUi) {
        gridNotfier.setWidget(
          row: row,
          col: col,
          data: _makeButtonNotifier(button, row, col),
        );
      } else {
        gridNeedsUpdate = true;
      }
    }
    board.grid.setButtonData(row: row, col: col, data: button);
    board.buttons.add(button);
  }

  void renameBoard(String oldName, String newName) => execute(
      RenameBoard(
        name: newName,
        prevName: oldName,
        id: _obf.id,
      ),
      updateUi: false);

  void _renameBoard(String name, Obf? board, {bool updateUi = false}) {
    board = board ?? _obf;
    board.name = name;
    if (updateUi && board == _obf) {
      titleController.text = board.name;
    }
  }

  void _recoverCol(int? col, {Obf? board, bool updateUi = true}) {
    board = board ?? _obf;
    col = col ?? board.grid.numberOfColumns;
    List<ButtonData?> toRecover = history.getLastRemovedRowOrCol()!;

    List<ParrotButtonNotifier?> notifiers = [];

    for (int row = 0; row < toRecover.length; row++) {
      ButtonData? data = toRecover[row];
      if (data == null) {
        notifiers.add(null);
      } else {
        notifiers.add(_makeButtonNotifier(data, row, col));
      }
    }

    if (updateUi && board == _obf) {
      gridNotfier.insertColumn(
        col,
        notifiers,
      );
    }

    _updateOnPressed();
    board.grid.insertColumnAt(col, newCol: toRecover);
  }

  void _updateOnPressed() {
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

  ParrotButtonNotifier _makeButtonNotifier(ButtonData bd, int row, int col) {
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

  void _recoverRow(int? row, {Obf? board, bool updateUi = true}) {
    board = board ?? _obf;
    row = row ?? board.grid.numberOfRows;
    List<ButtonData?> toRecover = history.getLastRemovedRowOrCol()!;

    List<ParrotButtonNotifier?> notifiers = [];
    for (int col = 0; col < toRecover.length; col++) {
      if (toRecover[col] == null) {
        notifiers.add(null);
      } else {
        notifiers.add(
          _makeButtonNotifier(toRecover[col]!, row, col),
        );
      }
    }

    if (updateUi && board == _obf) {
      gridNotfier.insertRow(row, notifiers);
      _updateOnPressed();
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

  void _configButton(
    Map<String, dynamic> diff,
    String buttonId,
    String boardId, {
    bool updateUi = true,
    ImageData? image,
    SoundData? sound,
  }) {
    final board = project.findBoardById(boardId);
    final button = board?.findButtonById(buttonId);
    button?.merge(diff, project: project);
    button?.image = image;
    button?.sound = sound;
    if (board == _obf && updateUi) {
      gridNotfier.forEach(
        (obj) {
          if (obj is ParrotButtonNotifier && obj.data.id == button?.id) {
            obj.update();
          }
        },
      );
    }
  }

  void addBoard(Obf board) => execute(
        AddBoard(
          id: board.id,
          name: board.name,
          rowCount: board.grid.numberOfRows,
          colCount: board.grid.numberOfColumns,
        ),
      );

  void _addBoard(String id, String name, int rowCount, int colCount) {
    Obf board = Obf(locale: 'en-us', name: name, id: id);
    List<List<ButtonData?>> order = List.generate(
      rowCount,
      (_) => List<ButtonData?>.filled(colCount, null, growable: true),
      growable: true,
    );
    board.grid = GridData(order: order);
    project.addBoard(board);
  }

  void removeBoard(Obf board) => execute(RemoveBoard(board.id));

  void _removeBoard(Obf board) {
    project.removeBoard(board);
    history.addRemoveBoard(board);
  }

  void _restoreBoard() {
    project.addBoard(history.getLastRemovedBoard()!);
  }
}
