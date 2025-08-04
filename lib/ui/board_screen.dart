import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/history_stack.dart';
import 'package:parrotaac/backend/project/code_gen_allowed/event/project_events.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project_restore_write_stream.dart';
import 'package:parrotaac/ui/board_screen_appbar.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/util_widgets/board.dart';
import 'package:parrotaac/ui/util_widgets/draggable_grid.dart';
import 'package:parrotaac/ui/widgets/sentence_box.dart';
import '../restorative_navigator.dart';
import 'board_modes.dart';
import 'board_screen_popup_history.dart';
import 'parrot_button.dart';
import 'restore_button_diff.dart' show RestorableButtonDiff;

class BoardScreen extends StatefulWidget {
  final ParrotProject project;
  final ProjectRestoreStream? restoreStream;
  final BoardHistoryStack? history;
  final BoardMode? initialMode;
  final List<SenteceBoxDisplayEntry>? initialBoxData;
  final List<ProjectEvent>? initialUndoEventStack;
  final List<ProjectEvent>? initialRedoEventStack;
  final BoardScreenPopupHistory? popupHistory;
  final RestorableButtonDiff? restorableButtonDiff;
  //WARNING: storing the path will only work if I wait to rename a project somehow
  const BoardScreen({
    super.key,
    required this.project,
    this.initialBoxData,
    this.initialMode,
    this.popupHistory,
    this.restoreStream,
    this.initialUndoEventStack,
    this.initialRedoEventStack,
    this.restorableButtonDiff,
    this.history,
  });

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  static const String defaultBoardName = "default name";
  static const String defaultID = "board";
  late final GridNotfier<ParrotButton> _gridNotfier;
  late final SentenceBoxController _sentenceController;
  late final ValueNotifier<BoardMode> _boardMode;

  late final TextEditingController _titleController;
  late final ValueNotifier<Obf> _currentObfNotfier;
  final ValueNotifier<bool> canUndo = ValueNotifier(false);
  final ValueNotifier<bool> canRedo = ValueNotifier(false);

  late final ProjectEventHandler eventHandler;

  Obf get _currentObf => _currentObfNotfier.value;
  set _currentObf(Obf obf) => _currentObfNotfier.value = obf;
  @override
  void initState() {
    _boardMode = ValueNotifier(widget.initialMode ?? BoardMode.normalMode);
    _currentObfNotfier = ValueNotifier(
      widget.history?.currentBoard ??
          widget.project.root ??
          Obf(
            locale: "en",
            name: defaultBoardName,
            id: defaultID,
          ),
    );

    _sentenceController = SentenceBoxController(
      projectPath: widget.project.path,
      initialData: widget.initialBoxData,
    );

    _sentenceController.addListener(() {
      final data = _sentenceController.dataCopyView();
      widget.restoreStream?.updateSentenceBar(data);
    });
    _titleController = TextEditingController(text: _currentObf.name);
    _gridNotfier = GridNotfier(
        data: [],
        toWidget: (obj) {
          if (obj is ParrotButtonNotifier) {
            return ParrotButton(
              controller: obj,
              currentBoard: _currentObf,
              restorableButtonDiff: widget.restorableButtonDiff,
              popupHistory: widget.popupHistory,
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
      () => widget.restoreStream?.updateBoardMode(_boardMode.value),
    );
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
        currentObf: _currentObfNotfier,
        restoreStream: widget.restoreStream);

    _boardMode.addListener(() {
      if (_boardMode.value == BoardMode.normalMode) {
        eventHandler.clear();
      }
    });

    if (widget.initialUndoEventStack != null) {
      eventHandler.bulkExecute(
        widget.initialUndoEventStack!,
        updateUi: false,
      );
    }
    if (widget.initialRedoEventStack != null) {
      eventHandler.setRedoStack(widget.initialRedoEventStack!);
    }
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
    await widget.project.write(path: widget.project.path);
  }

  void addButtonToSentenceBox(ButtonData buttonData) {
    _sentenceController.add(
      SenteceBoxDisplayEntry(
        data: buttonData,
        board: _currentObf,
      ),
    );
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => RestorativeNavigator().pop(context),
        ),
      ),
      body: BoardWidget(
        project: widget.project,
        history: widget.history,
        eventHandler: eventHandler,
        boardMode: _boardMode,
        restorableButtonDiff: widget.restorableButtonDiff,
        gridNotfier: _gridNotfier,
        popupHistory: widget.popupHistory,
        restoreStream: widget.restoreStream,
        sentenceBoxController: _sentenceController,
        currentObfNotfier: _currentObfNotfier,
      ),
    );
  }
}
