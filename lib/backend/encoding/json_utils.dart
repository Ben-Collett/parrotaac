mixin JsonEncodable {
  Map<String, dynamic> toJson();
}

Map<String, dynamic> toJsonMap(dynamic val) {
  return val.toJson();
}
