import 'dart:async';
import 'package:parrotaac/backend/mutex.dart';
import 'package:parrotaac/backend/project/code_gen_allowed/event/project_events.dart';
import 'package:parrotaac/backend/state_restoration_utils.dart';
import 'package:parrotaac/ui/codgen/board_screen_popups.dart';
import 'package:parrotaac/ui/widgets/sentence_box.dart';

import '../ui/board_modes.dart';

class ProjectRestoreStream {
  final _stream = StreamController<_ProjectRestoreEvent>();
  final ProjectRestorationData data;
  final Map<Type, DateTime> _createdMap;
  final MutexTypeMap locks = MutexTypeMap();

  ProjectRestoreStream(this.data) : _createdMap = {} {
    _stream.stream.listen(_update);
  }
  void updateBoardMode(BoardMode mode) {
    _stream.sink.add(_UpdateBoardMode(mode));
  }

  void updateShowSentenceBar(bool value) {
    _stream.sink.add(_ShowSentenceBar(value));
  }

  void updateShowSideBar(bool value) {
    _stream.sink.add(_ShowSideBar(value));
  }

  void updateProjectPopupHistory(List<BoardScreenPopup> popups) {
    _stream.sink.add(_UpdatePopups(popups));
  }

  void removeCurrentButtonData() {
    //TODO: potinteial edge case where the user opens another button config before this one deletes
    _stream.sink.add(_RemoveCurrentButtonData());
  }

  void updateCurrentButtonDiff(Map<String, dynamic> diff) {
    _stream.sink.add(_UpdateButtonDiff(diff));
  }

  void updateCurrentButtonBoardLinkingAction(String? action) {
    _stream.sink.add(_UpdateBoardLinkingAction(action));
  }

  void updateHistory(List<String> boardIds) =>
      _stream.sink.add(_UpdateBoardHistory(boardIds));

  void updateUndoStack(List<ProjectEvent> events) =>
      _stream.sink.add(_UpdateUndoEventHistory(events));

  void updateRedoStack(List<ProjectEvent> events) =>
      _stream.sink.add(_UpdateRedoEventHistory(events));

  void updateSentenceBar(List<SenteceBoxDisplayEntry> data) {
    bool hasBoard(SenteceBoxDisplayEntry entry) => entry.board != null;
    BoardButtonPair toIdPair(SenteceBoxDisplayEntry entry) =>
        BoardButtonPair(buttonId: entry.data.id, boardId: entry.board!.id);

    List<BoardButtonPair> pairs = data.where(hasBoard).map(toIdPair).toList();

    _stream.sink.add(_UpdateSentenceBox(pairs));
  }

  void _update(_ProjectRestoreEvent event) async {
    locks.synchronized(
      object: event,
      computation: () async {
        if (_shouldAdd(event)) {
          _updateTimestamp(event);
          await event.update(data);
        }
      },
    );
  }

  void _updateTimestamp(_ProjectRestoreEvent event) {
    _createdMap[event.runtimeType] = event.createdAt;
  }

  bool _shouldAdd(_ProjectRestoreEvent event) {
    DateTime prevTime = _createdMap[event.runtimeType] ?? DateTime(0);

    return event.wasCreatedMoreRecentThenOrAtSameTimeAs(prevTime);
  }

  Future<void> close() async {
    _stream.close();
    await data.close();
  }
}

class BoardButtonPair {
  final String buttonId;
  final String boardId;
  static const _boardKey = "board_id";
  static const _buttonKey = "button_key";
  Map<String, String> get asMap => {_boardKey: boardId, _buttonKey: buttonId};
  const BoardButtonPair({required this.buttonId, required this.boardId});

  static BoardButtonPair? fromMap(Map map) {
    if (map[_boardKey] is String && map[_buttonKey] is String) {
      final String boardId = map[_boardKey];
      final String buttonId = map[_buttonKey];
      return BoardButtonPair(buttonId: buttonId, boardId: boardId);
    }
    return null;
  }

  @override
  String toString() => asMap.toString();
}

abstract class _ProjectRestoreEvent with TimeStamped {
  Future<void> update(ProjectRestorationData data);
}

class _UpdateBoardLinkingAction extends _ProjectRestoreEvent {
  final String? action;
  _UpdateBoardLinkingAction(this.action);

  @override
  Future<void> update(ProjectRestorationData data) =>
      data.writeBoardLinkingAction(action);
}

class _UpdateBoardHistory extends _ProjectRestoreEvent {
  final List<String> ids;
  _UpdateBoardHistory(this.ids);

  @override
  Future<void> update(ProjectRestorationData data) =>
      data.writeNewBoardHistory(ids);
}

class _UpdateSentenceBox extends _ProjectRestoreEvent {
  List<BoardButtonPair> buttons;
  _UpdateSentenceBox(this.buttons);

  @override
  Future<void> update(ProjectRestorationData data) =>
      data.writeSentenceBoxHistory(buttons);
}

class _UpdateUndoEventHistory extends _ProjectRestoreEvent {
  final List<ProjectEvent> events;
  _UpdateUndoEventHistory(this.events);

  @override
  Future<void> update(ProjectRestorationData data) =>
      data.writeUndoStack(events);
}

class _UpdateRedoEventHistory extends _ProjectRestoreEvent {
  final List<ProjectEvent> events;
  _UpdateRedoEventHistory(this.events);

  @override
  Future<void> update(ProjectRestorationData data) =>
      data.writeRedoStack(events);
}

class _UpdatePopups extends _ProjectRestoreEvent {
  List<BoardScreenPopup> popups;
  _UpdatePopups(this.popups);

  @override
  Future<void> update(ProjectRestorationData data) =>
      data.writePopupHistory(popups);
}

class _UpdateBoardMode extends _ProjectRestoreEvent {
  final BoardMode mode;

  _UpdateBoardMode(this.mode);
  @override
  Future<void> update(ProjectRestorationData data) => data.writeBoardMode(mode);
}

class _ShowSentenceBar extends _ProjectRestoreEvent {
  final bool value;

  _ShowSentenceBar(this.value);
  @override
  Future<void> update(ProjectRestorationData data) =>
      data.writeShowSentenceBar(value);
}

class _ShowSideBar extends _ProjectRestoreEvent {
  final bool value;
  _ShowSideBar(this.value);

  @override
  Future<void> update(ProjectRestorationData data) =>
      data.writeShowSideBar(value);
}

class _RemoveCurrentButtonData extends _ProjectRestoreEvent {
  @override
  Future<void> update(ProjectRestorationData data) =>
      data.removeCurrentButtonData();
}

class _UpdateButtonDiff extends _ProjectRestoreEvent {
  final Map<String, dynamic> diff;
  _UpdateButtonDiff(this.diff);

  @override
  Future<void> update(ProjectRestorationData data) =>
      data.writeButtonDiff(diff);
}

mixin TimeStamped {
  final DateTime createdAt = DateTime.now();
  bool wasCreatedMoreRecentThenOrAtSameTimeAs(DateTime other) =>
      createdAt.compareTo(other) >= 0;
}
