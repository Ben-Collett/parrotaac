import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/grid_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/utils/collections/set_utils.dart';
import 'package:parrotaac/utils/encoding/json_map_utils.dart';
import 'package:parrotaac/backend/project/code_gen_allowed/event/selection_data/selection_data.dart';
import 'package:parrotaac/backend/project/code_gen_allowed/event/selection_history.dart';
import 'package:parrotaac/utils/debugging/simple_logger.dart';
import 'package:parrotaac/backend/project/code_gen_allowed/event/swap_data/swap_data.dart';
import 'package:parrotaac/extensions/button_data_extensions.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/iterable_extensions.dart';
import 'package:parrotaac/extensions/list_extensions.dart';
import 'package:parrotaac/extensions/map_extensions.dart';
import 'package:parrotaac/extensions/obf_extensions.dart';
import 'package:parrotaac/extensions/set_extensions.dart';
import 'package:parrotaac/backend/project/code_gen_allowed/event/event_handler.dart';
import 'package:parrotaac/ui/widgets/parrot_button.dart';
import 'package:parrotaac/ui/widgets/empty_spot.dart';
import 'package:path/path.dart' as p;
import './event_jump_table.pyg.dart';
part 'project_events.g.dart';

abstract class ProjectEvent {
  String? get returnToBoardId;

  ///if returnToBoardId is null this getter must be overridden
  List<String> get boardsToWrite => [returnToBoardId!];
  static ProjectEvent? decode(String jsonString) {
    final json = jsonDecode(jsonString);
    ProjectEvent? event = decodeEvent(json);

    if (event == null) {
      SimpleLogger().logWarning("malformed event: $json");
      return event;
    }
    return event;
  }

  void execute(ProjectEventHandler handler);

  Map<String, dynamic> encode() {
    return encodeEvent(this);
  }

  String encodeToJsonString() {
    return jsonEncode(encode());
  }

  Map<String, dynamic> toJson();

  ProjectEvent undoEvent();
}

@JsonSerializable()
class AddBoard extends ProjectEvent {
  final String id;
  final String name;
  final int rowCount;
  final int colCount;
  static const tableId = 1;

  @override
  String? get returnToBoardId => null;

  AddBoard({
    required this.id,
    required this.rowCount,
    required this.colCount,
    required this.name,
  });

  factory AddBoard.fromJson(Map<String, dynamic> json) =>
      _$AddBoardFromJson(json);

  @override
  ProjectEvent undoEvent() => RemoveBoard(id);

  @override
  Map<String, dynamic> toJson() => _$AddBoardToJson(this);

  @override
  List<String> get boardsToWrite => [id];

  @override
  void execute(ProjectEventHandler handler) {
    Obf board = Obf(locale: 'en-us', name: name, id: id);
    List<List<ButtonData?>> order = List.generate(
      rowCount,
      (_) => List<ButtonData?>.filled(colCount, null, growable: true),
      growable: true,
    );
    board.grid = GridData(order: order);
    handler.project.addBoard(board);
  }
}

@JsonSerializable()
class RemoveBoard extends ProjectEvent {
  final String id;
  static const tableId = 2;

  RemoveBoard(this.id);

  factory RemoveBoard.fromJson(Map<String, dynamic> json) =>
      _$RemoveBoardFromJson(json);

  @override
  ProjectEvent undoEvent() => RestoreBoard(id);

  @override
  Map<String, dynamic> toJson() => _$RemoveBoardToJson(this);

  @override
  String? get returnToBoardId => null;

  @override
  List<String> get boardsToWrite => [id];

  @override
  void execute(ProjectEventHandler handler) {
    Obf? board = handler.project.findBoardById(id);
    if (board == null) {
      return;
    }
    handler.project.removeBoard(board);
    handler.history.addRemoveBoard(board);
  }
}

