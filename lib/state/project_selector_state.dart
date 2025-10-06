import 'dart:collection';
import 'dart:io' show Directory;

import 'package:flutter/widgets.dart';
import 'package:parrotaac/backend/project/project_interface.dart';
import 'package:parrotaac/state/has_state.dart';

import 'project_dir_state.dart';

class ProjectSelectorState implements HasState {
  final selectModeNotifier = ValueNotifier(false);
  final searchTextController = TextEditingController();
  final selectedNotifier = _SelectedNotifier();
  final stringTextController = ValueNotifier<String>("");

  bool get selectMode => selectModeNotifier.value;
  String get searchText => searchTextController.text;

  ProjectSelectorState() {
    searchTextController.addListener(() {
      stringTextController.value = searchTextController.text;
    });
  }
  @override
  void dispose() {
    stringTextController.dispose();
    selectModeNotifier.dispose();
    searchTextController.dispose();
    selectedNotifier;
  }
}

class _SelectedNotifier extends ChangeNotifier {
  final Set<DisplayData> _values = {};

  _SelectedNotifier() {
    defaultProjectDirListener.addOnDeleteListener(remove);
  }

  ValueNotifier<bool> emptyNotifier = ValueNotifier(true);

  UnmodifiableSetView<DisplayData> get data => UnmodifiableSetView(_values);
  Iterable<Directory> get dataAsDirs => _values
      .where((data) => data.path != null)
      .map((data) => Directory(data.path!));
  bool get isNotEmpty => _values.isNotEmpty;
  int get length => _values.length;

  ///if dir is null it won't be added
  ///if [dir] is in the set or is null then listeners won't be notfied
  void addIfNotNull(DisplayData? dir) {
    if (dir != null) {
      emptyNotifier.value = false;
      final bool setChanged = _values.add(dir);
      if (setChanged) {
        notifyListeners();
      }
    }
  }

  void clear() {
    emptyNotifier.value = true;
    if (_values.isNotEmpty) {
      _values.clear();
      notifyListeners();
    }
  }

  void remove(DisplayData data) {
    final removedData = _values.remove(data);
    if (removedData) {
      notifyListeners();
      emptyNotifier.value = _values.isEmpty;
    }
  }

  @override
  void dispose() {
    defaultProjectDirListener.removeOnDeleteListener(remove);
    emptyNotifier.dispose();
    super.dispose();
  }
}
