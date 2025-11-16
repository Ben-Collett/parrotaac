import 'package:parrotaac/backend/encoding/json_utils.dart';

extension IterableExtensions<T> on Iterable<T> {
  List<Map<String, dynamic>> mapToJsonEncodedList() =>
      map((val) => toJsonMap(val)).toList();

  bool atLeastOneNull() {
    return any((v) => v == null);
  }

  bool atLeastOneEquals(T val) {
    return any((v) => v == val);
  }

  bool atLeastOneDoesntEquals(T val) {
    return !atLeastOneEquals(val);
  }

  bool atMostOneEquals(T val) {
    return where((v) => v == val).length <= 1;
  }

  int get nullCount {
    return length - nonNulls.length;
  }
}
