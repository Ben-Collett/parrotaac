import 'dart:collection';

extension SafeOperations<T> on Queue<T> {
  T removeLastOrDefaultTo(T defaultValue) {
    return safeRemoveLast() ?? defaultValue;
  }

  T? safeRemoveLast() {
    if (isNotEmpty) {
      return removeLast();
    }
    return null;
  }
}
