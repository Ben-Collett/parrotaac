import 'package:parrotaac/backend/quick_store.dart';

import 'package:flutter/widgets.dart';

final globalRestorationQuickstore = QuickStoreHiveImp("global_rest");

Future<void> initializeGlobalRestorationData() async {
  await globalRestorationQuickstore.initialize();
  await _AppLifecycleHandler().init();
}

bool get wasBackgrounded => globalRestorationQuickstore["was_backgrounded"];
bool get wasAuthenticated =>
    globalRestorationQuickstore["was_authenticated"] ?? false;
set wasAuthenticated(bool value) =>
    globalRestorationQuickstore.writeData("was_authenticated", value);

class _AppLifecycleHandler with WidgetsBindingObserver {
  _AppLifecycleHandler();

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      await globalRestorationQuickstore.writeData("was_backgrounded", true);
    } else if (state == AppLifecycleState.resumed) {
      await globalRestorationQuickstore.writeData("was_backgrounded", false);
    }
  }
}

String? get userToken => globalRestorationQuickstore["user_token"];
set userToken(String? token) =>
    globalRestorationQuickstore.writeData("user_token", token);
