import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/setting_screen.dart';
import 'package:parrotaac/ui/popups/lock_popups/admin_lock.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';
import 'package:parrotaac/ui/widgets/sentence_box.dart';

import 'board_modes.dart';
import 'parrot_button.dart';
import 'popups/button_config.dart';

class BoardScreen extends StatefulWidget {
  final ParrotProject project;
  //WARNING: storing the path will only work if I wait to rename a project somehow
  final String? path;
  const BoardScreen({super.key, required this.project, this.path});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  static const String defaultBoardName = "default name";
  static const String defaultID = "board";
  late final GridNotfier<ParrotButton> gridNotfier;
  late final SentenceBoxController sentenceController;
  Set<ParrotButtonNotifier> buttonSet = {};
  final ValueNotifier<BoardMode> boardMode =
      ValueNotifier(BoardMode.normalMode);
  late Obf currentObf;

  @override
  void initState() {
    currentObf = widget.project.root ??
        Obf(
          locale: "en",
          name: defaultBoardName,
          id: defaultID,
        );

    sentenceController = SentenceBoxController(projectPath: widget.path);

    gridNotfier = GridNotfier(
      data: _getButtonsFromObf(currentObf),
      toWidget: (obj) {
        if (obj is ParrotButtonNotifier) {
          return ParrotButton(controller: obj);
        }
        return null;
      },
      draggable: false,
      onMove: _updateButtonNotfierOnDelete,
    );
    _updateButtonSet();
    boardMode.addListener(
      () async {
        if (boardMode.value == BoardMode.normalMode) {
          updateButtonPositionsInObf();
          await finalizeTempImages();
          widget.project.autoResolveAllIdCollisionsInFile();
          widget.project.deleteTempFiles();
          await writeToDisk();
          _updateButtonSet();
        }
      },
    );

    boardMode.addListener(
      () {
        BoardMode mode = boardMode.value;
        gridNotfier.draggable = mode.draggableButtons;
        gridNotfier.emptySpotWidget = mode.emptySpotWidget;
        gridNotfier.toWidget = toParrotButton;
        mode.onPressedOverride(gridNotfier);

        if (mode == BoardMode.builderMode) {
          gridNotfier.onEmptyPressed = _showCreateNewButtonDialog;
        } else if (mode == BoardMode.deleteRowMode) {
          gridNotfier.onEmptyPressed = (row, _) {
            gridNotfier.removeRow(row);
            mode.onPressedOverride(
                gridNotfier); //updates the grid notifier to tell the buttons inside of it to delete the new row
            gridNotfier.forEachIndexed((obj, int row, int col) {
              if (obj is ParrotButtonNotifier) {
                _updateButtonNotfierOnDelete(obj, row, col);
              }
            });
          };
        } else if (mode == BoardMode.deleteColMode) {
          gridNotfier.onEmptyPressed = (_, col) {
            gridNotfier.removeCol(col);
            mode.onPressedOverride(
                gridNotfier); //updates the grid notifier to tell the buttons inside of it to delete the new col.
            gridNotfier.forEachIndexed((obj, int row, int col) {
              if (obj is ParrotButtonNotifier) {
                _updateButtonNotfierOnDelete(obj, row, col);
              }
            });
          };
        } else {
          gridNotfier.onEmptyPressed = null;
        }
      },
    );

    super.initState();
  }

  void _updateButtonNotfierOnDelete(Object data, int row, int col) {
    if (data is ParrotButtonNotifier) {
      data.onDelete = () {
        gridNotfier.removeAt(row, col);
      };
    }
  }

