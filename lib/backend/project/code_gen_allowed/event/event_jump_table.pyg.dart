// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:parrotaac/backend/project/code_gen_allowed/event/project_events.dart';

final Map<Type, int> _mapEvent = {
  AddBoard: AddBoard.tableId,
  RemoveBoard: RemoveBoard.tableId,
  RestoreBoard: RestoreBoard.tableId,
  ConfigButton: ConfigButton.tableId,
  AddColumn: AddColumn.tableId,
  RenameBoard: RenameBoard.tableId,
  RemoveColumn: RemoveColumn.tableId,
  RecoverColumn: RecoverColumn.tableId,
  AddRow: AddRow.tableId,
  AddButton: AddButton.tableId,
  RemoveButton: RemoveButton.tableId,
  RecoverButton: RecoverButton.tableId,
  RemoveRow: RemoveRow.tableId,
  RecoverRow: RecoverRow.tableId,
  SwapEvent: SwapEvent.tableId,
  BulkRemove: BulkRemove.tableId,
  BulkRecover: BulkRecover.tableId,
  ChangeBoardColor: ChangeBoardColor.tableId,
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
    case AddBoard.tableId:
      return AddBoard.fromJson(data);
    case RemoveBoard.tableId:
      return RemoveBoard.fromJson(data);
    case RestoreBoard.tableId:
      return RestoreBoard.fromJson(data);
    case ConfigButton.tableId:
      return ConfigButton.fromJson(data);
    case AddColumn.tableId:
      return AddColumn.fromJson(data);
    case RenameBoard.tableId:
      return RenameBoard.fromJson(data);
    case RemoveColumn.tableId:
      return RemoveColumn.fromJson(data);
    case RecoverColumn.tableId:
      return RecoverColumn.fromJson(data);
    case AddRow.tableId:
      return AddRow.fromJson(data);
    case AddButton.tableId:
      return AddButton.fromJson(data);
    case RemoveButton.tableId:
      return RemoveButton.fromJson(data);
    case RecoverButton.tableId:
      return RecoverButton.fromJson(data);
    case RemoveRow.tableId:
      return RemoveRow.fromJson(data);
    case RecoverRow.tableId:
      return RecoverRow.fromJson(data);
    case SwapEvent.tableId:
      return SwapEvent.fromJson(data);
    case BulkRemove.tableId:
      return BulkRemove.fromJson(data);
    case BulkRecover.tableId:
      return BulkRecover.fromJson(data);
    case ChangeBoardColor.tableId:
      return ChangeBoardColor.fromJson(data);
    default:
      return null;
  }
}
