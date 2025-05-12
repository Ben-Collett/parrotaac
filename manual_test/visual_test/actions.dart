import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/grid_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/ui/board_screen.dart';

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
    var project = ParrotProject(name: "tmp", path: Directory.systemTemp.path);
    final String clear = PredefinedSpecialtyAction.clear.asString;
    final String speak = PredefinedSpecialtyAction.speak.asString;
    final String backspace = PredefinedSpecialtyAction.backSpace.asString;
    final String home = PredefinedSpecialtyAction.home.asString;

    ButtonData hello = ButtonData(
      label: "hello",
      id: "b5",
    );
    Obf ob1 = Obf(locale: 'en', id: 'o1', name: 'hi');
    Obf ob2 = Obf(locale: 'en', id: 'o2', name: 'hi');

    ButtonData link = ButtonData(label: "link", id: "link", linkedBoard: ob2);
    ButtonData clearButton =
        ButtonData(label: "clear", id: "b1", action: clear);
    ButtonData speakButton =
        ButtonData(label: "speak", id: "b2", action: speak);
    ButtonData backspaceButton =
        ButtonData(label: "backspace", id: "b3", action: backspace);
    ButtonData homeSpeak =
        ButtonData(label: "home", id: "b4", actions: [home, speak]);

    GridData g1 = GridData(order: [
      [clearButton, hello],
      [speakButton, link]
    ]);
    GridData g2 = GridData(order: [
      [backspaceButton, homeSpeak],
      [null, null],
    ]);

    ob1.grid = g1;
    ob2.grid = g2;
    project.addBoard(ob1);
    project.addBoard(ob2);

    project.root = ob1;
    return Scaffold(
      appBar: AppBar(
          title: const Text('board selector'),
          backgroundColor: Color(0xFFAFABDF)),
      body: BoardScreen(project: project),
    );
  }
}
