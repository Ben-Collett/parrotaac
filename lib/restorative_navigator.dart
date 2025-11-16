//TODO: close selection history when needed
import 'dart:collection';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';
import 'package:parrotaac/backend/project/project_settings.dart';
import 'package:parrotaac/backend/project_restore_write_stream.dart';
import 'package:parrotaac/backend/quick_store.dart';
import 'package:parrotaac/backend/selection_history.dart';
import 'package:parrotaac/backend/settings_utils.dart';
import 'package:parrotaac/backend/state_restoration_utils.dart';
import 'package:parrotaac/setting_screen.dart';
import 'package:parrotaac/ui/board_modes.dart';
import 'package:parrotaac/ui/board_screen.dart';
import 'package:parrotaac/ui/board_screen_popup_history.dart';
import 'package:parrotaac/ui/popups/button_config.dart';
import 'package:parrotaac/ui/popups/lock_popups/admin_authentication_states.dart';
import 'package:parrotaac/ui/popups/lock_popups/admin_lock.dart';
import 'package:parrotaac/ui/restore_button_diff.dart';
import 'package:parrotaac/ui/settings/labels.dart';

import 'project_selector.dart';

///singleton
class RestorativeNavigator {
  bool fullyInitialized = false;

  ///the index of the last widget that can be displayed without admin privlages
  ///should only be used directly after _restore
  int _lastNonAdmin = 0;
  final _quickStore = IndexedQuickstore("route");
  RestorativeNavigator._privateConstructor();

  List<Widget> screens = [];
  bool get hasPreviousScreen => screens.length > 1;

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
    final adminState = await showAdminLockPopup(context: context);
    if (adminState != AdminAuthenticationState.accepted) {
      return;
    }
    _quickStore.pushAndWrite({_nameKey: ScreenName.settings.name});