@JsonSerializable()
class RestoreBoard extends ProjectEvent {
  final String id;
  static const tableId = 3;
  @override
  String? get returnToBoardId => null;
  RestoreBoard(this.id);
  factory RestoreBoard.fromJson(Map<String, dynamic> json) =>
      _$RestoreBoardFromJson(json);

  @override
  ProjectEvent undoEvent() => RemoveBoard(id);

  @override
  Map<String, dynamic> toJson() => _$RestoreBoardToJson(this);

  @override
  List<String> get boardsToWrite => [id];

  @override
  void execute(ProjectEventHandler handler) {
    handler.restoreBoard();
  }
}

@JsonSerializable()
class ConfigButton extends ProjectEvent {
  static const tableId = 4;
  final String boardId;
  final String buttonId;
  final Map<String, dynamic> undoChanges;
  final Map<String, dynamic> diff;
  //TODO There should be a way to avoid the lines below especially when we need to handle networking that is alot of wasted bytes
  final Map<String, dynamic>? originalSound;
  final Map<String, dynamic>? newSound;
  final Map<String, dynamic>? originalImage;
  final Map<String, dynamic>? newImage;
  @override
  String? get returnToBoardId => boardId;

  ConfigButton({
    required this.boardId,
    required this.buttonId,
    required this.undoChanges,
    required this.diff,
    this.originalSound,
    this.newSound,
    this.originalImage,
    this.newImage,
  });
  factory ConfigButton.fromJson(Map<String, dynamic> json) =>
      _$ConfigButtonFromJson(deepCastMapToJsonMap(json)!);
  void updatePatch(ProjectEventHandler handler) {
    ImageData? newImage;
    ImageData? oldImage;
    SoundData? newSound;
    SoundData? oldSound;

    if (this.newImage != null) {
      newImage = ImageData.decodeJson(this.newImage!);
    }
    if (originalImage != null) {
      oldImage = ImageData.decodeJson(originalImage!);
    }
    if (this.newSound != null) {
      newSound = SoundData.decode(this.newSound!);
    }
    if (originalSound != null) {
      oldSound = SoundData.decode(originalSound!);
    }

    //if both are null I shouldn't need to remove or add anything if only one or more is not null then I need to add or delete.
    if (oldImage?.path != newImage?.path) {
      if (newImage != null) {
        handler.currentPatch?.addImageFile(_fullPath(handler, newImage.path!));
      }
      if (oldImage != null) {
        handler.currentPatch?.removeImageFile(
          _fullPath(handler, oldImage.path!),
        );
      }
    }

    if (oldSound?.path != newSound?.path) {
      if (newSound != null) {
        handler.currentPatch?.addAudioFile(_fullPath(handler, newSound.path!));
      }
      if (oldSound != null) {
        handler.currentPatch?.removeAudioFile(
          _fullPath(handler, oldSound.path!),
        );
      }
    }
  }

  @override
  Map<String, dynamic> toJson() => _$ConfigButtonToJson(this);
  @override
  ProjectEvent undoEvent() {
    return ConfigButton(
      undoChanges: diff,
      diff: undoChanges,
      boardId: boardId,
      buttonId: buttonId,
      newSound: originalSound,
      newImage: originalImage,
      originalSound: newSound,
      originalImage: newImage,
    );
  }

  @override
  void execute(ProjectEventHandler handler) {
    updatePatch(handler);

    final board = handler.project.findBoardById(boardId);
    final button = board?.findButtonById(buttonId);
    SoundData? sound;
    if (newSound != null) {
      sound = SoundData.decode(newSound!);
    }

    ImageData? image;
    if (newImage != null) {
      image = ImageData.decodeJson(newImage!);
    }

    button?.merge(diff, project: handler.project);
    button?.image = image;
    button?.sound = sound;
    if (board == handler.currentBoard && handler.autoUpdateUi) {
      handler.gridNotifier.forEach((obj) {
        if (obj is ParrotButtonNotifier && obj.data.id == button?.id) {
          obj.update();
        }
      });
    }
  }
}

