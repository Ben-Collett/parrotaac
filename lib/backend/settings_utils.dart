import 'package:flutter/foundation.dart';
import 'package:parrotaac/backend/quick_store.dart';
import 'package:parrotaac/backend/simple_logger.dart';

Map<String, _ControllerReferenceTracker> _refMap = {};

class _ControllerReferenceTracker extends ChangeNotifier {
  int refCount = 0;
  void update() {
    notifyListeners();
  }
}

QuickStore _settingsQuickstore = QuickStore('settings');
Future<void> initializeSettings() {
  return _settingsQuickstore.initialize();
}

Future<void> setSetting(String key, dynamic value) {
  _refMap[key]?.update();
  return _settingsQuickstore.writeData(key, value);
}

T? getSetting<T>(String key) {
  dynamic out = _settingsQuickstore[key];
  if (out is T?) {
    return out;
  } else {
    SimpleLogger().logError("setting doesn't match expected type for $key");
    return null;
  }
}

ChangeNotifier addNotifier(String key) {
  if (!_refMap.containsKey(key)) {
    _refMap[key] = _ControllerReferenceTracker();
  }
  _refMap[key]!.refCount++;
  return _refMap[key]!;
}

void removeNotifier(String key) {
  if (!_refMap.containsKey(key)) {
    SimpleLogger()
        .logError("attempted to remove non-existent key $key from $_refMap");
    return;
  }
  _refMap[key]!.refCount--;
  if (_refMap[key]!.refCount <= 0) {
    _refMap[key]!.dispose();
    _refMap.remove(key);
  }
}