    screens.add(SettingsScreen(board: board, project: project));
    if (context.mounted) {
      return RestorativeNavigator().goToTopScreen(context);
    }
  }

  Future<void> _updateQuckStore() async {
    await _quickStore.clear();
    for (Widget screen in screens) {
      final ScreenName? screenName = ScreenName.screenNameFromType(screen);
      assert(
        screenName != null,
        "widget type $screen somehow wasn't in ScreenNames",
      );
      Map<String, dynamic> out = {_nameKey: screenName!.name};
      if (screen is BoardScreen) {
        out["project_path"] = screen.project.path;
      }
      await _quickStore.pushAndWrite(out);
    }
  }

  Future<dynamic> goToTopScreen(BuildContext context) async {
    if (!fullyInitialized) {
      final alreadyFinished = screens.length - 1 == _lastNonAdmin;
      if (!alreadyFinished && !await _authenticated(context)) {
        screens = screens.sublist(0, _lastNonAdmin + 1);
        await _updateQuckStore();
      }
      fullyInitialized = true;
      if (screens.length - 1 == _lastNonAdmin) {
        return;
      }
    }
    if (context.mounted) {
      return Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => topScreen));
    }
  }

  Widget get topScreen {
    return screens.lastOrNull ?? ProjectSelector();
  }

  ///should only be called after _restore
  Widget getLastNonAdminScreen() {
    final thereIsNoAdminLock = LockType.fromString(getAdminLockLabel()).isNone;
    if (alreadyAuthenticated || thereIsNoAdminLock) {
      return screens.last;
    }
    return screens[_lastNonAdmin];
  }

  Future<dynamic> openProject(
    BuildContext context,
    ParrotProject project,
  ) async {
    ProjectRestorationData restorationData =
        await ProjectRestorationData.fromPath(project.path);
    if (restorationData.currentBoardMode != BoardMode.normalMode) {
      final AdminAuthenticationState authState;
      if (context.mounted) {
        authState = await showAdminLockPopup(context: context);
      } else {
        authState = AdminAuthenticationState.canceled;
      }

      if (authState != AdminAuthenticationState.accepted) {
        return;
      }
    }
    _quickStore.pushAndWrite({
      _nameKey: ScreenName.grid.name,
      "project_path": project.path,
    });

    project.settings = await ProjectSettings.fromProject(project);

    screens.add(
      await _getBoardScreen(project, restorationData: restorationData),
    );

    if (context.mounted) return goToTopScreen(context);
  }

  Future<dynamic> goToProjectSelector(BuildContext context) {
    _quickStore.pushAndWrite({_nameKey: ScreenName.projectSelector.name});
    screens.add(ProjectSelector());
    return goToTopScreen(context);
  }

  Future<void> pop(BuildContext context) async {
    await _quickStore.removeTop();
    if (screens.isNotEmpty) {
      if (screens.last is BoardScreen) {
        BoardScreen last = screens.last as BoardScreen;
        Future.wait([
          last.restorationData.close(),
          if (last.project.settings != null) last.project.settings!.close(),
          if (last.restoreStream != null) last.restoreStream!.close(),
        ]);
      }
      screens.removeAt(screens.length - 1);
    }

    if (context.mounted) return goToTopScreen(context);
  }

  Future<void> _restore() async {
    ParrotProject? topProject;
    int counter = 0;
    for (final data in _quickStore.getAllData()) {
      if (data is Map && data['name'] is String) {
        final String name = data['name'];
        final ScreenName? screenName = ScreenName.values
            .where((n) => n.name == name)
            .firstOrNull;
        if (screenName == null) {
          continue;
        }
        bool doesNotNeedAdmin;

        switch (screenName) {
          case ScreenName.projectSelector:
            screens.add(ProjectSelector());
            doesNotNeedAdmin = true;
          case ScreenName.grid:
            topProject = ParrotProject.fromDirectory(
              Directory(data['project_path']),
            );
            topProject.settings = await ProjectSettings.fromProject(topProject);
            BoardScreen boardScreen = await _getBoardScreen(topProject);
            screens.add(boardScreen);

            doesNotNeedAdmin = boardScreen.isInNormalMode;

          case ScreenName.settings:
            screens.add(SettingsScreen(project: topProject));
            doesNotNeedAdmin = false;
        }

        if (doesNotNeedAdmin && counter == _lastNonAdmin) {
          _lastNonAdmin++;
        }
        counter++;
      }
    }
    if (screens.firstOrNull is! ProjectSelector) {
      screens.insert(0, ProjectSelector());
    } else {
      _lastNonAdmin--;
    }

    if (alreadyAuthenticated) {
      fullyInitialized = true;
    }
  }

  Future<bool> _authenticated(BuildContext context) async {
    final state = await showAdminLockPopup(context: context);
    return state == AdminAuthenticationState.accepted;
  }

  Future<BoardScreen> _getBoardScreen(
    ParrotProject project, {
    ProjectRestorationData? restorationData,
  }) async {
    restorationData ??= await ProjectRestorationData.fromPath(project.path);
    final selectionHistoryQuickStore = QuickStoreHiveImp(
      "selection_history",
      path: project.path,
    );

    await selectionHistoryQuickStore.initialize();

    final selectionHistory = WorkingSelectionHistory.from(
      selectionHistoryQuickStore,
      project: project,
    );

    ProjectRestoreStream stream = ProjectRestoreStream(restorationData);

    BoardLinkingActionMode? boardLinkingAction = BoardLinkingActionMode.values
        .where((a) => a.label == restorationData!.boardLinkingActionMode)
        .firstOrNull;

    final diff = RestorableButtonDiff(
      changes: restorationData.openButtonDiff,
      restoreStream: stream,
      boardLinkingAction: boardLinkingAction,
    );
    final popupHistory = BoardScreenPopupHistory(
      restorationData.currentPopupHistory,
      restoreSteam: stream,
    );

    restorationData.currentUndoStack;

    return BoardScreen(
      project: project,
      restoreStream: stream,
      restorationData: restorationData,
      selectionHistory: selectionHistory,
      popupHistory: popupHistory,
      restorableButtonDiff: diff,
    );
  }
}