@JsonSerializable()
class AddColumn extends ProjectEvent {
  final String id;
  static const tableId = 5;
  @override
  String? get returnToBoardId => id;

  AddColumn({required this.id});
  factory AddColumn.fromJson(Map<String, dynamic> json) =>
      _$AddColumnFromJson(json);

  @override
  ProjectEvent undoEvent() => RemoveColumn(id: id);

  @override
  Map<String, dynamic> toJson() => _$AddColumnToJson(this);

  @override
  void execute(ProjectEventHandler handler) {
    Obf board = handler.project.findBoardById(id) ?? handler.currentBoard;
    if (board == handler.currentBoard) {
      if (handler.autoUpdateUi) {
        handler.gridNotifier.addColumn();
        handler.updateOnPressed();
      }
    }
    board.grid.addColumnToTheRight();
  }
}

@JsonSerializable()
class RenameBoard extends ProjectEvent {
  static const tableId = 6;
  final String id;
  final String name;
  final String prevName;
  @override
  String? get returnToBoardId => id;

  RenameBoard({required this.name, required this.prevName, required this.id});

  @override
  ProjectEvent undoEvent() {
    return RenameBoard(name: prevName, prevName: name, id: id);
  }

  factory RenameBoard.fromJson(Map<String, dynamic> json) =>
      _$RenameBoardFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$RenameBoardToJson(this);

  @override
  void execute(ProjectEventHandler handler) {
    Obf board = handler.project.findBoardById(id) ?? handler.currentBoard;
    board.name = name;
    if (handler.autoUpdateUi && board == handler.currentBoard) {
      handler.titleController.text = board.name;
    }
  }
}

@JsonSerializable()
class RemoveColumn extends ProjectEvent {
  static const tableId = 7;
  final String id;
  final int? col;

  @override
  String? get returnToBoardId => id;

  RemoveColumn({required this.id, this.col});
  factory RemoveColumn.fromJson(Map<String, dynamic> json) =>
      _$RemoveColumnFromJson(json);

  @override
  ProjectEvent undoEvent() {
    return RecoverColumn(id: id, col: col);
  }

  @override
  Map<String, dynamic> toJson() => _$RemoveColumnToJson(this);

  @override
  void execute(ProjectEventHandler handler) {
    Obf board = handler.project.findBoardById(id) ?? handler.currentBoard;
    int column = col ?? (board.grid.numberOfColumns - 1);

    List<ButtonData?> removedCol = board.grid.getCol(column);
    handler.history.addRemovedRowOrCol(removedCol);

    if (board == handler.currentBoard) {
      if (handler.autoUpdateUi) {
        handler.gridNotifier.removeCol(column);
        handler.updateOnPressed();
      }
    }
    board.grid.removeCol(column);
  }
}

@JsonSerializable()
class RecoverColumn extends ProjectEvent {
  static const tableId = 8;
  final String id;
  final int? col;

  @override
  String? get returnToBoardId => id;

  RecoverColumn({required this.id, this.col});
  factory RecoverColumn.fromJson(Map<String, dynamic> json) =>
      _$RecoverColumnFromJson(json);

  @override
  ProjectEvent undoEvent() {
    return RemoveColumn(id: id, col: col);
  }

  @override
  Map<String, dynamic> toJson() => _$RecoverColumnToJson(this);

  @override
  void execute(ProjectEventHandler handler) {
    handler.recoverCol(col);
  }
}

@JsonSerializable()
class AddRow extends ProjectEvent {
  static const tableId = 9;
  final String id;
  @override
  String? get returnToBoardId => id;

  AddRow({required this.id});
  factory AddRow.fromJson(Map<String, dynamic> json) => _$AddRowFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AddRowToJson(this);

  @override
  ProjectEvent undoEvent() => RemoveRow(id: id);

