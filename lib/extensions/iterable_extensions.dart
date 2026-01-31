import 'package:parrotaac/backend/encoding/json_utils.dart';

extension IterableExtensions<T> on Iterable<T> {
  List<Map<String, dynamic>> mapToJsonEncodedList() =>
      map((val) => toJsonMap(val)).toList();
}
