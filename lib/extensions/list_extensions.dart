import 'dart:io';
import 'package:flutter/material.dart';
import 'package:parrotaac/backend/selection_data.dart';
import 'package:parrotaac/extensions/file_system_entity_extensions.dart';
import 'package:parrotaac/extensions/num_extensions.dart';

extension FindFromName on List<FileSystemEntity> {
  FileSystemEntity? findFromName(String name) =>
      where((entity) => entity.baseNameWithoutExtension == name).firstOrNull;
}

extension Grid<T> on List<List<T>> {
  T fromPair(RowColPair pair) {
    assert(
      pair.row.exclusiveIsInBetween(-1, length),
      "can't get from pair row out of bounds",
    );
    assert(
      pair.col.exclusiveIsInBetween(-1, this[pair.row].length),
      "can't get from pair column out of boudns",
    );

    return this[pair.row][pair.col];
  }

  void insertRow(int row, List<T> data) {
    assert(row <= length, "row greater then length on insert");
    insert(row, data);
  }

  void insertCol(int col, List<T> data) {
    for (int row = 0; row < data.length; row++) {
      this[row].insert(col, data[row]);
    }
  }

  void removeRow(int row) => removeAt(row);

  void removeCol(int col) {
    for (List row in this) {
      row.removeAt(col);
    }
  }
}

extension Sorted<T extends Comparable> on Iterable<T> {
  List<T> get descendingOrder {
    final out = toList();
    out.sort((a, b) => b.compareTo(a));
    return out;
  }

  List<T> get ascendingOrder {
    final out = toList();
    out.sort((a, b) => a.compareTo(b));
    return out;
  }
}

extension Flatten<T> on Iterable<T> {
  Iterable<K> flatten<K>() sync* {
    for (var val in this) {
      if (val is Iterable) {
        yield* val.flatten<K>();
      } else {
        assert(val is K, "flattening iterable with unexpected type");
        yield val as K;
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
