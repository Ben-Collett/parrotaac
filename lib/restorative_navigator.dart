import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/history_stack.dart';
import 'package:parrotaac/backend/project/code_gen_allowed/event/project_events.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project_restore_write_stream.dart';
import 'package:parrotaac/backend/quick_store.dart';
import 'package:parrotaac/backend/state_restoration_utils.dart';
import 'package:parrotaac/board_selector.dart';
import 'package:parrotaac/setting_screen.dart';
import 'package:parrotaac/ui/board_modes.dart';
import 'package:parrotaac/ui/board_screen.dart';
import 'package:parrotaac/ui/board_screen_popup_history.dart';
import 'package:parrotaac/ui/popups/button_config.dart';
import 'package:parrotaac/ui/restore_button_diff.dart';
import 'package:parrotaac/ui/widgets/sentence_box.dart';

///singleton
class RestorativeNavigator {
  final _quickStore = IndexedQuickstore("route");
  RestorativeNavigator._privateConstructor();

  final List<Widget> screens = [];
  final Queue<ProjectRestorationData> _openRestorationData = Queue();

  static final RestorativeNavigator _instance =
      RestorativeNavigator._privateConstructor();

  factory RestorativeNavigator() {
    return _instance;
  }
  static const String _nameKey = "name";
  Future<void> initialize() async {
    await _quickStore.initialize();
    await _restore();
  }

  Future<dynamic> goToSettings(
    BuildContext context, {
    ParrotProject? project,
    Obf? board,
  }) async {
    _quickStore.pushAndWrite({_nameKey: ScreenName.settings.name});

    screens.add(SettingsScreen());
    return RestorativeNavigator()._goToTopScreen(context);
  }

  Future<dynamic> _goToTopScreen(BuildContext context) {
    return Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => topScreen),
    );
  }

  Widget get topScreen {
    return screens.lastOrNull ?? ProjectSelector();
  }

  Future<dynamic> openProject(
      BuildContext context, ParrotProject project) async {
    _quickStore.pushAndWrite(
      {
        _nameKey: ScreenName.grid.name,
        "project_path": project.path,
      },
    );

    screens.add(
      await _getBoardScreen(project),
    );

    if (context.mounted) return _goToTopScreen(context);
  }

  Future<dynamic> goToProjectSelector(BuildContext context) {
    _quickStore.pushAndWrite({_nameKey: ScreenName.projectSelector.name});
    screens.add(ProjectSelector());
    return _goToTopScreen(context);
  }

  Future<void> pop(BuildContext context) async {
    await _quickStore.removeTop();
    if (screens.isNotEmpty) {
      if (screens.last is BoardScreen) {
        await _openRestorationData.removeLast().close();
      }
      screens.removeAt(screens.length - 1);
    }

    if (context.mounted) return _goToTopScreen(context);
  }

  Future<void> _restore() async {
    for (final data in _quickStore.getAllData()) {
      if (data is Map && data['name'] is String) {
        final String name = data['name'];
        final ScreenName? screenName =
            ScreenName.values.where((n) => n.name == name).firstOrNull;
        if (screenName == null) {
          continue;
        }

        switch (screenName) {
          case ScreenName.projectSelector:
            screens.add(ProjectSelector());
          case ScreenName.grid:
            screens.add(
              await _getBoardScreen(
                ParrotProject.fromDirectory(
                  Directory(
                    data['project_path'],
                  ),
                ),
              ),
            );
          case ScreenName.settings:
            screens.add(SettingsScreen());
        }
      }
    }
  }

  Future<BoardScreen> _getBoardScreen(ParrotProject project) async {
    ProjectRestorationData restorationData =
        await ProjectRestorationData.fromPath(project.path);

    const historyMaxSize = 100;
    BoardHistoryStack historyStack = restorationData.createBoardHistory(
      project,
      historyMaxSize,
    );

    List<SenteceBoxDisplayEntry> initialBoxData =
        restorationData.getSentenceBoxData(project);

    BoardMode boardMode = restorationData.currentBoardMode;
    ProjectRestoreStream stream = ProjectRestoreStream(restorationData);
    List<ProjectEvent> initialUndo = restorationData.currentUndoStack;
    List<ProjectEvent> initialRedo = restorationData.currentRedoStack;

    final initialHistory = restorationData.currentPopupHistory;
    final popupHistory =
        BoardScreenPopupHistory(initialHistory, restoreSteam: stream);

    BoardLinkingActionMode? boardLinkingAction = BoardLinkingActionMode.values
        .where((a) => a.label == restorationData.boardLinkingActionMode)
        .firstOrNull;

    final diff = RestorableButtonDiff(
        changes: restorationData.openButtonDiff,
        restoreStream: stream,
        boardLinkingAction: boardLinkingAction);

    _openRestorationData.add(restorationData);

    return BoardScreen(
      project: project,
      restoreStream: stream,
      initialBoxData: initialBoxData,
      initialMode: boardMode,
      popupHistory: popupHistory,
      restorableButtonDiff: diff,
      initialUndoEventStack: initialUndo,
      initialRedoEventStack: initialRedo,
      history: historyStack,
    );
  }
}
