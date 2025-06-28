import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/ui/board_screen_appbar.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/util_widgets/board.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';
import 'package:parrotaac/ui/widgets/sentence_box.dart';
import 'board_modes.dart';
import 'parrot_button.dart';

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
  late final GridNotfier<ParrotButton> _gridNotfier;
  late final SentenceBoxController _sentenceController;
  final ValueNotifier<BoardMode> _boardMode =
      ValueNotifier(BoardMode.normalMode);
  late final TextEditingController _titleController;
  late final ValueNotifier<Obf> _currentObfNotfier;
  final ValueNotifier<bool> canUndo = ValueNotifier(false);
  final ValueNotifier<bool> canRedo = ValueNotifier(false);

  late final ProjectEventHandler eventHandler;

  Obf get _currentObf => _currentObfNotfier.value;
  set _currentObf(Obf obf) => _currentObfNotfier.value = obf;
  @override
  void initState() {
    _currentObfNotfier = ValueNotifier(
      widget.project.root ??
          Obf(
            locale: "en",
            name: defaultBoardName,
            id: defaultID,
          ),
    );

    _sentenceController = SentenceBoxController(projectPath: widget.path);
    _titleController = TextEditingController(text: _currentObf.name);
    _gridNotfier = GridNotfier(
        data: [],
        toWidget: (obj) {
          if (obj is ParrotButtonNotifier) {
            return ParrotButton(
              controller: obj,
              eventHandler: eventHandler,
            );
          }
          return null;
        },
        draggable: false,
        onSwap: (oldRow, oldCol, newRow, newCol) {
          eventHandler.swapButtons(oldRow, oldCol, newRow, newCol);
          final data = _gridNotfier.getWidget(newRow, newCol);
          _updateButtonNotfierOnDelete(
            data!,
            eventHandler,
            newRow,
            newCol,
          );
        });
    _boardMode.addListener(
      () async {
        if (_boardMode.value == BoardMode.normalMode) {
          _updateButtonPositionsInObf();
          _updateObfName();
          await _finalizeTempFiles();
          widget.project.autoResolveAllIdCollisionsInFile();
          widget.project.deleteTempFiles();
          await writeToDisk();
        }
      },
    );

    _currentObfNotfier.addListener(() {
      _titleController.text = _currentObf.name;
    });
    eventHandler = ProjectEventHandler(
        project: widget.project,
        gridNotfier: _gridNotfier,
        boxController: _sentenceController,
        canUndo: canUndo,
        canRedo: canRedo,
        modeNotifier: _boardMode,
        titleController: _titleController,
        currentObf: _currentObfNotfier);
    super.initState();
  }

  void _updateButtonNotfierOnDelete(
      Object data, ProjectEventHandler eventHandler, int row, int col) {
    if (data is ParrotButtonNotifier) {
      data.onDelete = () {
        eventHandler.removeButton(row, col);
      };
    }
  }

  Future<void> _finalizeTempFiles() async {
    await _finalizeTempImages();
    await _finalizeTempAudioFiles();
  }

  Future<void> _finalizeTempImages() async {
    Map<String, String> paths =
        await widget.project.mapTempImageToPermantSpot();
    await widget.project.moveFiles(paths);
    widget.project.updateImagePathReferencesInProject(paths);
  }

  Future<void> _finalizeTempAudioFiles() async {
    Map<String, String> paths =
        await widget.project.mapTempAudioToPermantSpot();
    await widget.project.moveFiles(paths);
    widget.project.updateAudioPathReferencesInProject(paths);
  }

  Future<void> writeToDisk() async {
    await widget.project.write(path: widget.path);
  }

  void addButtonToSentenceBox(ButtonData buttonData) {
    _sentenceController.add(buttonData);
  }

  void _updateObfName() {
    _currentObf.name = _titleController.text.trim();
  }

  void _changeObf(Obf obf) {
    _currentObf = obf;
  }

  void goToRootBoard() {
    Obf? root = widget.project.root;
    if (root != null) {
      _changeObf(root);
    }
  }

  @override
  void dispose() {
    _updateButtonPositionsInObf();
    _gridNotfier.dispose();
    _boardMode.dispose();
    _sentenceController.dispose();
    _titleController.dispose();
    _currentObfNotfier.dispose();
    super.dispose();
  }

  void _updateButtonPositionsInObf() {
    List<List<ButtonData?>> order = [];
    for (List<ParrotButton?> row in _gridNotfier.widgets) {
      order.add(row.map((b) => b?.buttonData).toList());
      for (ParrotButton? button in row) {
        if (button != null &&
            !_currentObf.buttons.contains(button.buttonData)) {
          _currentObf.buttons.add(button.buttonData);
        }
      }
    }
    _currentObf.grid.setOrder(order);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: boardScreenAppbar(
        context: context,
        boardMode: _boardMode,
        titleController: _titleController,
        project: widget.project,
        eventHandler: eventHandler,
      ),
      body: BoardWidget(
        project: widget.project,
        path: widget.path,
        eventHandler: eventHandler,
        boardMode: _boardMode,
        gridNotfier: _gridNotfier,
        sentenceBoxController: _sentenceController,
        currentObfNotfier: _currentObfNotfier,
      ),
    );
  }
}
