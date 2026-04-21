Map<String, dynamic>? castMapToJsonMap(dynamic map) {
  if (map is! Map) {
    return null;
  }

  try {
    return map.cast<String, dynamic>();
  } catch (e) {
    return null;
  }
}

Map<String, dynamic>? deepCastMapToJsonMap(dynamic map) {
  if (map is! Map) return null;
  Map<String, dynamic> out = {};
  for (MapEntry entry in map.entries) {
    if (entry.value is! Map) {
      out[entry.key] = entry.value;
    } else {
      out[entry.key] = deepCastMapToJsonMap(entry.value);
    }
  }
  return out;
}
