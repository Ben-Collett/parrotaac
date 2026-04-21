import 'dart:collection';

import 'package:flutter/widgets.dart';

///a stack implemented through a double ended queue
class QueueStack<T> {
  final _queue = Queue<T>();
  VoidCallback? onChange;
  QueueStack({this.onChange});

  void push(T value) {
    _queue.add(value);
    onChange?.call();
  }

  void update(Iterable<T> values) {
    if (isEmpty && values.isEmpty) return;
    _queue.clear();
    _queue.addAll(values);
    onChange?.call();
  }

  T pop() {
    T out = _queue.removeLast();
    onChange?.call();
    return out;
  }

  void clear() {
    if (_queue.isNotEmpty) {
      _queue.clear();
      onChange?.call();
    }
  }

  List<T> toList() => _queue.toList();

  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;
}