  @override
  void execute(ProjectEventHandler handler) {
    Obf board = handler.fromIdOrCurrent(id);
    if (board == handler.currentBoard) {
      if (handler.autoUpdateUi) {
        handler.gridNotifier.addRow();
      }
    }

    board.grid.addRowToTheBottom();
  }
}

@JsonSerializable()
class AddButton extends ProjectEvent {
  static const tableId = 10;
  final String boardId;
  final int row;
  final int col;
  @override
  String? get returnToBoardId => boardId;
  final Map<String, dynamic> buttonData;
  final Map<String, dynamic>? imageData;
  final Map<String, dynamic>? soundData;

  AddButton({
    required this.row,
    required this.col,
    required this.boardId,
    required this.buttonData,
    this.soundData,
    this.imageData,
  });
  factory AddButton.fromJson(Map json) =>
      _$AddButtonFromJson(deepCastMapToJsonMap(json)!);
  @override
  Map<String, dynamic> toJson() => _$AddButtonToJson(this);
  @override
  ProjectEvent undoEvent() =>
      RemoveButton(boardId: boardId, row: row, col: col);

  @override
  void execute(ProjectEventHandler handler) {
    ImageData? image;
    if (imageData != null) {
      image = ImageData.decodeJson(imageData!);
      if (image.path != null) {
        handler.currentPatch?.addImageFile(_fullPath(handler, image.path!));
      }
    }
    SoundData? sound;
    if (soundData != null) {
      sound = SoundData.decode(soundData!);
      if (sound.path != null) {
        handler.currentPatch?.addAudioFile(_fullPath(handler, sound.path!));
      }
    }

    Obf? board = handler.project.findBoardById(boardId);
    assert(board != null, "can't add to null board");
    ButtonData button = ButtonData.decode(json: buttonData);

    button.image = button.image ?? image;
    button.sound = button.sound ?? sound;

    board?.grid.setButtonData(row: row, col: col, data: button);
    board?.buttons.add(button);

    if (board == handler.currentBoard) {
      if (handler.autoUpdateUi) {
        handler.gridNotifier.setWidget(
          row: row,
          col: col,
          data: handler.makeButtonNotifier(button, row, col),
        );
      }
    }
  }
}

@JsonSerializable()
class RemoveButton extends ProjectEvent {
  static const tableId = 11;
  final String boardId;
  final int row;
  final int col;
  @override
  String? get returnToBoardId => boardId;
  RemoveButton({required this.boardId, required this.row, required this.col});

  factory RemoveButton.fromJson(Map<String, dynamic> json) =>
      _$RemoveButtonFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$RemoveButtonToJson(this);

  @override
  ProjectEvent undoEvent() =>
      RecoverButton(row: row, col: col, boardId: boardId);

  @override
  void execute(ProjectEventHandler handler) {
    Obf board = handler.fromIdOrCurrent(boardId);
    ButtonData? buttonData = board.grid.getButtonData(row, col);

    //button data doesn't break anything if it is null but it is wasted IO and computation, if there is ever the need this assert can be removed.
    assert(
      buttonData != null,
      "removing null button, this is an unnecessary call",
    );

    if (buttonData?.image?.path != null) {
      handler.currentPatch?.removeImageFile(
        _fullPath(handler, buttonData!.image!.path!),
      );
    }
    if (buttonData?.sound?.path != null) {
      handler.currentPatch?.removeAudioFile(buttonData!.sound!.path!);
    }
    if (buttonData != null) {
      handler.history.addToRemovedButtons(buttonData);
    }
    if (board == handler.currentBoard && handler.autoUpdateUi) {
      handler.gridNotifier.removeAt(row, col);
    }
    board.grid.setButtonData(row: row, col: col, data: null);
  }
}

@JsonSerializable()
class RecoverButton extends ProjectEvent {
  static const tableId = 12;
  final int row;
  final int col;
  final String boardId;
  @override
  String? get returnToBoardId => boardId;
  RecoverButton({required this.boardId, required this.row, required this.col});

