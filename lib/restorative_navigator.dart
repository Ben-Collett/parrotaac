//TODO: the restorative navigator needs to handle admin authentication when restoring but not when app closes in background
import 'dart:collection';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project/project_settings.dart';
import 'package:parrotaac/backend/project_restore_write_stream.dart';
import 'package:parrotaac/backend/quick_store.dart';
import 'package:parrotaac/backend/state_restoration_utils.dart';
import 'package:parrotaac/board_selector.dart';
import 'package:parrotaac/setting_screen.dart';
import 'package:parrotaac/ui/board_screen.dart';
import 'package:parrotaac/ui/board_screen_popup_history.dart';
import 'package:parrotaac/ui/popups/button_config.dart';
import 'package:parrotaac/ui/restore_button_diff.dart';

///singleton
class RestorativeNavigator {
  final _quickStore = IndexedQuickstore("route");
  RestorativeNavigator._privateConstructor();

  final List<Widget> screens = [];
  bool get hasPreviousScreen => screens.isNotEmpty;

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

    screens.add(SettingsScreen(board: board, project: project));
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

    project.settings = await ProjectSettings.fromProject(project);

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
        BoardScreen last = screens.last as BoardScreen;
        Future.wait([
          last.restorationData.close(),
          if (last.project.settings != null) last.project.settings!.close(),
          if (last.restoreStream != null) last.restoreStream!.close()
        ]);
      }
      screens.removeAt(screens.length - 1);
    }

    if (context.mounted) return _goToTopScreen(context);
  }

  Future<void> _restore() async {
    ParrotProject? topProject;
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
            topProject = ParrotProject.fromDirectory(
              Directory(
                data['project_path'],
              ),
            );
            topProject.settings = await ProjectSettings.fromProject(topProject);
            screens.add(await _getBoardScreen(topProject));
          case ScreenName.settings:
            screens.add(
              SettingsScreen(
                project: topProject,
              ),
            );
        }
      }
    }
  }

  Future<BoardScreen> _getBoardScreen(ParrotProject project) async {
    ProjectRestorationData restorationData =
        await ProjectRestorationData.fromPath(project.path);

    ProjectRestoreStream stream = ProjectRestoreStream(restorationData);

    BoardLinkingActionMode? boardLinkingAction = BoardLinkingActionMode.values
        .where((a) => a.label == restorationData.boardLinkingActionMode)
        .firstOrNull;

    final diff = RestorableButtonDiff(
        changes: restorationData.openButtonDiff,
        restoreStream: stream,
        boardLinkingAction: boardLinkingAction);
    final popupHistory = BoardScreenPopupHistory(
        restorationData.currentPopupHistory,
        restoreSteam: stream);

    return BoardScreen(
      project: project,
      restoreStream: stream,
      restorationData: restorationData,
      popupHistory: popupHistory,
      restorableButtonDiff: diff,
    );
  }
}
