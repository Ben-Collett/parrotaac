// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddBoard _$AddBoardFromJson(Map<String, dynamic> json) => AddBoard(
      id: json['id'] as String,
      rowCount: (json['rowCount'] as num).toInt(),
      colCount: (json['colCount'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$AddBoardToJson(AddBoard instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'rowCount': instance.rowCount,
      'colCount': instance.colCount,
    };

RemoveBoard _$RemoveBoardFromJson(Map<String, dynamic> json) => RemoveBoard(
      json['id'] as String,
    );

Map<String, dynamic> _$RemoveBoardToJson(RemoveBoard instance) =>
    <String, dynamic>{
      'id': instance.id,
    };

RestoreBoard _$RestoreBoardFromJson(Map<String, dynamic> json) => RestoreBoard(
      json['id'] as String,
    );

Map<String, dynamic> _$RestoreBoardToJson(RestoreBoard instance) =>
    <String, dynamic>{
      'id': instance.id,
    };

ConfigButton _$ConfigButtonFromJson(Map<String, dynamic> json) => ConfigButton(
      boardId: json['boardId'] as String,
      buttonId: json['buttonId'] as String,
      undoChanges: json['undoChanges'] as Map<String, dynamic>,
      diff: json['diff'] as Map<String, dynamic>,
      originalSound: json['originalSound'] as Map<String, dynamic>?,
      newSound: json['newSound'] as Map<String, dynamic>?,
      originalImage: json['originalImage'] as Map<String, dynamic>?,
      newImage: json['newImage'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ConfigButtonToJson(ConfigButton instance) =>
    <String, dynamic>{
      'boardId': instance.boardId,
      'buttonId': instance.buttonId,
      'undoChanges': instance.undoChanges,
      'diff': instance.diff,
      'originalSound': instance.originalSound,
      'newSound': instance.newSound,
      'originalImage': instance.originalImage,
      'newImage': instance.newImage,
    };

AddColumn _$AddColumnFromJson(Map<String, dynamic> json) => AddColumn(
      col: (json['col'] as num?)?.toInt(),
      id: json['id'] as String,
    );

Map<String, dynamic> _$AddColumnToJson(AddColumn instance) => <String, dynamic>{
      'id': instance.id,
      'col': instance.col,
    };

RenameBoard _$RenameBoardFromJson(Map<String, dynamic> json) => RenameBoard(
      name: json['name'] as String,
      prevName: json['prevName'] as String,
      id: json['id'] as String,
    );

Map<String, dynamic> _$RenameBoardToJson(RenameBoard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'prevName': instance.prevName,
    };

RemoveColumn _$RemoveColumnFromJson(Map<String, dynamic> json) => RemoveColumn(
      id: json['id'] as String,
      col: (json['col'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RemoveColumnToJson(RemoveColumn instance) =>
    <String, dynamic>{
      'id': instance.id,
      'col': instance.col,
    };

RecoverColumn _$RecoverColumnFromJson(Map<String, dynamic> json) =>
    RecoverColumn(
      id: json['id'] as String,
      col: (json['col'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RecoverColumnToJson(RecoverColumn instance) =>
    <String, dynamic>{
      'id': instance.id,
      'col': instance.col,
    };

AddRow _$AddRowFromJson(Map<String, dynamic> json) => AddRow(
      row: (json['row'] as num?)?.toInt(),
      id: json['id'] as String,
    );

Map<String, dynamic> _$AddRowToJson(AddRow instance) => <String, dynamic>{
      'id': instance.id,
      'row': instance.row,
    };

AddButton _$AddButtonFromJson(Map<String, dynamic> json) => AddButton(
      row: (json['row'] as num).toInt(),
      col: (json['col'] as num).toInt(),
      boardId: json['boardId'] as String,
      buttonData: json['buttonData'] as Map<String, dynamic>,
      soundData: json['soundData'] as Map<String, dynamic>?,
      imageData: json['imageData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AddButtonToJson(AddButton instance) => <String, dynamic>{
      'boardId': instance.boardId,
      'row': instance.row,
      'col': instance.col,
      'buttonData': instance.buttonData,
      'imageData': instance.imageData,
      'soundData': instance.soundData,
    };

RemoveButton _$RemoveButtonFromJson(Map<String, dynamic> json) => RemoveButton(
      boardId: json['boardId'] as String,
      row: (json['row'] as num).toInt(),
      col: (json['col'] as num).toInt(),
    );

Map<String, dynamic> _$RemoveButtonToJson(RemoveButton instance) =>
    <String, dynamic>{
      'boardId': instance.boardId,
      'row': instance.row,
      'col': instance.col,
    };

RecoverButton _$RecoverButtonFromJson(Map<String, dynamic> json) =>
    RecoverButton(
      boardId: json['boardId'] as String,
      row: (json['row'] as num).toInt(),
      col: (json['col'] as num).toInt(),
    );

Map<String, dynamic> _$RecoverButtonToJson(RecoverButton instance) =>
    <String, dynamic>{
      'row': instance.row,
      'col': instance.col,
      'boardId': instance.boardId,
    };

RemoveRow _$RemoveRowFromJson(Map<String, dynamic> json) => RemoveRow(
      id: json['id'] as String,
      row: (json['row'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RemoveRowToJson(RemoveRow instance) => <String, dynamic>{
      'id': instance.id,
      'row': instance.row,
    };

RecoverRow _$RecoverRowFromJson(Map<String, dynamic> json) => RecoverRow(
      id: json['id'] as String,
      row: (json['row'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RecoverRowToJson(RecoverRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'row': instance.row,
    };

SwapButtons _$SwapButtonsFromJson(Map<String, dynamic> json) => SwapButtons(
      boardId: json['boardId'] as String,
      oldRow: (json['oldRow'] as num).toInt(),
      newRow: (json['newRow'] as num).toInt(),
      oldCol: (json['oldCol'] as num).toInt(),
      newCol: (json['newCol'] as num).toInt(),
    );

Map<String, dynamic> _$SwapButtonsToJson(SwapButtons instance) =>
    <String, dynamic>{
      'boardId': instance.boardId,
      'oldRow': instance.oldRow,
      'oldCol': instance.oldCol,
      'newRow': instance.newRow,
      'newCol': instance.newCol,
    };

ChangeBoardColor _$ChangeBoardColorFromJson(Map<String, dynamic> json) =>
    ChangeBoardColor(
      boardId: json['boardId'] as String,
      originalColor: json['originalColor'] as String,
      newColor: json['newColor'] as String,
    );

Map<String, dynamic> _$ChangeBoardColorToJson(ChangeBoardColor instance) =>
    <String, dynamic>{
      'boardId': instance.boardId,
      'originalColor': instance.originalColor,
      'newColor': instance.newColor,
    };
