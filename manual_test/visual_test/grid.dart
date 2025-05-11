import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:openboard_wrapper/image_data.dart';
import 'package:parrotaac/ui/parrot_button.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';

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
    ColorData red = ColorData(red: 255);
    ColorData blue = ColorData(blue: 255);
    ColorData green = ColorData(green: 255);

    ButtonData bd = ButtonData(label: "hi", backgroundColor: red);
    ButtonData bd2 = ButtonData(label: "hi", backgroundColor: blue);
    ButtonData bd3 = ButtonData(
        label: "hi",
        backgroundColor: green,
        image: ImageData(url: "https://picsum.photos/400/300"));

    List<List<Object?>> data = [
      [ParrotButtonNotifier(data: bd), ParrotButtonNotifier(data: bd2)],
      [null, ParrotButtonNotifier(data: bd3)],
    ];
    GridNotfier<ParrotButton> grid = GridNotfier<ParrotButton>(
        data: data,
        toWidget: (d) {
          if (d is ParrotButtonNotifier) {
            return ParrotButton(controller: d);
          }
          return null;
        },
        draggable: true);
    return Scaffold(
        appBar: AppBar(
            title: Row(
              children: [
                const Text('grid test'),
                TextButton(
                  child: Text('add row and column'),
                  onPressed: () {
                    grid.addRow();
                    grid.addColumn();
                  },
                ),
                TextButton(
                  child: Text('toggle draggable'),
                  onPressed: () {
                    grid.draggable = !grid.draggable;
                  },
                ),
                TextButton(
                  child: Text('set top left'),
                  onPressed: () {
                    Random random = Random();
                    ColorData randomColor = ColorData(
                        red: random.nextInt(256),
                        blue: random.nextInt(256),
                        green: random.nextInt(256));
                    ButtonData buttonData = ButtonData(
                        backgroundColor: randomColor, label: "hello");
                    Object? obj = grid.data[0][0];
                    if (obj is ParrotButtonNotifier) {
                      obj.data = buttonData;
                    }
                  },
                ),
              ],
            ),
            backgroundColor: Color(0xFFAFABDF)),
        body: DraggableGrid(gridNotfier: grid));
  }
}
