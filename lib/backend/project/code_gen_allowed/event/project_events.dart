import 'package:json_annotation/json_annotation.dart';
part 'project_events.g.dart';

abstract class ProjectEvent {
  static const events = {"add_board": AddBoard};

  String? get returnToBoardId => null;
  static ProjectEvent? decode(Map<String, dynamic> json) {
    return null;
  }

  Map<String, dynamic> encode() {
    return {};
  }

  ProjectEvent undoEvent();
}

class AddBoard extends ProjectEvent {
  final String id;
  final String name;
  final int rowCount;
  final int colCount;

  AddBoard({
    required this.id,
    required this.rowCount,
    required this.colCount,
    required this.name,
  });

  @override
  ProjectEvent undoEvent() => RemoveBoard(id);
}

class RemoveBoard extends ProjectEvent {
  final String id;
  RemoveBoard(this.id);

  @override
  ProjectEvent undoEvent() => RestoreBoard(id);
}

class RestoreBoard extends ProjectEvent {
  final String id;
  RestoreBoard(this.id);

  @override
  ProjectEvent undoEvent() => RemoveBoard(id);
}

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
}

class AddColumn extends ProjectEvent {
  final String id;
  final int? col;
  @override
  String? get returnToBoardId => id;

  AddColumn({this.col, required this.id});

  @override
  ProjectEvent undoEvent() => RemoveColumn(id: id, col: col);
}

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
}

class RemoveColumn extends ProjectEvent {
  final String id;
  final int? col;

  @override
  String? get returnToBoardId => id;

  RemoveColumn({required this.id, this.col});

  @override
  ProjectEvent undoEvent() {
    return RecoverColumn(id: id, col: col);
  }
}

class RecoverColumn extends ProjectEvent {
  final String id;
  final int? col;

  @override
  String? get returnToBoardId => id;

  RecoverColumn({required this.id, this.col});

  @override
  ProjectEvent undoEvent() {
    return RemoveColumn(id: id, col: col);
  }
}

class AddRow extends ProjectEvent {
  final String id;
  final int? row;
  @override
  String? get returnToBoardId => id;

  AddRow({this.row, required this.id});

  @override
  ProjectEvent undoEvent() => RemoveRow(id: id, row: row);
}

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

  @override
  ProjectEvent undoEvent() => RemoveButton(
        boardId: boardId,
        row: row,
        col: col,
      );
}

class RemoveButton extends ProjectEvent {
  final String boardId;
  final int row;
  final int col;
  @override
  String? get returnToBoardId => boardId;
  RemoveButton({
    required this.boardId,
    required this.row,
    required this.col,
  });

  @override
  ProjectEvent undoEvent() => RecoverButton(
        row: row,
        col: col,
        boardId: boardId,
      );
}

class RecoverButton extends ProjectEvent {
  final int row;
  final int col;
  final String boardId;
  @override
  String? get returnToBoardId => boardId;
  RecoverButton({
    required this.boardId,
    required this.row,
    required this.col,
  });

  @override
  ProjectEvent undoEvent() {
    return RemoveButton(boardId: boardId, row: row, col: col);
  }
}

class RemoveRow extends ProjectEvent {
  final String id;
  final int? row;
  @override
  String? get returnToBoardId => id;
  RemoveRow({
    required this.id,
    this.row,
  });

  @override
  ProjectEvent undoEvent() => RecoverRow(id: id, row: row);
}

class RecoverRow extends ProjectEvent {
  final String id;
  final int? row;
  @override
  String? get returnToBoardId => id;
  RecoverRow({
    required this.id,
    this.row,
  });

  @override
  ProjectEvent undoEvent() => RemoveRow(id: id, row: row);
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
      newCol: oldCol);

  factory SwapButtons.fromJson(Map<String, dynamic> json) =>
      _$SwapButtonsFromJson(json);

  Map<String, dynamic> toJson() => _$SwapButtonsToJson(this);
}

class Undo {
  Undo();
  Undo.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson() => {};
}

class Redo {
  Redo();
  Redo.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson() => {};
}
