import 'dart:math';

import 'package:flutter/material.dart';
import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/history_stack.dart';
import 'package:parrotaac/backend/project/file_cleanup_data.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project/patch.dart';
import 'package:parrotaac/backend/project_restore_write_stream.dart';
import 'package:parrotaac/backend/state_restoration_utils.dart';
import 'package:parrotaac/ui/board_screen_appbar.dart';
import 'package:parrotaac/ui/board_sidebar.dart';
import 'package:parrotaac/ui/event_handler.dart';
import 'package:parrotaac/ui/popups/loading.dart';
import 'package:parrotaac/ui/popups/lock_popups/admin_lock.dart';
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
  final ProjectRestorationData restorationData;
  final BoardScreenPopupHistory? popupHistory;
  final RestorableButtonDiff? restorableButtonDiff;

  bool get isInNormalMode =>
      restorationData.currentBoardMode == BoardMode.normalMode;
  //WARNING: storing the path will only work if I wait to rename a project somehow
  const BoardScreen({
    super.key,
    required this.project,
    required this.restorationData,
    this.popupHistory,
    this.restoreStream,
    this.restorableButtonDiff,
  });

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late final GridNotifier<ParrotButton> _gridNotifier;
  late final SentenceBoxController _sentenceController;
  late final ValueNotifier<BoardMode> _boardMode;
  late final ValueNotifier<bool> showSideBar;
  late final BoardHistoryStack _boardHistory;

  late final TextEditingController _titleController;
  final ValueNotifier<bool> canUndo = ValueNotifier(false);
  final ValueNotifier<bool> canRedo = ValueNotifier(false);
  final Patch currentPatch = Patch(actions: []);

  late final ProjectEventHandler eventHandler;

  Obf get _currentObf => _boardHistory.currentBoard;
  set _currentObf(Obf obf) => _boardHistory.push(obf);
  @override
  void initState() {
    ParrotProject project = widget.project;
    ProjectRestorationData? restorationData = widget.restorationData;
    _boardMode = ValueNotifier(restorationData.currentBoardMode);
    const historySize = 1000;
    _boardHistory = restorationData.createBoardHistory(project, historySize);

    _sentenceController = SentenceBoxController(
      projectPath: project.path,
      initialData: restorationData.getSentenceBoxData(widget.project),
      enabled: project.settings?.showSentenceBar ?? true,
    );

    _sentenceController.addListener(() {
      final data = _sentenceController.dataCopyView();
      widget.restoreStream?.updateSentenceBar(data);
    });
    _titleController = TextEditingController(text: _currentObf.name);
    _gridNotifier = GridNotifier(
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
        final data = _gridNotifier.getWidget(newRow, newCol);
        _updateButtonNotfierOnDelete(data!, eventHandler, newRow, newCol);
      },
    );

    alreadyAuthenticated = _boardMode.value != BoardMode.normalMode;
    _boardMode.addListener(
      () => widget.restoreStream?.updateBoardMode(_boardMode.value),
    );
    _boardMode.addListener(() async {
      if (_boardMode.value == BoardMode.normalMode) {
        _updateButtonPositionsInObf();
        _updateObfName();
        Set<String> boardsToWrite = eventHandler.updatedBoardsIds.toSet();
        currentPatch.actions.addAll(eventHandler.currentlyExecutedEvents());

        project.removedUnrefrencedButtons();
        project.removedUnrefrencedImageData();
        project.removedUnrefrencedSoundData();
        final cleanupData = await FileCleanupData.fromProject(project);

        await cleanupData.cleanUp();
        //await currentPatch.writeZip("/tmp/hi.zip"); //TODO upload patch instead

        currentPatch.clear();
        eventHandler.clear();
        //await _finalizeTempFiles();
        //widget.project.deleteTempFiles();
        await writeToDisk(boardsToWrite);
      }
    });
    _boardMode.addListener(() {
      if (_boardMode.value == BoardMode.normalMode) {
        alreadyAuthenticated = false;
      } else {
        alreadyAuthenticated = true;
      }
    });

    _boardMode.addListener(() {
      if (_boardMode.value == BoardMode.normalMode) {
        showSideBar.value = false;
      }
    });

    showSideBar = ValueNotifier(
      restorationData.showSideBar ?? _boardMode.value != BoardMode.normalMode,
    );

    showSideBar.addListener(() {
      widget.restoreStream?.updateShowSideBar(showSideBar.value);
    });

    _boardHistory.addListener(() {
      _titleController.text = _currentObf.name;
    });

    eventHandler = ProjectEventHandler(
      project: widget.project,
      gridNotfier: _gridNotifier,
      boxController: _sentenceController,
      canUndo: canUndo,
      canRedo: canRedo,
      currentPatch: currentPatch,
      boardHistory: _boardHistory,
      modeNotifier: _boardMode,
      titleController: _titleController,
      restoreStream: widget.restoreStream,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!project.restored) {
        eventHandler.bulkExecute(
          restorationData.currentUndoStack,
          updateUi: false,
        );

        project.restored = true;

        eventHandler.setRedoStack(restorationData.currentRedoStack);
        _sentenceController.update();
      } else {
        eventHandler.setUndoStack(restorationData.currentUndoStack);
        eventHandler.setRedoStack(restorationData.currentRedoStack);
      }
    });

    //WidgetsBinding.instance.addPostFrameCallback((_) {
    // applyPatch("/tmp/hi.zip");
    //});

    super.initState();
  }

  void applyPatch(String path) {
    showLoadingDialogUntilCompleted(
      context: context,
      message: "applying patch",
      future: Patch.applyPatch(path, eventHandler),
    );
  }

  void _updateButtonNotfierOnDelete(
    Object data,
    ProjectEventHandler eventHandler,
    int row,
    int col,
  ) {
    if (data is ParrotButtonNotifier) {
      data.onDelete = () {
        eventHandler.removeButton(row, col);
      };
    }
  }

  Future<void> writeToDisk(Iterable<String> boardsToWrite) async {
    await widget.project.write(updatedBoards: boardsToWrite.toSet());
  }

  void addButtonToSentenceBox(ButtonData buttonData) {
    _sentenceController.add(
      SenteceBoxDisplayEntry(data: buttonData, board: _currentObf),
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
    _gridNotifier.dispose();
    _boardMode.dispose();
    _sentenceController.dispose();
    _titleController.dispose();
    _boardHistory.dispose();
    super.dispose();
  }

  void _updateButtonPositionsInObf() {
    List<List<ButtonData?>> order = [];
    for (List<ParrotButton?> row in _gridNotifier.widgets) {
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
        showSideBar: showSideBar,
        project: widget.project,
        boardHistory: _boardHistory,
        grid: _gridNotifier,
        eventHandler: eventHandler,
        leading: BackButton(
          onPressed: () {
            showAdminLockPopup(
              context: context,
              onAccept: () {
                RestorativeNavigator().pop(context);
                alreadyAuthenticated = true;
              },
            );
          },
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: showSideBar,
        builder: (context, isSidebarVisible, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final double sideBarWidth = min(constraints.maxWidth * .15, 80);
              const duration = Duration(milliseconds: 200);
              double sidebarTargetWidth = isSidebarVisible ? sideBarWidth : 0;

              return Row(
                children: [
                  // Animate the BoardWidget's width
                  Expanded(
                    child: AnimatedContainer(
                      duration: duration,
                      child: BoardWidget(
                        project: widget.project,
                        history: _boardHistory,
                        eventHandler: eventHandler,
                        boardMode: _boardMode,
                        restorableButtonDiff: widget.restorableButtonDiff,
                        gridNotifier: _gridNotifier,
                        popupHistory: widget.popupHistory,
                        restoreStream: widget.restoreStream,
                        sentenceBoxController: _sentenceController,
                      ),
                    ),
                  ),

                  // Animate sidebar sliding in/out
                  AnimatedContainer(
                    duration: duration,
                    width: sidebarTargetWidth,
                    child: SizedBox(
                      height: constraints
                          .maxHeight, //suppresses animation when height changes
                      child: BoardSidebar(
                        eventHandler: eventHandler,
                        boardMode: _boardMode,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
