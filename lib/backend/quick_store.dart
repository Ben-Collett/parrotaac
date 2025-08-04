import 'package:hive_flutter/hive_flutter.dart';

Future<void> initializeQuickStorePluggins() {
  return Hive.initFlutter();
}

class QuickStore {
  final String name;
  final String? path;
  bool _initialized = false;
  late final Box _box;

  QuickStore(
    this.name, {
    this.path,
  });

  bool get isNotInitialized => !_initialized;

  Future<void> initialize() async {
    _box = await Hive.openBox(name, path: path);
    _initialized = true;
  }

  Future<void> removeFromKey(dynamic key) => _box.delete(key);

  ///[value] and [key] should be primiatives only, ints, strings, bools, or  list of primitives.
  Future<void> writeData(dynamic key, dynamic value) async {
    return _box.put(key, value);
  }

  ///[key] should be a primiative or a list of primiatves only
  dynamic operator [](dynamic key) {
    return _box.get(key);
  }

  Map<dynamic, dynamic> toMap() => _box.toMap();

  Future<void> close() async {
    await _box.close();
  }
}

class IndexedQuickstore {
  final String name;
  Box get _box => Hive.box(name);
  IndexedQuickstore(this.name);

  Future<void> initialize() async {
    await Hive.openBox(name);
  }

  Future<void> pushAndWrite(dynamic data) {
    return _box.add(data);
  }

  dynamic peek() {
    return _box.getAt(_box.length - 1);
  }

  Future<void> removeTop() {
    return _box.deleteAt(_box.length - 1);
  }

  Iterable<dynamic> getAllData() {
    return _box.values;
  }
}
