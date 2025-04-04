import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/setting_screen.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';

import '../parrot_project.dart';
import 'parrot_button.dart';

class BoardScreen extends StatefulWidget {
  final ParrotProject obz;
  //WARNING: storing the path will only work if I wait to rename a project somehow
  final String? path;
  const BoardScreen({super.key, required this.obz, this.path});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  static const String defaultBoardName = "default name";
  static const String defaultID = "board";
  late final GridNotfier<ParrotButton> notfier;
  Set<ParrotButton> buttonSet = {};
  final ValueNotifier<bool> builderMode = ValueNotifier(false);
  late Obf currentObf;

  @override
  void initState() {
    currentObf = widget.obz.root ??
        Obf(
          locale: "en",
          name: defaultBoardName,
          id: defaultID,
        );

    notfier =
        GridNotfier(widgets: _getButtonsFromObf(currentObf), draggable: false);
    _updateButtonSet();
    builderMode.addListener(
      () {
        if (!builderMode.value) {
          updateObf();
          writeToDisk();
          _updateButtonSet();
        }
      },
    );

    builderMode.addListener(() {
      notfier.draggable = builderMode.value;
    });

    super.initState();
  }

  void updatesParrotControllers() {}

  void writeToDisk() {
    widget.obz.write();
  }

  void changeObf(Obf obf) {
    updateObf();
    currentObf = obf;
    notfier.setWidgets(_getButtonsFromObf(obf));
  }

  List<List<ParrotButton?>> _getButtonsFromObf(Obf obf) {
    List<List<ParrotButton?>> buttons = [];
    final int rowCount = obf.grid.numberOfRows;
    final int colCount = obf.grid.numberOfColumns;
    for (int i = 0; i < rowCount; i++) {
      buttons.add([]);
      for (int j = 0; j < colCount; j++) {
        ButtonData? button = obf.grid.getButtonData(i, j);
        if (button != null) {
          buttons.last.add(
            ParrotButton(
              controller: ParrotButtonNotifier(
                data: button,
                goToLinkedBoard: changeObf,
                rootBoardPath: widget.path,
              ),
            ),
          );
        } else {
          buttons.last.add(null);
        }
      }
    }
    return buttons;
  }

  @override
  void dispose() {
    updateObf();
    _updateButtonSet();
    buttonSet.forEach(_disposeButtonController);
    notfier.dispose();
    builderMode.dispose();
    super.dispose();
  }

  void _disposeButtonController(ParrotButton button) =>
      button.controller.dispose();
  void _updateButtonSet() {
    final buttonSetFromGrid = _buttonSetFromGrid(notfier.widgets);
    buttonSet.difference(buttonSetFromGrid).forEach(_disposeButtonController);
    buttonSet = buttonSetFromGrid;
  }

  Set<ParrotButton> _buttonSetFromGrid(List<List<ParrotButton?>> buttons) {
    Set<ParrotButton> out = {};
    for (List<ParrotButton?> row in buttons) {
      for (ParrotButton? button in row) {
        if (button != null) {
          out.add(button);
        }
      }
    }
    return out;
  }

  void updateObf() {
    List<List<ButtonData?>> order = [];
    for (List<ParrotButton?> row in notfier.widgets) {
      order.add(row.map((b) => b?.buttonData).toList());
    }
    currentObf.grid.setOrder(order);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ParrotAAC'),
            Row(
              children: [
                IconButton(
                  icon: ValueListenableBuilder(
                      valueListenable: builderMode,
                      builder: (_, val, __) {
                        if (val) {
                          return const Icon(Icons.close);
                        }
                        return const Icon(Icons.handyman);
                      }),
                  onPressed: () => builderMode.value = !builderMode.value,
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettingsScreen()),
                  ),
                ),
              ],
            )
          ],
        ),
        backgroundColor: Color(0xFFAFABDF),
      ),
      body: DraggableGrid(gridNotfier: notfier),
    );
  }
}
