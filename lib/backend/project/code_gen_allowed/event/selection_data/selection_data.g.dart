// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selection_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SelectionData _$SelectionDataFromJson(Map<String, dynamic> json) =>
    SelectionData(
      selectedRows: (json['selectedRows'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toSet(),
      selectedCols: (json['selectedCols'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toSet(),
      selectedWidgets: SelectionData._rowColSetFromJson(
        json['selectedWidgets'],
      ),
    );

Map<String, dynamic> _$SelectionDataToJson(
  SelectionData instance,
) => <String, dynamic>{
  'selectedRows': instance.selectedRows.toList(),
  'selectedCols': instance.selectedCols.toList(),
  'selectedWidgets': SelectionData._rowColSetToJson(instance.selectedWidgets),
};

RowColPair _$RowColPairFromJson(Map<String, dynamic> json) =>
    RowColPair((json['row'] as num).toInt(), (json['col'] as num).toInt());

Map<String, dynamic> _$RowColPairToJson(RowColPair instance) =>
    <String, dynamic>{'row': instance.row, 'col': instance.col};
