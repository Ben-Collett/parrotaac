import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backend/quick_store.dart';
import 'backend/settings_utils.dart';
import 'restorative_navigator.dart';

void main() async {
  await initializeQuickStorePluggins();

  await Future.wait(
    [
      initializeSettings(),
      RestorativeNavigator().initialize(),
    ],
  );
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parrot AAC',
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RestorativeNavigator().topScreen;
  }
}
