import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:parrotaac/backend/project/project_utils.dart';
import 'package:parrotaac/backend/simple_logger.dart';

Future<void> initializeQuickStorePluggins() {
  return Hive.initFlutter();
}

mixin QuickStore {
  String get name;
  bool get isNotInitialized;
  Future<void> removeFromKey(dynamic key);
  Future<void> writeData(dynamic key, dynamic value, {bool log});
  dynamic operator [](dynamic key);
  bool isTrue(String key);
  bool isFalse(String key);
  Future<void> clear();
  Iterable<dynamic> get keys;
  bool containsKey(String key);
  Future<void> close();
  bool get isEmpty;
  bool get isNotEmpty;
  Map<dynamic, dynamic> toMap();
  T safeGet<T>(dynamic key, {required T defaultValue});
}

mixin ListenableQuickstore on QuickStore {
  void executeAndRegisterListener(VoidCallback callback) {
    registerListener(callback);
    callback.call();
  }

  void registerListener(Function() callback);
  void removeListener(Function() callback);
}

class QuickStoreHiveImp with QuickStore {
  @override
  final String name;
  final String? path;
  bool _initialized = false;
  late final Box _box;

  QuickStoreHiveImp(this.name, {this.path});

  @override
  bool get isNotInitialized => !_initialized;

  @override
  Iterable<dynamic> get keys => _box.keys;

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

  @override
  bool get isEmpty => _box.isEmpty;
  @override
  bool get isNotEmpty => _box.isNotEmpty;

  bool _isHiveSupportedPrimitiveType(dynamic value) =>
      (value is bool ||
      value is int ||
      value is String ||
      value is double ||
      value == null);

  ///[value] and [key] should be primiatives only, ints, strings, bools, or  list of primitives.
  @override
  Future<void> writeData(dynamic key, dynamic value, {bool log = false}) async {
    if (log) {
      SimpleLogger().logInfo(
        "$key $value | keyType: ${key.runtimeType}, valueType: ${value.runtimeType}",
      );
    }
    bool isSafeToCompare = _isHiveSupportedPrimitiveType(value);
    if (isSafeToCompare && this[key] == value) {
      return;
    }

    return _box.put(key, value);
  }

  @override
  T safeGet<T>(dynamic key, {required T defaultValue}) {
    return key.safeCast<T>() ?? defaultValue;
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

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}

class ListenableHiveQuickstore extends QuickStoreHiveImp
    with ListenableQuickstore {
  final List<VoidCallback> _callbacks = [];

  ListenableHiveQuickstore(super.name, {super.path});
  @override
  void registerListener(VoidCallback callback) {
    _callbacks.add(callback);
  }

  @override
  void removeListener(VoidCallback callback) {
    _callbacks.remove(callback);
  }

  void _callCallbacks() {
    void call(Function() callback) => callback.call();
    _callbacks.forEach(call);
  }

  @override
  Future<void> writeData(key, value, {bool log = false}) async {
    await super.writeData(key, value, log: log);
    _callCallbacks();
  }

  @override
  Future<void> clear() async {
    await super.clear();
    _callCallbacks();
  }

  @override
  Future<void> close() {
    _callbacks.clear();
    return super.close();
  }
}

class IndexedQuickstore {
  final String name;
  final String? path;
  Box get _box => Hive.box(name);
  IndexedQuickstore(this.name, {this.path});

  Future<void> initialize() async {
    final path =
        this.path ?? await applicationDocumentDir.then((dir) => dir.path);

    await Hive.openBox(name, path: path);
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
