import 'package:parrotaac/backend/quick_store.dart';

import 'package:flutter/widgets.dart';

final _globalRestorationData = QuickStore("global_rest");

Future<void> initializeGlobalRestorationData() async {
  await _globalRestorationData.initialize();
  await _AppLifecycleHandler().init();
}

bool get wasBackgrounded => _globalRestorationData["was_backgrounded"];
bool get wasAuthenticated =>
    _globalRestorationData["was_authenticated"] ?? false;
set wasAuthenticated(bool value) =>
    _globalRestorationData.writeData("was_authenticated", value);

class _AppLifecycleHandler with WidgetsBindingObserver {
  _AppLifecycleHandler();

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      await _globalRestorationData.writeData("was_backgrounded", true);
    } else if (state == AppLifecycleState.resumed) {
      await _globalRestorationData.writeData("was_backgrounded", false);
    }
  }
}
