import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';

import '../parrot_project.dart';
import 'parrot_button.dart';

class BoardScreen extends StatefulWidget {
  final ParrotProject obz;
  const BoardScreen({super.key, required this.obz});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  static const String defaultBoardName = "default name";
  static const String defaultID = "board";
  late final GridNotfier<ParrotButton> notfier;
  late Obf currentObf;

  @override
  void initState() {
    currentObf = widget.obz.root ??
        Obf(
          locale: "en",
          name: defaultBoardName,
          id: defaultID,
        );

    notfier = GridNotfier(widgets: _getButtonsFromObf(currentObf));
    super.initState();
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
    notfier.dispose();
    super.dispose();
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
    return DraggableGrid(gridNotfier: notfier);
  }
}
