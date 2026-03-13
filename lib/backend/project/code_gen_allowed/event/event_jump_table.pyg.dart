// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:parrotaac/backend/project/code_gen_allowed/event/project_events.dart';

final Map<Type, int> _mapEvent = {
  AddBoard: 1,
  RemoveBoard: 2,
  RestoreBoard: 3,
  ConfigButton: 4,
  AddColumn: 5,
  RenameBoard: 6,
  RemoveColumn: 7,
  RecoverColumn: 8,
  AddRow: 9,
  AddButton: 10,
  RemoveButton: 11,
  RecoverButton: 12,
  RemoveRow: 13,
  RecoverRow: 14,
  SwapEvent: 15,
  BulkRemove: 16,
  BulkRecover: 17,
  ChangeBoardColor: 18,
};

Map<String, dynamic> encodeEvent(ProjectEvent event) {
  final type = event.runtimeType;
  final id = _mapEvent[type];

  final encoded = event.toJson();

  return {"t": id, "v": 1, "c": encoded};
}

dynamic decodeEvent(Map<String, dynamic> data) {
  final id = data["t"] as int?;
  data = data["c"];

  switch (id) {
    case 1:
      return AddBoard.fromJson(data);
    case 2:
      return RemoveBoard.fromJson(data);
    case 3:
      return RestoreBoard.fromJson(data);
    case 4:
      return ConfigButton.fromJson(data);
    case 5:
      return AddColumn.fromJson(data);
    case 6:
      return RenameBoard.fromJson(data);
    case 7:
      return RemoveColumn.fromJson(data);
    case 8:
      return RecoverColumn.fromJson(data);
    case 9:
      return AddRow.fromJson(data);
    case 10:
      return AddButton.fromJson(data);
    case 11:
      return RemoveButton.fromJson(data);
    case 12:
      return RecoverButton.fromJson(data);
    case 13:
      return RemoveRow.fromJson(data);
    case 14:
      return RecoverRow.fromJson(data);
    case 15:
      return SwapEvent.fromJson(data);
    case 16:
      return BulkRemove.fromJson(data);
    case 17:
      return BulkRecover.fromJson(data);
    case 18:
      return ChangeBoardColor.fromJson(data);
    default:
      return null;
  }
}