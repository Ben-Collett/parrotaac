import 'package:flutter/material.dart';

class MapOfNotifiers<K> {
  final Map<K, ChangeNotifier> _map = {};
  ChangeNotifier? operator [](K key) => _map[key];
  void operator []=(K key, ChangeNotifier value) => _map[key] = value;

  void clearAndDispose() {
    void dispose(ChangeNotifier notifier) => notifier.dispose();
    _map.values.forEach(dispose);
    _map.clear();
  }
}
