import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/setting_screen.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';
import 'package:parrotaac/ui/widgets/sentence_box.dart';

import '../parrot_project.dart';
import 'parrot_button.dart';
import 'popups/button_config.dart';

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
  late final GridNotfier<ParrotButton> gridNotfier;
  late final SentenceBoxController sentenceController;
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

    sentenceController = SentenceBoxController(projectPath: widget.path);
    gridNotfier = GridNotfier(
      widgets: _getButtonsFromObf(currentObf),
      draggable: false,
    );
    _updateButtonSet();
    builderMode.addListener(
      () async {
        if (!builderMode.value) {
          updateButtonPositionsInObf();
          await finalizeTempImages();
          widget.obz.autoResolveAllIdCollisionsInFile();
          widget.obz.deleteTempFiles();
          await writeToDisk();
          _updateButtonSet();
        }
      },
    );
    final Widget emptySpotWidget = Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.lightBlue, width: 5)),
          child: Center(
            child: Icon(Icons.add, color: Colors.lightBlue),
          ),
        ));

    builderMode.addListener(
      () {
        gridNotfier.draggable = builderMode.value;
        if (builderMode.value == true) {
          gridNotfier.emptySpotWidget = emptySpotWidget;
          gridNotfier.onEmptyPressed = (row, col) {
            ParrotButtonNotifier notifier =
                ParrotButtonNotifier(projectPath: widget.path);
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  content: SizedBox(
                    child: ButtonConfigPopup(buttonController: notifier),
                  ),
                  actions: [
                    IconButton(
                      color: Colors.red,
                      icon: Icon(Icons.cancel),
                      onPressed: () {
                        notifier.dispose();
                        Navigator.of(context).pop();
                      },
                    ),
                    IconButton(
                      color: Colors.green,
                      icon: Icon(Icons.check),
                      onPressed: () {
                        Navigator.of(context).pop();
                        gridNotfier.setWidget(
                          row: row,
                          col: col,
                          widget: ParrotButton(controller: notifier),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          };
        } else {
          gridNotfier.emptySpotWidget = null;
          gridNotfier.onEmptyPressed = null;
        }
      },
    );

    super.initState();
  }

  Future<void> finalizeTempImages() async {
    Map<String, String> paths = await widget.obz.mapTempImageToPermantSpot();
    await widget.obz.moveFiles(paths);
    widget.obz.updateImagePaths(paths);
  }

  Future<void> writeToDisk() async {
    await widget.obz.write(path: widget.path);
  }

  void addButtonToSentenceBox(ButtonData buttonData) {
    sentenceController.add(buttonData);
  }

  void changeObf(Obf obf) {
    updateButtonPositionsInObf();
    currentObf = obf;
    gridNotfier.setWidgets(_getButtonsFromObf(obf));
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
                boxController: sentenceController,
                goToLinkedBoard: changeObf,
                projectPath: widget.path,
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
    updateButtonPositionsInObf();
    _updateButtonSet();
    buttonSet.forEach(_disposeButtonController);
    gridNotfier.dispose();
    builderMode.dispose();
    sentenceController.dispose();
    super.dispose();
  }

  void _disposeButtonController(ParrotButton button) =>
      button.controller.dispose();
  void _updateButtonSet() {
    final buttonSetFromGrid = _buttonSetFromGrid(gridNotfier.widgets);
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

  void updateButtonPositionsInObf() {
    List<List<ButtonData?>> order = [];
    for (List<ParrotButton?> row in gridNotfier.widgets) {
      order.add(row.map((b) => b?.buttonData).toList());
      for (ParrotButton? button in row) {
        if (button != null && !currentObf.buttons.contains(button.buttonData)) {
          currentObf.buttons.add(button.buttonData);
        }
      }
    }
    currentObf.grid.setOrder(order);
  }

  Widget _sentenceBoxButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    const color = Colors.grey;
    return Expanded(
      child: SizedBox.expand(
        child: Material(
          color: color,
          child: InkWell(onTap: onTap, child: Icon(icon)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clearButton = _sentenceBoxButton(
      icon: Icons.clear,
      onTap: sentenceController.clear,
    );
    final backSpaceButton = _sentenceBoxButton(
      icon: Icons.backspace,
      onTap: sentenceController.backSpace,
    );

    final speakButton = _sentenceBoxButton(
      icon: Icons.chat_outlined,
      onTap: sentenceController.speak,
    );

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
      body: Column(
        children: [
          Flexible(
            child: Row(
              children: [
                Flexible(
                  flex: 10,
                  child: SentenceBox(controller: sentenceController),
                ),
                speakButton,
                backSpaceButton,
                clearButton,
              ],
            ),
          ),
          Flexible(flex: 10, child: DraggableGrid(gridNotfier: gridNotfier)),
        ],
      ),
    );
  }
}