  void _showCreateNewButtonDialog(int row, int col) {
    {
      ParrotButtonNotifier notifier = ParrotButtonNotifier(
        projectPath: widget.path,
      );
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
                  notifier.onDelete = () => gridNotfier.removeAt(row, col);
                  notifier.boxController = sentenceController;
                  gridNotfier.setWidget(
                    row: row,
                    col: col,
                    data: notifier,
                  );

                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  ParrotButton? toParrotButton(Object? object) {
    if (object is ParrotButtonNotifier) {
      return ParrotButton(
        controller: object,
        holdToConfig: boardMode.value.configOnButtonHold,
      );
    }
    return null;
  }

  Future<void> finalizeTempImages() async {
    Map<String, String> paths =
        await widget.project.mapTempImageToPermantSpot();
    await widget.project.moveFiles(paths);
    widget.project.updateImagePaths(paths);
  }

  Future<void> writeToDisk() async {
    await widget.project.write(path: widget.path);
  }

  void addButtonToSentenceBox(ButtonData buttonData) {
    sentenceController.add(buttonData);
  }

  void changeObf(Obf obf) {
    updateButtonPositionsInObf();
    currentObf = obf;
    gridNotfier.setData(_getButtonsFromObf(obf));
  }

  void goToRootBoard() {
    Obf? root = widget.project.root;
    if (root != null) {
      changeObf(root);
    }
  }

  List<List<Object?>> _getButtonsFromObf(Obf obf) {
    List<List<Object?>> buttons = [];
    final int rowCount = obf.grid.numberOfRows;
    final int colCount = obf.grid.numberOfColumns;
    for (int i = 0; i < rowCount; i++) {
      buttons.add([]);
      for (int j = 0; j < colCount; j++) {
        ButtonData? button = obf.grid.getButtonData(i, j);
        if (button != null) {
          buttons.last.add(
            ParrotButtonNotifier(
              data: button,
              boxController: sentenceController,
              goToLinkedBoard: changeObf,
              goHome: goToRootBoard,
              onDelete: () {
                gridNotfier.removeAt(i, j);
              },
              projectPath: widget.path,
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
    void disposeNotfier(n) => n.dispose;
    gridNotfier.dispose();
    buttonSet.forEach(disposeNotfier);
    boardMode.dispose();
    sentenceController.dispose();
    super.dispose();
  }

  void _updateButtonSet() {
    void disposeNotfier(n) => n.dispose;
    final buttonSetFromGrid = _buttonSetFromGrid(gridNotfier.data);
    buttonSet.difference(buttonSetFromGrid).forEach(disposeNotfier);
    buttonSet = buttonSetFromGrid;
  }

  Set<ParrotButtonNotifier> _buttonSetFromGrid(List<List<Object?>> buttons) {
    Set<ParrotButtonNotifier> out = {};
    for (List<Object?> row in buttons) {
      for (Object? button in row) {
        if (button is ParrotButtonNotifier) {
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
    final addColButton = IconButton(
      onPressed: gridNotfier.addColumn,
      icon: FittedBox(
        fit: BoxFit.contain,
        child: SvgPicture.asset('assets/images/add_col.svg', height: 50),
      ),
      color: boardMode.value == BoardMode.deleteRowMode
          ? Colors.grey
          : Colors.white,
    );
    final addRowButton = IconButton(
      onPressed: gridNotfier.addRow,
      icon: FittedBox(
        fit: BoxFit.contain,
        child: SvgPicture.asset('assets/images/add_row.svg', width: 50),
      ),
    );

    final settingsButton = IconButton(
      icon: Icon(Icons.settings),
      onPressed: () => showAdminLockPopup(
        context: context,
        onAccept: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SettingsScreen()),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ParrotAAC'),
            ValueListenableBuilder(
                valueListenable: boardMode,
                builder: (context, mode, _) {
                  bool inNormalMode = mode == BoardMode.normalMode;
                  final removeRowButton = Container(
                    color: boardMode.value == BoardMode.deleteRowMode
                        ? Colors.grey
                        : Colors.transparent,
                    child: IconButton(
                      onPressed: () {
                        boardMode.value = mode == BoardMode.deleteRowMode
                            ? BoardMode.builderMode
                            : BoardMode.deleteRowMode;
                      },
                      icon: FittedBox(
                        fit: BoxFit.contain,
                        child: SvgPicture.asset('assets/images/remove_row.svg',
                            width: 50),
                      ),
                    ),
                  );
                  final removeColButton = Container(
                    color: boardMode.value == BoardMode.deleteColMode
                        ? Colors.grey
                        : Colors.transparent,
                    child: IconButton(
                      onPressed: () {
                        boardMode.value = mode == BoardMode.deleteColMode
                            ? BoardMode.builderMode
                            : BoardMode.deleteColMode;
                      },
                      icon: FittedBox(
                        fit: BoxFit.contain,
                        child: SvgPicture.asset('assets/images/remove_col.svg',
                            height: 50),
                      ),
                    ),
                  );
                  IconData icon = inNormalMode ? Icons.handyman : Icons.close;
                  final builderModeButton = IconButton(
                      icon: Icon(icon),
                      onPressed: () {
                        if (inNormalMode) {
                          showAdminLockPopup(
                              context: context,
                              onAccept: () {
                                boardMode.value = BoardMode.builderMode;
                              });
                        } else {
                          boardMode.value = BoardMode.normalMode;
                        }
                      });

                  final List<Widget> notInNormalModeWidgets;
                  if (!inNormalMode) {
                    notInNormalModeWidgets = [
                      removeColButton,
                      removeRowButton,
                      addRowButton,
                      addColButton
                    ];
                  } else {
                    notInNormalModeWidgets = [];
                  }
                  return Row(
                    children: [
                      ...notInNormalModeWidgets,
                      builderModeButton,
                      settingsButton,
                    ],
                  );
                })
          ],
        ),
        backgroundColor: Color(0xFFAFABDF),
      ),
      body: ValueListenableBuilder(
          valueListenable: boardMode,
          builder: (context, inBuilderMode, _) {
            List<Flexible> children = [
              Flexible(
                flex: 2,
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
              Flexible(
                flex: 25,
                child: DraggableGrid(gridNotfier: gridNotfier),
              ),
            ];
            return Column(
              children: children,
            );
          }),
    );
  }
}
