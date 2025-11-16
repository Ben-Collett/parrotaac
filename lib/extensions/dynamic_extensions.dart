extension DynamicExtensions on dynamic {
  bool equalsAny(List<dynamic> vals) {
    return vals.any((val) => val == this);
  }
}