  factory RecoverButton.fromJson(Map<String, dynamic> json) =>
      _$RecoverButtonFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$RecoverButtonToJson(this);

  @override
  ProjectEvent undoEvent() {
    return RemoveButton(boardId: boardId, row: row, col: col);
  }

  @override
  void execute(ProjectEventHandler handler) {
    handler.recoverButton(row, col);
  }
}

@JsonSerializable()
class RemoveRow extends ProjectEvent {
  static const tableId = 13;
  final String id;
  final int? row;
  @override
  String? get returnToBoardId => id;
  RemoveRow({required this.id, this.row});

  factory RemoveRow.fromJson(Map<String, dynamic> json) =>
      _$RemoveRowFromJson(json);

  @override
  ProjectEvent undoEvent() => RecoverRow(id: id, row: row);

  @override
  Map<String, dynamic> toJson() => _$RemoveRowToJson(this);

  @override
  void execute(ProjectEventHandler handler) {
    Obf board = handler.fromIdOrCurrent(id);
    int toRemove = row ?? (board.grid.numberOfRows - 1);

    List<ButtonData?> removedRow = board.grid.getRow(toRemove);
    handler.history.addRemovedRowOrCol(removedRow);
    if (board == handler.currentBoard) {
      if (handler.autoUpdateUi) {
        handler.gridNotifier.removeRow(toRemove);
        handler.updateOnPressed();
      }
    }
    board.grid.removeRow(toRemove);
  }
}

@JsonSerializable()
class RecoverRow extends ProjectEvent {
  static const tableId = 14;
  final String id;
  final int? row;
  @override
  String? get returnToBoardId => id;
  RecoverRow({required this.id, this.row});

  factory RecoverRow.fromJson(Map<String, dynamic> json) =>
      _$RecoverRowFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$RecoverRowToJson(this);
  @override
  ProjectEvent undoEvent() => RemoveRow(id: id, row: row);

  @override
  void execute(ProjectEventHandler handler) {
    handler.recoverRow(row);
  }
}

@JsonSerializable()
class SwapEvent extends ProjectEvent {
  static const tableId = 15;
  final SwapData swapData;

  @override
  String? get returnToBoardId => boardId;
  final String boardId;

  SwapEvent({required this.boardId, required this.swapData});

  @override
  ProjectEvent undoEvent() => this;

  factory SwapEvent.fromJson(Map<String, dynamic> json) =>
      _$SwapEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SwapEventToJson(this);

  @override
  List<String> get boardsToWrite => {swapData.s1.id, swapData.s2.id}.toList();

  @override
  void execute(ProjectEventHandler handler) {
    swapData.performSwap(handler.project);
    final updateUi = handler.autoUpdateUi;
    final currentBoardId = handler.currentBoard.id;
    if (boardId == currentBoardId) {
      if (updateUi) {
        handler.fullUIUpdate();
      }
    }

    final s1 = swapData.s1;
    final s2 = swapData.s2;
    final SelectionDataInterface sel1;
    final SelectionDataInterface sel2;
    if (s1.id == currentBoardId) {
      sel1 = handler.gridNotifier.selectionController;
    } else {
      sel1 =
          handler.selectionHistory.findSelectionFromId(s1.id)?.copy() ??
          SelectionData();
    }

    if (s2.id == currentBoardId) {
      sel2 = handler.gridNotifier.selectionController;
    } else {
      sel2 =
          handler.selectionHistory.findSelectionFromId(s2.id)?.copy() ??
          SelectionData();
    }

    SwapData.swapSelection(sel1, sel2, s1, s2);

    if (s1.id != currentBoardId) {
      handler.selectionHistory.updateData(s1.id, (data) {
        data.setTo(sel1 as SelectionData);
      });
    }
    if (s2.id != currentBoardId && s1.id != s2.id) {
      handler.selectionHistory.updateData(s2.id, (data) {
        data.setTo(sel2 as SelectionData);
      });
    }
  }
}

