import 'dart:collection';
import 'dart:io' show Directory;

import 'package:flutter/widgets.dart';
import 'package:parrotaac/state/has_state.dart';

class ProjectSelectorState implements HasState {
  final selectModeNotifier = ValueNotifier(false);
  final searchTextController = TextEditingController();
  final selectedNotifier = _SelectedNotifier();

  bool get selectMode => selectModeNotifier.value;
  String get searchText => searchTextController.text;

  @override
  void dispose() {
    selectModeNotifier.dispose();
    searchTextController.dispose();
    selectedNotifier;
  }
}

class _SelectedNotifier extends ChangeNotifier {
  final Set<Directory> _values = {};

  ValueNotifier<bool> emptyNotifier = ValueNotifier(true);
  UnmodifiableSetView<Directory> get values => UnmodifiableSetView(_values);
  bool get isNotEmpty => _values.isNotEmpty;
  int get length => _values.length;

  ///if dir is null it won't be added
  ///if [dir] is in the set or is null then listeners won't be notfied
  void addIfNotNull(Directory? dir) {
    if (dir != null) {
      emptyNotifier.value = false;
      final bool setChanged = _values.add(dir);
      if (setChanged) {
        notifyListeners();
      }
    }
  }

  void clear() {
    if (_values.isNotEmpty) {
      _values.clear();
      notifyListeners();
    }
  }

  void remove(Directory? dir) {
    final startingLength = _values.length;
    _values.removeWhere((d) => d.path == dir?.path);
    final newLength = _values.length;
    if (startingLength != newLength) {
      notifyListeners();
    }
    if (newLength == 0) {
      emptyNotifier.value = true;
    }
  }

  @override
  void dispose() {
    emptyNotifier.dispose();
    super.dispose();
  }
}
