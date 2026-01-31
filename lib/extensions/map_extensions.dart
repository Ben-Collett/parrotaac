import 'package:parrotaac/safe_cast.dart';

extension MapDiff on Map<String, dynamic> {
  Map<String, dynamic> valuesThatAreDifferent(Map<String, dynamic> other) {
    final diff = <String, dynamic>{};

    // All keys from both maps
    final allKeys = {...keys, ...other.keys};

    for (final key in allKeys) {
      final value1 = this[key];
      final value2 = other[key];

      if (!containsKey(key)) {
        // Key is only in other (m2)
        diff[key] = value2;
      } else if (!other.containsKey(key)) {
        // Key is only in this (m1)
        diff[key] = null;
      } else if (value1 is Map<String, dynamic> &&
          value2 is Map<String, dynamic>) {
        // Recursively compare sub-maps
        final nestedDiff = value1.valuesThatAreDifferent(value2);
        if (nestedDiff.isNotEmpty) {
          diff[key] = nestedDiff;
        }
      } else if (value1 != value2) {
        // Different primitive or object values
        diff[key] = value2;
      }
    }

    return diff;
  }
}

extension MapExtensions<K, V> on Map<K, V> {
  Map<K, V2> mapValue<V2>(V2 Function(V) func) {
    return map<K, V2>((k, v) => MapEntry(k, func(v)));
  }

  Map<K, V> where(bool Function(K, V) condition) {
    Map<K, V> out = Map.from(this);
    out.removeWhere((k, v) => !condition(k, v));
    return out;
  }
}

extension SafeGet on Map {
  T safeGet<T>(dynamic key, {required T defaultValue}) =>
      safeCast<T>(this[key], defaultValue: defaultValue);
}

extension IncrementAndDecrement on Map<dynamic, int> {
  void incrementAll(Iterable<dynamic> keys, {int startingValue = 1}) {
    for (final key in keys) {
      increment(key);
    }
  }

  void decrementAll(Iterable<dynamic> keys, {int startingValue = 1}) {
    for (final key in keys) {
      decrement(key);
    }
  }

  void increment(dynamic key, {int startingValue = 1}) {
    if (this[key] == null) {
      this[key] = startingValue;
    } else {
      this[key] = this[key]! + 1;
    }
  }

  void decrement(dynamic key) {
    if (this[key] != null) {
      this[key] = this[key]! - 1;
    }
  }

  void removeKeyIfBelowThreshold({
    required dynamic key,
    required int threshold,
  }) {
    if (this[key] != null && this[key]! < threshold) {
      remove(key);
    }
  }
}
