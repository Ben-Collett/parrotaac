// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_screen_popups.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ButtonConfig _$ButtonConfigFromJson(Map<String, dynamic> json) =>
    ButtonConfig(json['buttonId'] as String);

Map<String, dynamic> _$ButtonConfigToJson(ButtonConfig instance) =>
    <String, dynamic>{'buttonId': instance.buttonId};

ButtonCreate _$ButtonCreateFromJson(Map<String, dynamic> json) =>
    ButtonCreate((json['row'] as num).toInt(), (json['col'] as num).toInt());

Map<String, dynamic> _$ButtonCreateToJson(ButtonCreate instance) =>
    <String, dynamic>{'row': instance.row, 'col': instance.col};

OpenSymbolsPopup _$OpenSymbolsPopupFromJson(Map<String, dynamic> json) =>
    OpenSymbolsPopup(
        currentSearch: json['currentSearch'] as String?,
        selectedSymbol: json['selectedSymbol'] as Map<String, dynamic>?,
      )
      ..changedTones = (json['changedTones'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      );

Map<String, dynamic> _$OpenSymbolsPopupToJson(OpenSymbolsPopup instance) =>
    <String, dynamic>{
      'currentSearch': instance.currentSearch,
      'changedTones': instance.changedTones,
      'selectedSymbol': instance.selectedSymbol,
    };

SelectBoardScreen _$SelectBoardScreenFromJson(Map<String, dynamic> json) =>
    SelectBoardScreen(json['boardId'] as String);

Map<String, dynamic> _$SelectBoardScreenToJson(SelectBoardScreen instance) =>
    <String, dynamic>{'boardId': instance.boardId};

CreateBoard _$CreateBoardFromJson(Map<String, dynamic> json) => CreateBoard(
  rowCount: (json['rowCount'] as num?)?.toInt(),
  colCount: (json['colCount'] as num?)?.toInt(),
  name: json['name'] as String?,
);

Map<String, dynamic> _$CreateBoardToJson(CreateBoard instance) =>
    <String, dynamic>{
      'rowCount': instance.rowCount,
      'colCount': instance.colCount,
      'name': instance.name,
    };