@JsonSerializable()
class BulkRemove extends ProjectEvent {
  static const tableId = 16;
  final Map<String, Set<int>> rowsToRemove;
  final Map<String, Set<int>> colsToRemove;

  @JsonKey(fromJson: _buttonsFromJson, toJson: _toJson)
  final Map<String, Set<RowColPair>> buttonsToRemove;
  BulkRemove({
    Map<String, Set<int>>? rowsToRemove,
    Map<String, Set<int>>? colsToRemove,
    Map<String, Set<RowColPair>>? buttonsToRemove,
  }) : rowsToRemove = rowsToRemove ?? {},
       colsToRemove = colsToRemove ?? {},
       buttonsToRemove = buttonsToRemove ?? {};

  factory BulkRemove.fromSelection(WorkingSelectionHistory selectionHistory) {
    final selectedRows = selectionHistory.selectedRows().mapValue(
      (vals) => vals.toSet(),
    );
    final selectedCols = selectionHistory.selectedCols().mapValue(
      (vals) => vals.toSet(),
    );

    final selectedButtons = selectionHistory.selectedButtons;

    return BulkRemove(
      rowsToRemove: selectedRows,
      colsToRemove: selectedCols,
      buttonsToRemove: selectedButtons,
    );
  }

  static Map<String, Set<RowColPair>> _buttonsFromJson(Map json) {
    final Map<String, Set<RowColPair>> out = {};
    for (final entry in json.entries) {
      final Set<RowColPair> temp = {};
      if (entry.value is Iterable) {
        for (dynamic val in entry.value) {
          temp.addIfNotNull(RowColPair.fromJson(val));
        }
      }
      out[entry.key] = temp;
    }
    return out;
  }

  static Map<String, dynamic> _toJson(Map<String, Set<RowColPair>> toConvert) {
    final Map<String, dynamic> out = {};
    for (MapEntry<String, Set<RowColPair>> entry in toConvert.entries) {
      out[entry.key] = entry.value.mapToJsonEncodedList();
    }
    return out;
  }

  factory BulkRemove.fromJson(Map<String, dynamic> json) =>
      _$BulkRemoveFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BulkRemoveToJson(this);

  @override
  void execute(ProjectEventHandler handler) {
    Map<String, Obf?> seenBoards = {};

    _bulkRemove<RowColPair>(
      removeEntry: (board, pairs) {
        for (final pair in pairs) {
          RemoveButton(
            boardId: board.id,
            col: pair.col,
            row: pair.row,
          ).execute(handler);
        }
      },
      handler: handler,
      map: buttonsToRemove,
      boardCache: seenBoards,
    );

    _bulkRemove<int>(
      removeEntry: (board, rows) {
        final descending = rows.descendingOrder;
        for (final row in descending) {
          RemoveRow(id: board.id, row: row).execute(handler);
        }
      },
      handler: handler,
      map: rowsToRemove,
      boardCache: seenBoards,
    );

    _bulkRemove<int>(
      removeEntry: (board, cols) {
        final descending = cols.descendingOrder;
        for (final col in descending) {
          RemoveColumn(id: board.id, col: col).execute(handler);
        }
      },
      handler: handler,
      map: colsToRemove,
      boardCache: seenBoards,
    );
  }

  void _bulkRemove<T>({
    required Function(Obf, Set<T>) removeEntry,
    required ProjectEventHandler handler,
    required Map<String, Set<T>> map,
    required Map<String, Obf?> boardCache,
  }) {
    final project = handler.project;
    for (MapEntry entry in map.entries) {
      final id = entry.key;
      final value = entry.value;
      Obf? board = boardCache.containsKey(entry.key)
          ? boardCache[entry.key]
          : project.findBoardById(id);

      boardCache[id] = board;
      if (board != null) {
        removeEntry(board, value);
      }
    }
  }

