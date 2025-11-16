import 'package:flutter/material.dart';
import 'package:parrotaac/backend/quick_store.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/ui/popups/lock_popups/admin_lock.dart';
import 'package:parrotaac/ui/settings/defaults.dart';
import 'package:parrotaac/ui/settings/labels.dart';

Map<String, _ControllerReferenceTracker> _refMap = {};

class _ControllerReferenceTracker extends ChangeNotifier {
  int refCount = 0;
  void update() {
    notifyListeners();
  }
}

QuickStoreHiveImp _settingsQuickstore = QuickStoreHiveImp('settings');
Future<void> initializeSettings() {
  return _settingsQuickstore.initialize();
}

Future<void> setSetting(String key, dynamic value) {
  _refMap[key]?.update();
  return _settingsQuickstore.writeData(key, value);
}

String getAdminLockLabel() => getSettingOr(adminLockLabel, LockType.none.label);
Color getAppbarColor() =>
    Color(getSettingOr<int>(appBarColorLabel, defaultAppbarColor));
T? getSetting<T>(String key) {
  //TODO: check if in quikstore and log if not
  dynamic out = _settingsQuickstore[key];
  if (out is T?) {
    return out;
  } else {
    SimpleLogger().logError("setting doesn't match expected type for $key");
    return null;
  }
}

T getSettingOr<T>(String key, T value) => getSetting(key) ?? value;

ChangeNotifier addNotifier(String key) {
  if (!_refMap.containsKey(key)) {
    _refMap[key] = _ControllerReferenceTracker();
  }
  _refMap[key]!.refCount++;
  return _refMap[key]!;
}

void removeNotifier(String key) {
  if (!_refMap.containsKey(key)) {
    SimpleLogger().logError(
      "attempted to remove non-existent key $key from $_refMap",
    );
    return;
  }
  _refMap[key]!.refCount--;
  if (_refMap[key]!.refCount <= 0) {
    _refMap[key]!.dispose();
    _refMap.remove(key);
  }
}
