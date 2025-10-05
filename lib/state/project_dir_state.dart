import 'dart:collection';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project/project_interface.dart';
import 'package:parrotaac/backend/project/project_utils.dart';
import 'package:parrotaac/backend/simple_logger.dart';

typedef DeleteListener = void Function(DisplayData);
typedef AddListener = void Function(DisplayData);
final ProjectDirsListener defaultProjectDirListener = ProjectDirsListener();

class ProjectDirsListener extends ChangeNotifier {
  final List<DisplayData> _data = [];

  UnmodifiableListView<DisplayData> get data => UnmodifiableListView(_data);
  final Set<VoidCallback> _onRefreshListeners = {};
  final Set<AddListener> _onAddListeners = {};
  final Set<DeleteListener> _onDeleteListeners = {};

  void add(Directory dir) {
    final data = ParrotProjectDisplayData.fromDir(dir);
    _data.insert(0, data);
    for (final action in _onAddListeners) {
      action(data);
    }
    notifyListeners();
  }

  void addOnRefreshListener(VoidCallback onRefresh) =>
      _onRefreshListeners.add(onRefresh);

  void removeOnRefreshListener(VoidCallback onRefresh) =>
      _onRefreshListeners.remove(onRefresh);
  void addOnAddListener(AddListener onAdd) => _onAddListeners.add(onAdd);

  void removeOnAddListener(AddListener onAdd) => _onAddListeners.remove(onAdd);
  void addOnDeleteListener(DeleteListener onDelete) =>
      _onDeleteListeners.add(onDelete);

  void removeOnDeleteListener(DeleteListener onDelete) =>
      _onDeleteListeners.remove(onDelete);
  void delete(DisplayData data) {
    bool removedData = _data.remove(data);
    if (removedData) {
      for (final action in _onDeleteListeners) {
        action(data);
      }
    } else {
      SimpleLogger().logError("removed display data that doesn't exist: $data");
    }
  }

  Future<void> refresh() async {
    _data.clear();
    Iterable<Directory> dirs = await projectDirs();
    List<DisplayData> displayData = dirs
        .map(ParrotProjectDisplayData.fromDir)
        .toList();

    displayData.sort(_byLastAccessedThenByAlphabeticalOrder);
    _data.addAll(displayData);
    for (var action in _onRefreshListeners) {
      action();
    }

    notifyListeners();
  }

  int _byLastAccessedThenByAlphabeticalOrder(DisplayData d1, DisplayData d2) {
    DateTime? t1 = d1.lastAccessed;
    DateTime? t2 = d2.lastAccessed;
    if (d1.lastAccessed == null && d2.lastAccessed == null) {
      return d1.name.compareTo(d2.name);
    } else if (t1 == null) {
      return 1;
    } else if (t2 == null) {
      return -1;
    } else if (t1.isBefore(t2)) {
      return 1;
    } else if (t1.isAfter(t2)) {
      return -1;
    }
    return d1.name.compareTo(d2.name);
  }

  void clearListeners() {
    _onDeleteListeners.clear();
    _onAddListeners.clear();
    _onRefreshListeners.clear();
  }

  @override
  void dispose() {
    clearListeners();
    super.dispose();
  }
}
