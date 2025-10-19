import 'backend/project/custom_manifest_keys.dart';

String defaultRootBoardFromSize(int rowCount, int colCount) {
  assert(rowCount >= 0, "can't have negative row count");
  assert(colCount >= 0, "can't have negative col count");
  StringBuffer order = StringBuffer();
  order.write("[");
  for (var i = 0; i < rowCount; i++) {
    order.write('[');
    for (var j = 0; j < colCount; j++) {
      order.write('null');
      if (j + 1 != colCount) {
        order.write(',');
      }
    }
    order.write(']');

    if (i + 1 != rowCount) {
      order.write(",");
    }
  }

  order.write("]");

  return '{"id":"root","format":"open-board-0.1","locale":"en","name":"root","buttons":[],"grid":{"rows":$rowCount,"columns":$colCount,"order":$order},"images":[],"sounds":[]}';
}

String defaultManifest({
  String? name,
  String? imagePath,
  DateTime? lastAccessed,
}) {
  StringBuffer out = StringBuffer(
    '{"root":"boards/root.obf","format":"open-board-0.1","paths":{"boards":{"root":"boards/root.obf"}}',
  );
  _addNonNullField(out, nameKey, name);
  _addNonNullField(out, imagePathKey, imagePath);
  _addNonNullField(out, lastAccessedKey, lastAccessed);

  return "$out}";
}

void _addNonNullField(StringBuffer buffer, String key, Object? value) {
  if (value != null) {
    buffer.write(',"$key":"$value"');
  }
}
