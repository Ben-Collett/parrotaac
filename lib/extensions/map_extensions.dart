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
