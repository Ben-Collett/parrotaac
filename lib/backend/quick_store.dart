import 'package:hive_flutter/hive_flutter.dart';
import 'package:parrotaac/backend/project/project_utils.dart';
import 'package:parrotaac/backend/simple_logger.dart';

Future<void> initializeQuickStorePluggins() {
  return Hive.initFlutter();
}

abstract class QuickStore {
  String get name;
  bool get isNotInitialized;
  Future<void> removeFromKey(dynamic key);
  Future<void> writeData(dynamic key, dynamic value);
  dynamic operator [](dynamic key);
  bool isTrue(String key);
  bool isFalse(String key);
  bool containsKey(String key);
  Future<void> close();
  Map<dynamic, dynamic> toMap();
}

class QuickStoreHiveImp extends QuickStore {
  @override
  final String name;
  final String? path;
  bool _initialized = false;
  late final Box _box;

  QuickStoreHiveImp(this.name, {this.path});

  @override
  bool get isNotInitialized => !_initialized;

  Future<void> initialize() async {
    final path = this.path ?? (await applicationDocumentDir).path;
    _box = await Hive.openBox(name, path: path);
    _initialized = true;
  }

  @override
  bool containsKey(String key) => _box.containsKey(key);

  @override
  Future<void> removeFromKey(dynamic key) {
    return _box.delete(key);
  }

  bool _isHiveSupportedPrimitiveType(dynamic value) =>
      (value is bool ||
      value is int ||
      value is String ||
      value is double ||
      value == null);

  ///[value] and [key] should be primiatives only, ints, strings, bools, or  list of primitives.
  @override
  Future<void> writeData(dynamic key, dynamic value) async {
    bool isSafeToCompare = _isHiveSupportedPrimitiveType(value);
    if (isSafeToCompare && this[key] == value) {
      return;
    }

    return _box.put(key, value);
  }

  ///[key] should be a primiative or a list of primiatves only
  @override
  dynamic operator [](dynamic key) {
    return _box.get(key);
  }

  @override
  Map<dynamic, dynamic> toMap() => _box.toMap();

  @override
  Future<void> close() async {
    await _box.close();
  }

  @override
  bool isFalse(String key) => this[key] == false;

  @override
  bool isTrue(String key) => this[key] == true;
}

class IndexedQuickstore {
  final String name;
  Box get _box => Hive.box(name);
  IndexedQuickstore(this.name);

  Future<void> initialize() async {
    await Hive.openBox(
      name,
      path: await applicationDocumentDir.then((dir) => dir.path),
    );
  }

  Future<void> pushAndWrite(dynamic data) {
    return _box.add(data);
  }

  Future<void> clear() {
    return _box.clear();
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
