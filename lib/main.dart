import 'package:flutter/material.dart';
import 'package:parrotaac/backend/global_restoration_data.dart';
import 'package:parrotaac/backend/is_computer.dart';
import 'package:parrotaac/backend/server/server_utils.dart';
import 'package:parrotaac/ui/popups/lock_popups/admin_lock.dart';
import 'package:parrotaac/ui/settings/labels.dart';

import 'backend/quick_store.dart';
import 'backend/settings_utils.dart';
import 'restorative_navigator.dart';

void main() async {
  await initializeQuickStorePluggins();

  //must be called before RestorativeNavigator().initialize()
  await initializeGlobalRestorationData();

  await Future.wait([initializeSettings(), initializeServer()]);

  await RestorativeNavigator().initialize();

  if (isMobile && wasBackgrounded) {
    alreadyAuthenticated = wasAuthenticated;
  }

  accessTokenOverride =
      "temp::1759179283:1759179283:48aa3787db51cfd9ae43e948:a6b56bd1dbe6839ee332b12acba5747e5bc8b1fccffa005af1942c2c1bd0df7ba3094d0535780b1c8ec4e79cf5c079193828ab3dc03ed7d65a575f7d6919ac5e";
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
