import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parrotaac/default_board_strings.dart';
import 'package:parrotaac/ui/parrot_button.dart';
import 'package:parrotaac/ui/popups/button_config.dart';
import 'package:path/path.dart';

void main() {
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Parrot AAC',
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Directory temp = Directory.systemTemp;
    String projectPath = join(temp.path, "create_popup_testDir");
    Directory projectDir = Directory(projectPath);

    if (projectDir.existsSync()) projectDir.deleteSync(recursive: true);
    createProjectSync(projectDir);

    final controller = ParrotButtonNotifier(projectPath: projectPath);

    return Scaffold(
      appBar: AppBar(
          title: const Text('buttonCreate'),
          backgroundColor: Color(0xFFAFABDF)),
      body: ButtonConfigPopup(buttonController: controller),
    );
  }
}

void createProjectSync(Directory projectDir) {
  String obfPath = join(projectDir.path, "boards/", "root.obf");
  String manifestPath = join(projectDir.path, "manifest.json");
  String obf = defaultRootObf;
  String manifest = defaultManifest();

  File manifestFile = File(manifestPath);
  manifestFile.createSync(recursive: true);
  manifestFile.writeAsStringSync(manifest);

  File obfFile = File(obfPath);
  obfFile.createSync(recursive: true);
  obfFile.writeAsStringSync(obf);
}
