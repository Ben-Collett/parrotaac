// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
