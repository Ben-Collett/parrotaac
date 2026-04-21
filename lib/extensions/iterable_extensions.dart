import 'package:parrotaac/utils/encoding/json_encodable.dart';

extension IterableExtensions<T> on Iterable<T> {
  List<Map<String, dynamic>> mapToJsonEncodedList() =>
      map((val) => toJsonMap(val)).toList();
}
