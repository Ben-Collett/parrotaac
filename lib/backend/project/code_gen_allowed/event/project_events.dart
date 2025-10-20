import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/grid_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:openboard_wrapper/sound_data.dart';
import 'package:parrotaac/backend/map_utils.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/extensions/button_data_extensions.dart';
import 'package:parrotaac/extensions/color_extensions.dart';
import 'package:parrotaac/extensions/obf_extensions.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/parrot_button.dart';
import 'package:parrotaac/ui/widgets/empty_spot.dart';
part 'project_events.g.dart';

abstract class ProjectEvent {
  EventType get type;
  String? get returnToBoardId;

  ///if returnToBoardId is null this getter must be overridden
  String get boardToWrite => returnToBoardId!;
  static ProjectEvent? decode(Map<String, dynamic> json) {
    ProjectEvent? event;
    EventType? type = EventType.fromString(json["type"]);

    Map<String, dynamic>? content = castMapToJsonMap(json["content"]);
    if (type != null && content != null) {
      return type.create(content);
    }
    return event;
  }

  void execute(ProjectEventHandler handler);

  Map<String, dynamic> encode() {
    return {"version": 1, "type": type.asString, "content": toJson()};
  }

  Map<String, dynamic> toJson();

  ProjectEvent undoEvent();
}

enum EventType {
  addBoard("add_board", AddBoard.fromJson),
  addColumn("add_col", AddColumn.fromJson),
  removeCol("remove_col", RemoveColumn.fromJson),
  removeRow("remove_row", RemoveRow.fromJson),
  removeBoard("remove_board", RemoveBoard.fromJson),
  restoreBoard("restore_board", RestoreBoard.fromJson),
  recoverCol("recover_col", RecoverColumn.fromJson),
  recoverRow("recover_row", RecoverRow.fromJson),
  addRow("add_row", AddRow.fromJson),
  configButton("config_button", ConfigButton.fromJson),
  renameBoard("rename_board", RenameBoard.fromJson),
  addButton("add_button", AddButton.fromJson),
  removeButton("remove_button", RemoveButton.fromJson),
  recoverButton("recover_button", RecoverButton.fromJson),
  changeBoardColor("change_board_color", ChangeBoardColor.fromJson),
  swapButtons("swap_buttons", SwapButtons.fromJson);

  const EventType(this.asString, this.create);

  final String asString;
  final Function(Map<String, dynamic>) create;

  static EventType? fromString(String? type) => EventType.values.firstWhere(
    (e) => e.asString == type,
    orElse: () => throw ArgumentError('Unknown event type: $type'),
  );
}

@JsonSerializable()
class AddBoard extends ProjectEvent {
  final String id;
  final String name;
  final int rowCount;
  final int colCount;
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
  EventType get type => EventType.addBoard;

  @override
  String get boardToWrite => id;

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
  RemoveBoard(this.id);

  factory RemoveBoard.fromJson(Map<String, dynamic> json) =>
      _$RemoveBoardFromJson(json);

  @override
  ProjectEvent undoEvent() => RestoreBoard(id);

  @override
  Map<String, dynamic> toJson() => _$RemoveBoardToJson(this);

  @override
  EventType get type => EventType.removeBoard;

  @override
  String? get returnToBoardId => null;

  @override
  String get boardToWrite => id;

  @override
  void execute(ProjectEventHandler handler) {
    Obf? board = handler.project.findBoardById(id);
    if (board == null) {
      SimpleLogger().logWarning("removing non existent board");
      return;
    }
    handler.project.removeBoard(board);
    handler.history.addRemoveBoard(board);
  }
}

@JsonSerializable()
class RestoreBoard extends ProjectEvent {
  final String id;
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
  EventType get type => EventType.restoreBoard;

  @override
  String get boardToWrite => id;

  @override
  void execute(ProjectEventHandler handler) {
    handler.restoreBoard();
  }
}

@JsonSerializable()
class ConfigButton extends ProjectEvent {
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
  EventType get type => EventType.configButton;

