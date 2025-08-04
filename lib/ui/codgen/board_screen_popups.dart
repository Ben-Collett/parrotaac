import 'package:json_annotation/json_annotation.dart';
import 'package:parrotaac/backend/map_utils.dart';
import 'package:parrotaac/backend/simple_logger.dart';

part 'board_screen_popups.g.dart';

abstract class BoardScreenPopup {
  String get type;

  const BoardScreenPopup();

  static BoardScreenPopup? decode(Map<String, dynamic> json) {
    Map<String, dynamic>? content = castMapToJsonMap(json['content']);
    if (content == null) {
      SimpleLogger().logWarning("can't decode popup as $json content is null");
      return null;
    }
    switch (json['type']) {
      case 'button_config':
        return ButtonConfig.fromJson(content);
      case 'button_create':
        return ButtonCreate.fromJson(content);
      case 'select_background_color':
        return SelectBackgroundColor.fromJson(content);
      case 'select_border_color':
        return SelectBorderColor.fromJson(content);
      case 'create_board':
        return CreateBoard.fromJson(content);
      case "select_board":
        return SelectBoardScreen.fromJson(content);
      default:
        SimpleLogger().logWarning("can't decode $json as popup");
        return null;
    }
  }

  Map<String, dynamic> encode() => {
        'type': type,
        'content': toJson(),
      };

  Map<String, dynamic> toJson();
}

@JsonSerializable()
class ButtonConfig extends BoardScreenPopup {
  @override
  final String type = 'button_config';

  final String buttonId;

  ButtonConfig(this.buttonId);

  factory ButtonConfig.fromJson(Map<String, dynamic> json) =>
      _$ButtonConfigFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ButtonConfigToJson(this);
}

@JsonSerializable()
class ButtonCreate extends BoardScreenPopup {
  @override
  final String type = 'button_create';

  final int row;
  final int col;

  ButtonCreate(this.row, this.col);

  factory ButtonCreate.fromJson(Map<String, dynamic> json) =>
      _$ButtonCreateFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ButtonCreateToJson(this);
}

abstract class SelectColor extends BoardScreenPopup {
  @override
  String get type => 'select_color';
  @override
  Map<String, dynamic> toJson() => {};
}

@JsonSerializable()
class SelectBoardScreen extends BoardScreenPopup {
  String boardId;
  SelectBoardScreen(this.boardId);

  factory SelectBoardScreen.fromJson(Map<String, dynamic> json) =>
      _$SelectBoardScreenFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$SelectBoardScreenToJson(this);
  @override
  String get type => "select_board";
}

@JsonSerializable()
class CreateBoard extends BoardScreenPopup {
  int? rowCount;
  int? colCount;
  String? name;
  CreateBoard({this.rowCount, this.colCount, this.name});
  factory CreateBoard.fromJson(Map<String, dynamic> json) =>
      _$CreateBoardFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$CreateBoardToJson(this);

  @override
  String get type => "create_board";
}

class SelectBackgroundColor extends SelectColor {
  @override
  final String type = 'select_background_color';
  SelectBackgroundColor();
  factory SelectBackgroundColor.fromJson(Map<String, dynamic> json) =>
      SelectBackgroundColor();
}

class SelectBorderColor extends SelectColor {
  @override
  final String type = 'select_border_color';
  SelectBorderColor();
  factory SelectBorderColor.fromJson(Map<String, dynamic> json) =>
      SelectBorderColor();
}
