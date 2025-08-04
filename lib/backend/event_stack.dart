import 'dart:collection';
import 'dart:ui';

import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/obf.dart';
import 'package:parrotaac/backend/project/code_gen_allowed/event/project_events.dart';
import 'package:parrotaac/backend/stack.dart';

class EventHistory {
  ///the bool should be true if the caller is currently undoing an event.
  final void Function(ProjectEvent, bool) executeEvent;
  final QueueStack<ProjectEvent> _undoStack;
  final QueueStack<ProjectEvent> _redoStack;

  ///stores every button that has been removed since the last clear
  ///In the future this could be made to be updated when undoing and then doing another event however for now this seems impractical
  final Queue<ButtonData> _removedButtons = Queue();
  final Queue<Obf> _removedBoards = Queue();
  final Queue<List<ButtonData?>> _removedRowsAndCols = Queue();
  EventHistory({
    required this.executeEvent,
    VoidCallback? onUndoStackChange,
    VoidCallback? onRedoStackChange,
  })  : _undoStack = QueueStack<ProjectEvent>(onChange: onUndoStackChange),
        _redoStack = QueueStack<ProjectEvent>(onChange: onRedoStackChange);
  void undo() {
    ProjectEvent event = _undoStack.pop();
    executeEvent(event.undoEvent(), true);
    _redoStack.push(event);
  }

  UnmodifiableListView<ProjectEvent> get undoList =>
      UnmodifiableListView(_undoStack.toList());
  UnmodifiableListView<ProjectEvent> get redoList =>
      UnmodifiableListView(_redoStack.toList());

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _removedBoards.clear();
    _removedButtons.clear();
    _removedRowsAndCols.clear();
  }

  void redo() {
    ProjectEvent event = _redoStack.pop();
    executeEvent(event, false);
    _undoStack.push(event);
  }

  void updateRedoStack(Iterable<ProjectEvent> events) =>
      _redoStack.update(events);

  ButtonData? getLastRemovedButton() {
    if (_removedButtons.isEmpty) {
      return null;
    }
    return _removedButtons.removeLast();
  }

  void addRemovedRowOrCol(List<ButtonData?> data) {
    _removedRowsAndCols.add(data);
  }

  void addRemoveBoard(Obf board) {
    _removedBoards.add(board);
  }

  List<ButtonData?>? getLastRemovedRowOrCol() {
    if (_removedRowsAndCols.isEmpty) {
      return null;
    }
    return _removedRowsAndCols.removeLast();
  }

  Obf? getLastRemovedBoard() {
    if (_removedBoards.isEmpty) {
      return null;
    }
    return _removedBoards.removeLast();
  }

  void add(ProjectEvent event) {
    _undoStack.push(event);
    _redoStack.clear();
  }

  void addToRemovedButtons(ButtonData bd) {
    _removedButtons.add(bd);
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
}
