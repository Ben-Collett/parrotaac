import 'backend/project/custom_manifest_keys.dart';

const defaultRootObf =
    '{"id":"root","format":"open-board-0.1","locale":"en","name":"root","buttons":[],"grid":{"rows":0,"columns":0,"order":[]},"images":[],"sounds":[]}';

String defaultManifest({
  String? name,
  String? imagePath,
  DateTime? lastAccessed,
}) {
  StringBuffer out = StringBuffer(
      '{"root":"boards/root.obf","format":"open-board-0.1","paths":{"boards":{"root":"boards/root.obf"}}');
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
