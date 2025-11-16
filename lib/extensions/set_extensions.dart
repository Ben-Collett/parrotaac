extension SetExtensions<T> on Set<T> {
  ///if condition is true then val will be in the set else it will be removed from the set
  void setIf(bool condition, T val) {
    if (condition) {
      add(val);
    } else {
      remove(val);
    }
  }

  void addIfNotNull(T? val) {
    if (val != null) {
      add(val);
    }
  }

  void inPlaceMap(T Function(T val) toElement) {
    final out = map(toElement);
    clear();
    addAll(out);
  }
}
