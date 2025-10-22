import 'package:flutter/material.dart';
import 'package:parrotaac/backend/global_restoration_data.dart';
import 'package:parrotaac/backend/is_computer.dart';
import 'package:parrotaac/backend/server/login_utils.dart';
import 'package:parrotaac/backend/server/server_utils.dart';
import 'package:parrotaac/state/project_dir_state.dart';
import 'package:parrotaac/ui/popups/lock_popups/admin_lock.dart';
import 'package:parrotaac/ui/settings/labels.dart';

import 'backend/quick_store.dart';
import 'backend/settings_utils.dart';
import 'restorative_navigator.dart';

void main() async {
  Future refreshProject = defaultProjectDirListener.refresh();
  await initializeQuickStorePluggins();

  //must be called before RestorativeNavigator().initialize()
  await initializeGlobalRestorationData();

  await Future.wait([initializeSettings(), initializeServer(), refreshProject]);

  await RestorativeNavigator().initialize();

  if (isMobile && wasBackgrounded) {
    alreadyAuthenticated = wasAuthenticated;
  }

  accessTokenOverride =
      "temp::1760412868:1760412868:9929be4d18864b86d68be6df:e8bb20b3102e40efe84474b8914609ef3187539c9ab01441cd4b8b7f93b55aeaa45e781e25c7875f2b446fcd9f3a79048dec830967c7d1edb98576ce45e0fcbf";
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Parrot AAC', home: MainScreen());
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (alreadyAuthenticated ||
          LockType.fromString(
                getSetting<String>(adminLockLabel) ?? LockType.none.label,
              ) ==
              LockType.none) {
        RestorativeNavigator().fullyInitialized = true;
        return;
      }
      RestorativeNavigator().goToTopScreen(context);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RestorativeNavigator().getLastNonAdminScreen();
  }
}