  @override
  String? get returnToBoardId => null;

  @override
  List<String> get boardsToWrite => mergeToSet<String>([
    colsToRemove.keys,
    rowsToRemove.keys,
    buttonsToRemove.keys,
  ]).toList();

  @override
  ProjectEvent undoEvent() => BulkRecover(
    rowsToRecover: rowsToRemove,
    colsToRecover: colsToRemove,
    buttonsToRecover: buttonsToRemove,
  );
}

@JsonSerializable()
class BulkRecover extends ProjectEvent {
  static const tableId = 17;
  final Map<String, Set<int>> rowsToRecover;
  final Map<String, Set<int>> colsToRecover;

  @JsonKey(fromJson: BulkRemove._buttonsFromJson, toJson: BulkRemove._toJson)
  final Map<String, Set<RowColPair>> buttonsToRecover;

  BulkRecover({
    required this.rowsToRecover,
    required this.colsToRecover,
    required this.buttonsToRecover,
  });

  @override
  void execute(ProjectEventHandler handler) {
    //WARNING: order of recovering rows and columns must match the order of removal in reverse

    for (final entries in colsToRecover.entries) {
      final toRecover = entries.value.ascendingOrder;
      for (final col in toRecover) {
        RecoverColumn(id: entries.key, col: col).execute(handler);
      }
    }

    for (final entries in rowsToRecover.entries) {
      final toRecover = entries.value.ascendingOrder;
      for (final row in toRecover) {
        RecoverRow(id: entries.key, row: row).execute(handler);
      }
    }

    for (final entries in buttonsToRecover.entries) {
      final toRecover = entries.value;
      for (final button in toRecover) {
        RecoverButton(
          boardId: entries.key,
          row: button.row,
          col: button.col,
        ).execute(handler);
      }
    }
  }

  @override
  String? get returnToBoardId => null;

  @override
  List<String> get boardsToWrite => mergeToSet<String>([
    colsToRecover.keys,
    rowsToRecover.keys,
    buttonsToRecover.keys,
  ]).toList();

  @override
  Map<String, dynamic> toJson() => _$BulkRecoverToJson(this);
  factory BulkRecover.fromJson(Map<String, dynamic> json) =>
      _$BulkRecoverFromJson(json);

  @override
  ProjectEvent undoEvent() => BulkRemove(
    rowsToRemove: rowsToRecover,
    colsToRemove: colsToRecover,
    buttonsToRemove: buttonsToRecover,
  );
}

@JsonSerializable()
class ChangeBoardColor extends ProjectEvent {
  static const tableId = 18;
  final String boardId;
  final String originalColor;
  final String newColor;
  @override
  String get returnToBoardId => boardId;
  ChangeBoardColor({
    required this.boardId,
    required this.originalColor,
    required this.newColor,
  });

  @override
  Map<String, dynamic> toJson() => _$ChangeBoardColorToJson(this);

  factory ChangeBoardColor.fromJson(Map<String, dynamic> json) =>
      _$ChangeBoardColorFromJson(json);

  @override
  ProjectEvent undoEvent() => ChangeBoardColor(
    boardId: boardId,
    originalColor: newColor,
    newColor: originalColor,
  );

  @override
  void execute(ProjectEventHandler handler) {
    Obf board = handler.fromIdOrCurrent(boardId);
    board.boardColor = ColorData.fromString(newColor);
    if (handler.autoUpdateUi) {
      handler.gridNotifier.backgroundColorNotifier.value = board.boardColor
          .toColor();
      handler.gridNotifier.emptySpotWidget = EmptySpotWidget(
        color: EmptySpotWidget.fromBackground(
          handler.gridNotifier.backgroundColorNotifier.value,
        ),
      );
    }
  }
}

String _fullPath(ProjectEventHandler handler, String path) =>
    p.join(handler.project.path, path);
