import 'dart:io';
import 'package:flutter/material.dart';
import 'package:parrotaac/extensions/file_system_entity_extensions.dart';

extension FindFromName on List<FileSystemEntity> {
  FileSystemEntity? findFromName(String name) =>
      where((entity) => entity.baseNameWithoutExtension == name).firstOrNull;
}

extension Flatten<T> on Iterable<T> {
  Iterable<dynamic> flatten() sync* {
    for (var val in this) {
      if (val is Iterable) {
        yield* val.flatten();
      } else {
        yield val;
      }
    }
  }
}

extension Dispose on Iterable {
  void disposeNotifiers() {
    for (final val in this) {
      if (val is ChangeNotifier) {
        val.dispose();
      }
    }
  }
}
