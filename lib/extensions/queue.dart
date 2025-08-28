import 'dart:collection';

extension RemoveLastOr<T> on Queue<T> {
  T removeLastOr(T defaultValue) {
    if (isEmpty) {
      return defaultValue;
    }
    return removeLast();
  }
}
