import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/parrot_project.dart';
import 'package:parrotaac/ui/board_screen.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../test/boards/board_strings.dart';

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
    final Obf simpleObf = Obf.fromJsonString(simpleBoard);
    final Obf voclization = Obf.fromJsonString(vocilizationBoard);
    voclization.grid.getButtonData(0, 0)?.backgroundColor =
        ColorData(blue: 255);

    simpleObf.grid.getButtonData(0, 0)?.linkedBoard = voclization;
    voclization.grid.getButtonData(0, 0)?.linkedBoard = simpleObf;
    ParrotProject project = ParrotProject(
        name: "name", path: p.join(Directory.systemTemp.path, 'board test'));
    project.root = simpleObf;
    project.addBoard(voclization).addBoard(simpleObf);

    BoardScreen screen = BoardScreen(obz: project);
    //screen.parseObf(currentObf);
    return Scaffold(
      appBar: AppBar(
          title: const Text('board selector'),
          backgroundColor: Color(0xFFAFABDF)),
      body: screen,
    );
  }
}
