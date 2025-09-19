import 'dart:collection';

import 'package:parrotaac/extensions/linked_map_extensions.dart';

///uses LRU style caching
class MemoryCache<K, V> {
  final int maxEntries;
  final LinkedHashMap<K, V> _map = LinkedHashMap();

  MemoryCache({required this.maxEntries});
  V? operator [](K key) {
    if (_map.containsKey(key)) {
      _map.moveKeyToEnd(key);
    }
    return _map[key];
  }

  void operator []=(K key, V value) {
    _map[key] = value;
    if (_map.length > maxEntries) {
      _map.removeOldest();
    }
  }

  void invalidate(K key) {
    _map.remove(key);
  }

  void clear() {
    _map.clear();
  }

  bool containsKey(K key) {
    return _map.containsKey(key);
  }
}