  @override
  void execute(ProjectEventHandler handler) {
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
      handler.gridNotfier.forEach((obj) {
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
  EventType get type => EventType.addColumn;

  @override
  void execute(ProjectEventHandler handler) {
    Obf board = handler.project.findBoardById(id) ?? handler.currentBoard;
    if (board == handler.currentBoard) {
      if (handler.autoUpdateUi) {
        handler.gridNotfier.addColumn();
        handler.updateOnPressed();
      }
    }
    board.grid.addColumnToTheRight();
  }
}

@JsonSerializable()
class RenameBoard extends ProjectEvent {
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
  EventType get type => EventType.renameBoard;

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
  EventType get type => EventType.removeCol;

  @override
  void execute(ProjectEventHandler handler) {
    Obf board = handler.project.findBoardById(id) ?? handler.currentBoard;
    int column = col ?? (board.grid.numberOfColumns - 1);

    List<ButtonData?> removedCol = board.grid.getCol(column);
    handler.history.addRemovedRowOrCol(removedCol);

    if (board == handler.currentBoard) {
      if (handler.autoUpdateUi) {
        handler.gridNotfier.removeCol(column);
        handler.updateOnPressed();
      }
    }
    board.grid.removeCol(column);
  }
}

@JsonSerializable()
class RecoverColumn extends ProjectEvent {
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
  EventType get type => EventType.recoverCol;

  @override
  void execute(ProjectEventHandler handler) {
    handler.recoverCol(col);
  }
}

@JsonSerializable()
class AddRow extends ProjectEvent {
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
  EventType get type => EventType.addRow;

  @override
  void execute(ProjectEventHandler handler) {
    Obf board = handler.fromIdOrCurrent(id);
    if (board == handler.currentBoard) {
      if (handler.autoUpdateUi) {
        handler.gridNotfier.addRow();
      }
    }

    board.grid.addRowToTheBottom();
  }
}

@JsonSerializable()
class AddButton extends ProjectEvent {
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
  EventType get type => EventType.addButton;

  @override
  void execute(ProjectEventHandler handler) {
    ImageData? image;
    if (imageData != null) {
      image = ImageData.decodeJson(imageData!);
    }
    SoundData? sound;
    if (soundData != null) {
      sound = SoundData.decode(soundData!);
    }

    Obf? board = handler.project.findBoardById(boardId);
    assert(board != null, "can't add to null board");
    ButtonData button = ButtonData.decode(json: buttonData);

    button.image = button.image ?? image;
    button.sound = button.sound ?? sound;
    if (board == handler.currentBoard) {
      if (handler.autoUpdateUi) {
        handler.gridNotfier.setWidget(
          row: row,
          col: col,
          data: handler.makeButtonNotifier(button, row, col),
        );
      }
    }
    board?.grid.setButtonData(row: row, col: col, data: button);
    board?.buttons.add(button);
  }
}

@JsonSerializable()
class RemoveButton extends ProjectEvent {
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
  EventType get type => EventType.removeButton;

  @override
  void execute(ProjectEventHandler handler) {
    Obf board = handler.fromIdOrCurrent(boardId);
    handler.history.addToRemovedButtons(board.grid.getButtonData(row, col)!);
    if (board == handler.currentBoard && handler.autoUpdateUi) {
      handler.gridNotfier.removeAt(row, col);
    }
    board.grid.setButtonData(row: row, col: col, data: null);
  }
}

@JsonSerializable()
class RecoverButton extends ProjectEvent {
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
  EventType get type => EventType.recoverButton;

  @override
  void execute(ProjectEventHandler handler) {
    handler.recoverButton(row, col);
  }
}

@JsonSerializable()
class RemoveRow extends ProjectEvent {
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
  EventType get type => EventType.removeRow;

  @override
  void execute(ProjectEventHandler handler) {
    Obf board = handler.fromIdOrCurrent(id);
    int toRemove = row ?? (board.grid.numberOfRows - 1);

    List<ButtonData?> removedRow = board.grid.getRow(toRemove);
    handler.history.addRemovedRowOrCol(removedRow);
    if (board == handler.currentBoard) {
      if (handler.autoUpdateUi) {
        handler.gridNotfier.removeRow(toRemove);
        handler.updateOnPressed();
      }
    }
    board.grid.removeRow(toRemove);
  }
}

@JsonSerializable()
class RecoverRow extends ProjectEvent {
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
  EventType get type => EventType.recoverRow;

  @override
  void execute(ProjectEventHandler handler) {
    handler.recoverRow(row);
  }
}

@JsonSerializable()
class SwapButtons extends ProjectEvent {
  final String boardId;
  final int oldRow, oldCol;
  final int newRow, newCol;
  @override
  String? get returnToBoardId => boardId;
  SwapButtons({
    required this.boardId,
    required this.oldRow,
    required this.newRow,
    required this.oldCol,
    required this.newCol,
  });

  @override
  ProjectEvent undoEvent() => SwapButtons(
    boardId: boardId,
    oldRow: newRow,
    newRow: oldRow,
    oldCol: newCol,
    newCol: oldCol,
  );

  factory SwapButtons.fromJson(Map<String, dynamic> json) =>
      _$SwapButtonsFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SwapButtonsToJson(this);

  @override
  EventType get type => EventType.swapButtons;

  @override
  void execute(ProjectEventHandler handler) {
    Obf board = handler.fromIdOrCurrent(boardId);
    if (board == handler.currentBoard) {
      if (handler.autoUpdateUi) {
        handler.gridNotfier.swap(oldRow, oldCol, newRow, newCol);
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
}

@JsonSerializable()
class ChangeBoardColor extends ProjectEvent {
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
  EventType get type => EventType.changeBoardColor;

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
      handler.gridNotfier.backgroundColorNotifier.value = board.boardColor
          .toColor();
      handler.gridNotfier.emptySpotWidget = EmptySpotWidget(
        color: EmptySpotWidget.fromBackground(
          handler.gridNotfier.backgroundColorNotifier.value,
        ),
      );
    }
  }
}
