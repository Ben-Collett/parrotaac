extension SetExtensions<T> on Set<T> {
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
