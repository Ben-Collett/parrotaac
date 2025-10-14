import 'dart:collection';

import 'package:parrotaac/backend/project_restore_write_stream.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/ui/codgen/board_screen_popups.dart';

class BoardScreenPopupHistory {
  final Queue<BoardScreenPopup> _toRecover;
  final Queue<BoardScreenPopup> _history = Queue();
  final ProjectRestoreStream? restoreSteam;
  BoardScreenPopupHistory(
    List<BoardScreenPopup>? initialHistory, {
    this.restoreSteam,
  }) : _toRecover = Queue.from(initialHistory ?? []);

  void pushScreen(BoardScreenPopup popup, {bool writeHistory = true}) {
    _logNullStreamWarning();
    _history.add(popup);
    if (writeHistory) {
      restoreSteam?.updateProjectPopupHistory(_history.toList());
    }
  }

  BoardScreenPopup popScreen() {
    _logNullStreamWarning();
    final out = _history.removeLast();
    restoreSteam?.updateProjectPopupHistory(_history.toList());
    return out;
  }

  BoardScreenPopup? get topScreen {
    if (_history.isEmpty) return null;
    return _history.last;
  }

  void write() {
    _logNullStreamWarning();
    restoreSteam?.updateProjectPopupHistory(_history.toList());
  }

  void _logNullStreamWarning() {
    if (restoreSteam == null) {
      SimpleLogger().logWarning(
        "restore stream is null not writing popup history to disk",
      );
    }
  }

  BoardScreenPopup? removeNextToRecover() {
    if (_toRecover.isEmpty) return null;
    return _toRecover.removeFirst();
  }
}
