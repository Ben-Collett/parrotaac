// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swap_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SwapData _$SwapDataFromJson(Map<String, dynamic> json) => SwapData(
  SingleSwapData.fromJson(json['s1'] as Map<String, dynamic>),
  SingleSwapData.fromJson(json['s2'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SwapDataToJson(SwapData instance) => <String, dynamic>{
  's1': instance.s1,
  's2': instance.s2,
};

SingleSwapData _$SingleSwapDataFromJson(Map<String, dynamic> json) =>
    SingleSwapData(
      id: json['id'] as String,
      row: (json['row'] as num?)?.toInt(),
      col: (json['col'] as num?)?.toInt(),
      widget: json['widget'] == null
          ? null
          : RowColPair.fromJson(json['widget'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SingleSwapDataToJson(SingleSwapData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'row': instance.row,
      'col': instance.col,
      'widget': instance.widget,
    };
