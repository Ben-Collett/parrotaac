import 'dart:collection';

extension Caching<K, V> on LinkedHashMap<K, V> {
  ///does not add the key if it didn't already exist merely moves it to the end if it did
  void moveKeyToEnd(K key) {
    if (!containsKey(key)) {
      return;
    }
    final value = remove(key);
    this[key] = value as V;
  }

  void removeOldest() {
    remove(keys.first);
  }
}
